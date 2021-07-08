#ifndef GBA_SAVEDATA_H
#define GBA_SAVEDATA_H

#include "common.h"

EWRAM_CODE THUMB uint32_t rip_save_to_ram(uint32_t * destination, uint32_t max_size);
EWRAM_CODE THUMB void dump_ram_to_sram(const uint32_t * source, uint32_t size);

enum SaveType {
    SAV_NONE = 0x0000,

    SAV_SRAM = 0x0100,
    SAV_SRAM_32k = 0x0101,

    SAV_EEPROM = 0x0200,
    SAV_EEPROM_512 = 0x0201,
    SAV_EEPROM_8k = 0x0202,
    SAV_EEPROM_8k_v125_v126 = 0x0204,

    SAV_FLASH = 0x0400,
    SAV_FLASH_64k = 0x0401,
    
    SAV_FLASH512 = 0x0800,
    SAV_FLASH512_128k = 0x0801,

    SAV_FLASH1M = 0x1000,
    SAV_FLASH1M_128k = 0x1001,

    SAV_UNKNOWN = 0xffff,
};

#endif // GBA_SAVEDATA_H
