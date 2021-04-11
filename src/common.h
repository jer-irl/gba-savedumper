#ifndef GBA_COMMON_H
#define GBA_COMMON_H

#include <stdint.h>

#define ROM_CODE __attribute__((section(".text")))
#define EWRAM_CODE __attribute__((section(".text.ram")))

#define THUMB __attribute__((target("thumb")))
#define ARM __attribute__((target("arm")))

EWRAM_CODE THUMB void memcpy8_naive(uint8_t * dst, const uint8_t * src, const uint32_t len);
EWRAM_CODE THUMB void memcpy16_naive(uint16_t * dst, const uint16_t * src, const uint32_t len);

#endif // GBA_COMMON_H
