#include "common.h"
#include "logging.h"

// From linker
extern uint32_t * const _magic_location;

bool magic_present() {
    return *_magic_location == 0xdeadbeef;
}

void set_magic() {
    *_magic_location = 0xdeadbeef;
}

void panic() {
    EWRAM_RODATA static char *PANIC_MSG = "Unrecoverable error";
    m3_log(PANIC_MSG);
    while (true) {}
}
