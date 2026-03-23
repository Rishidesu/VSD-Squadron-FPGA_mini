#  GPIO Integration – Validation Notes

##  1. Location of Memory-Mapped Peripheral Decoding

Peripheral selection is handled within the `SOC` module by examining the CPU address bus.

* The signal:

  ```verilog
  isIO = mem_addr[22];
  ```

  identifies accesses to the IO region (base address `0x0040_0000`).

* Individual peripherals are selected by comparing the **word-aligned address**.

```verilog
wire [29:0] mem_wordaddr = mem_addr[31:2];
wire gpio_sel = isIO && (mem_wordaddr == 30'h00100008);
```

This corresponds to the GPIO address `0x00400020`.

---

##  2. Mechanism of CPU Read/Write Operations

The CPU communicates with peripherals using a load/store interface:

* `mem_addr`   → target address
* `mem_wdata`  → data being written
* `mem_wmask`  → indicates write operation
* `mem_rstrb`  → indicates read request
* `mem_rdata`  → returned read value

###  Behavior:

* A **write** occurs when `mem_wmask` is non-zero
* A **read** occurs when `mem_rstrb` is asserted
* The peripheral places data on `mem_rdata` during reads

---

##  3. Existing Peripherals in the System

The SoC already includes basic IO devices:

* **LED Interface**

  * Write-only register
  * Selected via `IO_LEDS_bit`

* **UART Interface**

  * Separate registers for data and status
  * Supports both read and write operations

The GPIO module was integrated into the same IO address space, following this established structure.

---

##  4. GPIO Address Mapping

The GPIO is accessed using a full 32-bit address defined in firmware:

```c
#define IO_BASE   0x00400000
#define GPIO_ADDR (IO_BASE + 0x20)
```

 Final address: `0x00400020`

###  Address Interpretation:

* `mem_addr[22] = 1` → indicates IO region
* Offset `0x20` → selects GPIO register

---

##  5. CPU Interaction with GPIO IP

The sequence of operations is as follows:

1. CPU executes a **store (`sw`) instruction**

   * `mem_wmask` becomes active
   * GPIO write enable is triggered:

     ```verilog
     gpio_wr_en = gpio_sel && mem_wmask;
     ```

2. Data is stored in the internal GPIO register on the clock edge

3. CPU executes a **load (`lw`) instruction**

   * `mem_rstrb` is asserted

4. GPIO returns stored data via `gpio_rdata`

5. Read data is routed back to CPU:

```verilog
assign mem_rdata = isRAM ? RAM_rdata :
                   gpio_sel ? gpio_rdata : 32'b0;
```

---

##  6. Simulation Verification

Simulation was performed using waveform analysis tools to confirm system behavior.

###  Verified Observations:

* GPIO register updates correctly on write operations

* Read operations return the exact stored value

* UART output confirms correctness (e.g., `000000A5`)

* Key signals behave as expected:

  * `clk`, `resetn`
  * `mem_addr`, `mem_wdata`
  * `gpio_wr_en`, `gpio_rdata`

* Simulation terminates properly using an `ecall` instruction

---

## Final Outcome

The validation confirms:

* Correct memory-mapped integration
* Accurate read/write functionality
* Proper CPU-to-peripheral communication
* Reliable end-to-end system behavior

 The GPIO IP functions as expected within the SoC environment
