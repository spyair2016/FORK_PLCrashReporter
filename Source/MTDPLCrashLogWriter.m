/*
 * Author: Landon Fuller <landonf@plausiblelabs.com>
 *
 * Copyright (c) 2008-2013 Plausible Labs Cooperative, Inc.
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

#import <stdlib.h>
#import <fcntl.h>
#import <errno.h>
#import <string.h>
#import <stdbool.h>
#import <dlfcn.h>

#import <sys/sysctl.h>
#import <sys/time.h>

#import <mach-o/dyld.h>

#import <stdatomic.h>

#if __has_include(<CrashReporter/MTDPLCrashReport.h>)
#import <CrashReporter/MTDPLCrashReport.h>
#else
#import "MTDPLCrashReport.h"
#endif

#import "MTDPLCrashLogWriter.h"
#import "MTDPLCrashLogWriterEncoding.h"
#import "MTDPLCrashAsyncSignalInfo.h"
#import "MTDPLCrashAsyncSymbolication.h"

#import "MTDPLCrashSysctl.h"
#import "MTDPLCrashProcessInfo.h"

/**
 * @internal
 * Maximum number of frames that will be written to the crash report for a single thread. Used as a safety measure
 * to avoid overrunning our output limit when writing a crash report triggered by frame recursion.
 */
#define MAX_THREAD_FRAMES 512 // matches Apple's crash reporting on Snow Leopard

/**
 * @internal
 * Protobuf Field IDs, as defined in crashreport.proto
 */
enum {
    /** CrashReport.system_info */
    MTDPLCRASH_PROTO_SYSTEM_INFO_ID = 1,

    /** CrashReport.system_info.operating_system */
    MTDPLCRASH_PROTO_SYSTEM_INFO_OS_ID = 1,

    /** CrashReport.system_info.os_version */
    MTDPLCRASH_PROTO_SYSTEM_INFO_OS_VERSION_ID = 2,

    /** CrashReport.system_info.architecture */
    MTDPLCRASH_PROTO_SYSTEM_INFO_ARCHITECTURE_TYPE_ID = 3,

    /** CrashReport.system_info.timestamp */
    MTDPLCRASH_PROTO_SYSTEM_INFO_TIMESTAMP_ID = 4,

    /** CrashReport.system_info.os_build */
    MTDPLCRASH_PROTO_SYSTEM_INFO_OS_BUILD_ID = 5,

    /** CrashReport.app_info */
    MTDPLCRASH_PROTO_APP_INFO_ID = 2,
    
    /** CrashReport.app_info.app_identifier */
    MTDPLCRASH_PROTO_APP_INFO_APP_IDENTIFIER_ID = 1,
    
    /** CrashReport.app_info.app_version */
    MTDPLCRASH_PROTO_APP_INFO_APP_VERSION_ID = 2,
    
    /** CrashReport.app_info.app_marketing_version */
    MTDPLCRASH_PROTO_APP_INFO_APP_MARKETING_VERSION_ID = 3,


    /** CrashReport.symbol.name */
    MTDPLCRASH_PROTO_SYMBOL_NAME = 1,

    /** CrashReport.symbol.start_address */
    MTDPLCRASH_PROTO_SYMBOL_START_ADDRESS = 2,
    
    /** CrashReport.symbol.end_address */
    MTDPLCRASH_PROTO_SYMBOL_END_ADDRESS = 3,


    /** CrashReport.threads */
    MTDPLCRASH_PROTO_THREADS_ID = 3,
    

    /** CrashReports.thread.thread_number */
    MTDPLCRASH_PROTO_THREAD_THREAD_NUMBER_ID = 1,

    /** CrashReports.thread.frames */
    MTDPLCRASH_PROTO_THREAD_FRAMES_ID = 2,

    /** CrashReport.thread.crashed */
    MTDPLCRASH_PROTO_THREAD_CRASHED_ID = 3,


    /** CrashReport.thread.frame.pc */
    MTDPLCRASH_PROTO_THREAD_FRAME_PC_ID = 3,
    
    /** CrashReport.thread.frame.symbol */
    MTDPLCRASH_PROTO_THREAD_FRAME_SYMBOL_ID = 6,


    /** CrashReport.thread.registers */
    MTDPLCRASH_PROTO_THREAD_REGISTERS_ID = 4,

    /** CrashReport.thread.register.name */
    MTDPLCRASH_PROTO_THREAD_REGISTER_NAME_ID = 1,

    /** CrashReport.thread.register.value */
    MTDPLCRASH_PROTO_THREAD_REGISTER_VALUE_ID = 2,


    /** CrashReport.images */
    MTDPLCRASH_PROTO_BINARY_IMAGES_ID = 4,

    /** CrashReport.BinaryImage.base_address */
    MTDPLCRASH_PROTO_BINARY_IMAGE_ADDR_ID = 1,

    /** CrashReport.BinaryImage.size */
    MTDPLCRASH_PROTO_BINARY_IMAGE_SIZE_ID = 2,

    /** CrashReport.BinaryImage.name */
    MTDPLCRASH_PROTO_BINARY_IMAGE_NAME_ID = 3,
    
    /** CrashReport.BinaryImage.uuid */
    MTDPLCRASH_PROTO_BINARY_IMAGE_UUID_ID = 4,

    /** CrashReport.BinaryImage.code_type */
    MTDPLCRASH_PROTO_BINARY_IMAGE_CODE_TYPE_ID = 5,

    
    /** CrashReport.exception */
    MTDPLCRASH_PROTO_EXCEPTION_ID = 5,

    /** CrashReport.exception.name */
    MTDPLCRASH_PROTO_EXCEPTION_NAME_ID = 1,
    
    /** CrashReport.exception.reason */
    MTDPLCRASH_PROTO_EXCEPTION_REASON_ID = 2,
    
    /** CrashReports.exception.frames */
    MTDPLCRASH_PROTO_EXCEPTION_FRAMES_ID = 3,


    /** CrashReport.signal */
    MTDPLCRASH_PROTO_SIGNAL_ID = 6,

    /** CrashReport.signal.name */
    MTDPLCRASH_PROTO_SIGNAL_NAME_ID = 1,

    /** CrashReport.signal.code */
    MTDPLCRASH_PROTO_SIGNAL_CODE_ID = 2,
    
    /** CrashReport.signal.address */
    MTDPLCRASH_PROTO_SIGNAL_ADDRESS_ID = 3,
    
    /** CrashReport.signal.mach_exception */
    MTDPLCRASH_PROTO_SIGNAL_MACH_EXCEPTION_ID = 4,
    
    
    /** CrashReport.signal.mach_exception.type */
    MTDPLCRASH_PROTO_SIGNAL_MACH_EXCEPTION_TYPE_ID = 1,
    
    /** CrashReport.signal.mach_exception.codes */
    MTDPLCRASH_PROTO_SIGNAL_MACH_EXCEPTION_CODES_ID = 2,


