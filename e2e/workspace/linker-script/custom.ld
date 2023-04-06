SECTIONS
{
  . = 0x200000 + SIZEOF_HEADERS;
  .rodata : { *(.rodata*) }
  . += 0x10000;
  .text : { *(.text*) }
  . += 0x10000;
  .got : { *(.got*) }
  . += 0x10000;
  .bss : { *(.bss*) }
  . += 0x10000 - SIZEOF(.bss) % 0x10000;
  .tbss : { *(.tbss*) }
  . += 0x10000 - SIZEOF(.tbss) % 0x10000;
  .data : { *(.data*) }
  . += 0x10000;
  .custom ALIGN(0x8) :
  {
    PROVIDE(custom_global_symbol = .);
    BYTE(42)
  }
}
