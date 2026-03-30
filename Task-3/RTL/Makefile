ARCH = rv32i
ABI = ilp32

RVGCC = riscv64-unknown-elf-gcc
RVLD  = riscv64-unknown-elf-ld

CFLAGS = -march=$(ARCH) -mabi=$(ABI) -nostdlib -nostartfiles -ffreestanding -O0

all: gpio_ctrl_test.hex

gpio_ctrl_test.o: gpio_ctrl_test.c
	$(RVGCC) $(CFLAGS) -c gpio_ctrl_test.c -o gpio_ctrl_test.o

start.o: start.S
	$(RVGCC) $(CFLAGS) -c start.S -o start.o

gpio_ctrl_test.elf: gpio_ctrl_test.o start.o
	$(RVLD) -m elf32lriscv -T bram.ld gpio_ctrl_test.o start.o -o gpio_ctrl_test.elf

gpio_ctrl_test.hex: gpio_ctrl_test.elf
	./firmware_words gpio_ctrl_test.elf -ram 6144 -max_addr 6144 -out firmware.hex

clean:
	rm -f *.o *.elf *.hex
