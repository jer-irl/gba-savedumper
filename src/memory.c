#include "memory.h"

#include "common.h"

void memcpy8_naive(volatile uint8_t * const dst, const volatile uint8_t * const src, const uint32_t len) {
    for (uint32_t i = 0; i < len; ++i) {
        dst[i] = src[i];
    }
}

void memcpy16_naive(volatile uint16_t * const dst, const volatile uint16_t * const src, const uint32_t len) {
    for (uint32_t i = 0; i < len / 2; ++i) {
        dst[i] = src[i];
    }
}

uint32_t nulltermcpy8_naive(volatile uint8_t * const dst, const volatile uint8_t * const src) {
    uint32_t i = 0;
    do {
        dst[i] = src[i];
    } while (src[i++] != '\0');
    return i;
}

const uint32_t * scan_memory32(const uint8_t * const pattern, const uint32_t * const search_begin, const uint32_t * const search_end) {
    const uint32_t * search_ptr = search_begin;
    while (search_ptr != search_end) {
        if (streq8((const uint8_t *) pattern, (const uint8_t *) search_ptr)) {
            return search_ptr;
        }

        ++search_ptr;
    }
    return NULL;
}

bool streq8(const uint8_t * const pattern, const uint8_t * const comparison) {
    const uint8_t * pattern_ptr = pattern;
    const uint8_t * comparison_ptr = comparison;

    while (*pattern_ptr != '\0') {
        if (*pattern_ptr != *comparison_ptr) {
            return false;
        }
        ++pattern_ptr;
        ++comparison_ptr;
    }

    return true;
}
