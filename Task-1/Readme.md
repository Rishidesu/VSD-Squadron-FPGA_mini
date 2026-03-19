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
<img width="1920" height="1200" alt="Screenshot (333)" src="https://github.com/user-attachments/assets/ed848424-8403-4c67-aa27-dd68d26809d1" />
after the changes in number and output display text
<img width="1920" height="1200" alt="Screenshot (334)" src="https://github.com/user-attachments/assets/a26a7fb0-ab70-431f-bade-c7d04f2ffd0f" />

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
<img width="1920" height="1200" alt="Screenshot (331)" src="https://github.com/user-attachments/assets/edd2bf0e-46d8-4c4e-93e8-a25235c32fbc" />
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
<img width="1920" height="1200" alt="Screenshot (332)" src="https://github.com/user-attachments/assets/448b8f58-53a4-4322-baca-7c134615870b" />

Some are done  in noVNC session- terminal 
Images are:
<img width="1829" height="1025" alt="Screenshot 2026-03-19 162745" src="https://github.com/user-attachments/assets/c22d0b1c-cfa5-48af-ad6f-2a2e0e331017" />
<img width="1920" height="1200" alt="Screenshot (321)" src="https://github.com/user-attachments/assets/6f6b51e4-3d55-460b-918b-cb9e44f0330f" />











