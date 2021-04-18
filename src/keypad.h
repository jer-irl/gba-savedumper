#ifndef GBA_KEYPAD_H
#define GBA_KEYPAD_H

#include "common.h"

enum KeypadValues {
    KEY_NONE = 0,
    KEY_A = 1 << 0,
    KEY_B = 1 << 1,
    KEY_SELECT = 1 << 2,
    KEY_START = 1 << 3,
    KEY_RIGHT = 1 << 4,
    KEY_LEFT = 1 << 5,
    KEY_UP = 1 << 6,
    KEY_DOWN = 1 << 7,
    KEY_R = 1 << 8,
    KEY_L = 1 << 9,
};

EWRAM_CODE THUMB bool any_key_is_down();
EWRAM_CODE THUMB bool key_is_down(enum KeypadValues);
EWRAM_CODE THUMB enum KeypadValues keypress_await(enum KeypadValues);

#endif // GBA_KEYPAD_H
