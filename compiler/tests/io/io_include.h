/*
 * Pick rlibc (embedded) vs rlibc_host.h (POSIX) for dual-target io tests.
 * RCC: cpp sees RRISC_IO_TEST_HOST undefined -> ../../../lib/rlibc_io.h
 * Host gcc: -DRRISC_IO_TEST_HOST + macros so app code still says putchar/puts/...
 */
#ifndef RRISC_COMPILER_TESTS_IO_INCLUDE_H
#define RRISC_COMPILER_TESTS_IO_INCLUDE_H

#if defined(RRISC_IO_TEST_HOST)
#include "../../../lib/rlibc_host.h"
#define putchar rrisc_host_putchar
#define getchar rrisc_host_getchar
#define puts rrisc_host_puts
#define gets rrisc_host_gets
#define exit rrisc_host_exit
#else
#include "../../../lib/rlibc_io.h"
#endif

#endif
