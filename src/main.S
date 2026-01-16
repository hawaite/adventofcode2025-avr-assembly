#define __SFR_OFFSET 0
#include "avr/io.h"

.global main
.extern write_word_on_leds
.extern set_leds_from_buffer
.extern write_x_reg_to_leds_buffer_in_base_4
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

  ; need to translate to base 4
  ; then use the fancy output function
  ; of maybe the base 4 function just writes to the LED buffer in one go.

  ; zero landings in r27:r26
  ; zero crossings in r5:r4
  
  ; move r5:r4 in to X for rendering to LEDs
  mov r27, r5
  mov r26, r4

  rcall write_x_reg_to_leds_buffer_in_base_4

  rcall set_leds_from_buffer

done:
  rjmp done