    /** CrashReport.process_info */
    MTDPLCRASH_PROTO_PROCESS_INFO_ID = 7,
    
    /** CrashReport.process_info.process_name */
    MTDPLCRASH_PROTO_PROCESS_INFO_PROCESS_NAME_ID = 1,
    
    /** CrashReport.process_info.process_id */
    MTDPLCRASH_PROTO_PROCESS_INFO_PROCESS_ID_ID = 2,
    
    /** CrashReport.process_info.process_path */
    MTDPLCRASH_PROTO_PROCESS_INFO_PROCESS_PATH_ID = 3,
    
    /** CrashReport.process_info.parent_process_name */
    MTDPLCRASH_PROTO_PROCESS_INFO_PARENT_PROCESS_NAME_ID = 4,
    
    /** CrashReport.process_info.parent_process_id */
    MTDPLCRASH_PROTO_PROCESS_INFO_PARENT_PROCESS_ID_ID = 5,
    
    /** CrashReport.process_info.native */
    MTDPLCRASH_PROTO_PROCESS_INFO_NATIVE_ID = 6,
    
    /** CrashReport.process_info.start_time */
    MTDPLCRASH_PROTO_PROCESS_INFO_START_TIME_ID = 7,

    
    /** CrashReport.Processor.encoding */
    MTDPLCRASH_PROTO_PROCESSOR_ENCODING_ID = 1,
    
    /** CrashReport.Processor.encoding */
    MTDPLCRASH_PROTO_PROCESSOR_TYPE_ID = 2,
    
    /** CrashReport.Processor.encoding */
    MTDPLCRASH_PROTO_PROCESSOR_SUBTYPE_ID = 3,


    /** CrashReport.machine_info */
    MTDPLCRASH_PROTO_MACHINE_INFO_ID = 8,

    /** CrashReport.machine_info.model */
    MTDPLCRASH_PROTO_MACHINE_INFO_MODEL_ID = 1,

    /** CrashReport.machine_info.processor */
    MTDPLCRASH_PROTO_MACHINE_INFO_PROCESSOR_ID = 2,

    /** CrashReport.machine_info.processor_count */
    MTDPLCRASH_PROTO_MACHINE_INFO_PROCESSOR_COUNT_ID = 3,

    /** CrashReport.machine_info.logical_processor_count */
    MTDPLCRASH_PROTO_MACHINE_INFO_LOGICAL_PROCESSOR_COUNT_ID = 4,


    /** CrashReport.report_info */
    MTDPLCRASH_PROTO_REPORT_INFO_ID = 9,
    
    /** CrashReport.report_info.crashed */
    MTDPLCRASH_PROTO_REPORT_INFO_USER_REQUESTED_ID = 1,

    /** CrashReport.report_info.uuid */
    MTDPLCRASH_PROTO_REPORT_INFO_UUID_ID = 2,

    /** CrashReport.custom_data */
    MTDPLCRASH_PROTO_CUSTOM_DATA_ID = 10,
};

static void plprotobuf_cbinary_data_init (MTDPLProtobufCBinaryData *data, const void *pointer, size_t len) {
    data->data = malloc(len);
    memcpy(data->data , pointer, len);
    data->len = len;
}

static void plprotobuf_cbinary_data_string_init (MTDPLProtobufCBinaryData *data, const char *value) {
    data->data = (void *)value;
    data->len = value ? strlen(value) : 0;
}

static void plprotobuf_cbinary_data_nsstring_init (MTDPLProtobufCBinaryData *data, NSString *value) {
    plprotobuf_cbinary_data_string_init(data, strdup([value UTF8String]));
}

static void plprotobuf_cbinary_data_free (MTDPLProtobufCBinaryData *data) {
    if (data != NULL && data->data != NULL) {
        free(data->data);
        data->data = NULL;
        data->len = 0;
    }
}

/**
 * Initialize a new crash log writer instance and issue a memory barrier upon completion. This fetches all necessary
 * environment information.
 *
 * @param writer Writer instance to be initialized.
 * @param app_identifier Unique per-application identifier. On Mac OS X, this is likely the CFBundleIdentifier.
 * @param app_version Application version string.
 * @param app_marketing_version Application marketing version string (may be nil).
 * @param symbol_strategy The strategy to use for local symbolication.
 * @param user_requested If true, the written report will be marked as a 'generated' non-crash report, rather than as
 * a true crash report created upon an actual crash.
 *
 * @note If this function fails, plcrash_log_writer_free() should be called
 * to free any partially allocated data.
 *
 * @warning This function is not guaranteed to be async-safe, and must be called prior to enabling the crash handler.
 */
