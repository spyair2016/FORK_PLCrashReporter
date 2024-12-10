/*
 * Author: Landon Fuller <landonf@plausible.coop>
 *
 * Copyright (c) 2012-2013 Plausible Labs Cooperative, Inc.
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

/*
 * For external library integrators:
 *
 * Set this value to any valid C symbol prefix. This will automatically
 * prepend the given prefix to all external symbols in the library.
 *
 * This may be used to avoid symbol conflicts between multiple libraries
 * that may both incorporate PLCrashReporter.
 */
// #define PLCRASHREPORTER_PREFIX AcmeCo


// We need two extra layers of indirection to make CPP substitute
// the PLCRASHREPORTER_PREFIX define.
#define MTDPLNS_impl2(prefix, symbol) prefix ## symbol
#define MTDPLNS_impl(prefix, symbol) MTDPLNS_impl2(prefix, symbol)
#define MTDPLNS(symbol) MTDPLNS_impl(MTDPLCRASHREPORTER_PREFIX, symbol)


/*
 * Rewrite all ObjC/C symbols.
 *
 * For C++ symbol handling, refer to the MTDPLCR_CPP_BEGIN_NS and MTDPLCR_CPP_END_NS
 * macros.
 */
#ifdef MTDPLCRASHREPORTER_PREFIX

/* Objective-C Classes */
#define MTDPLCrashMachExceptionServer          MTDPLNS(MTDPLCrashMachExceptionServer)
#define MTDPLCrashReport                       MTDPLNS(MTDPLCrashReport)
#define MTDPLCrashReportApplicationInfo        MTDPLNS(MTDPLCrashReportApplicationInfo)
#define MTDPLCrashReportBinaryImageInfo        MTDPLNS(MTDPLCrashReportBinaryImageInfo)
#define MTDPLCrashReportExceptionInfo          MTDPLNS(MTDPLCrashReportExceptionInfo)
#define MTDPLCrashReportMachExceptionInfo      MTDPLNS(MTDPLCrashReportMachExceptionInfo)
#define MTDPLCrashReportMachineInfo            MTDPLNS(MTDPLCrashReportMachineInfo)
#define MTDPLCrashReportProcessInfo            MTDPLNS(MTDPLCrashReportProcessInfo)
#define MTDPLCrashReportProcessorInfo          MTDPLNS(MTDPLCrashReportProcessorInfo)
#define MTDPLCrashReportRegisterInfo           MTDPLNS(MTDPLCrashReportRegisterInfo)
#define MTDPLCrashReportSignalInfo             MTDPLNS(MTDPLCrashReportSignalInfo)
#define MTDPLCrashReportStackFrameInfo         MTDPLNS(MTDPLCrashReportStackFrameInfo)
#define MTDPLCrashReportSymbolInfo             MTDPLNS(MTDPLCrashReportSymbolInfo)
#define MTDPLCrashReportSystemInfo             MTDPLNS(MTDPLCrashReportSystemInfo)
#define MTDPLCrashReportTextFormatter          MTDPLNS(MTDPLCrashReportTextFormatter)
#define MTDPLCrashReportThreadInfo             MTDPLNS(MTDPLCrashReportThreadInfo)
#define MTDPLCrashReporter                     MTDPLNS(MTDPLCrashReporter)
#define MTDPLCrashSignalHandler                MTDPLNS(MTDPLCrashSignalHandler)
#define MTDPLCrashHostInfo                     MTDPLNS(MTDPLCrashHostInfo)
#define MTDPLCrashMachExceptionPort            MTDPLNS(MTDPLCrashMachExceptionPort)
#define MTDPLCrashMachExceptionPortSet         MTDPLNS(MTDPLCrashMachExceptionPortSet)
#define MTDPLCrashProcessInfo                  MTDPLNS(MTDPLCrashProcessInfo)
#define MTDPLCrashReporterConfig               MTDPLNS(MTDPLCrashReporterConfig)
#define MTDPLCrashUncaughtExceptionHandler     MTDPLNS(MTDPLCrashUncaughtExceptionHandler)
#define MTDPLCrashReportFormatter              MTDPLNS(MTDPLCrashReportFormatter)

