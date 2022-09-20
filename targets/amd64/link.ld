ENTRY(_start)
OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)
SECTIONS
{
    . = 0x7c00;
    .boot : {
        *(.boot .boot.*)
        
    }
}