plcrash_error_t plcrash_log_writer_init (plcrash_log_writer_t *writer,
                                         NSString *app_identifier,
                                         NSString *app_version,
                                         NSString *app_marketing_version,
                                         plcrash_async_symbol_strategy_t symbol_strategy,
                                         BOOL user_requested)
{
    /* Default to 0 */
    memset(writer, 0, sizeof(*writer));

    /* Initialize configuration */
    writer->symbol_strategy = symbol_strategy;

    /* Default to false */
    writer->report_info.user_requested = user_requested;

    /* Generate a UUID for this incident; CFUUID is used in favor of NSUUID as to maintain compatibility
     * with (Mac OS X 10.7|iOS 5) and earlier. */
    {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        CFUUIDBytes bytes = CFUUIDGetUUIDBytes(uuid);
        MTDPLCF_ASSERT(sizeof(bytes) == sizeof(writer->report_info.uuid_bytes));
        memcpy(writer->report_info.uuid_bytes, &bytes, sizeof(writer->report_info.uuid_bytes));
        CFRelease(uuid);
    }

    /* Fetch the application information */
    {
        plprotobuf_cbinary_data_nsstring_init(&writer->application_info.app_identifier, app_identifier);
        plprotobuf_cbinary_data_nsstring_init(&writer->application_info.app_version, app_version);
        if (app_marketing_version != nil) {
            plprotobuf_cbinary_data_nsstring_init(&writer->application_info.app_marketing_version, app_marketing_version);
        }
    }
    
    /* Fetch the process information */
    {
        /* Current process */
        MTDPLCrashProcessInfo *pinfo = [MTDPLCrashProcessInfo currentProcessInfo];
        if (pinfo == nil) {
            /* Should only occur if the process is no longer valid */
            MTDPLCF_DEBUG("Could not retrieve process info for target");
            return MTDPLCRASH_EINVAL;
        }

        {
            /* Retrieve PID */
            writer->process_info.process_id = pinfo.processID;

            /* Retrieve name and start time. */
            if (pinfo.processName != nil) {
                plprotobuf_cbinary_data_nsstring_init(&writer->process_info.process_name, pinfo.processName);
            }
            writer->process_info.start_time = pinfo.startTime.tv_sec;

            /* Retrieve path */
            uint32_t process_path_len = 0;
            _NSGetExecutablePath(NULL, &process_path_len);
            if (process_path_len > 0) {
                char *process_path = malloc(process_path_len);
                _NSGetExecutablePath(process_path, &process_path_len);
                writer->process_info.process_path.data = process_path;
                writer->process_info.process_path.len = process_path_len;
            }
        }

        /* Parent process */
        {
            /* Retrieve PID */
            writer->process_info.parent_process_id = pinfo.parentProcessID;

            /* Retrieve name. This will fail on iOS 9+, where EPERM is returned due to new sandbox constraints. */
            MTDPLCrashProcessInfo *parentInfo = [[MTDPLCrashProcessInfo alloc] initWithProcessID: pinfo.parentProcessID];
            if (parentInfo != nil) {
                if (parentInfo.processName != nil) {
                    plprotobuf_cbinary_data_nsstring_init(&writer->process_info.parent_process_name, parentInfo.processName);
                }
            } else {
                MTDPLCF_DEBUG("Could not retrieve parent process name: %s", strerror(errno));
            }

        }
    }

    /* Fetch the machine information */
    {
        /* Model */
#if TARGET_OS_IPHONE && !TARGET_OS_MACCATALYST
        /* On iOS, we want hw.machine (e.g. hw.machine = iPad2,1; hw.model = K93AP) */
        char *model = plcrash_sysctl_string("hw.machine");
#else
        /* On Mac OS X, we want hw.model (e.g. hw.machine = x86_64; hw.model = Macmini5,3) */
        char *model = plcrash_sysctl_string("hw.model");
#endif
        if (model == NULL) {
            MTDPLCF_DEBUG("Could not retrive hw.model: %s", strerror(errno));
        }
        plprotobuf_cbinary_data_string_init(&writer->machine_info.model, model);
        
        /* CPU */
        {
            int retval;

            /* Fetch the CPU types */
            if (plcrash_sysctl_int("hw.cputype", &retval)) {
                writer->machine_info.cpu_type = retval;
            } else {
                MTDPLCF_DEBUG("Could not retrive hw.cputype: %s", strerror(errno));
            }
            
            if (plcrash_sysctl_int("hw.cpusubtype", &retval)) {
                writer->machine_info.cpu_subtype = retval;
            } else {
                MTDPLCF_DEBUG("Could not retrive hw.cpusubtype: %s", strerror(errno));
            }

            /* Processor count */
            if (plcrash_sysctl_int("hw.physicalcpu_max", &retval)) {
                writer->machine_info.processor_count = retval;
            } else {
                MTDPLCF_DEBUG("Could not retrive hw.physicalcpu_max: %s", strerror(errno));
            }

            if (plcrash_sysctl_int("hw.logicalcpu_max", &retval)) {
                writer->machine_info.logical_processor_count = retval;
            } else {
                MTDPLCF_DEBUG("Could not retrive hw.logicalcpu_max: %s", strerror(errno));
            }
        }
        
        /*
         * Check if the process is emulated. This sysctl is defined in the Universal Binary Programming Guidelines,
         * Second Edition:
         *
         * http://developer.apple.com/legacy/mac/library/documentation/MacOSX/Conceptual/universal_binary/universal_binary.pdf
         */
        {
            int retval;

            if (plcrash_sysctl_int("sysctl.proc_native", &retval)) {
                if (retval == 0) {
                    writer->process_info.native = false;
                } else {
                    writer->process_info.native = true;
                }
            } else {
                /* If the sysctl is not available, the process can be assumed to be native. */
                writer->process_info.native = true;
            }
        }
    }

    /* Fetch the OS information */    
    char *build = plcrash_sysctl_string("kern.osversion");
    if (build == NULL) {
        MTDPLCF_DEBUG("Could not retrive kern.osversion: %s", strerror(errno));
    }
    plprotobuf_cbinary_data_string_init(&writer->system_info.build, build);

#if TARGET_OS_IPHONE || TARGET_OS_MAC
    /* iOS, tvOS, macOS and Mac Catalyst */
    {
        NSProcessInfo *processInfo = [NSProcessInfo processInfo];
        NSOperatingSystemVersion systemVersion = processInfo.operatingSystemVersion;
        NSString *systemVersionString = [NSString stringWithFormat:@"%ld.%ld", (long)systemVersion.majorVersion, (long)systemVersion.minorVersion];
        if (systemVersion.patchVersion > 0) {
            systemVersionString = [systemVersionString stringByAppendingFormat:@".%ld", (long)systemVersion.patchVersion];
        }
        plprotobuf_cbinary_data_nsstring_init(&writer->system_info.version, systemVersionString);
    }
#else
#error Unsupported Platform
#endif

    /* Ensure that any signal handler has a consistent view of the above initialization. */
    atomic_thread_fence(memory_order_seq_cst);

    return MTDPLCRASH_ESUCCESS;
}

/**
 * Set the uncaught exception for this writer. Once set, this exception will be used to
 * provide exception data for the crash log output.
 *
 * @warning This function is not async safe, and must be called outside of a signal handler.
 */
void plcrash_log_writer_set_exception (plcrash_log_writer_t *writer, NSException *exception) {
    assert(writer->uncaught_exception.has_exception == false);

    /* Save the exception data */
    writer->uncaught_exception.has_exception = true;
    writer->uncaught_exception.name = strdup([[exception name] UTF8String]);
    writer->uncaught_exception.reason = strdup([exception reason] != nil ? [[exception reason] UTF8String] : "");

    /* Save the call stack, if available */
    NSArray *callStackArray = [exception callStackReturnAddresses];
    if (callStackArray != nil && [callStackArray count] > 0) {
        size_t count = [callStackArray count];
        writer->uncaught_exception.callstack_count = count;
        writer->uncaught_exception.callstack = malloc(sizeof(void *) * count);

        size_t i = 0;
        for (NSNumber *num in callStackArray) {
            assert(i < count);
            writer->uncaught_exception.callstack[i] = (void *)(uintptr_t)[num unsignedLongLongValue];
            i++;
        }
    }

    /* Ensure that any signal handler has a consistent view of the above initialization. */
    atomic_thread_fence(memory_order_seq_cst);
}

/**
 * Set the custom data for this writer. Once set, this information will be used to
 * provide custom data for the crash log output.
 *
 * @warning This function is not async safe, and must be called outside of a signal handler.
 */
void plcrash_log_writer_set_custom_data (plcrash_log_writer_t *writer, NSData *custom_data) {
    /* If there is already user data, delete it */
    if (writer->custom_data.data) {
        plprotobuf_cbinary_data_free(&writer->custom_data);
    }

    /* Save the user data */
    if (custom_data != nil) {
        plprotobuf_cbinary_data_init(&writer->custom_data, custom_data.bytes, custom_data.length);
    }
}

/**
 * Close the plcrash_writer_t output.
 *
 * @param writer Writer instance to be closed.
 */
plcrash_error_t plcrash_log_writer_close (plcrash_log_writer_t *writer) {
    return MTDPLCRASH_ESUCCESS;
}

/**
 * Free any crash log writer resources.
 *
 * @warning This method is not async safe.
 */
