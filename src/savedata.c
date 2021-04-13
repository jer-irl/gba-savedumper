#include "savedata.h"

#include "common.h"
#include "memory.h"

enum SaveType {
    SAV_UNKNOWN,
    SAV_SRAM,
    SAV_EEPROM,
    SAV_FLASH,
    SAV_FLASH512,
    SAV_FLASH1M,
};

EWRAM_CODE THUMB static enum SaveType prompt_cart_savetype();
EWRAM_CODE THUMB static enum SaveType detect_cart_savetype();

enum SaveType detect_cart_savetype() {
    EWRAM_RODATA static const uint8_t SRAM_PATTERN[] = "SRAM_";
    EWRAM_RODATA static const uint8_t EEPROM_PATTERN[] = "EEPROM_";
    EWRAM_RODATA static const uint8_t FLASH_PATTERN[] = "FLASH_";
    EWRAM_RODATA static const uint8_t FLASH512_PATTERN[] = "FLASH512_";
    EWRAM_RODATA static const uint8_t FLASH1M_PATTERN[] = "FLASH1M_";
    EWRAM_RODATA static const uint32_t * const ROM_REGION_BEGIN_ADDR = (const uint32_t *) 0x08000000;
    EWRAM_RODATA static const uint32_t * const ROM_REGION_END_ADDR = (const uint32_t *) 0x09ffffff;

    if (scan_memory32(SRAM_PATTERN, ROM_REGION_BEGIN_ADDR, ROM_REGION_END_ADDR)) {
        return SAV_SRAM;
    }
    if (scan_memory32(EEPROM_PATTERN, ROM_REGION_BEGIN_ADDR, ROM_REGION_END_ADDR)) {
        return SAV_EEPROM;
    }
    if (scan_memory32(FLASH_PATTERN, ROM_REGION_BEGIN_ADDR, ROM_REGION_END_ADDR)) {
        return SAV_FLASH;
    }
    if (scan_memory32(FLASH512_PATTERN, ROM_REGION_BEGIN_ADDR, ROM_REGION_END_ADDR)) {
        return SAV_FLASH512;
    }
    if (scan_memory32(FLASH1M_PATTERN, ROM_REGION_BEGIN_ADDR, ROM_REGION_END_ADDR)) {
        return SAV_FLASH512;
    }
    return SAV_UNKNOWN;
}
