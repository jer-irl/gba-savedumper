.cpu arm7tdmi
@.syntax unified

.section .text.rom

.arm

.set MGBA_LOG_ENABLE, 1
.set MGBA_LOG_REG_ENABLE, 0x04FFF780
.set MGBA_LOG_REG_FLAGS, 0x04FFF700
.set MGBA_LOG_STRING, 0x04FFF600
.set MGBA_LOG_ERROR, 1


.global _start
_start:
    b init

header:
    @ Nintendo logo; 156 bytes
    .byte 0x24,0xFF,0xAE,0x51,0x69,0x9A,0xA2,0x21,0x3D,0x84,0x82,0x0A,0x84,0xE4,0x09,0xAD
    .byte 0x11,0x24,0x8B,0x98,0xC0,0x81,0x7F,0x21,0xA3,0x52,0xBE,0x19,0x93,0x09,0xCE,0x20
    .byte 0x10,0x46,0x4A,0x4A,0xF8,0x27,0x31,0xEC,0x58,0xC7,0xE8,0x33,0x82,0xE3,0xCE,0xBF
    .byte 0x85,0xF4,0xDF,0x94,0xCE,0x4B,0x09,0xC1,0x94,0x56,0x8A,0xC0,0x13,0x72,0xA7,0xFC
    .byte 0x9F,0x84,0x4D,0x73,0xA3,0xCA,0x9A,0x61,0x58,0x97,0xA3,0x27,0xFC,0x03,0x98,0x76
    .byte 0x23,0x1D,0xC7,0x61,0x03,0x04,0xAE,0x56,0xBF,0x38,0x84,0x00,0x40,0xA7,0x0E,0xFD
    .byte 0xFF,0x52,0xFE,0x03,0x6F,0x95,0x30,0xF1,0x97,0xFB,0xC0,0x85,0x60,0xD6,0x80,0x25
    .byte 0xA9,0x63,0xBE,0x03,0x01,0x4E,0x38,0xE2,0xF9,0xA2,0x34,0xFF,0xBB,0x3E,0x03,0x44
    .byte 0x78,0x00,0x90,0xCB,0x88,0x11,0x3A,0x94,0x65,0xC0,0x7C,0x63,0x87,0xF0,0x3C,0xAF
    .byte 0xD6,0x25,0xE4,0x8B,0x38,0x0A,0xAC,0x72,0x21,0xD4,0xF8,0x07

    @ Game title; 12 bytes
    .zero 12

    @ AGB-UTTD game code; 4 bytes
    .byte 'B'               @ Game type: Normal "newer" game
    .byte 0x00,0x00         @ Short title
    .byte 'E'               @ Language: English

    .byte 0x30,0x31         @ Maker code; 0x30,0x31 for Nintendo
    .byte 0x96              @ Fixed
    .byte 0x00              @ Unit code
    .byte 0x00              @ Device type; 0 for normal catridges
    .zero 7                 @ Reserved
    .byte 0x00              @ Game version
    .byte 0x69              @ Header checksum
    .zero 2                 @ Reserved
end_header:

@ Fool mgba MB detection
.word 0xEA000000 @ b 0

.align
.asciz "FLASH1M_Vnnn"
.align

.set IRQ_MODE, 0x12
.set SYS_MODE, 0x1F
.set IRQ_STACK, 0x03007FA0
.set SYS_STACK, 0x03007300
.func init
init:
    mov r0, $IRQ_MODE
    msr cpsr_fc, r0
    ldr sp, =IRQ_STACK

    mov r0, $SYS_MODE
    msr cpsr_fc, r0
    ldr sp, =SYS_STACK

    .if MGBA_LOG_ENABLE
    ldr r0, =0xC0DE
    ldr r1, =$MGBA_LOG_REG_ENABLE
    strh r0, [r1]
    .endif


    bl copy_code_to_wram

    @ Branch to main(), switching to THUMB state
    ldr r0, =main
    add r0, $1
    mov lr, pc
    bx r0
    b init
.endfunc


