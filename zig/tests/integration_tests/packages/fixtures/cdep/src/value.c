#include "value.h"

#if SCALE != 3
#error "value.c expected -DSCALE=3"
#endif

int scaled_value(void) {
    return SCALE * 14;
}
