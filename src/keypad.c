#include "keypad.h"

EWRAM_RODATA static volatile uint16_t * const REG_KEYCNT = (uint16_t *) 0x04000132;
EWRAM_RODATA static volatile uint16_t * const REG_KEYINPUT = (uint16_t *) 0x04000130;
EWRAM_RODATA static const enum KeypadValues ALL_KEYS = 
    KEY_A | KEY_B | KEY_L | KEY_R | KEY_DOWN | KEY_UP | KEY_RIGHT | KEY_LEFT | KEY_START | KEY_SELECT;

void init_keypad() {
    *REG_KEYCNT = 0b0100000000000000 | (uint16_t) ALL_KEYS;
}

bool any_key_is_down() {
    return (~(*REG_KEYINPUT) & (uint16_t) ALL_KEYS) != 0;
}

bool key_is_down(const enum KeypadValues key) {
    return (~(*REG_KEYINPUT) & key) != 0;
}
