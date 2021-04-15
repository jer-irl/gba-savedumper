#include "memory.h"

#include "common.h"
#include "logging.h"

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

void dma_copy(
    const uint32_t channel, 
    void * const destination, 
    const void * const source, 
    const enum DmaControlFlags control, 
    const uint16_t num_transfers)
{
    if (channel > 3) {
        m3_log_inline("Invalid dma channel value");
        panic();
        return;
    }
    volatile uint32_t * const REG_DMA_CONTROL = (uint32_t *)(0x040000b8 + (0x0c * channel));
    volatile uint32_t const * * const REG_DMA_SOURCE = (const volatile uint32_t * *) (0x040000b0 + (0x0c * channel));
    volatile uint32_t * * const REG_DMA_DESTINATION = (volatile uint32_t * *) (0x040000b4 + (0x0c * channel));

    *REG_DMA_CONTROL = 0;
    *REG_DMA_SOURCE = (const uint32_t *) source;
    *REG_DMA_DESTINATION = (uint32_t *) destination;
    *REG_DMA_CONTROL = control | num_transfers;
}