.extern _ramtext_vma_begin _ramtext_lma_begin _ramtext_lma_end
.extern _ramrodata_vma_begin _ramrodata_lma_begin _ramrodata_lma_end
.func copy_code_to_wram
copy_code_to_wram:
    push {lr}

    @ Copy ramtext
    ldr r0, =_ramtext_lma_begin
    ldr r1, =_ramtext_vma_begin
    ldr r2, =_ramtext_lma_end
    sub r2, r0
    bl rom_memcpy16

    @Copy rodata
    ldr r0, =_ramrodata_lma_begin
    ldr r1, =_ramrodata_vma_begin
    ldr r2, =_ramrodata_lma_end
    sub r2, r0
    bl rom_memcpy16
    
    pop {lr}
    bx lr
.endfunc


.func rom_memcpy16
rom_memcpy16:
    @ r0 = src
    @ r1 = dst
    @ r2 = bytelen
    @ r3 = i
    @ r4 = scratch
    push {r4}
    mov r3, $0
.Lloop_begin:
    cmp r3, r2
    beq .Lloop_end

    ldrh r4, [r0, r3]
    strh r4, [r1, r3]

    add r3, $2

    b .Lloop_begin
.Lloop_end:
    pop {r4}
    bx lr
.endfunc


.section .text.ram
.thumb

.if MGBA_LOG_ENABLE
.macro mgba_log str_begin_label, str_end_label
    push {r0, r1, r2, lr, r3}
    ldr r0, =\str_begin_label
    ldr r1, =$MGBA_LOG_STRING
    .set mgba_msg_len, hello_msg_end - hello_msg_start
    ldr r2, =$mgba_msg_len
    bl ram_memcpy8

    ldr r0, =$MGBA_LOG_REG_FLAGS
    ldr r1, =$MGBA_LOG_ERROR | 0x100
    strh r1, [r0]
    pop {r0, r1, r2, r3}
    mov lr, r3
    pop {r3}
.endm
.else
.macro mgba_log str_begin_label, str_end_label
.endm
.endif


.func main
main:
    mgba_log hello_msg_start, hello_msg_end

    @ Setup screen, interrupts
    bl setup_screen

    mov r0, $'!'
    mov r1, $0
    mov r2, $0
    bl m4_putc

    bl setup_isr
    bl enable_irq

    @ Cart swap
    bl print_remove_flash_cart
    bl await_cart_removed
    bl print_insert_oem_cart
    bl await_cart_inserted
    
    @ Copy save data to EWRAM
    bl copy_save_data_to_ewram

    @ Cart swap
    bl print_remove_oem_cart
    bl await_cart_removed
    bl print_insert_flash_cart
    bl await_cart_inserted

    @ Copy save data from EWRAM to new cart sram
    bl copy_ewram_to_save_data

    @ End
    bl all_done
.endfunc


.func print_remove_flash_cart
print_remove_flash_cart:
    @ TODO
    bx lr
.endfunc


.func print_insert_oem_cart
print_insert_oem_cart:
    @ TODO
    bx lr
.endfunc


.func print_remove_oem_cart
print_remove_oem_cart:
    @ TODO
    bx lr
.endfunc


.func print_insert_flash_cart
print_insert_flash_cart:
    @ TODO
    bx lr
.endfunc

.func await_cart_removed
await_cart_removed:
    @ TODO
    bx lr
.endfunc


.func await_cart_inserted
await_cart_inserted:
    @ TODO
    bx lr
.endfunc


.func copy_save_data_to_ewram
copy_save_data_to_ewram:
    @ TODO
    bx lr
.endfunc


.func copy_ewram_to_save_data
copy_ewram_to_save_data:
    @ TODO
    bx lr
.endfunc


.set REG_DISPCNT, 0x04000000
.set DISPCNT_MODE_MASK, 0x00000007
.set DISPCNT_PAGE_MASK, 0x00000010
.set REG_DISPSTAT, 0x04000004
.set REG_VCOUNT, 0x04000006
.set M4_VIDEO_PAGE0, 0x06000000
.set M4_VIDEO_PAGE1, 0x06010000
.set TARGET_VIDEO_MODE, 0x403
.func setup_screen
setup_screen:
    ldr r0, =$TARGET_VIDEO_MODE
    ldr r1, =$REG_DISPCNT
    str r0, [r1]
    bx lr
.endfunc


.func print_swap_to_oem
print_swap_to_oem:
    @ TODO
    bx lr
.endfunc


