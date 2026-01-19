#define __SFR_OFFSET 0
#include "avr/io.h"

.global write_byte_on_leds
.global write_word_on_leds

.extern spi_transfer
.extern leds_send_start_frame
.extern leds_send_end_frame

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