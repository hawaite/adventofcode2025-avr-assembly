#define __SFR_OFFSET 0
#include "avr/io.h"

.global main
.extern rgb_buf
.extern row_buf
.extern write_word_on_leds
.extern day1

main:
  ; DO, SCL, SPI Flash chip-enable, and LED Chip-enable all output
  ; DI (PB0) remains input
  ldi   r16, (1<<PB1) | (1<<PB2) | (1<<PB3) | (1<<PB4)
  out   DDRB, r16

  ;make sure PB3 and PB4 are high (the two chip selects).
  sbi PORTB, 3
  sbi PORTB, 4

  ; write default value of X-register (0x0000) to blank out LEDs
  rcall write_word_on_leds

  rcall day1

  ; zero crossings remains in X-register (r26:r27)
  ; X-register also what is used by the 'write_word' subroutine
  ; so no need to move any bytes around
  rcall write_word_on_leds
  
done:
  rjmp done