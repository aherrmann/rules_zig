#include <stdint.h>
#include <stdio.h>

int32_t mul(int32_t, int32_t);

int main() {
    int32_t result = mul(-2, 3);
    int32_t expected = -6;
    if (result != expected) {
	fprintf(stderr, "FAIL: Expected %d, got %d.\n", expected, result);
	return 1;
    }
}
