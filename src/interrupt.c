#include "interrupt.h"

#include "common.h"
#include "logging.h"

EWRAM_RODATA static uint16_t * const REG_IE = (uint16_t *) 0x04000200;
EWRAM_RODATA static uint16_t * const REG_IF = (uint16_t *) 0x04000202;
EWRAM_RODATA static uint16_t * const REG_IME = (uint16_t *) 0x04000208;

typedef void (*interrupt_service_routine)();
EWRAM_RODATA static interrupt_service_routine * const ISR_ENTRY_PTR = (interrupt_service_routine *) 0x03007ffc;

EWRAM_RODATA static const uint32_t MAX_NUM_INSTALLED_HANDLERS = 0x10;
EWRAM_DATA static interrupt_handler INSTALLED_HANDLERS[0x10];
EWRAM_DATA static uint32_t NUM_INSTALLED_HANDLERS = 0;

__attribute__((interrupt("IRQ"))) EWRAM_CODE ARM static void master_isr();

void init_interrupts() {
    *ISR_ENTRY_PTR = master_isr;
    *REG_IME = 0x1;
}

void ack_interrupt(const enum InterruptFlag interrupt) {
    *REG_IF = (uint16_t) interrupt;
}

void enable_interrupt(const enum InterruptFlag interrupt) {
    uint16_t tmp = *REG_IE;
    *REG_IE = tmp | (uint16_t) interrupt;
}

void disable_interrupt(const enum InterruptFlag interrupt) {
    uint16_t tmp = *REG_IE;
    *REG_IE = tmp & ~((uint16_t) interrupt);
}

void install_interrupt_handler(const interrupt_handler handler) {
    if (NUM_INSTALLED_HANDLERS >= MAX_NUM_INSTALLED_HANDLERS) {
        m3_log_inline("Too many interrupt handlers installed");
        panic();
    }

    INSTALLED_HANDLERS[NUM_INSTALLED_HANDLERS++] = handler;
}

void uninstall_interrupt_handler(const interrupt_handler handler) {
    for (uint32_t i = 0; i < NUM_INSTALLED_HANDLERS; ++i) {
        if (INSTALLED_HANDLERS[i] == handler) {
            if (NUM_INSTALLED_HANDLERS > 1) {
                INSTALLED_HANDLERS[i] = INSTALLED_HANDLERS[NUM_INSTALLED_HANDLERS - 1];
            }
            --NUM_INSTALLED_HANDLERS;
            return;
        }
    }
}

void master_isr() {
    // Disable interrupts while handling
    const uint32_t before_ime = *REG_IME;
    *REG_IME = 0;

    // Go to system mode
    asm volatile (
        "mrs r3, cpsr\n"
        "bic r3, r3, #0xdf\n"
        "orr r3, r3, #0x1f\n"
        "msr cpsr, r3\n"
        :
        :
        : "r3"
    );

    const enum InterruptFlag received_interrupts = *(enum InterruptFlag *) REG_IF;
    for (uint32_t i = 0; i < NUM_INSTALLED_HANDLERS; ++i) {
        asm volatile (
            "mov r0, %[rinterrupts]\n"
            "orr %[rhandler_addr], $1\n"
            "mov lr, pc\n"
            "bx %[rhandler_addr]\n"
            :
            : [rhandler_addr] "r" (&INSTALLED_HANDLERS[i]), [rinterrupts] "r" (received_interrupts)
            : "r0", "r1", "r2", "r3", "lr", "pc"
        );
    }

    const enum InterruptFlag remaining_interrupts = *(enum InterruptFlag *) REG_IF;
    if (remaining_interrupts != IRQ_NONE) {
        m3_log_inline("Not all interrupts handled");
        panic();
    }

    // Safety
    *REG_IME = 0;

    // IRQ mode
    asm volatile (
        "mrs r3, cpsr\n"
        "bic r3, r3, #0xdf\n"
        "orr r3, r3, #0x92\n"
        "msr cpsr, r3\n"
        :
        :
        : "r3"
    );

    // Re-enable interrupts
    *REG_IME = before_ime;
}
