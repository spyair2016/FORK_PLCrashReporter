/*
 * Author: Landon Fuller <landonf@plausiblelabs.com>
 *
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

#ifndef MTDPLCRASH_CONSTANTS_H
#define MTDPLCRASH_CONSTANTS_H

#include <assert.h>
#include <TargetConditionals.h>

#if defined(__cplusplus)
#   define MTDPLCR_EXPORT extern "C"
#   define MTDPLCR_C_BEGIN_DECLS extern "C" {
#   define MTDPLCR_C_END_DECLS }
#else
#   define MTDPLCR_EXPORT extern
#   define MTDPLCR_C_BEGIN_DECLS
#   define MTDPLCR_C_END_DECLS
#endif

#if defined(__cplusplus)
#  define NO_OTHER_MACRO_STARTS_WITH_THIS_NAME_
#  define IS_EMPTY_(name) defined(NO_OTHER_MACRO_STARTS_WITH_THIS_NAME_ ## name)
#  define IS_EMPTY(name) IS_EMPTY_(name)
#  if defined(MTDPLCRASHREPORTER_PREFIX) && !IS_EMPTY(MTDPLCRASHREPORTER_PREFIX)
     /** @internal Define the plcrash namespace, automatically inserting an inline namespace containing the configured MTDPLCRASHREPORTER_PREFIX, if any. */
#    define MTDPLCR_CPP_BEGIN_NS namespace plcrash { inline namespace MTDPLCRASHREPORTER_PREFIX {

    /** @internal Close the definition of the `plcrash` namespace (and the MTDPLCRASHREPORTER_PREFIX inline namespace, if any). */
#    define MTDPLCR_CPP_END_NS }}
#  else
#   define MTDPLCR_CPP_BEGIN_NS namespace plcrash {
#   define MTDPLCR_CPP_END_NS }
#  endif
#endif

#ifdef __clang__
#  define MTDPLCR_PRAGMA_CLANG(_p) _Pragma(_p)
#else
#  define MTDPLCR_PRAGMA_CLANG(_p)
#endif

#ifdef __clang__
#  define MTDPLCR_DEPRECATED __attribute__((deprecated))
#else
#  define MTDPLCR_DEPRECATED
#endif

#if defined(__clang__) || defined(__GNUC__)
#  define MTDPLCR_UNUSED __attribute__((unused))
#else
#  define MTDPLCR_UNUSED
#endif

#ifdef MTDPLCR_PRIVATE
/**
 * Marks a definition as deprecated only for for external clients, allowing
 * uses of it internal fo the framework.
 */
#  define MTDPLCR_EXTERNAL_DEPRECATED

/**
 * @internal
 * A macro to put above a definition marked MTDPLCR_EXTERNAL_DEPRECATED that will
 * silence warnings about there being a deprecation documentation marker but the
 * definition not being marked deprecated.
 */
#  define MTDPLCR_EXTERNAL_DEPRECATED_NOWARN_PUSH() \
      MTDPLCR_PRAGMA_CLANG("clang diagnostic push"); \
      MTDPLCR_PRAGMA_CLANG("clang diagnostic ignored \"-Wdocumentation-deprecated-sync\"")

/**
 * @internal
 * A macro to put below a definition marked MTDPLCR_EXTERNAL_DEPRECATED that will
 * silence warnings about there being a deprecation documentation marker but the
 * definition not being marked deprecated.
 */
#  define MTDPLCR_EXTERNAL_DEPRECATED_NOWARN_POP() MTDPLCR_PRAGMA_CLANG("clang diagnostic pop")

#else

#  define MTDPLCR_EXTERNAL_DEPRECATED MTDPLCR_DEPRECATED
#  define MTDPLCR_EXTERNAL_DEPRECATED_NOWARN_PUSH()
#  define MTDPLCR_EXTERNAL_DEPRECATED_NOWARN_PUSH()

#endif /* MTDPLCR_PRIVATE */

#ifdef MTDPLCR_PRIVATE
#  if defined(__clang__) && __has_feature(cxx_attributes) && __has_warning("-Wimplicit-fallthrough")
#    define MTDPLCR_FALLTHROUGH [[clang::fallthrough]]
#  else
#    define MTDPLCR_FALLTHROUGH do {} while (0)
#  endif
#endif

#ifdef MTDPLCR_PRIVATE
/**
 * @internal
 * Static compile-time assertion.
 *
 * @param name The assertion name; must be valid for use within a C identifier.
 * @param cond Assertion condition
 */
#  define MTDPLCR_ASSERT_STATIC(name, cond) MTDPLCR_ASSERT_STATIC_(name, cond, __LINE__)
/*
 * C++11 and C11 both provide a static_assert().
 *
 * Otherwise, we have to use typedef-based static assertions.
 */
#  if (defined(__cplusplus) && __cplusplus >= 201103L) || (!defined(__cplusplus) && defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L)
#    define MTDPLCR_ASSERT_STATIC_(name, cond, line) MTDPLCR_ASSERT_STATIC__(#name, cond)
#    define MTDPLCR_ASSERT_STATIC__(name, cond) static_assert(cond, #name)
#  else
#    define MTDPLCR_ASSERT_STATIC_(name, cond, line) MTDPLCR_ASSERT_STATIC__(name, cond, line)
#    define MTDPLCR_ASSERT_STATIC__(name, cond, line) typedef int plcf_static_assert_##name##_##line [(cond) ? 1 : -1] MTDPLCR_UNUSED
#  endif
#endif /* MTDPLCR_PRIVATE */

#endif /* MTDPLCRASH_CONSTANTS_H */
