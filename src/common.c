#include "common.h"

#include "bios.h"
#include "logging.h"

// From linker
extern uint32_t * const _magic_location;

bool magic_present() {
    return *_magic_location == 0xdeadbeef;
}

void set_magic() {
    *_magic_location = 0xdeadbeef;
}

__attribute__((noreturn)) void panic() {
    m3_log_inline("Unrecoverable error");
    while (true) {
        bios_halt();
    }
}