/* Public C functions */
#define MTDPLCrashMachExceptionForward         MTDPLNS(MTDPLCrashMachExceptionForward)
#define MTDPLCrashSignalHandlerForward         MTDPLNS(MTDPLCrashSignalHandlerForward)
#define plcrash_signal_handler              MTDPLNS(plcrash_signal_handler)


/* Public C global symbols */
#define MTDPLCrashReporterErrorDomain          MTDPLNS(MTDPLCrashReporterErrorDomain)
#define MTDPLCrashReportHostArchitecture       MTDPLNS(MTDPLCrashReportHostArchitecture)
#define MTDPLCrashReportHostOperatingSystem    MTDPLNS(MTDPLCrashReportHostOperatingSystem)
#define MTDPLCrashReporterException            MTDPLNS(MTDPLCrashReporterException)

/* For backwards compatibility, plcrash_async_byteorder vends C++ methods when included under C++. We have
 * to handle this distinctly from our MTDPLCR_CPP_BEGIN_NS C++ namespacing mechanism. */
#define plcrash_async_byteorder             MTDPLNS(plcrash_async_byteorder)

/*
 * All private C symbols. Once these are migrated to C++, we'll be able to use the much simpler
 * MTDPLCR_CPP_BEGIN_NS machinery.
 *
 * This list was automatically generated (and can be updated) by setting MTDPLCRASHREPORTER_PREFIX to 'AcmeCo',
 * building the library, and executing the following:
 * nm -g -U <static library> | grep '^[0-9]' | c++filt | grep -v AcmeCo | grep -E '_pl|_MTDPL' | awk '{print $3}' | cut -c 2- | sort | uniq | awk '{print "#define",$1,"MTDPLNS("$1")"}'
 */
