OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
OUTPUT_ARCH(arm)

ENTRY(_start)

MEMORY {
    ROM : ORIGIN = 0x08000000, LENGTH = 32M
    EWRAM : ORIGIN = 0x02000000, LENGTH = 256K
    EWRAM_SAFE_FROM_EZFLASH : ORIGIN = 0x02010000, LENGTH = 64K
    IWRAM : ORIGIN = 0x03000000, LENGTH = 32K
}

SECTIONS {
    .text : {
        *(.text .text.rom)
        . = ALIGN(4);
    } >ROM

    .rodata : { 
        *(.rodata .rodata.rom); 
        . = ALIGN(4);
    } >ROM

    .text.ram : {
        *(.text.ram*)
        . = ALIGN(4);
    } >EWRAM_SAFE_FROM_EZFLASH AT>ROM
    _ramtext_vma_begin = ADDR(.text.ram);
    _ramtext_vma_end = ADDR(.text.ram) + SIZEOF(.text.ram);
    _ramtext_lma_begin = LOADADDR(.text.ram);
    _ramtext_lma_end = LOADADDR(.text.ram) + SIZEOF(.text.ram);

    .rodata.ram : { 
        KEEP(*(.rodata.ram))
        . = ALIGN(4);
    } >EWRAM_SAFE_FROM_EZFLASH AT>ROM
    _ramrodata_vma_begin = ADDR(.rodata.ram);
    _ramrodata_vma_end = ADDR(.rodata.ram) + SIZEOF(.rodata.ram);
    _ramrodata_lma_begin = LOADADDR(.rodata.ram);
    _ramrodata_lma_end = LOADADDR(.rodata.ram) + SIZEOF(.rodata.ram);

    .data.ram : {
        KEEP(*(.data.ram*))
        . = ALIGN(4);
    } >EWRAM_SAFE_FROM_EZFLASH AT>ROM
    _ramdata_vma_begin = ADDR(.data.ram);
    _ramdata_vma_end = ADDR(.data.ram) + SIZEOF(.data.ram);
    _ramdata_lma_begin = LOADADDR(.data.ram);
    _ramdata_lma_end = LOADADDR(.data.ram) + SIZEOF(.data.ram);

    _ramsave_area_end = ORIGIN(EWRAM) + LENGTH(EWRAM);
    _ramsave_area_begin = _ramsave_area_end - 0x020000;
    _magic_location = _ramsave_area_begin - 0x04;

    .data : { 
        *(.data);
        . = ALIGN(4);
    } >IWRAM AT>ROM

    .bss : {
        *(.bss); 
        . = ALIGN(4);
    } >IWRAM

    /DISCARD/ : {
        *(.ARM.exidx .ARM.exidx.*);
    }
}
