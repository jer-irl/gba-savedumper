#ifndef GBA_MEMORY_H
#define GBA_MEMORY_H

#include "common.h"

EWRAM_CODE THUMB void memcpy8_naive(uint8_t * dst, const uint8_t * src, const uint32_t len);
EWRAM_CODE THUMB void memcpy16_naive(uint16_t * dst, const uint16_t * src, const uint32_t len);

EWRAM_CODE THUMB const uint32_t * scan_memory32(const uint8_t * pattern, const uint32_t * search_begin, const uint32_t * search_end);
EWRAM_CODE THUMB bool streq8(const uint8_t * pattern, const uint8_t * comparison);

#endif // GBA_MEMORY_H