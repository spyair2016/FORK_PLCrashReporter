/*
 * Author: Landon Fuller <landonf@plausible.coop>
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

#if __has_include(<CrashReporter/MTDPLCrashReportStackFrameInfo.h>)
#import <CrashReporter/MTDPLCrashReportStackFrameInfo.h>
#else
#import "MTDPLCrashReportStackFrameInfo.h"
#endif

/**
 * Crash log stack frame information.
 */
@implementation MTDPLCrashReportStackFrameInfo {

    /** Frame instruction pointer. */
    uint64_t _instructionPointer;

    /** Symbol information, if available. Otherwise, will be nil. */
    __strong MTDPLCrashReportSymbolInfo *_symbolInfo;
}

@synthesize instructionPointer = _instructionPointer;
@synthesize symbolInfo = _symbolInfo;

/**
 * Initialize with the provided frame info.
 *
 * @param instructionPointer The instruction pointer value for this frame.
 * @param symbolInfo Symbol information for this frame, if available. May be nil.
 */
- (id) initWithInstructionPointer: (uint64_t) instructionPointer symbolInfo: (MTDPLCrashReportSymbolInfo *) symbolInfo {
    if ((self = [super init]) == nil)
        return nil;
    
    _instructionPointer = instructionPointer;
    _symbolInfo = symbolInfo;
    return self;
}

@end
