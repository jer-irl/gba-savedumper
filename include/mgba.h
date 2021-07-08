#ifndef GBA_MGBA_H
#define GBA_MGBA_H

#include "common.h"

EWRAM_CODE THUMB bool in_mgba();
EWRAM_CODE THUMB void mgba_log(const uint8_t *message);

#define mgba_log_inline(message_literal) \
    { \
        EWRAM_RODATA static const uint8_t message[] = message_literal; \
        mgba_log(message); \
    }

#endif // GBA_MGBA_H
