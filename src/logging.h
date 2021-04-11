#ifndef GBA_LOGGING_H
#define GBA_LOGGING_H

#include <stdint.h>

#include "common.h"

EWRAM_CODE THUMB void m3_clr();
EWRAM_CODE THUMB void m3_puts(const char *s, uint8_t);
EWRAM_CODE THUMB void m3_log(const char *s);

#endif // GBA_LOGGING_H
