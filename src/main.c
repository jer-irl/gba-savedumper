#include "bios.h"
#include "common.h"
#include "keypad.h"
#include "logging.h"
#include "savedata.h"

EWRAM_CODE THUMB static void main_cold_boot();
EWRAM_CODE THUMB static void main_hot_reboot();

extern uint32_t _ramsave_area_begin[];
extern uint32_t _ramsave_area_end[];
extern uint32_t _ramsave_len_location;
extern uint32_t _ramsave_crc_location;

__attribute__((noreturn))
EWRAM_CODE THUMB int gba_main() {
    m3_init();
    m3_clr();
    m3_log_inline("Welcome");

    init_interrupts();

    const bool magic_present_on_startup = magic_present();
    set_magic();
    if (magic_present_on_startup) {
        main_hot_reboot();
    } else {
        main_cold_boot();
    }

    bios_halt();
    // Shouldn't get here
    panic();
    while (true) {}
}

void main_cold_boot() {
    m3_log_inline("Code loaded to RAM, please remove flash cart, swap to OEM cart, and press A");

    keypress_await(KEY_A);

    m3_log_inline("Beginning rip of save to RAM");
    const uint32_t len_ripped = rip_save_to_ram(_ramsave_area_begin, ((uint32_t) &_ramsave_area_end) - ((uint32_t) &_ramsave_area_begin));
    _ramsave_len_location = len_ripped;
    const uint32_t crc = get_checksum((const uint8_t *) _ramsave_area_begin, len_ripped);
    _ramsave_crc_location = crc;
    m3_log_inline("Done ripping, remove the OEM cartridge now, re-insert the flash cart, and press A");

    keypress_await(KEY_A);

    m3_log_inline("Things are going to get tricky...");
    m3_log_inline(
        "To allow the custom ROM to be reloaded, you will have to navigate "
        "the flash cart's menu and reload the ROM immediately."
    )
    m3_log_inline("Press A to proceed and reboot now");

    keypress_await(KEY_A);

    // Jump to rom
    asm volatile (
        "ldr r0, =$0x08000000\n"
        "bx r0\n"
    );
}

void main_hot_reboot() {
    m3_log_inline("Welcome back, we appear to have rebooted, picking up where we left off...");

    const uint32_t save_len = _ramsave_len_location;
    const uint32_t crc = _ramsave_crc_location;
    if (get_checksum((const uint8_t *)_ramsave_area_begin, save_len) != crc) {
        m3_log_inline("crc check failed, reboot overwrote some important memory");
        panic();
    }

    m3_log_inline("Dumping save");
    dump_ram_to_sram(_ramsave_area_begin, save_len);
    
    m3_log_inline("All done!");
}
