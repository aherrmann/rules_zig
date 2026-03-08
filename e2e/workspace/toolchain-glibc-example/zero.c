#define _GNU_SOURCE
#include "zero.h"

/*
 * Uses explicit_bzero() introduced in glibc 2.25.
 * On glibc 2.17 this symbol does not exist → linker error at build time.
 */
void zero(void *buf, size_t len)
{
    explicit_bzero(buf, len);   /* glibc 2.25+ */
}
