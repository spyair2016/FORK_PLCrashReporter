/*
 * Author: Landon Fuller <landonf@plausiblelabs.com>
 *
 * Copyright (c) 2008-2009 Plausible Labs Cooperative, Inc.
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

#if __has_include(<CrashReporter/MTDPLCrashReportSystemInfo.h>)
#import <CrashReporter/MTDPLCrashReportSystemInfo.h>
#import <CrashReporter/MTDPLCrashReportProcessorInfo.h>
#else
#import "MTDPLCrashReportSystemInfo.h"
#import "MTDPLCrashReportProcessorInfo.h"
#endif

/**
 * @ingroup constants
 *
 * The current host's operating system.
 */
MTDPLCrashReportOperatingSystem MTDPLCrashReportHostOperatingSystem =
// FIXME: Deprecated, use TARGET_OS_SIMULATOR
#if TARGET_IPHONE_SIMULATOR
    MTDPLCrashReportOperatingSystemiPhoneSimulator;
#elif TARGET_OS_TV
    MTDPLCrashReportOperatingSystemAppleTVOS;
#elif TARGET_OS_IPHONE && !TARGET_OS_MACCATALYST
    MTDPLCrashReportOperatingSystemiPhoneOS;
#elif TARGET_OS_MAC
    MTDPLCrashReportOperatingSystemMacOSX;
#else
    #error Unknown operating system
#endif




/**
 * @ingroup constants
 *
 * The current host's architecture.
 *
 * @deprecated This value has been deprecated, and will return MTDPLCrashReportArchitectureUnknown
 * on unsupported architectures.
 */
MTDPLCrashReportArchitecture MTDPLCrashReportHostArchitecture =
#ifdef __x86_64__
    MTDPLCrashReportArchitectureX86_64;
#elif defined(__i386__)
    MTDPLCrashReportArchitectureX86_32;
#elif defined(__ARM_ARCH_6K__)
    MTDPLCrashReportArchitectureARMv6;
#elif defined(__ARM_ARCH_7A__)
    MTDPLCrashReportArchitectureARMv7;
#elif defined(__ppc__)
    MTDPLCrashReportArchitecturePPC;
#else
    MTDPLCrashReportArchitectureUnknown;
#endif


/**
 * Crash log host data.
 *
 * This contains information about the host system, including operating system and architecture.
 */
@implementation MTDPLCrashReportSystemInfo {

    /** Operating system */
    MTDPLCrashReportOperatingSystem _operatingSystem;
    
    /** Operating system version */
    __strong NSString *_osVersion;
    
    /** OS build. May be nil. */
    __strong NSString *_osBuild;
    
    /** Architecture */
    MTDPLCrashReportArchitecture _architecture;
    
    /** Date crash report was generated. May be nil if the date is unknown. */
    __strong NSDate *_timestamp;

    /** Processor information. */
    __strong MTDPLCrashReportProcessorInfo *_processorInfo;
}

/**
 * Initialize the system info data object.
 *
 * @param operatingSystem Operating System
 * @param operatingSystemVersion OS version
 * @param architecture Architecture
 * @param timestamp Timestamp (may be nil).
 */
- (id) initWithOperatingSystem: (MTDPLCrashReportOperatingSystem) operatingSystem 
        operatingSystemVersion: (NSString *) operatingSystemVersion
                  architecture: (MTDPLCrashReportArchitecture) architecture
                     timestamp: (NSDate *) timestamp
{
    return [self initWithOperatingSystem: operatingSystem
                  operatingSystemVersion: operatingSystemVersion
                    operatingSystemBuild: nil
                            architecture: architecture
                           processorInfo: nil
                               timestamp: timestamp];
}

/**
 * Initialize the system info data object.
 *
 * @param operatingSystem Operating System
 * @param operatingSystemVersion OS version
 * @param operatingSystemBuild OS build (may be nil).
 * @param architecture Architecture
 * @param timestamp Timestamp (may be nil).
 */
- (id) initWithOperatingSystem: (MTDPLCrashReportOperatingSystem) operatingSystem 
        operatingSystemVersion: (NSString *) operatingSystemVersion
          operatingSystemBuild: (NSString *) operatingSystemBuild
                  architecture: (MTDPLCrashReportArchitecture) architecture
                     timestamp: (NSDate *) timestamp
{
    return [self initWithOperatingSystem: operatingSystem
                  operatingSystemVersion: operatingSystemVersion
                    operatingSystemBuild: operatingSystemBuild
                            architecture: architecture
                           processorInfo: nil
                               timestamp: timestamp];
}

/**
 * Initialize the system info data object.
 *
 * @param operatingSystem Operating System
 * @param operatingSystemVersion OS version
 * @param operatingSystemBuild OS build (may be nil).
 * @param architecture Architecture
 * @param processorInfo The processor info
 * @param timestamp Timestamp (may be nil).
 */
- (id) initWithOperatingSystem: (MTDPLCrashReportOperatingSystem) operatingSystem
        operatingSystemVersion: (NSString *) operatingSystemVersion
          operatingSystemBuild: (NSString *) operatingSystemBuild
                  architecture: (MTDPLCrashReportArchitecture) architecture
                 processorInfo: (MTDPLCrashReportProcessorInfo *) processorInfo
                     timestamp: (NSDate *) timestamp
{
    if ((self = [super init]) == nil)
        return nil;
    
    _operatingSystem = operatingSystem;
    _osVersion = operatingSystemVersion;
    _osBuild = operatingSystemBuild;
    _architecture = architecture;
    _processorInfo = processorInfo;
    _timestamp = timestamp;
    
    return self;
}

@synthesize operatingSystem = _operatingSystem;
@synthesize operatingSystemVersion = _osVersion;
@synthesize operatingSystemBuild = _osBuild;
@synthesize architecture = _architecture;
@synthesize timestamp = _timestamp;
@synthesize processorInfo = _processorInfo;

@end
