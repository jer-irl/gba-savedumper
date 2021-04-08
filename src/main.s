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
.extern _ramdata_vma_begin _ramdata_lma_begin _ramdata_lma_end
.func copy_code_to_wram
copy_code_to_wram:
    push {lr}

    @ Copy ramtext
    ldr r0, =_ramtext_lma_begin
    ldr r1, =_ramtext_vma_begin
    ldr r2, =_ramtext_lma_end
    sub r2, r0
    bl rom_memcpy16

    @ Copy rodata
    ldr r0, =_ramrodata_lma_begin
    ldr r1, =_ramrodata_vma_begin
    ldr r2, =_ramrodata_lma_end
    sub r2, r0
    bl rom_memcpy16

    @ Copy data
    ldr r0, =_ramdata_lma_begin
    ldr r1, =_ramdata_vma_begin
    ldr r2, =_ramdata_lma_end
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
    @ push {r0, r1, r2, lr, r3}
    @ ldr r0, =\str_begin_label
    @ ldr r1, =$MGBA_LOG_STRING
    @ .set mgba_msg_len, hello_msg_end - hello_msg_start
    @ ldr r2, =$mgba_msg_len
    @ bl ram_memcpy8

    @ ldr r0, =$MGBA_LOG_REG_FLAGS
    @ ldr r1, =$MGBA_LOG_ERROR | 0x100
    @ strh r1, [r0]
    @ pop {r0, r1, r2, r3}
    @ mov lr, r3
    @ pop {r3}
.endm
.else
.macro mgba_log str_begin_label, str_end_label
.endm
.endif


.func main
main:
    mov r0, $CARTSWAP_STAGE_FLASHCART_LOADED
    ldr r1, =$cart_swap_stage
    str r0, [r1]

    @ Setup screen, interrupts
    bl setup_screen
    bl m3_clear_screen

    bl setup_isr
    bl enable_irq

    @ Cart swap
    ldr r0, =$cart_swap_stage
    ldr r0, [r0]
    cmp r0, $CARTSWAP_STAGE_FLASHCART_LOADED
    bne .Lmain_goto_panic
    bl print_remove_flash_cart
    bl halt

.Lmain_goto_panic:
    bl panic
.endfunc

.func on_flash_cart_removed
on_flash_cart_removed:
    push {lr}
    ldr r0, =$cart_swap_stage
    ldr r1, [r0]
    cmp r1, $CARTSWAP_STAGE_FLASHCART_LOADED
    bne .Lon_flash_cart_removed_goto_panic

    @ No work to do here...

    mov r1, $CARTSWAP_STAGE_OEM_SAVE_NOT_YET_LOADED
    str r1, [r0]

    bl print_insert_oem_cart

    @ Already in interrupt, just return
    pop {pc}

.Lon_flash_cart_removed_goto_panic:
    bl panic
.endfunc

.func on_oem_cart_inserted
on_oem_cart_inserted:
    push {lr}

    ldr r0, =$cart_swap_stage
    ldr r1, [r0]
    cmp r1, $CARTSWAP_STAGE_OEM_SAVE_NOT_YET_LOADED
    bne .Lon_oem_cart_inserted_goto_panic

    push {r0}
    bl copy_save_data_to_ewram
    pop {r0}

    mov r1, $CARTSWAP_STAGE_OEM_SAVE_LOADED
    str r1, [r0]

    bl print_remove_oem_cart

    @ Already in interrupt, just return
    pop {pc}

.Lon_oem_cart_inserted_goto_panic:
    bl panic
.endfunc

.func on_oem_cart_removed
on_oem_cart_removed:
    push {lr}

    ldr r0, =$cart_swap_stage
    ldr r1, [r0]
    cmp r1, $CARTSWAP_STAGE_OEM_SAVE_LOADED
    bne .Lon_oem_cart_removed_goto_panic

    @ No work to do here

    mov r1, $CARTSWAP_STAGE_OEM_CART_REMOVED
    str r1, [r0]

    bl print_insert_flash_cart

    @ Already in interrupt, just return
    pop {pc}

