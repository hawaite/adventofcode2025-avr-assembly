#define __SFR_OFFSET 0
#include "avr/io.h"

.global write_x_reg_to_leds_buffer_in_base_4
.extern rgb_buf

write_x_reg_to_leds_buffer_in_base_4:
  ; set the first 2 LEDs to OFF because 0xFF in base 4 only uses 8 digits, and we have 10 LEDs
  ; then grab the first two bits of R27, this is your base 4 number.
  ; 0 means off, 1 means red, 2 means green, 3 means blue
  ; set the LED buffer appropriately.
  ; left shift 2 through accumulator
  push r18 ; r18 is temp
  push r19 ; r19 is a counter number of bytes left to process
  push r20 ; r20 is going to be where we build bytes to store to RAM
  push r21 ; r21 is the loop counter for building the two halfs of the byte
  push r26 ; X
  push r27
  push r28 ; Y
  push r29

  ldi r28, lo8(rgb_buf)
	ldi r29, hi8(rgb_buf) ; Y = pointer to rgb buffer

  ; first 2 LEDs are in the first byte. setting 0 turns them off
  ldi r20, 0x00
  st Y+, r20
  ldi r19, 4

write_x_reg_to_leds_buffer_in_base_4_L1:
  ldi r21, 2    ; process 2 LEDs
  ldi r20, 0x00 ; initialize the byte to 0x00

write_x_reg_to_leds_buffer_in_base_4_L2:
  swap r20
  ; grab two highest bits of X (R27[7,6])
  ldi r18, 0xC0
  and r18, r27 ; two highest bits now in r18.

  andi r20, 0xF0 ; clear bottom 4 bits
  ori r20, 0x00  ; set bottom 4 bits to required value (0)
  cpi r18, 0x00 ;0 = 0x00, set r20 to 0b0000 (off)
  breq done_setting_led

  andi r20, 0xF0 ; clear bottom 4 bits
  ori r20, 0x0C  ; set bottom 4 bits to required value (0b1100)
  cpi r18, 0x40 ;1 = 0x40, set r20 to 0b1100 (R)
  breq done_setting_led

  andi r20, 0xF0 ; clear bottom 4 bits
  ori r20, 0x0A  ; set bottom 4 bits to required value (0b1010)
  cpi r18, 0x80 ;2 = 0x80, set r20 to 0b1010 (G)
  breq done_setting_led

  andi r20, 0xF0 ; clear bottom 4 bits
  ori r20, 0x09  ; set bottom 4 bits to required value (0b1001)
  cpi r18, 0xC0 ;3 = 0xC0, set r20 to 0b1001 (B)
  breq done_setting_led

done_setting_led:
  ; rotate X two bits left
  lsl r26
  rol r27
  lsl r26
  rol r27

  dec r21
  brne write_x_reg_to_leds_buffer_in_base_4_L2 ; go again if r21 > 0

  st Y+, r20

  ; decrement byte counter
  dec r19
  brne write_x_reg_to_leds_buffer_in_base_4_L1

  pop r29
  pop r28
  pop r27
  pop r26
  pop r21
  pop r20
  pop r19
  pop r18
  ret