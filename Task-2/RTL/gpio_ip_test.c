#define IO_BASE     0x00400000
#define GPIO_ADDR   (IO_BASE + 0x20)

volatile unsigned int *gpio = (unsigned int *)GPIO_ADDR;

// simple delay (needed to see waveform changes)
void delay() {
    for (volatile int i = 0; i < 50000; i++);
}

void _start(void)
{
    unsigned int val = 0;

    while (1) {

        // WRITE to GPIO
        *gpio = val;

        // force ordering (important for simulation)
        asm volatile ("" ::: "memory");

        // READ back
        unsigned int read_val = *gpio;

        // simple check (optional logic)
        if (read_val != val) {
            // error pattern
            *gpio = 0x1F;
            while (1);
        }

        // increment pattern (5-bit for LEDs)
        val = (val + 1) & 0x1F;

        delay();
    }
}