void plcrash_log_writer_free (plcrash_log_writer_t *writer) {
    /* Free the app info */
    plprotobuf_cbinary_data_free(&writer->application_info.app_identifier);
    plprotobuf_cbinary_data_free(&writer->application_info.app_version);
    plprotobuf_cbinary_data_free(&writer->application_info.app_marketing_version);

    /* Free the process info */
    plprotobuf_cbinary_data_free(&writer->process_info.process_name);
    plprotobuf_cbinary_data_free(&writer->process_info.process_path);
    plprotobuf_cbinary_data_free(&writer->process_info.parent_process_name);
    
    /* Free the system info */
    plprotobuf_cbinary_data_free(&writer->system_info.version);
    plprotobuf_cbinary_data_free(&writer->system_info.build);
    
    /* Free the machine info */
    plprotobuf_cbinary_data_free(&writer->machine_info.model);

    /* Free the exception data */
    if (writer->uncaught_exception.has_exception) {
        if (writer->uncaught_exception.name != NULL)
            free(writer->uncaught_exception.name);

        if (writer->uncaught_exception.reason != NULL)
            free(writer->uncaught_exception.reason);
        
        if (writer->uncaught_exception.callstack != NULL)
            free(writer->uncaught_exception.callstack);
    }

    if (writer->custom_data.data) {
        plprotobuf_cbinary_data_free(&writer->custom_data);
    }
}

/**
 * @internal
 *
 * Write the system info message.
 *
 * @param file Output file
 * @param timestamp Timestamp to use (seconds since epoch). Must be same across calls, as varint encoding.
 */
static size_t plcrash_writer_write_system_info (plcrash_async_file_t *file, plcrash_log_writer_t *writer, int64_t timestamp) {
    size_t rv = 0;
    uint32_t enumval;

    /* OS */
    enumval = MTDPLCrashReportHostOperatingSystem;
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_SYSTEM_INFO_OS_ID, MTDPLPROTOBUF_C_TYPE_ENUM, &enumval);

    /* OS Version */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_SYSTEM_INFO_OS_VERSION_ID, MTDPLPROTOBUF_C_TYPE_BYTES, &writer->system_info.version);
    
    /* OS Build */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_SYSTEM_INFO_OS_BUILD_ID, MTDPLPROTOBUF_C_TYPE_BYTES, &writer->system_info.build);

    /* Machine type */
    enumval = MTDPLCrashReportHostArchitecture;
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_SYSTEM_INFO_ARCHITECTURE_TYPE_ID, MTDPLPROTOBUF_C_TYPE_ENUM, &enumval);

    /* Timestamp */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_SYSTEM_INFO_TIMESTAMP_ID, MTDPLPROTOBUF_C_TYPE_INT64, &timestamp);

    return rv;
}

/**
 * @internal
 *
 * Write the processor info message.
 *
 * @param file Output file
 * @param cpu_type The Mach CPU type.
 * @param cpu_subtype The Mach CPU subtype
 */
static size_t plcrash_writer_write_processor_info (plcrash_async_file_t *file, uint64_t cpu_type, uint64_t cpu_subtype) {
    size_t rv = 0;
    uint32_t enumval;
    
    /* Encoding */
    enumval = MTDPLCrashReportProcessorTypeEncodingMach;
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_PROCESSOR_ENCODING_ID, MTDPLPROTOBUF_C_TYPE_ENUM, &enumval);

    /* Type */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_PROCESSOR_TYPE_ID, MTDPLPROTOBUF_C_TYPE_UINT64, &cpu_type);

    /* Subtype */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_PROCESSOR_SUBTYPE_ID, MTDPLPROTOBUF_C_TYPE_UINT64, &cpu_subtype);
    
    return rv;
}

/**
 * @internal
 *
 * Write the machine info message.
 *
 * @param file Output file
 */
static size_t plcrash_writer_write_machine_info (plcrash_async_file_t *file, plcrash_log_writer_t *writer) {
    size_t rv = 0;
    
    /* Model */
    if (writer->machine_info.model.data != NULL)
        rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_MACHINE_INFO_MODEL_ID, MTDPLPROTOBUF_C_TYPE_BYTES, &writer->machine_info.model);

    /* Processor */
    {
        uint32_t size;

        /* Determine size */
        size = (uint32_t) plcrash_writer_write_processor_info(NULL, writer->machine_info.cpu_type, writer->machine_info.cpu_subtype);

        /* Write message */
        rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_MACHINE_INFO_PROCESSOR_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &size);
        rv += plcrash_writer_write_processor_info(file, writer->machine_info.cpu_type, writer->machine_info.cpu_subtype);
    }

    /* Physical Processor Count */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_MACHINE_INFO_PROCESSOR_COUNT_ID, MTDPLPROTOBUF_C_TYPE_UINT32, &writer->machine_info.processor_count);
    
    /* Logical Processor Count */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_MACHINE_INFO_LOGICAL_PROCESSOR_COUNT_ID, MTDPLPROTOBUF_C_TYPE_UINT32, &writer->machine_info.logical_processor_count);
    
    return rv;
}

/**
 * @internal
 *
 * Write the app info message.
 *
 * @param file Output file
 * @param app_identifier Application identifier
 * @param app_version Application version
 * @param app_marketing_version Application marketing version
 */
static size_t plcrash_writer_write_app_info (plcrash_async_file_t *file,
                                             MTDPLProtobufCBinaryData *app_identifier,
                                             MTDPLProtobufCBinaryData *app_version,
                                             MTDPLProtobufCBinaryData *app_marketing_version) {
    size_t rv = 0;

    /* App identifier */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_APP_INFO_APP_IDENTIFIER_ID, MTDPLPROTOBUF_C_TYPE_BYTES, app_identifier);
    
    /* App version */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_APP_INFO_APP_VERSION_ID, MTDPLPROTOBUF_C_TYPE_BYTES, app_version);
    
    /* App marketing version */
    if (app_marketing_version != NULL)
        rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_APP_INFO_APP_MARKETING_VERSION_ID, MTDPLPROTOBUF_C_TYPE_BYTES, app_marketing_version);
    
    return rv;
}

/**
 * @internal
 *
 * Write the process info message.
 *
 * @param file Output file
 * @param process_name Process name, or NULL if unavailable.
 * @param process_id Process ID
 * @param process_path Process path, or NULL if unavailable.
 * @param parent_process_name Parent process name, or NULL if unavailable.
 * @param parent_process_id Parent process ID
 * @param native If false, process is running under emulation.
 * @param start_time The start time of the process.
 */
