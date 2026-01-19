#define __SFR_OFFSET 0
#include "avr/io.h"

; A collection of subroutines for working with the SK9822 LEDs

.global set_leds_from_buffer
.global leds_send_start_frame
.global leds_send_end_frame
.extern spi_transfer
.extern rgb_buf

leds_send_start_frame:
  push r16
  ldi   r16, 0x00 ;start frame
  rjmp leds_send_frame
leds_send_end_frame:
  push r16
  ldi   r16, 0xFF ;end frame
leds_send_frame:
  push r20

  ldi   r20, 4
leds_send_frame_internal:
  rcall spi_transfer
  dec r20
  brne leds_send_frame_internal

  pop r20
  pop r16
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; expects a buffer of 5 bytes at rgb_buf.
; each byte represents 2 LEDs.
; each nibble represents a single LED with 1 bit representing on/off, 1 bit red, 1 bit green, 1 bit blue, in that order.
; note that the SK9822 LEDs I have use RBG ordering (contrary to the datasheet), so that is modified in this routine to use the more familiar RGB
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