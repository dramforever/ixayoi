.PHONY: all
all: boot.bin boot.hex

boot.hex: boot.bin
	hexdump -ve '"%08x" "\n"' boot.bin > boot.hex

boot.bin: boot.elf
	riscv32-none-elf-objcopy -j .text -O binary boot.elf boot.bin

boot.elf: link.ld boot.o software.o
	riscv32-none-elf-ld -T $^ -o $@

%.o: %.S
	riscv32-none-elf-as -march=rv32i -mabi=ilp32  -o $@ $^

%.o: %.c
	riscv32-none-elf-gcc -O2 -march=rv32i -mabi=ilp32 -ffreestanding -c -o $@ $^
