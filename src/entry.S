#define IRQ_MODE    #0x12
#define SYS_MODE    #0x1F

#define IRQ_STACK   0x03007FA0  @ XXX: Value used in Fire Emblem, Pokemon Fire Red
#define SYS_STACK   0x03007E00  @ XXX: Value used in Fire Emblem

.arm

.section .text.entry
.global _start
@.type _start, STT_FUNC
_start:
    b _init

.section .text
.global _init
_init:
    @ Initialize stack for IRQ mode
    mov r0, IRQ_MODE
    msr cpsr_fc, r0
    ldr sp, =IRQ_STACK

    @ Initialize stack for system mode
    mov r0, SYS_MODE
    msr cpsr_fc, r0
    ldr sp, =SYS_STACK
    @ Leave processor in system mode

    @ GBA ROMs normally set the master ISR here

    @ Branch to main(), switching to THUMB state
    ldr r0, =main
    mov lr, pc
    bx r0
    b _init
    