.Lon_oem_cart_removed_goto_panic:
    bl panic
.endfunc
    
.func on_flash_cart_reinserted
on_flash_cart_reinserted:
    push {lr}

    ldr r0, =$cart_swap_stage
    ldr r1, [r0]
    cmp r1, $CARTSWAP_STAGE_FLASHCART_REINSERTED
    bne .Lon_flash_cart_reinserted_goto_panic

    @ Copy save data from EWRAM to new cart sram
    push {r0}
    bl copy_ewram_to_save_data
    pop {r0}

    mov r1, $CARTSWAP_STAGE_OEM_SAVE_DUMPED
    str r1, [r0]

    @ End
    bl print_all_done

    @ Return out of the interrupt handler to halted cpu
    pop {pc}

.Lon_flash_cart_reinserted_goto_panic:
    bl panic
.endfunc


.func print_remove_flash_cart
print_remove_flash_cart:
    push {lr}

    bl m3_clear_screen
    ldr r0, =$remove_cart_message
    mov r1, $0
    mov r2, $0
    bl m3_puts

    pop {pc}
.endfunc


.func print_insert_oem_cart
print_insert_oem_cart:
    push {lr}

    bl m3_clear_screen
    ldr r0, =$insert_oem_cart_msg
    mov r1, $0
    mov r2, $0
    bl m3_puts

    pop {pc}
.endfunc


.func print_remove_oem_cart
print_remove_oem_cart:
    push {lr}

    bl m3_clear_screen
    ldr r0, =$remove_oem_cart_msg
    mov r1, $0
    mov r2, $0
    bl m3_puts

    pop {pc}
.endfunc


.func print_insert_flash_cart
print_insert_flash_cart:
    push {lr}

    bl m3_clear_screen
    ldr r0, =$insert_flash_cart_msg
    mov r1, $0
    mov r2, $0
    bl m3_puts

    pop {pc}
.endfunc


.func copy_save_data_to_ewram
copy_save_data_to_ewram:
    @ TODO
    bl panic
    bx lr
.endfunc


.func copy_ewram_to_save_data
copy_ewram_to_save_data:
    @ TODO
    bl panic
    bx lr
.endfunc


.set REG_DISPCNT, 0x04000000
.set DISPCNT_MODE_MASK, 0x00000007
.set DISPCNT_PAGE_MASK, 0x00000010
.set REG_DISPSTAT, 0x04000004
.set REG_VCOUNT, 0x04000006
.set M3_VIDEO_PAGE, 0x06000000
.set TARGET_VIDEO_MODE, 0x403
.func setup_screen
setup_screen:
    ldr r0, =$TARGET_VIDEO_MODE
    ldr r1, =$REG_DISPCNT
    strh r0, [r1]
    bx lr
.endfunc


.func print_swap_to_oem
print_swap_to_oem:
    @ TODO
    bx lr
.endfunc


.set REG_BASE, 0x04000000
.set REG_IE, REG_BASE + 0x0200
.set REG_IF, REG_BASE + 0x0202
.set REG_IME, REG_BASE + 0x0208
.set ISR_ADDR, 0x03007FFC
.set GAMEPAK_BIT, 0xB
.set GAMEPAK_MASK, 0b0010000000000000

.func enable_irq
enable_irq:
    ldr r0, =$REG_IE
    ldr r1, =$GAMEPAK_MASK
    str r1, [r0]
    ldr r0, =$REG_IME
    mov r1, $1
    str r1, [r0]

    bx lr
.endfunc


.func setup_isr
setup_isr:
    ldr r0, =$master_isr
    ldr r1, =$ISR_ADDR
    str r0, [r1]
    bx lr
.endfunc


.func thumb_master_isr
thumb_master_isr:
    push {lr}
    ldr r0, =$REG_IF
    ldrh r0, [r0]
    ldr r1, =$GAMEPAK_MASK
    cmp r0, r1
    bne .Lthumb_master_isr_unknown_interrupt
.Lthumb_master_isr_known_interrupt:
    bl handle_gamepak_interrupt
    pop {pc}

