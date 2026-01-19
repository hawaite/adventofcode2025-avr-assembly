#define __SFR_OFFSET 0
#include "avr/io.h"

.global five_second_delay

five_second_delay:
  push r18
  push r19
  push r20

  ldi  r18, 203
  ldi  r19, 236
  ldi  r20, 131
five_second_delay_internal: 
  dec  r20
  brne five_second_delay_internal
  dec  r19
  brne five_second_delay_internal
  dec  r18
  brne five_second_delay_internal

  pop r20
  pop r19
  pop r18
  ret
