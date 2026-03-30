##  Short Explaination

### 1.Address Offset Decoding

The CPU generates a 32-bit address (`mem_addr`) during load/store operations.  
This address is decoded in the SoC to determine whether the access is to RAM or a peripheral.

#### Step 1: IO vs RAM detection
```verilog
isIO = mem_addr[22];
```
- isIO = 1 → access is to IO space
- isIO = 0 → access is to RAM.

#### Step 2: Word-aligned address
```
mem_wordaddr = mem_addr[31:2];
```
Removes byte offset (since memory is word-based)
#### Step 3: GPIO selection
``` verilog
gpio_sel = isIO &&
           (mem_wordaddr >= 30'h00100008) &&
           (mem_wordaddr <= 30'h0010000A);
```

This corresponds to:

- 0x00400020 → **GPIO_DATA**
- 0x00400024 → **GPIO_DIR**
- 0x00400028 → **GPIO_READ**
#### Step 4: Register offset decoding
``` verilog
gpio_addr = mem_wordaddr - 30'h00100008;
```
This converts absolute address → internal register index:

| Address      | Word Address | Offset | Register   |
|-------------|-------------|--------|------------|
| 0x00400020  | 0x00100008  | 0      | GPIO_DATA  |
| 0x00400024  | 0x00100009  | 1      | GPIO_DIR   |
| 0x00400028  | 0x0010000A  | 2      | GPIO_READ  |

This is how one IP supports multiple registers using offsets.

---

### 2.Direction Control Behaviour

The GPIO_DIR register defines whether each bit behaves as input or output.

- 1 → **Output pin**
- 0 → **Input pin**
  
Output behaviour

```
gpio_out = gpio_data & gpio_dir; 

```
 
- Only bits with dir = 1 drive output

- Bits with dir = 0 are forced to 0 (not driven)

This prevents input pins from accidentally driving signals.

#### Read behaviour
```
rdata = gpio_out | (gpio_in & ~gpio_dir);
```
This splits behavior per bit:

#### Condition	Result
- dir = 1 (output)	return gpio_out
- dir = 0 (input)	return gpio_in

Why this is correct:

- Output pins → show what CPU wrote
- Input pins → show external signal
- Mixed configurations → handled bitwise

---

### Final Understanding
- Address decoding selects which register
- Direction register controls how each pin behaves
- Read logic ensures correct real-world GPIO semantics

This matches how GPIO peripherals work in real SoCs
