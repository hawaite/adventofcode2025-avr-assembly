#define __SFR_OFFSET 0
#include "avr/io.h"

.global spi_transfer

; byte to transfer out should be placed in r16 before this call
; received byte will be left in r16 on return

spi_transfer:
  push  r17

  out   USIDR, r16
  ldi   r16, (1<<USIWM0) | (0<<USICS0) | (1<<USITC)
  ldi   r17, (1<<USIWM0) | (0<<USICS0) | (1<<USITC) | (1<<USICLK)

  out   USICR, r16 ;MSB
  out   USICR, r17

  out   USICR, r16
  out   USICR, r17

  out   USICR, r16
  out   USICR, r17

  out   USICR, r16
  out   USICR, r17

  out   USICR, r16
  out   USICR, r17

  out   USICR, r16
  out   USICR, r17

  out   USICR, r16
  out   USICR, r17

  out   USICR, r16 ;LSB
  out   USICR, r17

  in    r16, USIDR
  pop   r17
  ret