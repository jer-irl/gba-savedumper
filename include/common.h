#ifndef GBA_COMMON_H
#define GBA_COMMON_H

#include <stdbool.h>

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;

typedef signed int int32_t;

#define NULL ((void *)0x0);

#define EWRAM_RODATA __attribute__((section(".rodata.ram")))
#define EWRAM_DATA __attribute__((section(".data.ram")))

#define ROM_CODE __attribute__((section(".text")))
#define EWRAM_CODE __attribute__((section(".text.ram")))

#define THUMB __attribute__((target("thumb")))
#define ARM __attribute__((target("arm")))

EWRAM_CODE THUMB bool magic_present();
EWRAM_CODE THUMB void set_magic();

__attribute__((noreturn)) EWRAM_CODE THUMB void panic();

EWRAM_CODE THUMB uint8_t get_checksum(const uint8_t * source, uint32_t length_bytes);
extern const uint8_t CHECKSUM_SEED;

#endif // GBA_COMMON_H
