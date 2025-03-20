#include <stdint.h>
#include <stdio.h>
#include "shared.h"

int main() {
    int32_t result = add(1, 2);
    int32_t expected = 3;
    if (result != expected) {
	fprintf(stderr, "FAIL: Expected %d, got %d.\n", expected, result);
	return 1;
    }
}
