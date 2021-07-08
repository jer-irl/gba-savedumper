#include "savedata.h"

#include "bios.h"
#include "common.h"
#include "gamedb.h"
#include "keypad.h"
#include "logging.h"
#include "memory.h"

EWRAM_RODATA static volatile const uint8_t * const SRAM_REGION_BEGIN = (const uint8_t *) 0x0e000000;
EWRAM_RODATA static volatile const uint8_t * const FLASH_REGION_BEGIN = (const uint8_t *) 0x0e000000;

EWRAM_CODE THUMB static enum SaveType get_savetype();
EWRAM_CODE THUMB static enum SaveType prompt_cart_savetype();
EWRAM_CODE THUMB static enum SaveType detect_cart_savetype();

EWRAM_CODE THUMB static void flash_swap_bank(uint32_t target_bank);

EWRAM_CODE THUMB static void eeprom_read(uint8_t * destination, uint32_t starting_block, uint32_t num_blocks, uint32_t eeprom_size_bytes);
EWRAM_CODE THUMB static void eeprom_read_block(uint8_t * destination, uint32_t source_block, uint32_t eeprom_size_bytes);
EWRAM_CODE THUMB static void eeprom_read_block512(uint8_t * destination, uint32_t source_block);
EWRAM_CODE THUMB static void eeprom_read_block8k(uint8_t * destination, uint32_t source_block);
EWRAM_CODE THUMB static uint32_t eeprom_detect_size_bytes();

uint32_t rip_save_to_ram(uint32_t * const destination, const uint32_t max_size) {
    uint32_t ripped_len = 0;
    switch (get_savetype()) {
        case SAV_NONE:
            m3_log_inline("No save to rip");
            panic();
            break;
        case SAV_UNKNOWN:
            m3_log_inline("Unknown save type");
            panic();
            break;
        case SAV_SRAM:
        case SAV_SRAM_32k:
            m3_log_inline("Ripping SRAM save");
            ripped_len = 0x10000;
            if (ripped_len > max_size) {
                m3_log_inline("Not enough space to rip save from SRAM");
                panic();
            }
            memcpy8_naive((uint8_t *) destination, SRAM_REGION_BEGIN, ripped_len);
            break;
        case SAV_EEPROM:
            m3_log_inline("Ripping EEPROM save unknown size");
            {
                const uint32_t eeprom_size = eeprom_detect_size_bytes();
                if (eeprom_size == 0x0200) {
                    goto SAV_EEPROM_512_LABEL;
                }
                else if (eeprom_size == 0x2000) {
                    goto SAV_EEPROM_8k_LABEL;
                }
            }
            m3_log_inline("Failed to detect EEPROM size");
            panic();
            break;

        case SAV_EEPROM_512:
        SAV_EEPROM_512_LABEL:
            m3_log_inline("Ripping EEPROM 512 save");
            ripped_len = 0x0200;
            if (ripped_len > max_size) {
                m3_log_inline("Not enough space to rip save from EEPROM 512");
                panic();
            }
            eeprom_read((uint8_t *) destination, 0, 0x40, ripped_len);
            break;

        case SAV_EEPROM_8k: 
        case SAV_EEPROM_8k_v125_v126: 
        SAV_EEPROM_8k_LABEL:
            m3_log_inline("Ripping EEPROM 8k save");
            ripped_len = 0x2000;
            if (ripped_len > max_size) {
                m3_log_inline("Not enough space to rip save from EEPROM ik");
                panic();
            }
            eeprom_read((uint8_t *) destination, 0, 0x400, ripped_len);
            break;

        case SAV_FLASH:
        case SAV_FLASH_64k:
            m3_log_inline("Ripping from 64k flash");
            ripped_len = 0x10000;
            if (ripped_len > max_size) {
                m3_log_inline("Not enough space to rip save from 64k flash");
                panic();
            }
            memcpy8_naive((uint8_t *) destination, FLASH_REGION_BEGIN, ripped_len);
            break;

        case SAV_FLASH512:
        case SAV_FLASH512_128k:
        case SAV_FLASH1M:
        case SAV_FLASH1M_128k:
            m3_log_inline("Ripping from 128k flash");
            ripped_len = 0x20000;
            if (ripped_len > max_size) {
                m3_log_inline("Not enough space to rip from 128k flash");
                panic();
            }
            m3_log_inline("bank 0");
            flash_swap_bank(0);
            memcpy8_naive((uint8_t *) destination, FLASH_REGION_BEGIN, 0x10000);
            m3_log_inline("bank 1");
            flash_swap_bank(1);
            memcpy8_naive((uint8_t *) destination + 0x10000, FLASH_REGION_BEGIN, 0x10000);
            break;
    }
    m3_log_inline("Done ripping save");
    return ripped_len;
}

