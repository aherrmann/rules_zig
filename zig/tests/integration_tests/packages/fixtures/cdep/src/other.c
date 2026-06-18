#include "value.h"

#if SCALE != 7
#error "other.c expected -DSCALE=7"
#endif

int offset_value(void) {
    return SCALE * 2;
}