.func enable_irq
enable_irq:
    @ TODO
    bx lr
.endfunc


.set REG_BASE, 0x04000000
.set REG_IE, $REG_BASE + 0x0200
.set REG_IF, $REG_BASE + 0x0202
.set REG_IME, $REG_BASE + 0x0208
.func setup_isr
setup_isr:
    @ TODO
    bx lr
.endfunc


.func wram_memcpy16
wram_memcpy16:
    @ TODO
    bx lr
.endfunc


.func print_text
print_text:
    @ TODO
    bx lr
.endfunc


.func all_done
all_done:
    @ TODO
    b all_done
.endfunc


.func ram_memcpy16
ram_memcpy16:
    @ r0 = src
    @ r1 = dst
    @ r2 = bytelen
    @ r3 = i
    @ r4 = scratch
    push {r4}
    mov r3, $0
.Lram_memcpy16_loop_begin:
    cmp r3, r2
    beq .Lram_memcpy16_loop_end

    ldr r4, [r0, r3]
    str r4, [r1, r3]

    add r3, $2

    b .Lram_memcpy16_loop_begin
.Lram_memcpy16_loop_end:
    pop {r4}
    bx lr
.endfunc


.func ram_memcpy8
ram_memcpy8:
    @ r0 = src
    @ r1 = dst
    @ r2 = bytelen
    @ r3 = i
    @ r4 = scratch
    push {r4}
    mov r3, $0
.Lram_memcpy8_loop_begin:
    cmp r3, r2
    beq .Lram_memcpy8_loop_end

    ldrb r4, [r0, r3]
    strb r4, [r1, r3]

    add r3, $1

    b .Lram_memcpy8_loop_begin
.Lram_memcpy8_loop_end:
    pop {r4}
    bx lr
.endfunc


.set M4_WIDTH, 240
.set M4_HEIGHT, 160
.set M4_GLIPH_WIDTH, M4_WIDTH / BITS_PER_GLIPH
.func m3_putc
m4_putc:
    @ r0 = character to print, ascii index
    @ r1 = gliph row
    @ r2 = gliph col

    @ r7 = constants for muls

    push {r4-r7}

    @ r1 := starting pixel idx on screen
    mov r7, $GLIPH_BITWIDTH
    mul r1, r7
    mov r7, $M4_WIDTH
    mul r1, r7
    mov r7, $GLIPH_BITHEIGHT
    mul r2, r7
    add r1, r2
    
    @ r2 := starting pixel location in memory
    ldr r2, =$M4_VIDEO_PAGE0
    add r2, r1

    @ r0 := gliph location
    sub r0, $ASCII_FIRST_GLIPH_IDX
    mov r7, $BYTES_PER_GLIPH
    mul r0, r7
    ldr r3, =sys8Glyphs
    add r0, r3

    @ for each row in gliph
    @ r1 is the gliph row iterator
    @ r3 is the gliph col iterator
    @ r5 is gliph row byte
    mov r1, $0
.Lm4_putc_outer_loop_begin:
    cmp r1, $GLIPH_BITHEIGHT
    beq .Lm4_putc_outer_loop_end

    @ load gliph row byte
    ldrb r5, [r0, r1]

    @ r4 is the bit value to write
    @ r6 is pixel bit scratch, later VRAM target location
    mov r3, $0
.Lm4_putc_inner_loop_begin:
    cmp r3, $GLIPH_BITWIDTH
    beq .Lm4_putc_inner_loop_end

    @ Calculate pixel value
    mov r6, r5
    lsr r6, r3
    mov r4, $1
    and r4, r6
    @cmp r4, $0
    @beq .Lm4_putc_done_coloring_pixel
    beq .Lm4_putc_no_pixel_draw
    ldr r4, =$0xffff
.Lm4_putc_done_coloring_pixel:

    @ Calculate target pixel byte address offset
    mov r6, r2
    mov r7, $GLIPH_BITWIDTH
    mul r7, r3
    add r6, r7
    add r6, r3

    @ Write pixel
    strh r4, [r6]

.Lm4_putc_no_pixel_draw:
    add r3, $1
    b .Lm4_putc_inner_loop_begin
.Lm4_putc_inner_loop_end:
    add r1, $1
    b .Lm4_putc_outer_loop_begin