void dump_ram_to_sram(const uint32_t * const source, const uint32_t size) {
    memcpy8_naive((uint8_t *) SRAM_REGION_BEGIN, (const uint8_t *) source, size);
}

enum SaveType get_savetype() {
    const enum SaveType prompted = prompt_cart_savetype();
    if (prompted != SAV_UNKNOWN) {
        return prompted;
    }
    const enum SaveType looked_up = lookup_rom_savetype();
    if (looked_up != SAV_UNKNOWN) {
        return looked_up;
    }
    return detect_cart_savetype();
}

// Cannot halt and await interrupt here, instead do a race-y spin wait.
// Hopefully no TAS'ers will come with frame-perfect inputs
enum SaveType prompt_cart_savetype() {
    m3_log_inline("If save type of oem cart is known, then press A, otherwise press B");

    if (keypress_await(KEY_A | KEY_B) == KEY_B) {
        return SAV_UNKNOWN;
    }

    m3_log_inline("Press one of the following keys: SRAM:L, EEPROM:R, FLASH:UP, FLASH512:DOWN, FLASH1M:RIGHT");

    switch (keypress_await(KEY_L | KEY_R | KEY_UP | KEY_DOWN | KEY_RIGHT)) {
        case KEY_L:
            return SAV_SRAM;
        case KEY_R:
            return SAV_EEPROM;
        case KEY_UP:
            return SAV_FLASH;
        case KEY_DOWN:
            return SAV_FLASH512;
        case KEY_RIGHT:
            return SAV_FLASH1M;
        default:
            m3_log_inline("Unexpected keypress");
            panic();
    }
}

enum SaveType detect_cart_savetype() {
    EWRAM_RODATA static const uint8_t SRAM_PATTERN[] = "SRAM_";
    EWRAM_RODATA static const uint8_t EEPROM_PATTERN[] = "EEPROM_";
    EWRAM_RODATA static const uint8_t FLASH_PATTERN[] = "FLASH_";
    EWRAM_RODATA static const uint8_t FLASH512_PATTERN[] = "FLASH512_";
    EWRAM_RODATA static const uint8_t FLASH1M_PATTERN[] = "FLASH1M_";
    EWRAM_RODATA static const uint32_t * const ROM_REGION_BEGIN_ADDR = (const uint32_t *) 0x08000000;
    EWRAM_RODATA static const uint32_t * const ROM_REGION_END_ADDR = (const uint32_t *) 0x09ffffff;

    m3_log_inline("Scanning ROM for save type");
    m3_log((char *) SRAM_PATTERN);
    if (scan_memory32(SRAM_PATTERN, ROM_REGION_BEGIN_ADDR, ROM_REGION_END_ADDR)) {
        return SAV_SRAM;
    }
    m3_log((char *) EEPROM_PATTERN);
    if (scan_memory32(EEPROM_PATTERN, ROM_REGION_BEGIN_ADDR, ROM_REGION_END_ADDR)) {
        return SAV_EEPROM;
    }
    m3_log((char *) FLASH_PATTERN);
    if (scan_memory32(FLASH_PATTERN, ROM_REGION_BEGIN_ADDR, ROM_REGION_END_ADDR)) {
        return SAV_FLASH;
    }
    m3_log((char *) FLASH512_PATTERN);
    if (scan_memory32(FLASH512_PATTERN, ROM_REGION_BEGIN_ADDR, ROM_REGION_END_ADDR)) {
        return SAV_FLASH512;
    }
    m3_log((char *) FLASH1M_PATTERN);
    if (scan_memory32(FLASH1M_PATTERN, ROM_REGION_BEGIN_ADDR, ROM_REGION_END_ADDR)) {
        return SAV_FLASH512;
    }
    return SAV_UNKNOWN;
}

void flash_swap_bank(const uint32_t target_bank) {
    *(volatile uint8_t *) 0x0e005555 = 0xaa;
    *(volatile uint8_t *) 0x0e002aaa = 0x55;
    *(volatile uint8_t *) 0x0e005555 = 0xb0;
    *(volatile uint8_t *) 0x0e000000 = target_bank;
}

