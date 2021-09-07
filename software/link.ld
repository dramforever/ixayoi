ENTRY(_start)
SECTIONS
{
    .text 0x80000000 : AT(0) {
        _image_begin = .;
        *(.text.start);
        *(.text);
        _image_end = .;
    }
}
