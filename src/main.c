#include "common.h"

#include "interrupt.h"
#include "logging.h"

EWRAM_CODE THUMB static void main_cold();
EWRAM_CODE THUMB static void main_hot();

EWRAM_CODE THUMB static void on_flash_cart_removed();
EWRAM_CODE THUMB static void on_oem_cart_inserted();
EWRAM_CODE THUMB static void on_oem_cart_removed();
EWRAM_CODE THUMB static void on_flash_cart_reinserted();

__attribute__((noreturn))
EWRAM_CODE THUMB int main() {
    m3_init();
    m3_clr();
    m3_log_inline("Welcome");

    init_interrupts();

    const bool magic_present_on_startup = magic_present();
    set_magic();
    if (magic_present_on_startup) {
        main_hot();
    } else {
        main_cold();
    }

    // Shouldn't get here
    panic();
}
