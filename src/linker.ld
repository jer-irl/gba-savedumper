ENTRY(_start)

MEMORY {
    ewram (w!x) : ORIGIN = 0x02000000, LENGTH = 256K
    iwram (w!x) : ORIGIN = 0x03000000, LENGTH = 32K
    rom (rx) : ORIGIN = 0x08000000, LENGTH = 32M
}

SECTIONS {
    .text : {
        *(.entry)
        *(.text .text.*);
        . = ALIGN(4);
    } >rom =0xff

    .rodata : {
        *(.rodata .rodata.*);
        . = ALIGN(4);
    } >rom = 0xff

    .data : {
        *(.data .data.*);
        . = ALIGN(4);
    } >iwram AT>rom = 0xff

    .bss : {
        *(.bss .bss.*);
        . = ALIGN(4);
    } >iwram

    /* discard anything not already mentioned */
    /DISCARD/ : { *(*) }
}
