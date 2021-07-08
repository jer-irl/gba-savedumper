#include "mgba.h"

#include "common.h"
#include "logging.h"
#include "memory.h"

EWRAM_RODATA static volatile uint16_t * const REG_MGBA_LOG_ENABLE = (uint16_t *) 0x04fff780;
EWRAM_RODATA static volatile uint16_t * const REG_MGBA_LOG_FLAGS = (uint16_t *) 0x04fff700;
EWRAM_RODATA static volatile uint8_t * const MGBA_LOG_STRING_ADDR = (uint8_t *) 0x04fff600;

bool in_mgba() {
    EWRAM_DATA static bool in_mgba_known = false;
    EWRAM_DATA static bool in_mgba_result = false;
    if (!in_mgba_known) {
        *REG_MGBA_LOG_ENABLE = 0xc0de;
        in_mgba_result = *REG_MGBA_LOG_ENABLE == 0x1dea;
        in_mgba_known = true;
    }

    return in_mgba_result;
}

void mgba_log(const uint8_t * const message) {
    const uint32_t written = nulltermcpy8_naive(MGBA_LOG_STRING_ADDR, message);
    if (written > 0x100) {
        m3_log_inline("Tried to log too long a string to mgba");
        panic();
        return;
    }
    *REG_MGBA_LOG_FLAGS = 0x100 | 1;
}
