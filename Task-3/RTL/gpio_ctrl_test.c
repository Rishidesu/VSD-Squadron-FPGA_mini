#define GPIO_BASE 0x00400020

#define GPIO_DATA (*(volatile unsigned int*)(GPIO_BASE))
#define GPIO_DIR  (*(volatile unsigned int*)(GPIO_BASE + 4))

int main() {

    // Step 1: set direction (lower 5 bits as output)
    GPIO_DIR = 0x1F;

    // Step 2: write value (01010)
    GPIO_DATA = 0x0A;

    // Step 3: stay here forever
    while(1);

    return 0;
}
