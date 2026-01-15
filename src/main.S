#define __SFR_OFFSET 0
#include "avr/io.h"

.global main
.extern rgb_buf
.extern write_word_on_leds
.extern set_leds_from_buffer
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

  rcall write_x_reg_to_leds_buffer_in_base_4

  rcall set_leds_from_buffer

done:
  rjmp done

write_x_reg_to_leds_buffer_in_base_4:
  ; set the first 2 LEDs to OFF because 0xFF in base 4 only uses 8 digits, and we have 10 LEDs
  ; then grab the first two bits of R27, this is your base 4 number.
  ; 0 means off, 1 means red, 2 means green, 3 means blue
  ; set the LED buffer appropriately.
  ; left shift 2 through accumulator
  push r18 ; r18 is temp
  push r19 ; r19 is a counter number of bytes left to process
  push r20 ; r20 is going to be where we build bytes to store to RAM
  push r26 ; X
  push r27
  push r28 ; Y
  push r29

  ldi r28, lo8(rgb_buf)
	ldi r29, hi8(rgb_buf) ; Y = pointer to rgb buffer

  ; first 2 LEDs are in the first byte. setting 0 turns them off
  ldi r20, 0x00 ; setting purple for debugging
  st Y+, r20

ldi r19, 4
write_x_reg_to_leds_buffer_in_base_4_L1:
  ; grab two highest bits of X (R27[7,6])
  ldi r18, 0xC0
  and r18, r27 ; two highest bits now in r18.

  ldi r20, 0x00 ; special case. alway initialize r20 to zero here
  cpi r18, 0x00 ;0 = 0x00, set r20 to 0b0000 (off)
  breq done_setting_leds

  ldi r20, 0xC0
  cpi r18, 0x40 ;1 = 0x40, set r20 to 0b1100 (R)
  breq done_setting_leds

  ldi r20, 0xA0
  cpi r18, 0x80 ;2 = 0x80, set r20 to 0b1010 (G)
  breq done_setting_leds

  ldi r20, 0x90
  cpi r18, 0xC0 ;3 = 0xC0, set r20 to 0b1001 (B)
  breq done_setting_leds

done_setting_leds:

  ; rotate X two bits left
  lsl r26
  rol r27
  lsl r26
  rol r27

  ; grab two highest bits of X (R27[7,6])
  ldi r18, 0xC0
  and r18, r27 ; two highest bits now in r18.

  ;ldi r20, 0x00 ; special case. do nothing. already zero
  cpi r18, 0x00 ;0 = 0x00, set r20 to 0b0000 (off)
  breq done_setting_leds_again

  andi r20, 0xF0 ; only keep top nibble
  ori r20, 0x0C
  cpi r18, 0x40 ;1 = 0x40, set r20 to 0b1100 (R)
  breq done_setting_leds_again

  andi r20, 0xF0 ; only keep top nibble
  ori r20, 0x0A
  cpi r18, 0x80 ;2 = 0x80, set r20 to 0b1010 (G)
  breq done_setting_leds_again

  andi r20, 0xF0 ; only keep top nibble
  ori r20, 0x09
  cpi r18, 0xC0 ;3 = 0xC0, set r20 to 0b1001 (B)
  breq done_setting_leds_again

done_setting_leds_again:  

  ; rotate X two bits left
  lsl r26
  rol r27
  lsl r26
  rol r27

  st Y+, r20

  ; decrement byte counter
  dec r19
  brne write_x_reg_to_leds_buffer_in_base_4_L1

  pop r29
  pop r28
  pop r27
  pop r26
  pop r20
  pop r19
  pop r18
  ret