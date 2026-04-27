// ================= SPI BASE =================
#define SPI_BASE   0x00401000

#define SPI_CTRL   (*(volatile unsigned int*)(SPI_BASE + 0))
#define SPI_TXDATA (*(volatile unsigned int*)(SPI_BASE + 4))
#define SPI_RXDATA (*(volatile unsigned int*)(SPI_BASE + 8))
#define SPI_STATUS (*(volatile unsigned int*)(SPI_BASE + 12))

// ================= ENTRY =================
void _start() {

    // Stack init (required for your CPU)
    asm volatile("li sp, 0x00001800");

    // ================= TEST START =================

    // Load data
    SPI_TXDATA = 0xA5;

    // Start FIRST transfer
    SPI_CTRL = (1<<0) | (1<<1) | (4<<8);

    //  IMMEDIATELY try SECOND START (while BUSY should be 1)
    SPI_CTRL = (1<<0) | (1<<1) | (4<<8);

    // Wait for transfer to complete
    while((SPI_STATUS & (1<<1)) == 0);

    // Read result
    volatile unsigned int data = SPI_RXDATA;

    // ================= END =================

    while(1); // stop here
}
