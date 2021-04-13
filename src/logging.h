#ifndef GBA_LOGGING_H
#define GBA_LOGGING_H

#include "common.h"

EWRAM_CODE THUMB void m3_init();
EWRAM_CODE THUMB void m3_clr();
EWRAM_CODE THUMB void m3_puts(const char *s, uint8_t);
EWRAM_CODE THUMB void m3_log(const char *s);

#define m3_log_inline(s) \
    { \
        EWRAM_RODATA static const char message[] = s; \
        m3_log(message); \
    }

#endif // GBA_LOGGING_H
