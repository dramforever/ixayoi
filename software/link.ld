ENTRY(_start)
SECTIONS
{
    .text 0x80000000 : AT(0) {
        _image_begin = .;
        *(.text.startup);
        *(.text);
        *(.data);
        *(.sdata);
        *(.rodata);
        *(.rodata.str1.4);
        *(.srodata);
        _image_end = .;
    }
}
