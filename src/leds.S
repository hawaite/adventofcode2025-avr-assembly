#define __SFR_OFFSET 0
#include "avr/io.h"

; A collection of subroutines for working with the SK9822 LEDs

.global write_byte_on_leds
.global write_word_on_leds
.global set_leds_from_buffer
.extern spi_transfer
.extern rgb_buf

leds_send_start_frame:
  push r20
  push r16

  ldi   r20, 4
leds_send_start_frame_L1:
  ldi   r16, 0x00 ;start
  rcall spi_transfer
  dec r20
  brne leds_send_start_frame_L1

  pop r16
  pop r20
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

leds_send_end_frame:
  push r20
  push r16

  ldi   r20, 4
leds_send_end_frame_L1:
  ldi   r16, 0xFF ;end
  rcall spi_transfer
  dec r20
  brne leds_send_end_frame_L1

  pop r16
  pop r20
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_byte_on_leds:
  push r16
  push r18
  push r19

  ; assume input byte is on r18
  cbi PORTB, 3
  rcall leds_send_start_frame

  ; two blank LEDs here
  ldi   r16, 0xE0 ;brightness
  rcall spi_transfer

  ldi   r16, 0x00 ;R
  rcall spi_transfer

  ldi   r16, 0x00 ;B
  rcall spi_transfer

  ldi   r16, 0x00 ;G
  rcall spi_transfer

  ldi   r16, 0xE0 ;brightness
  rcall spi_transfer

  ldi   r16, 0x00 ;R
  rcall spi_transfer

  ldi   r16, 0x00 ;B
  rcall spi_transfer

  ldi   r16, 0x00 ;G
  rcall spi_transfer

  ; then clock out 8 bits
  ldi r19, 8
write_byte_on_leds_internal:
  ldi   r16, 0xE1 ;brightness
  rcall spi_transfer

  ldi   r16, 0x00 ;R (OFF)
  rcall spi_transfer

  ldi   r16, 0x00 ;B
  rcall spi_transfer

  ldi   r16, 0xFF ;G
  ; if last bit of r18 is 0, set r16 to 0x00 to clock out OFF LED.
  sbrs r18, 7
  ldi   r16, 0x00 ;G
  rcall spi_transfer

  ; shift r18 left
  lsl r18

  dec r19
  brne write_byte_on_leds_internal

  rcall leds_send_end_frame

  sbi PORTB, 3

  pop r19
  pop r18
  pop r16

  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_word_on_leds:
  push r26
  push r27
  push r16
  push r19
  ; assume input word is on r27(high):r26(low) "X" register pair
  cbi PORTB, 3
  rcall leds_send_start_frame

  ; then clock out 10 bits
  ldi r19, 10
write_word_on_leds_internal:
  ldi   r16, 0xE1 ;brightness
  rcall spi_transfer

  ldi   r16, 0x00 ;R (OFF)
  rcall spi_transfer

  ldi   r16, 0x00 ;B
  rcall spi_transfer

  ldi   r16, 0xFF ;G
  ; if second bit of r27 (high) is set, set r16 to 0x00 to clock out OFF LED.
  sbrs r27, 1
  ldi   r16, 0x00 ;G
  rcall spi_transfer

  ; shift r26 (low) left, setting carry if the dropped bit was a 1
  lsl r26
  ;shift 27 (high) left through carry, causing input bit to be taken from carry
  ; effectively rotating the 16-bit word.
  rol r27

  dec r19
  brne write_word_on_leds_internal

  rcall leds_send_end_frame

  sbi PORTB, 3

  pop r19
  pop r16
  pop r27
  pop r26

  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_leds_from_buffer:
  push r30
  push r31
  push r19
  push r16
  push r0

  ; assume 'rgb_buf' has all 5 bytes set appropriately
  ; set Z register (r30:r31) with whatever the address of the buffer is in SRAM
  ldi r30, lo8(rgb_buf)
	ldi r31, hi8(rgb_buf) ; Z = address of rgb_buf

  cbi PORTB, 3
  rcall leds_send_start_frame

  ; iterate the 5 bytes. r19 is the counter
  ldi r19, 5
set_leds_from_buffer_internal:
  ld r0, Z+ ; load r0 with the byte at that address in SRAM, then increment Z
  
  ; LED ONE
  ldi   r16, 0xE1 ;LED ON, brightness 1
  sbrs  r0, 7 ; led 1, brightness
  ldi   r16, 0xE0 ;LED OFF, brightness 0
  rcall spi_transfer

  ldi   r16, 0xFF ; full red
  sbrs  r0, 6 ; if led 1 'red' bit is set, skip next. Otherwise, next instruction will set red to 0.
  ldi   r16, 0x00 ;R
  rcall spi_transfer

  ldi   r16, 0xFF ; full blue
  sbrs  r0, 4 ; if led 1 'blue' bit is set, skip next. Otherwise, next instruction will set blue to 0.
  ldi   r16, 0x00 ;B
  rcall spi_transfer

  ldi   r16, 0xFF ; full green
  sbrs  r0, 5 ; if led 1 'green' bit is set, skip next. Otherwise, next instruction will set green to 0.
  ldi   r16, 0x00 ;G
  rcall spi_transfer

  ; LED TWO
  ldi   r16, 0xE1 ;LED ON, brightness 1
  sbrs  r0, 3 ; led 2, brightness
  ldi   r16, 0xE0 ;LED OFF, brightness 0
  rcall spi_transfer

  ldi   r16, 0xFF ; full red
  sbrs  r0, 2 ; if led 2 'red' bit is set, skip next. Otherwise, next instruction will set red to 0.
  ldi   r16, 0x00 ;R
  rcall spi_transfer

  ldi   r16, 0xFF ; full blue
  sbrs  r0, 0 ; if led 2 'blue' bit is set, skip next. Otherwise, next instruction will set blue to 0.
  ldi   r16, 0x00 ;B
  rcall spi_transfer

  ldi   r16, 0xFF ; full green
  sbrs  r0, 1 ; if led 2 'green' bit is set, skip next. Otherwise, next instruction will set green to 0.
  ldi   r16, 0x00 ;G
  rcall spi_transfer

  dec r19
  brne set_leds_from_buffer_internal

  rcall leds_send_end_frame

  sbi PORTB, 3

  pop r0
  pop r16
  pop r19
  pop r31
  pop r30

  ret