#include "memory.h"

void memcpy16_naive(uint16_t * dst, const uint16_t * src, const uint32_t len) {
    for (uint32_t i = 0; i < len / 2; ++i) {
        dst[i] = src[i];
    }
}
