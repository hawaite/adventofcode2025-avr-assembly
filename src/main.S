#define __SFR_OFFSET 0
#include "avr/io.h"

.global main
.extern five_second_delay
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
  rcall write_x_reg_to_leds_buffer_in_base_4
  rcall set_leds_from_buffer

  rcall day1

  ; zero landings (part 1 answer) remains in X-register (r27:r26)
  ; zero crossings (part 2 answer) in r5:r4
  
  
output_result:
  ; output the part 1 answer to the LEDs
  ldi r18, 0x01 ; indicate this is a part 1 answer
  rcall write_x_reg_to_leds_buffer_in_base_4
  
  rcall set_leds_from_buffer
  rcall five_second_delay

  push r27
  push r26

  ; after 5 seconds write the part 2 answer to the LEDs
  ; move r5:r4 in to X for rendering to LEDs
  mov r27, r5
  mov r26, r4

  ldi r18, 0x02 ; indicate this is a part 2 answer
  rcall write_x_reg_to_leds_buffer_in_base_4

  ; can restore the state of X after the RGB buffer is set
  pop r26
  pop r27

  rcall set_leds_from_buffer
  rcall five_second_delay
  rjmp output_result