/*
 * Author: Landon Fuller <landonf@bikemonkey.org>
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

#import <Foundation/Foundation.h>
#import <mach/mach.h>

#import "MTDPLCrashFeatureConfig.h"
#import "MTDPLCrashMachExceptionPortSet.h"

#if MTDPLCRASH_FEATURE_MACH_EXCEPTIONS

@interface MTDPLCrashMachExceptionPort : NSObject

- (instancetype) initWithServerPort: (mach_port_t) port
                               mask: (exception_mask_t) mask
                           behavior: (exception_behavior_t) behavior
                             flavor: (thread_state_flavor_t) flavor;

+ (MTDPLCrashMachExceptionPortSet *) exceptionPortsForTask: (task_t) task mask: (exception_mask_t) mask error: (NSError **) outError;
+ (MTDPLCrashMachExceptionPortSet *) exceptionPortsForThread: (thread_t) thread mask: (exception_mask_t) mask error: (NSError **) outError;

- (BOOL) registerForTask: (task_t) task previousPortSet: (__strong MTDPLCrashMachExceptionPortSet **) ports error: (NSError **) outError;
- (BOOL) registerForThread: (thread_t) thread previousPortSet: (__strong MTDPLCrashMachExceptionPortSet **) ports error: (NSError **) outError;

/** Exception server port. */
@property(nonatomic, readonly) mach_port_t server_port;

/** Exception mask. */
@property(nonatomic, readonly) exception_mask_t mask;

/** Exception behavior. */
@property(nonatomic, readonly) exception_behavior_t behavior;

/** Exception thread flavor. */
@property(nonatomic, readonly) thread_state_flavor_t flavor;


@end

#endif /* MTDPLCRASH_FEATURE_MACH_EXCEPTIONS */