static size_t plcrash_writer_write_process_info (plcrash_async_file_t *file, MTDPLProtobufCBinaryData *process_name,
                                                 const pid_t process_id, MTDPLProtobufCBinaryData *process_path,
                                                 MTDPLProtobufCBinaryData *parent_process_name, const pid_t parent_process_id,
                                                 bool native, time_t start_time)
{
    size_t rv = 0;
    uint64_t tval;

    /*
     * In the current crash reporter serialization format, pid values are serialized as unsigned 32-bit integers. This
     * conforms with the actual implementation of pid_t on both 32-bit and 64-bit Darwin systems. To conform with
     * SuSV3, however, the values should be encoded as signed integers; the actual width of the type being implementation
     * defined.
     *
     * To maintain compatibility with existing report readers the values remain encoded as unsigned 32-bit integers,
     * but should be updated to int64 values in future major revision of the data format.
     */
    uint32_t pidval;

    /* Process name */
    if (process_name != NULL)
        rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_PROCESS_INFO_PROCESS_NAME_ID, MTDPLPROTOBUF_C_TYPE_BYTES, process_name);

    /* Process ID */
    pidval = process_id;
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_PROCESS_INFO_PROCESS_ID_ID, MTDPLPROTOBUF_C_TYPE_UINT32, &pidval);

    /* Process path */
    if (process_path != NULL)
        rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_PROCESS_INFO_PROCESS_PATH_ID, MTDPLPROTOBUF_C_TYPE_BYTES, process_path);
    
    /* Parent process name */
    if (parent_process_name != NULL)
        rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_PROCESS_INFO_PARENT_PROCESS_NAME_ID, MTDPLPROTOBUF_C_TYPE_BYTES, parent_process_name);
    

    /* Parent process ID */
    pidval = parent_process_id;
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_PROCESS_INFO_PARENT_PROCESS_ID_ID, MTDPLPROTOBUF_C_TYPE_UINT32, &pidval);

    /* Native process. */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_PROCESS_INFO_NATIVE_ID, MTDPLPROTOBUF_C_TYPE_BOOL, &native);
    
    /* Start time */
    tval = start_time;
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_PROCESS_INFO_START_TIME_ID, MTDPLPROTOBUF_C_TYPE_UINT64, &tval);

    return rv;
}

/**
 * @internal
 *
 * Write a single register.
 *
 * @param file Output file
 * @param regname The register to write's name.
 * @param regval The register to write's value.
 */
static size_t plcrash_writer_write_thread_register (plcrash_async_file_t *file, const char *regname, plcrash_greg_t regval) {
    uint64_t uint64val;
    size_t rv = 0;

    /* Write the name */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_THREAD_REGISTER_NAME_ID, MTDPLPROTOBUF_C_TYPE_STRING, regname);

    /* Write the value */
    uint64val = regval;
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_THREAD_REGISTER_VALUE_ID, MTDPLPROTOBUF_C_TYPE_UINT64, &uint64val);
    
    return rv;
}

/**
 * @internal
 *
 * Write all thread backtrace register messages
 *
 * @param file Output file
 * @param task The task from which @a uap was derived. All memory accesses will be mapped from this task.
 * @param cursor The cursor from which to acquire frame registers.
 */
static size_t plcrash_writer_write_thread_registers (plcrash_async_file_t *file, task_t task, plframe_cursor_t *cursor) {
    MTDPLCF_UNUSED_IN_RELEASE plframe_error_t frame_err;
    uint32_t regCount = (uint32_t) plframe_cursor_get_regcount(cursor);
    size_t rv = 0;
    
    /* Write out register messages */
    for (int i = 0; i < regCount; i++) {
        plcrash_greg_t regVal;
        const char *regname;
        uint32_t msgsize;

        /* Fetch the register value */
        if ((frame_err = plframe_cursor_get_reg(cursor, i, &regVal)) != MTDPLFRAME_ESUCCESS) {
            // Should never happen
            MTDPLCF_DEBUG("Could not fetch register %i value: %s", i, plframe_strerror(frame_err));
            regVal = 0;
        }

        /* Fetch the register name */
        regname = plframe_cursor_get_regname(cursor, i);

        /* Get the register message size */
        msgsize = (uint32_t) plcrash_writer_write_thread_register(NULL, regname, regVal);
        
        /* Write the header and message */
        rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_THREAD_REGISTERS_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &msgsize);
        rv += plcrash_writer_write_thread_register(file, regname, regVal);
    }
    
    return rv;
}

/**
 * @internal
 *
 * Write a symbol
 *
 * @param file Output file
 * @param name The symbol name
 * @param start_address The symbol start address
 */
static size_t plcrash_writer_write_symbol (plcrash_async_file_t *file, const char *name, uint64_t start_address) {
    size_t rv = 0;
    
    /* name */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_SYMBOL_NAME, MTDPLPROTOBUF_C_TYPE_STRING, name);
    
    /* start_address */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_SYMBOL_START_ADDRESS, MTDPLPROTOBUF_C_TYPE_UINT64, &start_address);
    
    return rv;
}

/**
 * @internal
 * Symbol lookup callback context
 */
struct pl_symbol_cb_ctx {
    /** File to use for writing out a symbol entry. May be NULL. */
    plcrash_async_file_t *file;

    /** Size of the symbol entry, to be written by the callback function upon writing an entry. */
    uint32_t msgsize;
};

/**
 * @internal
 *
 * pl_async_macho_found_symbol_cb callback implementation. Writes the result to the file available via @a ctx,
 * which must be a valid pl_symbol_cb_ctx structure.
 */
static void plcrash_writer_write_thread_frame_symbol_cb (pl_vm_address_t address, const char *name, void *ctx) {
    struct pl_symbol_cb_ctx *cb_ctx = ctx;
    cb_ctx->msgsize = (uint32_t) plcrash_writer_write_symbol(cb_ctx->file, name, address);
}

/**
 * @internal
 *
 * Write a thread backtrace frame
 *
 * @param file Output file
 * @param pcval The frame PC value.
 */
static size_t plcrash_writer_write_thread_frame (plcrash_async_file_t *file, plcrash_log_writer_t *writer, uint64_t pcval, plcrash_async_image_list_t *image_list, plcrash_async_symbol_cache_t *findContext) {
    size_t rv = 0;

    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_THREAD_FRAME_PC_ID, MTDPLPROTOBUF_C_TYPE_UINT64, &pcval);
    
    plcrash_async_image_list_set_reading(image_list, true);
    plcrash_async_image_t *image = plcrash_async_image_containing_address(image_list, (pl_vm_address_t) pcval);
    
    if (image != NULL && writer->symbol_strategy != MTDPLCRASH_ASYNC_SYMBOL_STRATEGY_NONE) {
        struct pl_symbol_cb_ctx ctx;
        plcrash_error_t ret;
        
        /* Get the symbol message size. If the symbol can not be found, our callback will not be called. If the symbol is found,
         * our callback is called and MTDPLCRASH_ESUCCESS is returned. */
        ctx.file = NULL;
        ctx.msgsize = 0x0;
        ret = plcrash_async_find_symbol(&image->macho_image, writer->symbol_strategy, findContext, (pl_vm_address_t) pcval, plcrash_writer_write_thread_frame_symbol_cb, &ctx);
        if (ret == MTDPLCRASH_ESUCCESS) {
            /* Write the header and message */
            rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_THREAD_FRAME_SYMBOL_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &ctx.msgsize);

            ctx.file = file;
            ret = plcrash_async_find_symbol(&image->macho_image, writer->symbol_strategy, findContext, (pl_vm_address_t) pcval, plcrash_writer_write_thread_frame_symbol_cb, &ctx);
            if (ret == MTDPLCRASH_ESUCCESS) {
                rv += ctx.msgsize;
            } else {
                /* This should not happen, but it would be very confusing if it did and nothing was logged. */
                MTDPLCF_DEBUG("Fetching the symbol unexpectedly failed during the second call");
            }
        }
    }

    plcrash_async_image_list_set_reading(image_list, false);


    return rv;
}

