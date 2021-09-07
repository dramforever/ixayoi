boot.bin: boot.elf
	riscv32-none-elf-objcopy -j .text -O binary boot.elf boot.bin

boot.elf: link.ld boot.o
	riscv32-none-elf-ld -T $^ -o $@

boot.o: boot.S
	riscv32-none-elf-as -o $@ $^

