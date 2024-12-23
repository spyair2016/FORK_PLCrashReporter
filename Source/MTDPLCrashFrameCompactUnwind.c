/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */


#include "MTDPLCrashFrameCompactUnwind.h"
#include "MTDPLCrashAsyncCompactUnwindEncoding.h"
#include "MTDPLCrashFeatureConfig.h"

#include <inttypes.h>

#if MTDPLCRASH_FEATURE_UNWIND_DWARF

/**
 * Attempt to fetch next frame using compact frame unwinding data from @a image_list.
 *
 * @param task The task containing the target frame stack.
 * @param image_list The list of images loaded in the target @a task.
 * @param current_frame The current stack frame.
 * @param previous_frame The previous stack frame, or NULL if this is the first frame.
 * @param next_frame The new frame to be initialized.
 *
 * @return Returns MTDPLFRAME_ESUCCESS on success, MTDPLFRAME_ENOFRAME is no additional frames are available, or a standard plframe_error_t code if an error occurs.
 */
plframe_error_t plframe_cursor_read_compact_unwind (task_t task,
                                                    plcrash_async_image_list_t *image_list,
                                                    const plframe_stackframe_t *current_frame,
                                                    const plframe_stackframe_t *previous_frame,
                                                    plframe_stackframe_t *next_frame)
{
    plframe_error_t result;
    plcrash_error_t err;

    /* Fetch the IP. It should always be available */
    if (!plcrash_async_thread_state_has_reg(&current_frame->thread_state, MTDPLCRASH_REG_IP)) {
        MTDPLCF_DEBUG("Frame is missing a valid IP register, skipping compact unwind encoding");
        return MTDPLFRAME_EBADFRAME;
    }
    plcrash_greg_t pc = plcrash_async_thread_state_get_reg(&current_frame->thread_state, MTDPLCRASH_REG_IP);
    if (pc == 0) {
        return MTDPLFRAME_ENOTSUP;
    }
    
    /* Find the corresponding image */
    plcrash_async_image_list_set_reading(image_list, true);
    plcrash_async_image_t *image = plcrash_async_image_containing_address(image_list, (pl_vm_address_t) pc);
    if (image == NULL) {
        MTDPLCF_DEBUG("Could not find a loaded image for the current frame pc: 0x%" PRIx64, (uint64_t) pc);
        result = MTDPLFRAME_ENOTSUP;
        goto cleanup;
    }
    
    /* Map the unwind section */
    plcrash_async_mobject_t unwind_mobj;
    err = plcrash_async_macho_map_section(&image->macho_image, SEG_TEXT, "__unwind_info", &unwind_mobj);
    if (err != MTDPLCRASH_ESUCCESS) {
        if (err != MTDPLCRASH_ENOTFOUND)
            MTDPLCF_DEBUG("Could not map the compact unwind info section for image %s: %d", image->macho_image.name, err);
        result = MTDPLFRAME_ENOTSUP;
        goto cleanup;
    }

    /* Initialize the CFE reader. */
    cpu_type_t cputype = image->macho_image.byteorder->swap32(image->macho_image.header.cputype);
    plcrash_async_cfe_reader_t reader;

    err = plcrash_async_cfe_reader_init(&reader, &unwind_mobj, cputype);
    if (err != MTDPLCRASH_ESUCCESS) {
        MTDPLCF_DEBUG("Could not parse the compact unwind info section for image '%s': %d", image->macho_image.name, err);
        result = MTDPLFRAME_EINVAL;
        goto cleanup_mobject;
    }

    /* Find the encoding entry (if any) and free the reader */
    pl_vm_address_t function_base;
    uint32_t encoding;
    err = plcrash_async_cfe_reader_find_pc(&reader, (pl_vm_address_t)(pc - image->macho_image.header_addr), &function_base, &encoding);
    plcrash_async_cfe_reader_free(&reader);
    if (err != MTDPLCRASH_ESUCCESS) {
        MTDPLCF_DEBUG("Did not find CFE entry for PC 0x%" PRIx64 ": %d", (uint64_t) pc, err);
        result = MTDPLFRAME_ENOTSUP;
        goto cleanup_mobject;
    }
    
    /* Decode the entry */
    plcrash_async_cfe_entry_t entry;
    err = plcrash_async_cfe_entry_init(&entry, cputype, encoding);
    if (err != MTDPLCRASH_ESUCCESS) {
        MTDPLCF_DEBUG("Could not decode CFE encoding 0x%" PRIx32 " for PC 0x%" PRIx64 ": %d", encoding, (uint64_t) pc, err);
        result = MTDPLFRAME_ENOTSUP;
        goto cleanup_mobject;
    }

    /* Skip entries for which no unwind information is unavailable */
    if (plcrash_async_cfe_entry_type(&entry) == MTDPLCRASH_ASYNC_CFE_ENTRY_TYPE_NONE) {
        result = MTDPLFRAME_ENOFRAME;
        goto cleanup_cfe_entry;
    }
    
    /* Compute the in-core function address */
    pl_vm_address_t function_address;
    if (!plcrash_async_address_apply_offset(image->macho_image.header_addr, function_base, &function_address)) {
        MTDPLCF_DEBUG("The provided function base (0x%" PRIx64 ") plus header address (0x%" PRIx64 ") will overflow pl_vm_address_t",
                   (uint64_t) function_base, (uint64_t) image->macho_image.header_addr);
        result = MTDPLFRAME_EINVAL;
        goto cleanup_cfe_entry;
    }

    /* Apply the frame delta -- this may fail. */
    MTDPLCF_UNUSED_IN_RELEASE plcrash_error_t debugError;
    if ((debugError = plcrash_async_cfe_entry_apply(task, function_address, &current_frame->thread_state, &entry, &next_frame->thread_state)) == MTDPLCRASH_ESUCCESS) {
        result = MTDPLFRAME_ESUCCESS;
    } else {
        MTDPLCF_DEBUG("Failed to apply CFE encoding 0x%" PRIx32 " for PC 0x%" PRIx64 ": %d", encoding, (uint64_t) pc, debugError);
        result = MTDPLFRAME_ENOFRAME;
    }

cleanup_cfe_entry:
    plcrash_async_cfe_entry_free(&entry);
cleanup_mobject:
    plcrash_async_mobject_free(&unwind_mobj);
cleanup:
    plcrash_async_image_list_set_reading(image_list, false);
    return result;
}

#endif /* MTDPLCRASH_FEATURE_UNWIND_DWARF */
