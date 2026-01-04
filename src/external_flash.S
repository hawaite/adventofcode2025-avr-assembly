#define __SFR_OFFSET 0
#include "avr/io.h"

.global read_spi_flash_byte
.extern spi_transfer

read_spi_flash_byte:
  ; assume address bytes in r18, r19, r20
  ; on return the byte should be in r16
  ; send 0x03, then r18, r19, r20, and then 0x00. 
  ; Last byte (0x00) clocks out the data at that location.

  ; pull chip-enable low for spi-flash
  cbi PORTB, 4

  ldi r16, 0x03 ; frame start
  rcall spi_transfer

  mov r16, r18 ; address[16:23]
  rcall spi_transfer

  mov r16, r19 ; address[8:15]
  rcall spi_transfer

  mov r16, r20 ; address[0:7]
  rcall spi_transfer

  ldi r16, 0x00 ; send out null byte to clock in from peripheral
  rcall spi_transfer

  sbi PORTB, 4
  ret 