#define pl_mach_thread_self MTDPLNS(pl_mach_thread_self)
#define plcrash__architecture__descriptor MTDPLNS(plcrash__architecture__descriptor)
#define plcrash__crash_report__application_info__descriptor MTDPLNS(plcrash__crash_report__application_info__descriptor)
#define plcrash__crash_report__application_info__init MTDPLNS(plcrash__crash_report__application_info__init)
#define plcrash__crash_report__binary_image__descriptor MTDPLNS(plcrash__crash_report__binary_image__descriptor)
#define plcrash__crash_report__binary_image__init MTDPLNS(plcrash__crash_report__binary_image__init)
#define plcrash__crash_report__descriptor MTDPLNS(plcrash__crash_report__descriptor)
#define plcrash__crash_report__exception__descriptor MTDPLNS(plcrash__crash_report__exception__descriptor)
#define plcrash__crash_report__exception__init MTDPLNS(plcrash__crash_report__exception__init)
#define plcrash__crash_report__free_unpacked MTDPLNS(plcrash__crash_report__free_unpacked)
#define plcrash__crash_report__get_packed_size MTDPLNS(plcrash__crash_report__get_packed_size)
#define plcrash__crash_report__init MTDPLNS(plcrash__crash_report__init)
#define plcrash__crash_report__machine_info__descriptor MTDPLNS(plcrash__crash_report__machine_info__descriptor)
#define plcrash__crash_report__machine_info__init MTDPLNS(plcrash__crash_report__machine_info__init)
#define plcrash__crash_report__pack MTDPLNS(plcrash__crash_report__pack)
#define plcrash__crash_report__pack_to_buffer MTDPLNS(plcrash__crash_report__pack_to_buffer)
#define plcrash__crash_report__process_info__descriptor MTDPLNS(plcrash__crash_report__process_info__descriptor)
#define plcrash__crash_report__process_info__init MTDPLNS(plcrash__crash_report__process_info__init)
#define plcrash__crash_report__processor__descriptor MTDPLNS(plcrash__crash_report__processor__descriptor)
#define plcrash__crash_report__processor__init MTDPLNS(plcrash__crash_report__processor__init)
#define plcrash__crash_report__processor__type_encoding__descriptor MTDPLNS(plcrash__crash_report__processor__type_encoding__descriptor)
#define plcrash__crash_report__report_info__descriptor MTDPLNS(plcrash__crash_report__report_info__descriptor)
#define plcrash__crash_report__report_info__init MTDPLNS(plcrash__crash_report__report_info__init)
#define plcrash__crash_report__signal__descriptor MTDPLNS(plcrash__crash_report__signal__descriptor)
#define plcrash__crash_report__signal__init MTDPLNS(plcrash__crash_report__signal__init)
#define plcrash__crash_report__signal__mach_exception__descriptor MTDPLNS(plcrash__crash_report__signal__mach_exception__descriptor)
#define plcrash__crash_report__signal__mach_exception__init MTDPLNS(plcrash__crash_report__signal__mach_exception__init)
#define plcrash__crash_report__symbol__descriptor MTDPLNS(plcrash__crash_report__symbol__descriptor)
#define plcrash__crash_report__symbol__init MTDPLNS(plcrash__crash_report__symbol__init)
#define plcrash__crash_report__system_info__descriptor MTDPLNS(plcrash__crash_report__system_info__descriptor)
#define plcrash__crash_report__system_info__init MTDPLNS(plcrash__crash_report__system_info__init)
#define plcrash__crash_report__system_info__operating_system__descriptor MTDPLNS(plcrash__crash_report__system_info__operating_system__descriptor)
#define plcrash__crash_report__thread__descriptor MTDPLNS(plcrash__crash_report__thread__descriptor)
#define plcrash__crash_report__thread__init MTDPLNS(plcrash__crash_report__thread__init)
#define plcrash__crash_report__thread__register_value__descriptor MTDPLNS(plcrash__crash_report__thread__register_value__descriptor)
#define plcrash__crash_report__thread__register_value__init MTDPLNS(plcrash__crash_report__thread__register_value__init)
#define plcrash__crash_report__thread__stack_frame__descriptor MTDPLNS(plcrash__crash_report__thread__stack_frame__descriptor)
#define plcrash__crash_report__thread__stack_frame__init MTDPLNS(plcrash__crash_report__thread__stack_frame__init)
#define plcrash__crash_report__unpack MTDPLNS(plcrash__crash_report__unpack)
#define plcrash_async_address_apply_offset MTDPLNS(plcrash_async_address_apply_offset)
#define plcrash_async_byteorder_big_endian MTDPLNS(plcrash_async_byteorder_big_endian)
#define plcrash_async_byteorder_direct MTDPLNS(plcrash_async_byteorder_direct)
#define plcrash_async_byteorder_little_endian MTDPLNS(plcrash_async_byteorder_little_endian)
#define plcrash_async_byteorder_swapped MTDPLNS(plcrash_async_byteorder_swapped)
#define plcrash_async_cfe_entry_apply MTDPLNS(plcrash_async_cfe_entry_apply)
#define plcrash_async_cfe_entry_free MTDPLNS(plcrash_async_cfe_entry_free)
#define plcrash_async_cfe_entry_init MTDPLNS(plcrash_async_cfe_entry_init)
#define plcrash_async_cfe_entry_register_count MTDPLNS(plcrash_async_cfe_entry_register_count)
#define plcrash_async_cfe_entry_register_list MTDPLNS(plcrash_async_cfe_entry_register_list)
#define plcrash_async_cfe_entry_return_address_register MTDPLNS(plcrash_async_cfe_entry_return_address_register)
#define plcrash_async_cfe_entry_stack_adjustment MTDPLNS(plcrash_async_cfe_entry_stack_adjustment)
#define plcrash_async_cfe_entry_stack_offset MTDPLNS(plcrash_async_cfe_entry_stack_offset)
#define plcrash_async_cfe_entry_type MTDPLNS(plcrash_async_cfe_entry_type)
#define plcrash_async_cfe_reader_find_pc MTDPLNS(plcrash_async_cfe_reader_find_pc)
#define plcrash_async_cfe_reader_free MTDPLNS(plcrash_async_cfe_reader_free)
#define plcrash_async_cfe_reader_init MTDPLNS(plcrash_async_cfe_reader_init)
#define plcrash_async_cfe_register_decode MTDPLNS(plcrash_async_cfe_register_decode)
#define plcrash_async_cfe_register_encode MTDPLNS(plcrash_async_cfe_register_encode)
#define plcrash_async_file_close MTDPLNS(plcrash_async_file_close)
#define plcrash_async_file_flush MTDPLNS(plcrash_async_file_flush)
#define plcrash_async_file_init MTDPLNS(plcrash_async_file_init)
#define plcrash_async_file_write MTDPLNS(plcrash_async_file_write)
#define plcrash_async_find_symbol MTDPLNS(plcrash_async_find_symbol)
#define plcrash_async_image_containing_address MTDPLNS(plcrash_async_image_containing_address)
#define plcrash_async_image_list_next MTDPLNS(plcrash_async_image_list_next)
#define plcrash_async_image_list_set_reading MTDPLNS(plcrash_async_image_list_set_reading)
#define plcrash_async_mach_exception_get_siginfo MTDPLNS(plcrash_async_mach_exception_get_siginfo)
#define plcrash_async_macho_byteorder MTDPLNS(plcrash_async_macho_byteorder)
#define plcrash_async_macho_contains_address MTDPLNS(plcrash_async_macho_contains_address)
#define plcrash_async_macho_cpu_subtype MTDPLNS(plcrash_async_macho_cpu_subtype)
#define plcrash_async_macho_cpu_type MTDPLNS(plcrash_async_macho_cpu_type)
#define plcrash_async_macho_find_command MTDPLNS(plcrash_async_macho_find_command)
#define plcrash_async_macho_find_segment_cmd MTDPLNS(plcrash_async_macho_find_segment_cmd)
#define plcrash_async_macho_find_symbol_by_name MTDPLNS(plcrash_async_macho_find_symbol_by_name)
#define plcrash_async_macho_find_symbol_by_pc MTDPLNS(plcrash_async_macho_find_symbol_by_pc)
#define plcrash_async_macho_header MTDPLNS(plcrash_async_macho_header)
#define plcrash_async_macho_header_size MTDPLNS(plcrash_async_macho_header_size)
#define plcrash_async_macho_map_section MTDPLNS(plcrash_async_macho_map_section)
#define plcrash_async_macho_map_segment MTDPLNS(plcrash_async_macho_map_segment)
#define plcrash_async_macho_mapped_segment_free MTDPLNS(plcrash_async_macho_mapped_segment_free)
#define plcrash_async_macho_next_command MTDPLNS(plcrash_async_macho_next_command)
#define plcrash_async_macho_next_command_type MTDPLNS(plcrash_async_macho_next_command_type)
#define plcrash_async_macho_string_free MTDPLNS(plcrash_async_macho_string_free)
#define plcrash_async_macho_string_get_length MTDPLNS(plcrash_async_macho_string_get_length)
#define plcrash_async_macho_string_get_pointer MTDPLNS(plcrash_async_macho_string_get_pointer)
#define plcrash_async_macho_string_init MTDPLNS(plcrash_async_macho_string_init)
#define plcrash_async_macho_symtab_reader_free MTDPLNS(plcrash_async_macho_symtab_reader_free)
#define plcrash_async_macho_symtab_reader_init MTDPLNS(plcrash_async_macho_symtab_reader_init)
#define plcrash_async_macho_symtab_reader_read MTDPLNS(plcrash_async_macho_symtab_reader_read)
#define plcrash_async_macho_symtab_reader_symbol_name MTDPLNS(plcrash_async_macho_symtab_reader_symbol_name)
#define plcrash_async_memcpy MTDPLNS(plcrash_async_memcpy)
#define plcrash_async_memset MTDPLNS(plcrash_async_memset)
#define plcrash_async_mobject_base_address MTDPLNS(plcrash_async_mobject_base_address)
#define plcrash_async_mobject_free MTDPLNS(plcrash_async_mobject_free)
#define plcrash_async_mobject_init MTDPLNS(plcrash_async_mobject_init)
#define plcrash_async_mobject_length MTDPLNS(plcrash_async_mobject_length)
#define plcrash_async_mobject_read_uint16 MTDPLNS(plcrash_async_mobject_read_uint16)
#define plcrash_async_mobject_read_uint32 MTDPLNS(plcrash_async_mobject_read_uint32)
#define plcrash_async_mobject_read_uint64 MTDPLNS(plcrash_async_mobject_read_uint64)
#define plcrash_async_mobject_read_uint8 MTDPLNS(plcrash_async_mobject_read_uint8)
#define plcrash_async_mobject_remap_address MTDPLNS(plcrash_async_mobject_remap_address)
#define plcrash_async_mobject_task MTDPLNS(plcrash_async_mobject_task)
#define plcrash_async_mobject_verify_local_pointer MTDPLNS(plcrash_async_mobject_verify_local_pointer)
#define plcrash_async_objc_cache_free MTDPLNS(plcrash_async_objc_cache_free)
#define plcrash_async_objc_cache_init MTDPLNS(plcrash_async_objc_cache_init)
#define plcrash_async_objc_find_method MTDPLNS(plcrash_async_objc_find_method)
#define plcrash_async_signal_sigcode MTDPLNS(plcrash_async_signal_sigcode)
#define plcrash_async_signal_signame MTDPLNS(plcrash_async_signal_signame)
#define plcrash_async_strcmp MTDPLNS(plcrash_async_strcmp)
#define plcrash_async_strerror MTDPLNS(plcrash_async_strerror)
#define plcrash_async_strncmp MTDPLNS(plcrash_async_strncmp)
#define plcrash_async_symbol_cache_free MTDPLNS(plcrash_async_symbol_cache_free)
#define plcrash_async_symbol_cache_init MTDPLNS(plcrash_async_symbol_cache_init)
#define plcrash_async_task_memcpy MTDPLNS(plcrash_async_task_memcpy)
#define plcrash_async_task_read_uint16 MTDPLNS(plcrash_async_task_read_uint16)
#define plcrash_async_task_read_uint32 MTDPLNS(plcrash_async_task_read_uint32)
#define plcrash_async_task_read_uint64 MTDPLNS(plcrash_async_task_read_uint64)
#define plcrash_async_task_read_uint8 MTDPLNS(plcrash_async_task_read_uint8)
#define plcrash_async_thread_state_clear_all_regs MTDPLNS(plcrash_async_thread_state_clear_all_regs)
#define plcrash_async_thread_state_clear_reg MTDPLNS(plcrash_async_thread_state_clear_reg)
#define plcrash_async_thread_state_clear_volatile_regs MTDPLNS(plcrash_async_thread_state_clear_volatile_regs)
#define plcrash_async_thread_state_copy MTDPLNS(plcrash_async_thread_state_copy)
#define plcrash_async_thread_state_current MTDPLNS(plcrash_async_thread_state_current)
#define plcrash_async_thread_state_current_stub MTDPLNS(plcrash_async_thread_state_current_stub)
#define plcrash_async_thread_state_get_greg_size MTDPLNS(plcrash_async_thread_state_get_greg_size)
#define plcrash_async_thread_state_get_reg MTDPLNS(plcrash_async_thread_state_get_reg)
#define plcrash_async_thread_state_get_reg_count MTDPLNS(plcrash_async_thread_state_get_reg_count)
#define plcrash_async_thread_state_get_reg_name MTDPLNS(plcrash_async_thread_state_get_reg_name)
#define plcrash_async_thread_state_get_stack_direction MTDPLNS(plcrash_async_thread_state_get_stack_direction)
#define plcrash_async_thread_state_has_reg MTDPLNS(plcrash_async_thread_state_has_reg)
#define plcrash_async_thread_state_init MTDPLNS(plcrash_async_thread_state_init)
#define plcrash_async_thread_state_mach_thread_init MTDPLNS(plcrash_async_thread_state_mach_thread_init)
#define plcrash_async_thread_state_map_dwarf_to_reg MTDPLNS(plcrash_async_thread_state_map_dwarf_to_reg)
#define plcrash_async_thread_state_map_reg_to_dwarf MTDPLNS(plcrash_async_thread_state_map_reg_to_dwarf)
#define plcrash_async_thread_state_mcontext_init MTDPLNS(plcrash_async_thread_state_mcontext_init)
#define plcrash_async_thread_state_set_reg MTDPLNS(plcrash_async_thread_state_set_reg)
#define plcrash_async_writen MTDPLNS(plcrash_async_writen)
#define plcrash_log_writer_close MTDPLNS(plcrash_log_writer_close)
#define plcrash_log_writer_free MTDPLNS(plcrash_log_writer_free)
#define plcrash_log_writer_init MTDPLNS(plcrash_log_writer_init)
#define plcrash_log_writer_set_exception MTDPLNS(plcrash_log_writer_set_exception)
#define plcrash_log_writer_write MTDPLNS(plcrash_log_writer_write)
#define plcrash_log_writer_set_custom_data MTDPLNS(plcrash_log_writer_set_custom_data)
#define plcrash_nasync_image_list_append MTDPLNS(plcrash_nasync_image_list_append)
#define plcrash_nasync_image_list_free MTDPLNS(plcrash_nasync_image_list_free)
#define plcrash_nasync_image_list_init MTDPLNS(plcrash_nasync_image_list_init)
#define plcrash_nasync_image_list_remove MTDPLNS(plcrash_nasync_image_list_remove)
#define plcrash_nasync_macho_free MTDPLNS(plcrash_nasync_macho_free)
#define plcrash_nasync_macho_init MTDPLNS(plcrash_nasync_macho_init)
#define plcrash_populate_error MTDPLNS(plcrash_populate_error)
#define plcrash_populate_mach_error MTDPLNS(plcrash_populate_mach_error)
#define plcrash_populate_posix_error MTDPLNS(plcrash_populate_posix_error)
#define plcrash_signal_handler MTDPLNS(plcrash_signal_handler)
#define plcrash_sysctl_int MTDPLNS(plcrash_sysctl_int)
#define plcrash_sysctl_string MTDPLNS(plcrash_sysctl_string)
#define plcrash_sysctl_valid_utf8_bytes MTDPLNS(plcrash_sysctl_valid_utf8_bytes)
#define plcrash_sysctl_valid_utf8_bytes_max MTDPLNS(plcrash_sysctl_valid_utf8_bytes_max)
#define plcrash_writer_pack MTDPLNS(plcrash_writer_pack)
#define plframe_cursor_free MTDPLNS(plframe_cursor_free)
#define plframe_cursor_get_reg MTDPLNS(plframe_cursor_get_reg)
#define plframe_cursor_get_regcount MTDPLNS(plframe_cursor_get_regcount)
#define plframe_cursor_get_regname MTDPLNS(plframe_cursor_get_regname)
#define plframe_cursor_init MTDPLNS(plframe_cursor_init)
#define plframe_cursor_next MTDPLNS(plframe_cursor_next)
#define plframe_cursor_next_with_readers MTDPLNS(plframe_cursor_next_with_readers)
#define plframe_cursor_read_compact_unwind MTDPLNS(plframe_cursor_read_compact_unwind)
#define plframe_cursor_read_dwarf_unwind MTDPLNS(plframe_cursor_read_dwarf_unwind)
#define plframe_cursor_read_frame_ptr MTDPLNS(plframe_cursor_read_frame_ptr)
#define plframe_cursor_thread_init MTDPLNS(plframe_cursor_thread_init)
#define plframe_strerror MTDPLNS(plframe_strerror)