.Lm4_putc_outer_loop_end:

    pop {r4-r7}

    bx lr
.endfunc



.arm
.func master_isr
master_isr:
    @ TODO
    bx lr
.endfunc


.section .rodata.ram

@ From Tonc
.set BYTES_PER_GLIPH, 8
.set BITS_PER_GLIPH, 64
.set GLIPH_BITWIDTH, 8
.set GLIPH_BYTEWIDTH, 1
.set GLIPH_BITHEIGHT, 8
.set ASCII_FIRST_GLIPH_IDX, 32
sys8Glyphs:
	.word 0x00000000,0x00000000,0x18181818,0x00180018,0x00003636,0x00000000,0x367F3636,0x0036367F
	.word 0x3C067C18,0x00183E60,0x1B356600,0x0033566C,0x6E16361C,0x00DE733B,0x000C1818,0x00000000
	.word 0x0C0C1830,0x0030180C,0x3030180C,0x000C1830,0xFF3C6600,0x0000663C,0x7E181800,0x00001818
	.word 0x00000000,0x0C181800,0x7E000000,0x00000000,0x00000000,0x00181800,0x183060C0,0x0003060C
	.word 0x7E76663C,0x003C666E,0x181E1C18,0x00181818,0x3060663C,0x007E0C18,0x3860663C,0x003C6660
	.word 0x33363C38,0x0030307F,0x603E067E,0x003C6660,0x3E060C38,0x003C6666,0x3060607E,0x00181818
	.word 0x3C66663C,0x003C6666,0x7C66663C,0x001C3060,0x00181800,0x00181800,0x00181800,0x0C181800
	.word 0x06186000,0x00006018,0x007E0000,0x0000007E,0x60180600,0x00000618,0x3060663C,0x00180018

	.word 0x5A5A663C,0x003C067A,0x7E66663C,0x00666666,0x3E66663E,0x003E6666,0x06060C78,0x00780C06
	.word 0x6666361E,0x001E3666,0x1E06067E,0x007E0606,0x1E06067E,0x00060606,0x7606663C,0x007C6666
	.word 0x7E666666,0x00666666,0x1818183C,0x003C1818,0x60606060,0x003C6660,0x0F1B3363,0x0063331B
	.word 0x06060606,0x007E0606,0x6B7F7763,0x00636363,0x7B6F6763,0x00636373,0x6666663C,0x003C6666
	.word 0x3E66663E,0x00060606,0x3333331E,0x007E3B33,0x3E66663E,0x00666636,0x3C0E663C,0x003C6670
	.word 0x1818187E,0x00181818,0x66666666,0x003C6666,0x66666666,0x00183C3C,0x6B636363,0x0063777F
	.word 0x183C66C3,0x00C3663C,0x183C66C3,0x00181818,0x0C18307F,0x007F0306,0x0C0C0C3C,0x003C0C0C
	.word 0x180C0603,0x00C06030,0x3030303C,0x003C3030,0x00663C18,0x00000000,0x00000000,0x003F0000

	.word 0x00301818,0x00000000,0x603C0000,0x007C667C,0x663E0606,0x003E6666,0x063C0000,0x003C0606
	.word 0x667C6060,0x007C6666,0x663C0000,0x003C067E,0x0C3E0C38,0x000C0C0C,0x667C0000,0x3C607C66
	.word 0x663E0606,0x00666666,0x18180018,0x00301818,0x30300030,0x1E303030,0x36660606,0x0066361E
	.word 0x18181818,0x00301818,0x7F370000,0x0063636B,0x663E0000,0x00666666,0x663C0000,0x003C6666
	.word 0x663E0000,0x06063E66,0x667C0000,0x60607C66,0x663E0000,0x00060606,0x063C0000,0x003E603C
	.word 0x0C3E0C0C,0x00380C0C,0x66660000,0x007C6666,0x66660000,0x00183C66,0x63630000,0x00367F6B
	.word 0x36630000,0x0063361C,0x66660000,0x0C183C66,0x307E0000,0x007E0C18,0x0C181830,0x00301818
	.word 0x18181818,0x00181818,0x3018180C,0x000C1818,0x003B6E00,0x00000000,0x00000000,0x00000000


hello_msg_start:
    .asciz "hello there"
hello_msg_end:
