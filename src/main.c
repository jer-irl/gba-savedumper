#include "bios.h"
#include "common.h"

#include "interrupt.h"
#include "keypad.h"
#include "logging.h"
#include "mgba.h"
#include "savedata.h"

EWRAM_CODE THUMB static void main_cold_boot();

EWRAM_CODE THUMB static void handle_flash_cart_removed(enum InterruptFlag);
EWRAM_CODE THUMB static void on_flash_cart_removed();

EWRAM_CODE THUMB static void handle_oem_cart_inserted_gamepak(enum InterruptFlag);
EWRAM_CODE THUMB static void handle_oem_cart_inserted_keypad(enum InterruptFlag);
EWRAM_CODE THUMB static void on_oem_cart_inserted();

EWRAM_CODE THUMB static void handle_oem_cart_removed(enum InterruptFlag);
EWRAM_CODE THUMB static void on_oem_cart_removed();

EWRAM_CODE THUMB static void handle_flash_cart_reinserted_keypad(enum InterruptFlag);
EWRAM_CODE THUMB static void handle_flash_cart_reinserted_gamepak(enum InterruptFlag);
EWRAM_CODE THUMB static void handle_reboot_requested_keypad(enum InterruptFlag);
EWRAM_CODE THUMB static void main_hot_reboot();
EWRAM_CODE THUMB static void on_flash_cart_reinserted_and_reloaded();

__attribute__((noreturn))
EWRAM_CODE THUMB int main() {
    m3_init();
    m3_clr();
    m3_log_inline("Welcome");

    init_keypad();
    init_interrupts();

    const bool magic_present_on_startup = magic_present();
    set_magic();
    if (magic_present_on_startup) {
        main_hot_reboot();
    } else {
        main_cold_boot();
    }

    // Shouldn't get here
    panic();
}

void main_cold_boot() {
    install_interrupt_handler(IRQ_GAMEPAK, handle_flash_cart_removed);

    m3_log_inline("Code loaded to RAM, please remove flash cart");

    bios_halt();
}

void handle_flash_cart_removed(const enum InterruptFlag interrupt) {
    (void) interrupt;

    ack_interrupt(IRQ_GAMEPAK);
    uninstall_interrupt_handler(handle_flash_cart_removed);

    on_flash_cart_removed();
}

void on_flash_cart_removed() {
    // mgba doesn't raise cartridge interrupt when a cartridge is inserted :(
    // Instead, prompt for button input
    const bool in_emulator = in_mgba();
    if (in_emulator) {
        install_interrupt_handler(IRQ_KEYPAD, handle_oem_cart_inserted_keypad);
    }
    else {
        install_interrupt_handler(IRQ_GAMEPAK, handle_oem_cart_inserted_gamepak);
    }

    m3_log_inline("Insert OEM cartridge");
    if (in_emulator) {
        m3_log_inline("mgba doesn't properly emulate insertion of cartridge, please press A when new ROM is present");
    }
}

void handle_oem_cart_inserted_keypad(const enum InterruptFlag interrupt) {
    (void) interrupt;

    if (!key_is_down(KEY_A)) {
        return;
    }

    ack_interrupt(IRQ_KEYPAD);
    uninstall_interrupt_handler(handle_oem_cart_inserted_keypad);

    on_oem_cart_inserted();
}

void handle_oem_cart_inserted_gamepak(const enum InterruptFlag interrupt) {
    (void) interrupt;

    ack_interrupt(IRQ_GAMEPAK);
    uninstall_interrupt_handler(handle_oem_cart_inserted_gamepak);

    on_oem_cart_inserted();
}

extern uint32_t * const _ramsave_area_begin;
extern uint32_t * const _ramsave_area_end;
extern uint32_t * const _ramsave_len_location;
extern uint32_t * const _ramsave_crc_location;
void on_oem_cart_inserted() {
    m3_log_inline("Beginning rip of save to RAM");
    const uint32_t len_ripped = rip_save_to_ram(_ramsave_area_begin, (uint32_t) _ramsave_area_end - (uint32_t) _ramsave_area_begin);
    *_ramsave_len_location = len_ripped;

    const uint32_t crc = get_crc(_ramsave_area_begin, len_ripped);
    *_ramsave_crc_location = crc;

    install_interrupt_handler(IRQ_GAMEPAK, handle_oem_cart_removed);
    m3_log_inline("Done ripping, remove the OEM cartridge now.");
}

void handle_oem_cart_removed(const enum InterruptFlag interrupt) {
    (void) interrupt;

    ack_interrupt(IRQ_GAMEPAK);
    uninstall_interrupt_handler(handle_oem_cart_removed);

    on_oem_cart_removed();
}

void on_oem_cart_removed() {
    if (in_mgba()) {
        install_interrupt_handler(IRQ_KEYPAD, handle_flash_cart_reinserted_keypad);
        m3_log_inline("Like before (for mgba) swap ROM back and press A to continue");
    }
    else {
        install_interrupt_handler(IRQ_GAMEPAK, handle_flash_cart_reinserted_gamepak);
        m3_log_inline("Re-insert the flash cart now");
    }
}

void handle_flash_cart_reinserted_keypad(const enum InterruptFlag interrupt) {
    (void) interrupt;

    if (!key_is_down(KEY_A)) {
        return;
    }

    ack_interrupt(IRQ_KEYPAD);
    uninstall_interrupt_handler(handle_flash_cart_reinserted_keypad);

    on_flash_cart_reinserted_and_reloaded();
}

void handle_flash_cart_reinserted_gamepak(const enum InterruptFlag interrupt) {
    (void) interrupt;

    ack_interrupt(IRQ_GAMEPAK);
    uninstall_interrupt_handler(handle_flash_cart_reinserted_gamepak);

    install_interrupt_handler(IRQ_KEYPAD, handle_reboot_requested_keypad);

    m3_log_inline("Things are going to get tricky...");
    m3_log_inline(
        "To allow the custom ROM to be reloaded, you will have to navigate "
        "the flash cart's menu and reload the ROM immediately."
    )
    m3_log_inline("Press A to proceed and reboot now");
}

void handle_reboot_requested_keypad(const enum InterruptFlag interrupt) {
    (void) interrupt;
    if (!key_is_down(KEY_A)) {
        return;
    }

    ack_interrupt(IRQ_KEYPAD);
    uninstall_interrupt_handler(handle_reboot_requested_keypad);

    // Jump to rom
    asm volatile (
        "ldr r0, =$0x08000000\n"
        "bx r0\n"
    );
}

void main_hot_reboot() {
    m3_log_inline("Welcome back, we appear to have rebooted, picking up where we left off...");

    on_flash_cart_reinserted_and_reloaded();
}

void on_flash_cart_reinserted_and_reloaded() {
    const uint32_t save_len = *_ramsave_len_location;
    const uint32_t crc = *_ramsave_crc_location;
    if (get_crc(_ramsave_area_begin, save_len) != crc) {
        m3_log_inline("crc check failed, reboot overwrote some important memory");
        panic();
    }

    m3_log_inline("Dumping save");
    dump_ram_to_sram(_ramsave_area_begin, save_len);
    
    m3_log_inline("All done!");
}
