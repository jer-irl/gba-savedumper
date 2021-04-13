#ifndef GBA_INTERRUPT_H
#define GBA_INTERRUPT_H

#include "common.h"

enum InterruptFlag {
    IRQ_NONE = 0,
    IRQ_KEYPAD = 1 << 0xc,
    IRQ_GAMEPAK = 1 << 0xd,
};

typedef void (*interrupt_handler)(enum InterruptFlag);

EWRAM_CODE THUMB void init_interrupts();

EWRAM_CODE THUMB void enable_interrupt(enum InterruptFlag);
EWRAM_CODE THUMB void disable_interrupt(enum InterruptFlag);

EWRAM_CODE THUMB void ack_interrupt(enum InterruptFlag);

EWRAM_CODE THUMB void install_interrupt_handler(interrupt_handler);
EWRAM_CODE THUMB void uninstall_interrupt_handler(interrupt_handler);

#endif // GBA_INTERRUPT_H