#endif

/*
 * The following symbols are exported by the protobuf-c library. When building
 * a shared library, we can hide these as private symbols.
 *
 * However, when building a static library, we can only do so if we use
 * MH_OBJECT "single object prelink". The MH_OBJECT approach allows us to apply
 * symbol hiding/aliasing/etc similar to that supported by dylibs, but because it is
 * seemingly unused within Apple, the use thereof regularly introduces linking bugs
 * and errors in new Xcode releases.
 *
 * Rather than fighting the linker, we use the namespacing machinery to rewrite these
 * symbols, but only when explicitly compiling MTDPLCrashReporter. Since protobuf-c is a library
 * that may be used elsewhere, we don't want to rewrite these symbols if they're used
 * independently by MTDPLCrashReporter API clients.
 */
#ifdef MTDPLCR_PRIVATE
   /* If no prefix has been defined, we need to specify our own private prefix */
#  ifndef MTDPLCRASHREPORTER_PREFIX
#    define MTDPLCRASHREPORTER_PREFIX MTDPL_
#  endif

#  define protobuf_c_buffer_simple_append                   MTDPLNS(protobuf_c_buffer_simple_append)
#  define protobuf_c_empty_string                           MTDPLNS(protobuf_c_empty_string)
#  define protobuf_c_enum_descriptor_get_value              MTDPLNS(protobuf_c_enum_descriptor_get_value)
#  define protobuf_c_enum_descriptor_get_value_by_name      MTDPLNS(protobuf_c_enum_descriptor_get_value_by_name)
#  define protobuf_c_message_check                          MTDPLNS(protobuf_c_message_check)
#  define protobuf_c_message_descriptor_get_field           MTDPLNS(protobuf_c_message_descriptor_get_field)
#  define protobuf_c_message_descriptor_get_field_by_name   MTDPLNS(protobuf_c_message_descriptor_get_field_by_name)
#  define protobuf_c_message_free_unpacked                  MTDPLNS(protobuf_c_message_free_unpacked)
#  define protobuf_c_message_get_packed_size                MTDPLNS(protobuf_c_message_get_packed_size)
#  define protobuf_c_message_init                           MTDPLNS(protobuf_c_message_init)
#  define protobuf_c_message_pack                           MTDPLNS(protobuf_c_message_pack)
#  define protobuf_c_message_pack_to_buffer                 MTDPLNS(protobuf_c_message_pack_to_buffer)
#  define protobuf_c_message_unpack                         MTDPLNS(protobuf_c_message_unpack)
#  define protobuf_c_service_descriptor_get_method_by_name  MTDPLNS(protobuf_c_service_descriptor_get_method_by_name)
#  define protobuf_c_service_destroy                        MTDPLNS(protobuf_c_service_destroy)
#  define protobuf_c_service_generated_init                 MTDPLNS(protobuf_c_service_generated_init)
#  define protobuf_c_service_invoke_internal                MTDPLNS(protobuf_c_service_invoke_internal)
#  define protobuf_c_version                                MTDPLNS(protobuf_c_version)
#  define protobuf_c_version_number                         MTDPLNS(protobuf_c_version_number)
#endif /* MTDPLCR_PRIVATE */
