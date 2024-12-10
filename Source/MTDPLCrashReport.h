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
 * EXPRESS OR IMMTDPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

#ifndef MTDPLCRASH_REPORT_H
#define MTDPLCRASH_REPORT_H

#if __has_include(<CrashReporter/MTDPLCrashReportApplicationInfo.h>)
#import <CrashReporter/MTDPLCrashReportApplicationInfo.h>
#import <CrashReporter/MTDPLCrashReportBinaryImageInfo.h>
#import <CrashReporter/MTDPLCrashReportExceptionInfo.h>
#import <CrashReporter/MTDPLCrashReportMachineInfo.h>
#import <CrashReporter/MTDPLCrashReportMachExceptionInfo.h>
#import <CrashReporter/MTDPLCrashReportProcessInfo.h>
#import <CrashReporter/MTDPLCrashReportProcessorInfo.h>
#import <CrashReporter/MTDPLCrashReportRegisterInfo.h>
#import <CrashReporter/MTDPLCrashReportSignalInfo.h>
#import <CrashReporter/MTDPLCrashReportStackFrameInfo.h>
#import <CrashReporter/MTDPLCrashReportSymbolInfo.h>
#import <CrashReporter/MTDPLCrashReportSystemInfo.h>
#import <CrashReporter/MTDPLCrashReportThreadInfo.h>
#else
#import "MTDPLCrashReportApplicationInfo.h"
#import "MTDPLCrashReportBinaryImageInfo.h"
#import "MTDPLCrashReportExceptionInfo.h"
#import "MTDPLCrashReportMachineInfo.h"
#import "MTDPLCrashReportMachExceptionInfo.h"
#import "MTDPLCrashReportProcessInfo.h"
#import "MTDPLCrashReportProcessorInfo.h"
#import "MTDPLCrashReportRegisterInfo.h"
#import "MTDPLCrashReportSignalInfo.h"
#import "MTDPLCrashReportStackFrameInfo.h"
#import "MTDPLCrashReportSymbolInfo.h"
#import "MTDPLCrashReportSystemInfo.h"
#import "MTDPLCrashReportThreadInfo.h"
#endif

/** 
 * @ingroup constants
 * Crash file magic identifier */
#define MTDPLCRASH_REPORT_FILE_MAGIC "plcrash"

/** 
 * @ingroup constants
 * Crash format version byte identifier. Will not change outside of the introduction of
 * an entirely new crash log format. */
#define MTDPLCRASH_REPORT_FILE_VERSION 1

/**
 * @ingroup types
 * Crash log file header format.
 *
 * Crash log files start with 7 byte magic identifier (#MTDPLCRASH_REPORT_FILE_MAGIC),
 * followed by a single unsigned byte version number (#MTDPLCRASH_REPORT_FILE_VERSION).
 * The crash log message format itself is extensible, so this version number will only
 * be incremented in the event of an incompatible encoding or format change.
 */
struct MTDPLCrashReportFileHeader {
    /** Crash log magic identifier, not NULL terminated */
    const char magic[7];

    /** Crash log encoding/format version */
    const uint8_t version;

    /** File data */
    const uint8_t data[];
} __attribute__((packed));


/**
 * @internal
 * Private decoder instance variables (used to hide the underlying protobuf parser).
 */
typedef struct _MTDPLCrashReportDecoder _MTDPLCrashReportDecoder;

@interface MTDPLCrashReport : NSObject

- (id) initWithData: (NSData *) encodedData error: (NSError **) outError;

- (MTDPLCrashReportBinaryImageInfo *) imageForAddress: (uint64_t) address;

/**
 * System information.
 */
@property(nonatomic, readonly, strong) MTDPLCrashReportSystemInfo *systemInfo;

/**
 * YES if machine information is available.
 */
@property(nonatomic, readonly) BOOL hasMachineInfo;

/**
 * Machine information. Only available in later (v1.1+) crash report format versions. If not available,
 * will be nil.
 */
@property(nonatomic, readonly, strong) MTDPLCrashReportMachineInfo *machineInfo;

/**
 * Application information.
 */
@property(nonatomic, readonly, strong) MTDPLCrashReportApplicationInfo *applicationInfo;

/**
 * YES if process information is available.
 */
@property(nonatomic, readonly) BOOL hasProcessInfo;

/**
 * Process information. Only available in later (v1.1+) crash report format versions. If not available,
 * will be nil.
 */
@property(nonatomic, readonly, strong) MTDPLCrashReportProcessInfo *processInfo;

/**
 * Signal information. This provides the signal and signal code of the fatal signal.
 */
@property(nonatomic, readonly, strong) MTDPLCrashReportSignalInfo *signalInfo;

/**
 * Mach exception information, if available. This will only be included in the
 * case that encoding crash reporter's exception-based reporting was enabled, and a Mach
 * exception was caught.
 *
 * @warning If Mach exception information is available, the legacy signalInfo property will also be provided; this
 * s required to maintain backwards compatibility with the established API. Note, however, that the signal info may be derived from the
 * Mach exception info by the encoding crash reporter, and thus may not exactly match the kernel exception-to-signal
 * mappings implemented in xnu. As such, when Mach exception info is available, its use should be preferred.
 */
@property(nonatomic, readonly, strong) MTDPLCrashReportMachExceptionInfo *machExceptionInfo;

/**
 * Thread information. Returns a list of MTDPLCrashReportThreadInfo instances.
 */
@property(nonatomic, readonly, strong) NSArray *threads;

/**
 * Binary image information. Returns a list of MTDPLCrashReportBinaryImageInfo instances.
 */
@property(nonatomic, readonly, strong) NSArray *images;

/**
 * YES if exception information is available.
 */
@property(nonatomic, readonly) BOOL hasExceptionInfo;

/**
 * Exception information. Only available if a crash was caused by an uncaught exception,
 * otherwise nil.
 */
@property(nonatomic, readonly, strong) MTDPLCrashReportExceptionInfo *exceptionInfo;

/**
 * Custom user data. Only available if user explicitly assigned it before crash happened,
 * otherwise nil.
 */
@property(nonatomic, readonly, strong) NSData *customData;

/**
 * A client-generated 16-byte UUID. May be used to filter duplicate reports submitted or generated
 * by a single client. Only available in later (v1.2+) crash report format versions. If not available,
 * will be NULL.
 */
@property(nonatomic, readonly) CFUUIDRef uuidRef;

@end

#endif
