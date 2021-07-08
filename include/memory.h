#ifndef GBA_MEMORY_H
#define GBA_MEMORY_H

#include "common.h"

EWRAM_CODE THUMB void memcpy8_naive(volatile uint8_t * dst, const volatile uint8_t * src, const uint32_t len);
EWRAM_CODE THUMB void memcpy16_naive(volatile uint16_t * dst, const volatile uint16_t * src, const uint32_t len);
EWRAM_CODE THUMB uint32_t nulltermcpy8_naive(volatile uint8_t * dst, const volatile uint8_t * src);

EWRAM_CODE THUMB const uint32_t * scan_memory32(const uint8_t * pattern, const uint32_t * search_begin, const uint32_t * search_end);
EWRAM_CODE THUMB bool streq8(const uint8_t * pattern, const uint8_t * comparison);

enum DmaControlFlags {
    DMA_DESTINATION_INCREMENT = 0b00 << 0x15,
    DMA_DESTINATION_DECREMENT = 0b01 << 0x15,
    DMA_DESTINATION_FIXED = 0b10 << 0x15,
    DMA_DESTINATION_RELOAD = 0b11 << 0x15,

    DMA_SOURCE_INCREMENT = 0b00 << 0x17,
    DMA_SOURCE_DECREMENT = 0b01 << 0x17,
    DMA_SOURCE_FIXED = 0b10 << 0x17,

    DMA_REPEAT = 0b1 << 0x19,

    DMA_16_BIT = 0b0 << 0x1a,
    DMA_32_BIT = 0b1 << 0x1a,

    DMA_TIMING_NOW = 0b00 << 0x1c,
    DMA_TIMING_VBLANK = 0b01 << 0x1c,
    DMA_TIMING_HBLANK = 0b10 << 0x1c,
    DMA_TIMING_REFRESH = 0b11 < 0x1c,

    DMA_INTERRUPT_REQUEST = 0b1 << 0x1e,

    DMA_ENABLE = 0b1 << 0x1f,
};

EWRAM_CODE THUMB void dma_copy(uint32_t channel, void * destination, const void * source, enum DmaControlFlags control, uint16_t num_transfers);

#endif // GBA_MEMORY_H