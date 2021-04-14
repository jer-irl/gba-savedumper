#ifndef GBA_SAVEDATA_H
#define GBA_SAVEDATA_H

#include "common.h"

EWRAM_CODE THUMB uint32_t rip_save_to_ram(uint32_t * destination, uint32_t max_size);
EWRAM_CODE THUMB void dump_ram_to_sram(const uint32_t * source, uint32_t size);

#endif // GBA_SAVEDATA_H
