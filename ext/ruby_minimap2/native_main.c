#include <stdlib.h>

#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"
#pragma clang diagnostic ignored "-Wincompatible-pointer-types-discards-qualifiers"
#endif

#define main mm2_embedded_main
#define exit(status) return (status)
#include "build/minimap2/main.c"

#ifdef __clang__
#pragma clang diagnostic pop
#endif
