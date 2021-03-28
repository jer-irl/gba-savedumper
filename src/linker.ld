OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
OUTPUT_ARCH(arm)

ENTRY(_start)

MEMORY
{
    ROM    : ORIGIN = 0x08000000, LENGTH = 32M
    EWRAM  : ORIGIN = 0x02000000, LENGTH = 256K
    IWRAM  : ORIGIN = 0x03000000, LENGTH = 32K
}


SECTIONS
{
    .text : {
        KEEP(build/entry.o(.text.entry))
        KEEP(build/header.o(.header))
        *(.text .text.*)
        . = ALIGN(4); 
    } > ROM

    .rodata : { 
        *(.rodata .rodata.*); 
        . = ALIGN(4); 
    } > ROM

    .data : { 
        _sidata = LOADADDR(.data);
        . = ALIGN(4);
        _sdata = .;

        *(.data);

        . = ALIGN(4);
        _edata = .; 
    } > IWRAM AT > ROM

    .bss : {
        . = ALIGN(4);
        _sbss = .;

        *(.bss); 

        . = ALIGN(4); 
        _ebss = .;
    } > IWRAM

    /DISCARD/ :
    {
        *(.ARM.exidx .ARM.exidx.*);
    }
}
