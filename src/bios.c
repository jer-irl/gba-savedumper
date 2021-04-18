#include "bios.h"
#include "common.h"
#include "interrupt.h"

EWRAM_CODE THUMB static void bios_wait_interrupt_handler(enum InterruptFlag);

EWRAM_DATA static enum InterruptFlag PENDING_INTERRUPTS = IRQ_NONE;

EWRAM_RODATA static volatile uint16_t * const BIOS_INTERRUPT_FLAGS = (volatile uint16_t *) 0x03007ff8;

struct bios_div_result bios_div(const int32_t numerator, const int32_t denominator) {
    struct bios_div_result result;
    asm (
        "mov r0, %[rnumerator]\n"
        "mov r1, %[rdenominator]\n"
        "swi 0x06\n"
        "mov %[rresultdiv], r0\n"
        "mov %[rresultmod], r1\n"
        : [rresultdiv] "=r" (result.div), [rresultmod] "=r" (result.mod)
        : [rnumerator] "r" (numerator), [rdenominator] "r" (denominator)
        : "r0", "r1", "r3"
    );
    return result;
}

void bios_halt() {
    while (true) {
        asm volatile (
            "swi 0x02"
        );
    }
}

void bios_intr_wait(const enum InterruptFlag interrupts) {
    PENDING_INTERRUPTS = interrupts;
    install_interrupt_handler(interrupts, bios_wait_interrupt_handler);

    asm volatile (
        "mov r0, $1\n"
        "mov r1, %[rinterrupts]\n"
        "swi 0x04\n"
        :
        : [rinterrupts] "r" (interrupts)
        : "r0", "r1"
    );

    uninstall_interrupt_handler(bios_wait_interrupt_handler);
    PENDING_INTERRUPTS = IRQ_NONE;
}

void bios_wait_interrupt_handler(const enum InterruptFlag interrupt) {
    ack_interrupt(interrupt);
    *BIOS_INTERRUPT_FLAGS = interrupt;
}
