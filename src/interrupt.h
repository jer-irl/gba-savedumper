#ifndef GBA_INTERRUPT_H
#define GBA_INTERRUPT_H

#include "common.h"

enum InterruptFlag {
    IRQ_NONE = 0,
    IRQ_KEYPAD = 1 << 0xc,
    IRQ_GAMEPAK = 1 << 0xd,
};

typedef void (*InterruptHandler)(enum InterruptFlag);

EWRAM_CODE THUMB void init_interrupts();

EWRAM_CODE THUMB void ack_interrupt(enum InterruptFlag);

EWRAM_CODE THUMB void install_interrupt_handler(enum InterruptFlag, InterruptHandler);
EWRAM_CODE THUMB void uninstall_interrupt_handler(InterruptHandler);

#endif // GBA_INTERRUPT_H
