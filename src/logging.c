#include "logging.h"

#include "bios.h"
#include "common.h"
#include "data.h"
#include "memory.h"

static const uint32_t M3_WIDTH = 240;
static const uint32_t M3_HEIGHT = 160;
static const uint32_t M3_PIXELS = M3_WIDTH * M3_HEIGHT;

static const uint32_t GLYPH_WIDTH_PIXELS = 8;
static const uint32_t GLYPH_HEIGHT_PIXELS = 8;

static const uint32_t M3_GLYPHS_PER_ROW = M3_WIDTH / 8;
static const uint32_t M3_GLYPH_ROWS = M3_HEIGHT / 8;

static uint16_t * const M3_PAGE_ADDR = (uint16_t *) 0x06000000;
static const uint32_t M3_PAGE_LEN = 0x12c00;

static EWRAM_CODE THUMB void m3_putc(char c, uint8_t glyph_row_idx, uint8_t glyph_col_idx);
static EWRAM_CODE THUMB uint32_t strlen_naive(const char *s);

void m3_clr() {
    for (uint16_t i = 0; i < M3_PIXELS; ++i) {
        M3_PAGE_ADDR[i] = 0;
    }
}

void m3_puts(const char * const s, const uint8_t row_idx) {
    uint32_t row = row_idx;
    uint32_t col = 0;
    const char * ptr = s;

    while (*ptr != '\0') {
        m3_putc(*ptr, row, col);

        ++col;
        if (col >= M3_GLYPHS_PER_ROW) {
            col = 0;
            ++row;
        }
        ++ptr;
    }
}

void m3_log(const char *s) {
    const uint32_t string_len = strlen_naive(s);
    const struct bios_div_result div_result = bios_div(string_len, M3_GLYPHS_PER_ROW);
    const uint32_t rows_required = div_result.mod > 0 ? div_result.div + 1 : div_result.div;
    const uint16_t * const src = M3_PAGE_ADDR + (rows_required * M3_WIDTH * GLYPH_HEIGHT_PIXELS);
    uint16_t * const dst = M3_PAGE_ADDR;
    const uint32_t copy_len = (uint32_t)(M3_PAGE_ADDR + M3_PAGE_LEN) - (uint32_t)(src);
    memcpy16_naive(dst, src, copy_len);
    m3_puts(s, M3_GLYPH_ROWS - rows_required);
}

uint32_t strlen_naive(const char * const s) {
    const char *ptr = s;
    uint32_t result = 0;
    while (*ptr) {
        ++ptr;
        ++result;
    }
    return result;
}

void m3_putc(const char c, const uint8_t row_idx, const uint8_t col_idx) {
    uint16_t * const starting_pixel_addr = (uint16_t *) (M3_PAGE_ADDR + (row_idx * M3_WIDTH * GLYPH_HEIGHT_PIXELS) + (col_idx * GLYPH_WIDTH_PIXELS));
    const uint8_t * const glyph_addr = (const uint8_t *) ASCII_GLYPHS + ((c - 32) * GLYPH_HEIGHT_PIXELS);
    for (uint32_t pixel_row = 0; pixel_row < GLYPH_HEIGHT_PIXELS; ++pixel_row) {
        for (uint32_t pixel_col = 0; pixel_col < GLYPH_WIDTH_PIXELS; ++pixel_col) {
            const uint8_t glyph_pixel_row_byte = *(glyph_addr + pixel_row);
            const uint8_t glyph_pixel_value = (glyph_pixel_row_byte >> pixel_col) & 1;
            const uint16_t value_to_write = glyph_pixel_value ? 0x7fff : 0;

            uint16_t * const m3_pixel_addr = starting_pixel_addr + (pixel_row * M3_WIDTH) + pixel_col;
            *m3_pixel_addr = value_to_write;
        }
    }
}