/**
 * @internal
 *
 * Write a thread message
 *
 * @param file Output file
 * @param task The task in which @a thread is executing.
 * @param thread Thread for which we'll output data.
 * @param thread_number The thread's index number.
 * @param thread_ctx Thread state to use for stack walking. If NULL, the thread state will be fetched from @a thread. If
 * @a thread is the currently executing thread, <em>must</em> be non-NULL.
 * @param image_list The Mach-O image list.
 * @param findContext Symbol lookup cache.
 * @param crashed If true, mark this as a crashed thread.
 */
static size_t plcrash_writer_write_thread (plcrash_async_file_t *file,
                                           plcrash_log_writer_t *writer,
                                           task_t task,
                                           thread_t thread,
                                           uint32_t thread_number,
                                           plcrash_async_thread_state_t *thread_ctx,
                                           plcrash_async_image_list_t *image_list,
                                           plcrash_async_symbol_cache_t *findContext,
                                           bool crashed)
{
    size_t rv = 0;
    plframe_cursor_t cursor;
    plframe_error_t ferr;

    /* A context must be supplied when walking the current thread */
    MTDPLCF_ASSERT(task != mach_task_self() || thread_ctx != NULL || thread != pl_mach_thread_self());

    /* Write the required elements first; fatal errors may occur below, in which case we need to have
     * written out required elements before returning. */
    {
        /* Write the thread ID */
        rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_THREAD_THREAD_NUMBER_ID, MTDPLPROTOBUF_C_TYPE_UINT32, &thread_number);

        /* Note crashed status */
        rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_THREAD_CRASHED_ID, MTDPLPROTOBUF_C_TYPE_BOOL, &crashed);
    }


    /* Write out the stack frames. */
    {
        /* Set up the frame cursor. */
        {            
            /* Use the provided context if available, otherwise initialize a new thread context
             * from the target thread's state. */
            plcrash_async_thread_state_t cursor_thr_state;
            if (thread_ctx) {
                cursor_thr_state = *thread_ctx;
            } else {
                plcrash_async_thread_state_mach_thread_init(&cursor_thr_state, thread);
            }

            /* Initialize the cursor */
            ferr = plframe_cursor_init(&cursor, task, &cursor_thr_state, image_list);
            if (ferr != MTDPLFRAME_ESUCCESS) {
                MTDPLCF_DEBUG("An error occured initializing the frame cursor: %s", plframe_strerror(ferr));
                return rv;
            }
        }

        /* Walk the stack, limiting the total number of frames that are output. */
        uint32_t frame_count = 0;
        while ((ferr = plframe_cursor_next(&cursor)) == MTDPLFRAME_ESUCCESS && frame_count < MAX_THREAD_FRAMES) {
            uint32_t frame_size;
            
            /* On the first frame, dump registers for the crashed thread */
            if (frame_count == 0 && crashed) {
                rv += plcrash_writer_write_thread_registers(file, task, &cursor);
            }

            /* Fetch the PC value */
            plcrash_greg_t pc = 0;
            if ((ferr = plframe_cursor_get_reg(&cursor, MTDPLCRASH_REG_IP, &pc)) != MTDPLFRAME_ESUCCESS) {
                MTDPLCF_DEBUG("Could not retrieve frame PC register: %s", plframe_strerror(ferr));
                break;
            }

            /* Determine the size */
            frame_size = (uint32_t) plcrash_writer_write_thread_frame(NULL, writer, pc, image_list, findContext);
            
            rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_THREAD_FRAMES_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &frame_size);
            rv += plcrash_writer_write_thread_frame(file, writer, pc, image_list, findContext);
            frame_count++;
        }

        /* Did we reach the end successfully? */
        if (ferr != MTDPLFRAME_ENOFRAME) {
            /* This is non-fatal, and in some circumstances -could- be caused by reaching the end of the stack if the
             * final frame pointer is not NULL. */
            MTDPLCF_DEBUG("Terminated stack walking early: %s", plframe_strerror(ferr));
        }
    }

    plframe_cursor_free(&cursor);
    return rv;
}


/**
 * @internal
 *
 * Write a binary image frame
 *
 * @param file Output file
 * @param image Mach-O image.
 */
static size_t plcrash_writer_write_binary_image (plcrash_async_file_t *file, plcrash_async_macho_t *image) {
    size_t rv = 0;

    /* Fetch the CPU types. Note that the wire format represents these as 64-bit unsigned integers.
     * We explicitly cast to an equivalently sized unsigned type to prevent improper sign extension. */
    uint64_t cpu_type = (uint32_t) image->byteorder->swap32(image->header.cputype);
    uint64_t cpu_subtype = (uint32_t) image->byteorder->swap32(image->header.cpusubtype);

    /* Text segment size */
    uint64_t mach_size = image->text_size;
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_BINARY_IMAGE_SIZE_ID, MTDPLPROTOBUF_C_TYPE_UINT64, &mach_size);
    
    /* Base address */
    {
        uintptr_t base_addr;
        uint64_t u64;

        base_addr = (uintptr_t) image->header_addr;
        u64 = base_addr;
        rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_BINARY_IMAGE_ADDR_ID, MTDPLPROTOBUF_C_TYPE_UINT64, &u64);
    }

    /* Name */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_BINARY_IMAGE_NAME_ID, MTDPLPROTOBUF_C_TYPE_STRING, image->name);

    /* UUID */
    struct uuid_command *uuid;
    uuid = plcrash_async_macho_find_command(image, LC_UUID);
    if (uuid != NULL) {
        MTDPLProtobufCBinaryData binary;
    
        /* Write the 128-bit UUID */
        binary.len = sizeof(uuid->uuid);
        binary.data = uuid->uuid;
        rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_BINARY_IMAGE_UUID_ID, MTDPLPROTOBUF_C_TYPE_BYTES, &binary);
    }
    
    /* Get the processor message size */
    uint32_t msgsize = (uint32_t) plcrash_writer_write_processor_info(NULL, cpu_type, cpu_subtype);

    /* Write the header and message */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_BINARY_IMAGE_CODE_TYPE_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &msgsize);
    rv += plcrash_writer_write_processor_info(file, cpu_type, cpu_subtype);

    return rv;
}


