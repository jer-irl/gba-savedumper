#ifndef GBA_MGBA_H
#define GBA_MGBA_H

#include "common.h"

EWRAM_CODE THUMB bool in_mgba();
EWRAM_CODE THUMB void mgba_log(const uint8_t *message);

#endif // GBA_MGBA_H
