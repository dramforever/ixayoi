#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

// Peripheral register spaces
volatile uint32_t * const UART_BASE = (volatile uint32_t *) 0x40600000;
volatile uint32_t * const GPIO_BASE = (volatile uint32_t *) 0x40000000;

// Register offsets
const size_t O_UART_RX = 0;
const size_t O_UART_TX = 1;
const size_t O_UART_STATUS = 2;

const size_t O_GPIO_DATA0 = 0;
const size_t O_GPIO_DATA1 = 2;

// Flags
const uint32_t F_UART_TX_FULL = 0x8;
const uint32_t F_UART_RX_VALID = 0x1;

// Hardware helper functions

inline void putchar(uint8_t data) {
    while (UART_BASE[ O_UART_STATUS ] & F_UART_TX_FULL);
    UART_BASE[ O_UART_TX ] = data;
}

inline uint8_t getchar() {
    while (!(UART_BASE[ O_UART_STATUS ] & F_UART_RX_VALID));
    return UART_BASE[ O_UART_RX ];
}

inline uint8_t read_leds() {
    return GPIO_BASE[ O_GPIO_DATA0 ];
}

inline void write_leds(uint8_t leds) {
    GPIO_BASE[ O_GPIO_DATA0 ] = leds;
}

inline uint8_t read_buttons() {
    return GPIO_BASE[ O_GPIO_DATA1 ];
}

inline bool button_pressed(int i) {
    return ! (read_buttons() & (1 << i));
}

inline void write_led(int i, bool on) {
    if (on) {
        write_leds(read_leds() | (1 << i));
    } else {
        write_leds(read_leds() & ~(1 << i));
    }
}

void puts(uint8_t *str) {
    for (const uint8_t *p = str; *p; p ++) {
        putchar(*p);
    }
}

void main() {
    for (;;) {
        if (button_pressed(0)) {
            puts("Button is not pressed\n");
        } else {
            puts("Button pressed\n");
        }

        // Counting loop for delay
        for (uint32_t i = 0; i < 100000000 / 7; i ++) {
            asm volatile ("");
        }
    }
}