/**
 * @internal
 *
 * Write the crash Exception message
 *
 * @param file Output file
 * @param writer Writer containing exception data
 */
static size_t plcrash_writer_write_exception (plcrash_async_file_t *file, plcrash_log_writer_t *writer, plcrash_async_image_list_t *image_list, plcrash_async_symbol_cache_t *findContext) {
    size_t rv = 0;

    /* Write the name and reason */
    assert(writer->uncaught_exception.has_exception);
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_EXCEPTION_NAME_ID, MTDPLPROTOBUF_C_TYPE_STRING, writer->uncaught_exception.name);
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_EXCEPTION_REASON_ID, MTDPLPROTOBUF_C_TYPE_STRING, writer->uncaught_exception.reason);
    
    /* Write the stack frames, if any */
    uint32_t frame_count = 0;
    for (size_t i = 0; i < writer->uncaught_exception.callstack_count && frame_count < MAX_THREAD_FRAMES; i++) {
        uint64_t pc = (uint64_t)(uintptr_t) writer->uncaught_exception.callstack[i];
        
        /* Determine the size */
        uint32_t frame_size = (uint32_t) plcrash_writer_write_thread_frame(NULL, writer, pc, image_list, findContext);
        
        rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_EXCEPTION_FRAMES_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &frame_size);
        rv += plcrash_writer_write_thread_frame(file, writer, pc, image_list, findContext);
        frame_count++;
    }

    return rv;
}

/**
 * @internal
 *
 * Write the crash signal's mach exception info.
 *
 * @param file Output file
 * @param siginfo The signal information
 */
static size_t plcrash_writer_write_mach_signal (plcrash_async_file_t *file, plcrash_log_mach_signal_info_t *siginfo) {
    size_t rv = 0;

    /* Type */
    uint64_t type = siginfo->type;
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_SIGNAL_MACH_EXCEPTION_TYPE_ID, MTDPLPROTOBUF_C_TYPE_UINT64, &type);
    
    /* Code(s) */
    for (mach_msg_type_number_t i = 0; i < siginfo->code_count; i++) {
        uint64_t code = siginfo->code[i];
        rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_SIGNAL_MACH_EXCEPTION_CODES_ID, MTDPLPROTOBUF_C_TYPE_UINT64, &code);
    }

    return rv;
}

/**
 * @internal
 *
 * Write the crash signal message
 *
 * @param file Output file
 * @param siginfo The signal information
 */
static size_t plcrash_writer_write_signal (plcrash_async_file_t *file, plcrash_log_signal_info_t *siginfo) {
    size_t rv = 0;
    
    /* BSD signal info is always required in the current report format; this restriction will be lifted
     * once we switch to the 2.0 format. */
    MTDPLCF_ASSERT(siginfo->bsd_info != NULL);
    
    /* Fetch the signal name */
    char name_buf[10];
    const char *name;
    if ((name = plcrash_async_signal_signame(siginfo->bsd_info->signo)) == NULL) {
        MTDPLCF_DEBUG("Warning -- unhandled signal number (signo=%d). This is a bug.", siginfo->bsd_info->signo);
        snprintf(name_buf, sizeof(name_buf), "#%d", siginfo->bsd_info->signo);
        name = name_buf;
    }

    /* Fetch the signal code string */
    char code_buf[10];
    const char *code;
    if ((code = plcrash_async_signal_sigcode(siginfo->bsd_info->signo, siginfo->bsd_info->code)) == NULL) {
        MTDPLCF_DEBUG("Warning -- unhandled signal sicode (signo=%d, code=%d). This is a bug.", siginfo->bsd_info->signo, siginfo->bsd_info->code);
        snprintf(code_buf, sizeof(code_buf), "#%d", siginfo->bsd_info->code);
        code = code_buf;
    }
    
    /* Address value */
    uint64_t addr = (uintptr_t) siginfo->bsd_info->address;

    /* Write it out */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_SIGNAL_NAME_ID, MTDPLPROTOBUF_C_TYPE_STRING, name);
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_SIGNAL_CODE_ID, MTDPLPROTOBUF_C_TYPE_STRING, code);
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_SIGNAL_ADDRESS_ID, MTDPLPROTOBUF_C_TYPE_UINT64, &addr);
    
    /* Mach exception info */
    if (siginfo->mach_info != NULL) {
        uint32_t size;
        
        /* Determine size */
        size = (uint32_t) plcrash_writer_write_mach_signal(NULL, siginfo->mach_info);
        
        /* Write message */
        rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_SIGNAL_MACH_EXCEPTION_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &size);
        rv += plcrash_writer_write_mach_signal(file, siginfo->mach_info);
    }

    return rv;
}

/**
 * @internal
 *
 * Write the report info message
 *
 * @param file Output file
 * @param writer Writer containing report data
 */
static size_t plcrash_writer_write_report_info (plcrash_async_file_t *file, plcrash_log_writer_t *writer) {
    size_t rv = 0;

    /* Note crashed status */
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_REPORT_INFO_USER_REQUESTED_ID, MTDPLPROTOBUF_C_TYPE_BOOL, &writer->report_info.user_requested);
    
    /* Write the 128-bit UUID */
    MTDPLProtobufCBinaryData uuid_bin;
    
    uuid_bin.len = sizeof(writer->report_info.uuid_bytes);
    uuid_bin.data = &writer->report_info.uuid_bytes;
    rv += plcrash_writer_pack(file, MTDPLCRASH_PROTO_REPORT_INFO_UUID_ID, MTDPLPROTOBUF_C_TYPE_BYTES, &uuid_bin);

    return rv;
}

/**
 * Write the crash report. All other running threads are suspended while the crash report is generated.
 *
 * @param writer The writer context.
 * @param crashed_thread The crashed thread. 
 * @param image_list The current list of loaded binary images.
 * @param file The output file.
 * @param siginfo Signal information.
 * @param current_state If non-NULL, the given thread state will be used when walking the current thread. The state must remain
 * valid until this function returns. Generally, this state will be generated by a signal handler, or via a
 * context-generating trampoline such as plcrash_log_writer_write_curthread(). If NULL, a thread dump for the current
 * thread will not be written. If @a crashed_thread is the current thread (as returned by mach_thread_self()), this
 * value <em>must</em> be provided.
 */
