#include "common.h"

#include "bios.h"
#include "logging.h"

// From linker
extern volatile uint32_t _magic_location;

EWRAM_RODATA const uint8_t CHECKSUM_SEED = 0b10001001;

bool magic_present() {
    return _magic_location == 0xdeadbeef;
}

void set_magic() {
    _magic_location = 0xdeadbeef;
}

__attribute__((noreturn)) void panic() {
    m3_log_inline("Unrecoverable error");
    while (true) {
        // bios_halt();
    }
}

uint8_t get_checksum(const uint8_t * const source, const uint32_t length_bytes) {
    uint8_t result = CHECKSUM_SEED;
    for (uint32_t i = 0; i < length_bytes; ++i) {
        result ^= source[i];
    }
    return result;
}
