#ifndef GBA_MEMORY_H
#define GBA_MEMORY_H

#include "common.h"

EWRAM_CODE THUMB void memcpy8_naive(volatile uint8_t * dst, const volatile uint8_t * src, const uint32_t len);
EWRAM_CODE THUMB void memcpy16_naive(volatile uint16_t * dst, const volatile uint16_t * src, const uint32_t len);
EWRAM_CODE THUMB uint32_t nulltermcpy8_naive(volatile uint8_t * dst, const volatile uint8_t * src);

EWRAM_CODE THUMB const uint32_t * scan_memory32(const uint8_t * pattern, const uint32_t * search_begin, const uint32_t * search_end);
EWRAM_CODE THUMB bool streq8(const uint8_t * pattern, const uint8_t * comparison);

#endif // GBA_MEMORY_H