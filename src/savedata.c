#include "savedata.h"

#include "common.h"
#include "keypad.h"
#include "logging.h"
#include "memory.h"

enum SaveType {
    SAV_UNKNOWN,
    SAV_SRAM,
    SAV_EEPROM,
    SAV_FLASH,
    SAV_FLASH512,
    SAV_FLASH1M,
};

EWRAM_CODE THUMB static enum SaveType get_savetype();
EWRAM_CODE THUMB static enum SaveType prompt_cart_savetype();
EWRAM_CODE THUMB static enum SaveType detect_cart_savetype();

uint32_t rip_save_to_ram(uint32_t * const destination, const uint32_t max_size) {
    // rip
    // write crc
    switch (get_savetype()) {
        case SAV_UNKNOWN:
        case SAV_SRAM:
        case SAV_EEPROM:
        case SAV_FLASH:
        case SAV_FLASH512:
        case SAV_FLASH1M:
            m3_log_inline("Unimplemented");
            panic();
    }
    return 0;
}

enum SaveType get_savetype() {
    const enum SaveType prompted = prompt_cart_savetype();
    if (prompted != SAV_UNKNOWN) {
        return prompted;
    }
    return detect_cart_savetype();
}

// Cannot halt and await interrupt here, instead do a race-y spin wait.
// Hopefully no TAS'ers will come with frame-perfect inputs
enum SaveType prompt_cart_savetype() {
    m3_log_inline("If save type of oem cart is known, then press A, otherwise press B");

    while (!any_key_is_down()) {}

    if (key_is_down(KEY_B)) {
        return SAV_UNKNOWN;
    }

    m3_log_inline("Press one of the following keys: SRAM:L, EEPROM:R, FLASH:UP, FLASH512:DOWN, FLASH1M:RIGHT");
    while (!any_key_is_down()) {}

    if (key_is_down(KEY_L)) {
        return SAV_SRAM;
    }
    if (key_is_down(KEY_R)) {
        return SAV_EEPROM;
    }
    if (key_is_down(KEY_UP)) {
        return SAV_FLASH;
    }
    if (key_is_down(KEY_DOWN)) {
        return SAV_FLASH512;
    }
    if (key_is_down(KEY_RIGHT)) {
        return SAV_FLASH1M;
    }

    m3_log_inline("Bad input, will attempt to autodetect");
    return SAV_UNKNOWN;
}

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