.Lthumb_master_isr_unknown_interrupt:
    bl m3_clear_screen
    ldr r0, =$bad_interrupt_msg
    mov r1, $0
    mov r2, $0
    bl m3_puts
    bl panic
.endfunc


.func handle_gamepak_interrupt
handle_gamepak_interrupt:
    push {lr}

    ldr r0, =$cart_swap_stage
    ldr r0, [r0]
    cmp r0, $CARTSWAP_STAGE_FLASHCART_NOT_YET_LOADED
    beq .Lhandle_gamepak_interrupt_FLASHCART_NOT_YET_LOADED
    cmp r0, $CARTSWAP_STAGE_FLASHCART_LOADED
    beq .Lhandle_gamepak_interrupt_FLASHCART_LOADED
    cmp r0, $CARTSWAP_STAGE_FLASHCART_REMOVED
    beq .Lhandle_gamepak_interrupt_FLASHCART_REMOVED
    cmp r0, $CARTSWAP_STAGE_OEM_SAVE_NOT_YET_LOADED
    beq .Lhandle_gamepak_interrupt_OEM_SAVE_NOT_YET_LOADED
    cmp r0, $CARTSWAP_STAGE_OEM_SAVE_LOADED
    beq .Lhandle_gamepak_interrupt_OEM_SAVE_LOADED
    cmp r0, $CARTSWAP_STAGE_OEM_CART_REMOVED
    beq .Lhandle_gamepak_interrupt_OEM_CART_REMOVED
    cmp r0, $CARTSWAP_STAGE_FLASHCART_REINSERTED
    beq .Lhandle_gamepak_interrupt_FLASHCART_REINSERTED
    cmp r0, $CARTSWAP_STAGE_OEM_SAVE_DUMPED
    beq .Lhandle_gamepak_interrupt_OEM_SAVE_DUMPED

    @ Unknown state
    bl panic

.Lhandle_gamepak_interrupt_FLASHCART_NOT_YET_LOADED:
    @ Shouldn't get into this state from an interrupt
    @ Did we yank too early somehow?
    bl panic

.Lhandle_gamepak_interrupt_FLASHCART_LOADED:
    bl on_flash_cart_removed
    b .Lhandle_gamepak_interrupt_done

.Lhandle_gamepak_interrupt_FLASHCART_REMOVED:
    bl on_oem_cart_inserted
    b .Lhandle_gamepak_interrupt_done

.Lhandle_gamepak_interrupt_OEM_SAVE_NOT_YET_LOADED:
    @ Shouldn't get here on interrupt
    bl on_oem_cart_removed
    b .Lhandle_gamepak_interrupt_done

.Lhandle_gamepak_interrupt_OEM_SAVE_LOADED:
    bl on_oem_cart_removed
    b .Lhandle_gamepak_interrupt_done

.Lhandle_gamepak_interrupt_OEM_CART_REMOVED:
    bl on_flash_cart_reinserted
    b .Lhandle_gamepak_interrupt_done

.Lhandle_gamepak_interrupt_FLASHCART_REINSERTED:
    @ Shouldn't get interrupt here
    bl panic

.Lhandle_gamepak_interrupt_OEM_SAVE_DUMPED:
    @ Shouldn't get interrupt here
    bl panic

.Lhandle_gamepak_interrupt_done:
    pop {pc}
.endfunc


.set SWI_HALT_THUMB, 0x02
.func halt
halt:
    @ TODO REPLACE WITH SWI
    b halt
    @swi $SWI_HALT_THUMB
    bl panic
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


.func print_all_done
print_all_done:
    @ TODO
    bx lr
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


