#define __SFR_OFFSET 0
#include "avr/io.h"

.global two_second_delay

; plus additional 12 cycles for the register stashing
two_second_delay:
  push r18
  push r19
  push r20

  ldi r18, 82
  ldi r19, 43
  ldi r20, 255
two_second_delay_inner:
  dec r20
  brne two_second_delay_inner
  dec r19
  brne two_second_delay_inner
  dec r18
  brne two_second_delay_inner

  pop r20
  pop r19
  pop r18
  ret