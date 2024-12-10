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

#ifndef MTDPLCRASH_ASYNC_THREAD_X86_H
#define MTDPLCRASH_ASYNC_THREAD_X86_H

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__i386__) || defined(__x86_64__)

// Large enough for 64-bit or 32-bit
typedef uint64_t plcrash_pdef_greg_t;
typedef uint64_t plcrash_pdef_fpreg_t;

#endif /* __i386__ */

/**
 * @internal
 * x86 registers, as defined by the System V ABI, IA32 Supplement.
 */
typedef enum {
    /*
     * General
     */
    
    /** Instruction pointer */
    MTDPLCRASH_X86_EIP = MTDPLCRASH_REG_IP,
    
    /** Stack frame pointer */
    MTDPLCRASH_X86_EBP = MTDPLCRASH_REG_FP,

    /** Stack pointer */
    MTDPLCRASH_X86_ESP = MTDPLCRASH_REG_SP,

    /** Return value */
    MTDPLCRASH_X86_EAX ,
    
    /** Dividend register */
    MTDPLCRASH_X86_EDX,
    
    /** Count register */
    MTDPLCRASH_X86_ECX,
    
    /** Local register variable */
    MTDPLCRASH_X86_EBX,
    
    /** Local register variable */
    MTDPLCRASH_X86_ESI,
    
    /** Local register variable */
    MTDPLCRASH_X86_EDI,    
    
    /** Flags */
    MTDPLCRASH_X86_EFLAGS,
    
    /* Scratcn */
    MTDPLCRASH_X86_TRAPNO,
    
    
    /*
     * Segment Registers
     */
    /** Segment register */
    MTDPLCRASH_X86_CS,
    
    /** Segment register */
    MTDPLCRASH_X86_DS,
    
    /** Segment register */
    MTDPLCRASH_X86_ES,
    
    /** Segment register */
    MTDPLCRASH_X86_FS,
    
    /** Segment register */
    MTDPLCRASH_X86_GS,
    
    /** Last register */
    MTDPLCRASH_X86_LAST_REG = MTDPLCRASH_X86_GS
} plcrash_x86_regnum_t;

/**
 * @internal
 * x86-64 Registers
 */
typedef enum {
    /*
     * General
     */
    
    /** Instruction pointer */
    MTDPLCRASH_X86_64_RIP = MTDPLCRASH_REG_IP,
    
    /** Optional stack frame pointer. */
    MTDPLCRASH_X86_64_RBP = MTDPLCRASH_REG_FP,

    /** Stack pointer. */
    MTDPLCRASH_X86_64_RSP = MTDPLCRASH_REG_SP,

    /** First return register. */
    MTDPLCRASH_X86_64_RAX,
    
    /** Local register variable. */
    MTDPLCRASH_X86_64_RBX,
    
    /** Fourth integer function argument. */
    MTDPLCRASH_X86_64_RCX,
    
    /** Third function argument. Second return register. */
    MTDPLCRASH_X86_64_RDX,
    
    /** First function argument. */
    MTDPLCRASH_X86_64_RDI,
    
    /** Second function argument. */
    MTDPLCRASH_X86_64_RSI,
    
    /** Temporary register. */
    MTDPLCRASH_X86_64_R8,
    
    /** Temporary register. */
    MTDPLCRASH_X86_64_R9,
    
    /** Temporary register. */
    MTDPLCRASH_X86_64_R10,
    
    /** Callee-saved register. */
    MTDPLCRASH_X86_64_R11,
    
    /** Callee-saved register. */
    MTDPLCRASH_X86_64_R12,
    
    /** Callee-saved register. */
    MTDPLCRASH_X86_64_R13,
    
    /** Callee-saved register. */
    MTDPLCRASH_X86_64_R14,
    
    /** Callee-saved register. */
    MTDPLCRASH_X86_64_R15,
    
    /** Flags */
    MTDPLCRASH_X86_64_RFLAGS,
    
    /*
     * Segment Registers
     */
    
    /** Segment register */
    MTDPLCRASH_X86_64_CS,
    
    /** Segment register */
    MTDPLCRASH_X86_64_FS,
    
    /** Segment register */
    MTDPLCRASH_X86_64_GS,
    
    /** Last register */
    MTDPLCRASH_X86_64_LAST_REG = MTDPLCRASH_X86_64_GS
} plcrash_x86_64_regnum_t;
    
#ifdef __cplusplus
}
#endif

#endif /* MTDPLCRASH_ASYNC_THREAD_X86_H */