.set M3_WIDTH, 240
.set M3_HEIGHT, 160
.set M3_BYTES_PER_PIXEL, 2
.set M3_GLIPHS_PER_ROW, M3_WIDTH / GLIPH_BITWIDTH
.set M3_GLIPHS_PER_COL, M3_HEIGHT / GLIPH_BITHEIGHT
.set M3_BYTES_PER_ROW, M3_WIDTH * M3_BYTES_PER_PIXEL
.func m3_putc
m3_putc:
    rtarget_gliph_ascii_idx .req r0
    rtarget_gliph_row .req r1
    rtarget_gliph_col .req r2

    @ r7 = constants for muls
    push {r4-r7, lr}

    rscratch .req r7

    rscreen_pixel_addr .req r1
    @ Calculate number of pixel rows
    mov rscratch, $M3_GLIPHS_PER_COL
    mul rscreen_pixel_addr, rtarget_gliph_row, rscratch
    @ Multiply by bytes per row
    ldr rscratch, =$M3_BYTES_PER_ROW
    mul rscreen_pixel_addr, rscratch
    @ Calculate number of pixel cols
    mov rscratch, $GLIPH_BITWIDTH
    mul rtarget_gliph_col, rscratch
    @ Add column byte offset
    mov rscratch, $M3_BYTES_PER_PIXEL
    mul rtarget_gliph_col, rscratch
    add rscreen_pixel_addr, rtarget_gliph_col
    @ Add to VRAM
    ldr rscratch, =$M3_VIDEO_PAGE
    add rscreen_pixel_addr, rscratch

    .unreq rtarget_gliph_col
    .unreq rtarget_gliph_row
    
    @ r0 := gliph location
    @ r0 is currently the ascii char idx
    rgliph_addr .req r0
    sub rgliph_addr, $ASCII_FIRST_GLIPH_IDX
    mov rscratch, $BYTES_PER_GLIPH
    mul rgliph_addr, rscratch
    ldr rscratch, =sys8Glyphs
    add rgliph_addr, rscratch

    @ for each row in gliph
    rgliph_pixel_bit_row_idx .req r2
    rgliph_bitrow_byte_value .req r5
    mov rgliph_pixel_bit_row_idx, $0
.Lm3_putc_outer_loop_begin:
    cmp rgliph_pixel_bit_row_idx, $GLIPH_BITHEIGHT
    beq .Lm3_putc_outer_loop_end

    @ load gliph row byte
    ldrb rgliph_bitrow_byte_value, [rgliph_addr, rgliph_pixel_bit_row_idx]

    @ r4 is the bit value to write
    @ r6 is pixel bit scratch, later VRAM target location
    rgliph_pixel_bit_col_idx .req r3
    mov rgliph_pixel_bit_col_idx, $0
.Lm3_putc_inner_loop_begin:
    cmp rgliph_pixel_bit_col_idx, $GLIPH_BITWIDTH
    beq .Lm3_putc_inner_loop_end

    @ Calculate pixel value
    rtmp0 .req r6
    rtmp1 .req r4
    mov rtmp0, rgliph_bitrow_byte_value
    lsr rtmp0, rgliph_pixel_bit_col_idx
    mov rtmp1, $1
    and rtmp1, rtmp0
    cmp rtmp1, $0
    beq .Lm3_putc_no_pixel_draw
    .unreq rtmp0
    .unreq rtmp1
    rpixel_to_write_value .req r4
    ldr rpixel_to_write_value, =$0x7fff

    @ Calculate target pixel byte address offset
    rpixel_vram_addr .req r6
    push {r0}
    rbytes_per_pixel .req r0
    mov rpixel_vram_addr, rscreen_pixel_addr
    ldr rscratch, =$M3_BYTES_PER_ROW
    mov rbytes_per_pixel, $M3_BYTES_PER_PIXEL
    mul rscratch, rgliph_pixel_bit_row_idx
    add rpixel_vram_addr, rscratch
    mov rscratch, rgliph_pixel_bit_col_idx
    mul rscratch, rbytes_per_pixel
    add rpixel_vram_addr, rscratch
    .unreq rbytes_per_pixel
    pop {r0}

    @ Write pixel
    strh rpixel_to_write_value, [rpixel_vram_addr]
    .unreq rpixel_vram_addr
    .unreq rpixel_to_write_value

.Lm3_putc_no_pixel_draw:
    add rgliph_pixel_bit_col_idx, $1
    b .Lm3_putc_inner_loop_begin
