MEMORY
{
   BRAM (RWX) : ORIGIN = 0x00000000, LENGTH = 0x1800
}

SECTIONS
{
    .text : {
        *(.text*)
    } > BRAM

    .data : {
        *(.data*)
    } > BRAM

    .bss : {
        *(.bss*)
    } > BRAM
}
