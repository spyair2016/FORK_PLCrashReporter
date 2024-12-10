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

#ifndef MTDPLCRASH_ASYNC_THREAD_ARM_H
#define MTDPLCRASH_ASYNC_THREAD_ARM_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Bitmask to strip pointer authentication (PAC).
 */
#define ARM64_PTR_MASK 0x0000000FFFFFFFFF

#if defined(__arm__) || defined(__arm64__)

// Large enough for 64-bit or 32-bit
typedef uint64_t plcrash_pdef_greg_t;
typedef uint64_t plcrash_pdef_fpreg_t;

#endif /* __arm__ */

/**
 * @internal
 * Arm registers
 */
typedef enum {
    /*
     * General
     */
    
    /** Program counter (r15) */
    MTDPLCRASH_ARM_PC = MTDPLCRASH_REG_IP,
    
    /** Frame pointer */
    MTDPLCRASH_ARM_R7 = MTDPLCRASH_REG_FP,
    
    /* stack pointer (r13) */
    MTDPLCRASH_ARM_SP = MTDPLCRASH_REG_SP,

    MTDPLCRASH_ARM_R0,
    MTDPLCRASH_ARM_R1,
    MTDPLCRASH_ARM_R2,
    MTDPLCRASH_ARM_R3,
    MTDPLCRASH_ARM_R4,
    MTDPLCRASH_ARM_R5,
    MTDPLCRASH_ARM_R6,
    // R7 is defined above
    MTDPLCRASH_ARM_R8,
    MTDPLCRASH_ARM_R9,
    MTDPLCRASH_ARM_R10,
    MTDPLCRASH_ARM_R11,
    MTDPLCRASH_ARM_R12,
    
    /* link register (r14) */
    MTDPLCRASH_ARM_LR,
    
    /** Current program status register */
    MTDPLCRASH_ARM_CPSR,
    
    /** Last register */
    MTDPLCRASH_ARM_LAST_REG = MTDPLCRASH_ARM_CPSR
} plcrash_arm_regnum_t;
    
/**
 * @internal
 * ARM64 registers
 */
typedef enum {
    /*
     * General
     */
    
    /** Program counter */
    MTDPLCRASH_ARM64_PC = MTDPLCRASH_REG_IP,
    
    /** Frame pointer (x29) */
    MTDPLCRASH_ARM64_FP = MTDPLCRASH_REG_FP,
    
    /* stack pointer (x31) */
    MTDPLCRASH_ARM64_SP = MTDPLCRASH_REG_SP,
    
    MTDPLCRASH_ARM64_X0,
    MTDPLCRASH_ARM64_X1,
    MTDPLCRASH_ARM64_X2,
    MTDPLCRASH_ARM64_X3,
    MTDPLCRASH_ARM64_X4,
    MTDPLCRASH_ARM64_X5,
    MTDPLCRASH_ARM64_X6,
    MTDPLCRASH_ARM64_X7,
    MTDPLCRASH_ARM64_X8,
    MTDPLCRASH_ARM64_X9,
    MTDPLCRASH_ARM64_X10,
    MTDPLCRASH_ARM64_X11,
    MTDPLCRASH_ARM64_X12,
    MTDPLCRASH_ARM64_X13,
    MTDPLCRASH_ARM64_X14,
    MTDPLCRASH_ARM64_X15,
    MTDPLCRASH_ARM64_X16,
    MTDPLCRASH_ARM64_X17,
    MTDPLCRASH_ARM64_X18,
    MTDPLCRASH_ARM64_X19,
    MTDPLCRASH_ARM64_X20,
    MTDPLCRASH_ARM64_X21,
    MTDPLCRASH_ARM64_X22,
    MTDPLCRASH_ARM64_X23,
    MTDPLCRASH_ARM64_X24,
    MTDPLCRASH_ARM64_X25,
    MTDPLCRASH_ARM64_X26,
    MTDPLCRASH_ARM64_X27,
    MTDPLCRASH_ARM64_X28,

    /* link register (x30) */
    MTDPLCRASH_ARM64_LR,
    
    /** Current program status register */
    MTDPLCRASH_ARM64_CPSR,
    
    /** Last register */
    MTDPLCRASH_ARM64_LAST_REG = MTDPLCRASH_ARM64_CPSR
} plcrash_arm64_regnum_t;

#ifdef __cplusplus
}
#endif

#endif /* MTDPLCRASH_ASYNC_THREAD_ARM_H */