.Lm3_putc_inner_loop_end:

.unreq rgliph_pixel_bit_col_idx

    add rgliph_pixel_bit_row_idx, $1
    b .Lm3_putc_outer_loop_begin
.Lm3_putc_outer_loop_end:

.unreq rgliph_pixel_bit_row_idx
.unreq rgliph_bitrow_byte_value

    pop {r4-r7, pc}

.unreq rscratch
.unreq rtarget_gliph_ascii_idx
.unreq rgliph_addr

.endfunc

.func m3_puts
m3_puts:
    rstring_addr .req r0
    rtarget_gliph_row .req r1
    rtarget_gliph_col .req r2

    push {r4, lr}

    ri .req r3
    rchar .req r4

    mov ri, $0
.Lm3_puts_loop_begin:
    ldrb rchar, [rstring_addr, ri]
    cmp rchar, $0
    beq .Lm3_puts_loop_end

    push {r0-r3}
    mov r0, rchar
    mov r1, rtarget_gliph_row
    mov r2, rtarget_gliph_col
    add r2, ri
    bl m3_putc
    pop {r0-r3}

    add ri, $1
    b .Lm3_puts_loop_begin
.Lm3_puts_loop_end:

    .unreq ri
    .unreq rchar

    pop {r4, pc}

.endfunc


.set M3_PIXELS, M3_HEIGHT * M3_WIDTH
.func m3_clear_screen
m3_clear_screen:
    ri .req r0
    rtotal_num_bytes .req r1
    rvalue_to_write .req r2
    rvram_addr .req r3

    mov ri, $0
    ldr rtotal_num_bytes, =$M3_PIXELS
    lsl rtotal_num_bytes, $1
    mov rvalue_to_write, $0
    ldr rvram_addr, =$M3_VIDEO_PAGE

.Lm3_clear_screen_loop_begin:
    cmp ri, rtotal_num_bytes
    beq .Lm3_clear_screen_loop_end
    
    strh rvalue_to_write, [rvram_addr, ri]

    add ri, $2
    b .Lm3_clear_screen_loop_begin
.Lm3_clear_screen_loop_end:

    .unreq ri
    .unreq rtotal_num_bytes
    .unreq rvalue_to_write

    bx lr
.endfunc


.func panic
panic:
    push {lr}

    bl m3_clear_screen
    ldr r0, =$panic_msg
    mov r1, $0
    mov r2, $0
    bl m3_puts

    @ TODO
.Lpanic_infinite_loop:
    b .Lpanic_infinite_loop

    pop {pc}
.endfunc


.arm
.func master_isr
master_isr:
    push {lr}
    ldr r0, =$thumb_master_isr
    orr r0, $1
    mov lr, pc
    bx r0
    pop {pc}
.endfunc


.section .data.ram

.set CARTSWAP_STAGE_FLASHCART_NOT_YET_LOADED, 0
.set CARTSWAP_STAGE_FLASHCART_LOADED, 1
.set CARTSWAP_STAGE_FLASHCART_REMOVED, 2
.set CARTSWAP_STAGE_OEM_SAVE_NOT_YET_LOADED, 3
.set CARTSWAP_STAGE_OEM_SAVE_LOADED, 4
.set CARTSWAP_STAGE_OEM_CART_REMOVED, 5
.set CARTSWAP_STAGE_FLASHCART_REINSERTED, 6
.set CARTSWAP_STAGE_OEM_SAVE_DUMPED, 7
cart_swap_stage:
    .word 0x00000000


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


.align
bad_interrupt_msg:
    .asciz "unknown interrupt received"

.align
panic_msg:
    .asciz "unrecoverable panic"

.align
remove_cart_message:
    .asciz "please remove cartridge"

.align
unknown_cartswap_state_msg:
    .asciz "Unknown cartswap state"

.align
insert_oem_cart_msg:
    .asciz "Insert original cart now"

.align
remove_oem_cart_msg:
    .asciz "Remove oem cart now"

.align
insert_flash_cart_msg:
    .asciz "Insert flash cart now"