void eeprom_read(uint8_t * const destination, const uint32_t starting_block, const uint32_t num_blocks, const uint32_t eeprom_size_bytes) {
    for (uint32_t i = 0; i < num_blocks; ++i) {
        eeprom_read_block(destination + (8 * i), starting_block + i, eeprom_size_bytes);
    }
}

void eeprom_read_block(uint8_t * const destination, const uint32_t source_block, const uint32_t eeprom_size_bytes) {
    if (eeprom_size_bytes == 0x0200) {
        eeprom_read_block512(destination, source_block);
    }
    else if (eeprom_size_bytes == 0x2000) {
        eeprom_read_block8k(destination, source_block);
    }
    else {
        m3_log_inline("Invalid eeprom size");
        panic();
    }
}

void eeprom_read_block512(uint8_t * const destination, const uint32_t source_block) {
    uint16_t command_buffer[9];
    command_buffer[0] = 0b1;
    command_buffer[1] = 0b1;
    command_buffer[2] = source_block >> 5;
    command_buffer[3] = source_block >> 4;
    command_buffer[4] = source_block >> 3;
    command_buffer[5] = source_block >> 2;
    command_buffer[6] = source_block >> 1;
    command_buffer[7] = source_block >> 0;
    command_buffer[8] = 0b0;

    dma_copy(3, (void *) 0x0d000000, &command_buffer, DMA_16_BIT | DMA_TIMING_NOW | DMA_ENABLE | DMA_DESTINATION_INCREMENT | DMA_SOURCE_INCREMENT, 9);

    uint16_t result_buffer[68];
    dma_copy(3, &result_buffer, (void *) 0x0d000000, DMA_16_BIT | DMA_TIMING_NOW | DMA_ENABLE | DMA_DESTINATION_INCREMENT | DMA_SOURCE_INCREMENT, 68);

    for (uint32_t i = 4; i < 68; ++i) {
        const uint32_t bit_idx = i - 4;
        const uint32_t byte_idx = bios_div(bit_idx, 8).div;
        destination[byte_idx] = (destination[byte_idx] << 1) | (result_buffer[i] & 0b1);
    }
}

void eeprom_read_block8k(uint8_t * const destination, const uint32_t source_block) {
    uint16_t command_buffer[17];
    command_buffer[0] = 0b1;
    command_buffer[1] = 0b1;
    command_buffer[2] = source_block >> 13;
    command_buffer[3] = source_block >> 12;
    command_buffer[4] = source_block >> 11;
    command_buffer[5] = source_block >> 10;
    command_buffer[6] = source_block >> 9;
    command_buffer[7] = source_block >> 8;
    command_buffer[8] = source_block >> 7;
    command_buffer[9] = source_block >> 6;
    command_buffer[10] = source_block >> 5;
    command_buffer[11] = source_block >> 4;
    command_buffer[12] = source_block >> 3;
    command_buffer[13] = source_block >> 2;
    command_buffer[14] = source_block >> 1;
    command_buffer[15] = source_block >> 0;
    command_buffer[16] = 0b0;

    dma_copy(3, (void *) 0x0d000000, &command_buffer, DMA_16_BIT | DMA_TIMING_NOW | DMA_ENABLE | DMA_DESTINATION_INCREMENT | DMA_SOURCE_INCREMENT, 17);

    uint16_t result_buffer[68];
    dma_copy(3, &result_buffer, (void *) 0x0d000000, DMA_16_BIT | DMA_TIMING_NOW | DMA_ENABLE | DMA_DESTINATION_INCREMENT | DMA_SOURCE_INCREMENT, 68);

    for (uint32_t i = 4; i < 68; ++i) {
        const uint32_t bit_idx = i - 4;
        const uint32_t byte_idx = bios_div(bit_idx, 8).div;
        destination[byte_idx] = (destination[byte_idx] << 1) | (result_buffer[i] & 0b1);
    }
}

uint32_t eeprom_detect_size_bytes() {
    switch (lookup_rom_savetype()) {
        case SAV_EEPROM_512:
            return 0x0200;
        case SAV_EEPROM_8k:
        case SAV_EEPROM_8k_v125_v126:
            return 0x2000;
        default:
            m3_log_inline("EEPROM save length");
            panic();
    }
}