plcrash_error_t plcrash_log_writer_write (plcrash_log_writer_t *writer,
                                          thread_t crashed_thread,
                                          plcrash_async_image_list_t *image_list,
                                          plcrash_async_file_t *file,
                                          plcrash_log_signal_info_t *siginfo,
                                          plcrash_async_thread_state_t *current_state)
{
    thread_act_array_t threads;
    mach_msg_type_number_t thread_count;

    /* A context must be supplied if the current thread is marked as the crashed thread; otherwise,
     * the thread's stack can not be safely walked. */
    MTDPLCF_ASSERT(pl_mach_thread_self() != crashed_thread || current_state != NULL);

    /* Get a list of all threads */
    if (task_threads(mach_task_self(), &threads, &thread_count) != KERN_SUCCESS) {
        MTDPLCF_DEBUG("Fetching thread list failed");
        thread_count = 0;
    }
    
    /* Suspend all but the current thread. */
    for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
        if (threads[i] != pl_mach_thread_self())
            thread_suspend(threads[i]);
    }

    /* Set up a symbol-finding context. */
    plcrash_async_symbol_cache_t findContext;
    plcrash_error_t err = plcrash_async_symbol_cache_init(&findContext);
    /* Abort if it failed, although that should never actually happen, ever. */
    if (err != MTDPLCRASH_ESUCCESS)
        return err;

    /* Write the file header */
    {
        uint8_t version = MTDPLCRASH_REPORT_FILE_VERSION;

        /* Write the magic string (with no trailing NULL) and the version number */
        plcrash_async_file_write(file, MTDPLCRASH_REPORT_FILE_MAGIC, strlen(MTDPLCRASH_REPORT_FILE_MAGIC));
        plcrash_async_file_write(file, &version, sizeof(version));
    }
    
    
    /* Report Info */
    {
        uint32_t size;
        
        /* Determine size */
        size = (uint32_t) plcrash_writer_write_report_info(NULL, writer);
        
        /* Write message */
        plcrash_writer_pack(file, MTDPLCRASH_PROTO_REPORT_INFO_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &size);
        plcrash_writer_write_report_info(file, writer);
    }

    /* System Info */
    {
        time_t timestamp;
        uint32_t size;

        /* Must stay the same across both calls, so get the timestamp here */
        if (time(&timestamp) == (time_t)-1) {
            MTDPLCF_DEBUG("Failed to fetch timestamp: %s", strerror(errno));
            timestamp = 0;
        }

        /* Determine size */
        size = (uint32_t) plcrash_writer_write_system_info(NULL, writer, timestamp);
        
        /* Write message */
        plcrash_writer_pack(file, MTDPLCRASH_PROTO_SYSTEM_INFO_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &size);
        plcrash_writer_write_system_info(file, writer, timestamp);
    }
    
    /* Machine Info */
    {
        uint32_t size;

        /* Determine size */
        size = (uint32_t) plcrash_writer_write_machine_info(NULL, writer);

        /* Write message */
        plcrash_writer_pack(file, MTDPLCRASH_PROTO_MACHINE_INFO_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &size);
        plcrash_writer_write_machine_info(file, writer);
    }

    /* App info */
    {
        uint32_t size;

        /* Determine size */
        size = (uint32_t) plcrash_writer_write_app_info(NULL, &writer->application_info.app_identifier, &writer->application_info.app_version, &writer->application_info.app_marketing_version);
        
        /* Write message */
        plcrash_writer_pack(file, MTDPLCRASH_PROTO_APP_INFO_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &size);
        plcrash_writer_write_app_info(file, &writer->application_info.app_identifier, &writer->application_info.app_version, &writer->application_info.app_marketing_version);
    }
    
    /* Process info */
    {
        uint32_t size;
        
        /* Determine size */
        size = (uint32_t) plcrash_writer_write_process_info(NULL, &writer->process_info.process_name, writer->process_info.process_id,
                                                 &writer->process_info.process_path, &writer->process_info.parent_process_name,
                                                 writer->process_info.parent_process_id, writer->process_info.native,
                                                 writer->process_info.start_time);
        
        /* Write message */
        plcrash_writer_pack(file, MTDPLCRASH_PROTO_PROCESS_INFO_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &size);
        plcrash_writer_write_process_info(file, &writer->process_info.process_name, writer->process_info.process_id,
                                          &writer->process_info.process_path, &writer->process_info.parent_process_name, 
                                          writer->process_info.parent_process_id, writer->process_info.native,
                                          writer->process_info.start_time);
    }
    
    /* Threads */
    uint32_t thread_number = 0;
    for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
        thread_t thread = threads[i];
        plcrash_async_thread_state_t *thr_ctx = NULL;
        bool crashed = false;
        uint32_t size;

        /* If executing on the target thread, we need to a valid context to walk */
        if (pl_mach_thread_self() == thread) {
            /* Can't log a report for the current thread without a valid context. */
            if (current_state == NULL)
                continue;
        
            thr_ctx = current_state;
        }
        
        /* Check if this is the crashed thread */
        if (crashed_thread == thread) {
            crashed = true;
        }

        /* Determine the size */
        size = (uint32_t) plcrash_writer_write_thread(NULL, writer, mach_task_self(), thread, thread_number, thr_ctx, image_list, &findContext, crashed);

        /* Write message */
        plcrash_writer_pack(file, MTDPLCRASH_PROTO_THREADS_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &size);
        plcrash_writer_write_thread(file, writer, mach_task_self(), thread, thread_number, thr_ctx, image_list, &findContext, crashed);

        thread_number++;
    }

    /* Binary Images */
    plcrash_async_image_list_set_reading(image_list, true);

    plcrash_async_image_t *image = NULL;
    while ((image = plcrash_async_image_list_next(image_list, image)) != NULL) {
        uint32_t size;

        /* Calculate the message size */
        size = (uint32_t) plcrash_writer_write_binary_image(NULL, &image->macho_image);
        plcrash_writer_pack(file, MTDPLCRASH_PROTO_BINARY_IMAGES_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &size);
        plcrash_writer_write_binary_image(file, &image->macho_image);
    }

    plcrash_async_image_list_set_reading(image_list, false);

    /* Exception */
    if (writer->uncaught_exception.has_exception) {
        uint32_t size;

        /* Calculate the message size */
        size = (uint32_t) plcrash_writer_write_exception(NULL, writer, image_list, &findContext);
        plcrash_writer_pack(file, MTDPLCRASH_PROTO_EXCEPTION_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &size);
        plcrash_writer_write_exception(file, writer, image_list, &findContext);
    }
    
    /* Signal */
    {
        uint32_t size;
        
        /* Calculate the message size */
        size = (uint32_t) plcrash_writer_write_signal(NULL, siginfo);
        plcrash_writer_pack(file, MTDPLCRASH_PROTO_SIGNAL_ID, MTDPLPROTOBUF_C_TYPE_MESSAGE, &size);
        plcrash_writer_write_signal(file, siginfo);
    }

    /* Custom data */
    if (writer->custom_data.data) {
        plcrash_writer_pack(file, MTDPLCRASH_PROTO_CUSTOM_DATA_ID, MTDPLPROTOBUF_C_TYPE_BYTES, &writer->custom_data);
    }
    
    plcrash_async_symbol_cache_free(&findContext);
    
    /* Clean up the thread array */
    for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
        if (threads[i] != pl_mach_thread_self())
            thread_resume(threads[i]);

        mach_port_deallocate(mach_task_self(), threads[i]);
    }

    vm_deallocate(mach_task_self(), (vm_address_t)threads, sizeof(thread_t) * thread_count);
    
    return MTDPLCRASH_ESUCCESS;
}


/*
 * @} plcrash_log_writer
 */
