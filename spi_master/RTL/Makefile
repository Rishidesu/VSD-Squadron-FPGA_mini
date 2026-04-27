# ===== RISC-V TOOLCHAIN =====
RISCV_PREFIX = riscv64-unknown-elf
CC = $(RISCV_PREFIX)-gcc
OBJCOPY = $(RISCV_PREFIX)-objcopy

CFLAGS = -O0 -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding

# ===== FPGA =====
TOP = SOC
VERILOG_FILES = riscv.v spi.v
PCF_FILE = VSDSquadronFM.pcf

FPGA_VARIANT = up5k
FPGA_PACKAGE = sg48

# ===== DEFAULT =====
all: build

# ===== FIRMWARE =====
firmware.elf: firmware.c link.ld
	$(CC) $(CFLAGS) -T link.ld -Wl,-e,_start firmware.c -o firmware.elf

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary firmware.elf firmware.bin

firmware.hex: firmware.bin
	hexdump -v -e '1/4 "%08x\n"' firmware.bin > firmware.hex

# ===== BUILD =====
build: firmware.hex
	yosys -p "synth_ice40 -top $(TOP) -json $(TOP).json" $(VERILOG_FILES)
	nextpnr-ice40 \
		--json $(TOP).json \
		--pcf $(PCF_FILE) \
		--asc $(TOP).asc \
		--$(FPGA_VARIANT) \
		--package $(FPGA_PACKAGE) \
		--pcf-allow-unconstrained
	icepack $(TOP).asc $(TOP).bin

# ===== FLASH =====
flash:
	iceprog $(TOP).bin

# ===== SIM =====
sim: firmware.hex
	iverilog -DBENCH -o soc_tb.vvp \
		soc_tb.v riscv.v spi.v ice40_stubs.v
	vvp soc_tb.vvp

# ===== CLEAN =====
clean:
	rm -f *.elf *.bin *.hex *.json *.asc *.vvp *.vcd
