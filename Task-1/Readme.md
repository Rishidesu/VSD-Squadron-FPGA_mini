# FPGA-IP-DEVELOPMENT  
## Task-1: RISC-V Toolchain Setup & Reference Flow Validation

This task focuses on setting up a functional RISC-V development environment and confirming that the complete software-to-simulation flow works correctly inside a cloud-based Linux setup.

The goal was not just to run commands, but to ensure that:
- The toolchain is correctly installed and usable  
- Programs can be compiled and executed on a RISC-V simulator  
- The firmware build flow for VSDFPGA is understood  

No physical FPGA board was involved at this stage.

---

## 🖥️ Development Environment

- **Workspace:** GitHub Codespaces  
- **OS:** Windows/Linux(noVNC)  
- **Terminal Access:** VS Code integrated terminal/Linux(noVNC) Terminal  
- **GUI Access:** noVNC session  


---

## 🚀 Verifying RISC-V Program Execution

- **Source Repository:** `vsd-riscv2`  
- **Directory Used:** `samples/`  

A basic C program was used to check whether the toolchain and simulator are functioning correctly.

### 🔧 Build and Run

```bash
riscv64-unknown-elf-gcc -o sum1ton sum1ton.c
spike pk sum1ton.o
```
## Simulation of the code used to verify the flow of RISC-V reference flow
<img width="1920" height="960" alt="image" src="https://github.com/user-attachments/assets/2f192fd3-4eb7-48d0-b312-b34edf925e82" />

after the changes in number and output display text
<img width="1920" height="1083" alt="image" src="https://github.com/user-attachments/assets/da67ac64-1984-426a-88a0-d04645f484ef" />


### ⚙️ VSD-FPGA Firmware Build(no hardware is used)
- **Repository:** `vsdfpga_labs`  
- **Target Design:** `basicRISCV`  
- **Firmware Path:** `basicRISCV/Firmware`  

This step validates the firmware build process used in the VSDFPGA workflow. The goal is to generate a memory initialization file that will later be used by the RTL design.

### 🔧 Commands Executed

```bash
git clone https://github.com/vsdip/vsdfpga_labs.git
cd vsdfpga_labs/basicRISCV/Firmware
make riscv_logo.bram.hex
```
Firmware built has successfully been done and the following file is generated:
``` bash
riscv_logo.bram.hex
```
Image for Reference:
<img width="1920" height="1036" alt="image" src="https://github.com/user-attachments/assets/f4e9fe15-c3f4-43d6-80e4-38973ac1756d" />

## The logo Execution using Spike simulator.
Along with HEX generation, the firmware source (`riscv_logo.c`) was compiled into a RISC-V ELF binary and executed on the Spike simulator to confirm correct program behavior.
---

### 🔧 Commands Executed

```bash
riscv64-unknown-elf-gcc -o riscv_logo riscv_logo.c
spike pk riscv_logo
```
### 📤 Program Output
```bash
LEARN TO THINK LIKE A CHIP
VSDSQUADRON FPGA MINI
BRINGS RISC-V TO VSD CLASSROOM
```
The program runs successfully on the Spike simulator and continuously prints the ASCII text, indicating that it is executing within an infinite loop.
#### Image for Reference
<img width="1920" height="1083" alt="image" src="https://github.com/user-attachments/assets/de75d902-e7a6-4e0d-af1b-fcce8cac0f3a" />


Some are done  in noVNC session- terminal 
Images are:
<img width="1853" height="1030" alt="image" src="https://github.com/user-attachments/assets/d4104832-59a5-44cb-b729-2a6ad5ca88b9" />
using gedit command
<img width="1649" height="924" alt="image" src="https://github.com/user-attachments/assets/132e6d11-0444-4be9-a96c-5c03a11bca90" />

<img width="1722" height="966" alt="Screenshot 2026-03-19 162639" src="https://github.com/user-attachments/assets/b390136c-bb17-4c96-a82f-b2c5d9734f99" />




## Understanding Check
---
## 🧩 Understanding Check

### 1. Where is the RISC-V program located?
The reference program can be found inside the `samples` directory of the `vsd-riscv2` repository, where example source files are provided for testing the toolchain.

---

### 2. How is the program compiled and loaded into memory?
The source code is compiled using the RISC-V cross-compiler to produce an ELF executable. This executable is then loaded into the simulated memory space by the Spike simulator, where it is executed with the help of the proxy kernel (`pk`).

---

### 3. How does the RISC-V core access memory and memory-mapped I/O?
The processor uses standard load and store instructions to interact with both main memory and peripheral devices. The distinction between memory and I/O is handled by the system’s address decoding logic, which routes accesses to the appropriate hardware component.

---

### 4. Where would a new FPGA IP block logically integrate?
A new IP block would be incorporated as a memory-mapped peripheral within the system’s RTL design. It would occupy a specific address range, allowing the processor to communicate with it using regular memory access instructions.











