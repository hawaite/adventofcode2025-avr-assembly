#define __SFR_OFFSET 0
#include "avr/io.h"

.global day1
.extern write_byte_on_leds
.extern row_buf
.extern two_second_delay

#define fetched_byte_count r25
#define dial_pos r24
#define moves_to_make r6
#define zero_landing_counter r26
#define xl r26
#define xh r27
#define yl r28
#define yh r29
#define zl r30
#define zh r31

; input is over 4000 lines in the format [RL][0-9]{1,3}\n
; need to grab the first byte to determine if addition (R) or subtraction(L)
; then keep grabbing bytes from SPI-Flash until you get 0x0A (\n)
; convert the 3 ascii numbers in to a single 16 bit word over 2 registers
; We now have the direction and magnitude
; We need to do the following python operation except just adding the magnitude to
;
; updated_magnitude = magnitude % 100 # dont need to add the whole thing, just whatever the remainder is
; current_digit = direction_operation(current_digit, magnitude) % 100
; if current_digit == 0:
;   zero_landings += 1
;
; challenges:
; - attiny85 has no multiply, divide, or modulus hardware
; - a single register is 8 bit, meanining max of unsigned 256 or signed +/- 128
; - could do the bruteforce thing where we just keep decrementing the count until zero
; - or could try detect if a sub/add would overflow.


; Z register used to hold index in to flash
; Y register used to hold index in to row buffer
; X register used to hold zero-landings as need 16-bit counter
day1:
  ldi dial_pos, 50
  
  ldi zl, 0x00
	ldi zh, 0x00 ; Z = current address in spi-flash. "for each char"

  ldi xl, 0x00
  ldi xh, 0x00 ; X = zero landings

  clr r4
  clr r5 ; we're using r5:r4 as a pseudo 16-bit register to hold the total zero crossings

parse_row:
  ldi yl, lo8(row_buf)
	ldi yh, hi8(row_buf) ; Y = current address in row buffer "i"
  
  ldi fetched_byte_count, 0

parse_byte:
  ; move spi-flash address in to r18-20 as used by read_spi_flash_byte subroutine
  ldi r18, 0x00 ; only using 16 bit addressing so top 8 bits are zero
  mov r19, zh
  mov r20, zl

  ; leaves result in r16
  rcall read_spi_flash_byte

  ; if read byte is 0x0A or 0x00, we need to process the buffer. Otherwise continue
  cpi r16, 0x0A
  breq is_newline_or_null
  cpi r16, 0x00
  breq is_newline_or_null

  ; we didnt branch so we need to keep grabbing bytes.
  ; subtract 0x30 to get the int value from the ascii value
  ; (note: this will mangle "R" and "L" values, but we'll just handle that later
  ; store it, 
  ; increment pointer in to row buffer (Y), 
  ; increment number of bytes saved, 
  ; increment pointer in to SPI Flash (Z)
  subi r16, 0x30
  st  Y+, r16 ; store r16 at the address pointed to by Y, then increment Y pointer
  inc fetched_byte_count

  adiw zl, 1 ; add 1 to the SPI Flash pointer
  ; still inside a 'row', so lets grab another byte
  rjmp parse_byte

is_newline_or_null:
  ; here we need to perform the rotation described in the buffer
  ; we have fetched_byte_count to tell us how many bytes long this thing was.
  ; for part 1, we dont actually care about the "hundredths" byte. It can be completely ignored.
  
  ; need to build a single register containing the remaining move
  ; if fetched_byte_count is 2, move is in Y[1]
  ; if fetched_byte_count is 3, move is ((Y[1])*10) + y[2]
  ; if fetched_byte_count is 4, move is ((Y[2])*10) + y[3]

  mov r18, r16 ; take a copy of the line terminator in r16 to use later

  ldi yl, lo8(row_buf)
	ldi yh, hi8(row_buf) ; reset the address of the row buffer

  ; after this block I want the remaining move to be in moves_to_make (r6)
  cpi fetched_byte_count, 2
  breq one_digit
  cpi fetched_byte_count, 3
  breq two_digit
  cpi fetched_byte_count, 4
  breq three_digit

after_remaining_move_parsed:
  ; grab first byte in the buffer which is 'direction'
  ; '28' is left (subtract), '34' is right (add) after we remove 0x30 earlier
  ld r17, Y

  cpi r17, 28
  breq left_move
  cpi r17, 34
  breq right_move
after_moves:

  ; check if dial now on zero
  cpi dial_pos, 0x00
  brne after_inc
  adiw zero_landing_counter, 1 ; inc X register only if dial_pos is zero

after_inc:
  adiw zl, 1 ; add 1 to the SPI Flash pointer
  ldi fetched_byte_count, 0 ; reset buffer pointer
  ; if r18 is 0x0A, jump to 'parse_row' to go round again
  ; if r18 is 0x00, we're done and return
  cpi r18, 0x0A
  breq parse_row

  ret

one_digit:
  ldd moves_to_make, Y+1
  rjmp after_remaining_move_parsed

two_digit:
  ; grab tens position
  ldd moves_to_make, Y+1
  mov r2, moves_to_make ; take a copy of tens position

  ; multiply by 8 by shifting 3 times
  lsl moves_to_make
  lsl moves_to_make
  lsl moves_to_make

  ; multiply by 2 by shifting once
  lsl r2

  add moves_to_make, r2

  ; grab units position
  ldd r2, Y+2
  add moves_to_make, r2
  rjmp after_remaining_move_parsed

three_digit:
  ; grab the hundreds position
  ldd r6, Y+1
  rcall add_pseudo_word ; we can just increment the zero passes by the hundredths place value

  ; grab tens position
  ldd moves_to_make, Y+2
  mov r2, moves_to_make ; take a copy of tens position

  ; multiply by 8 by shifting 3 times
  lsl moves_to_make
  lsl moves_to_make
  lsl moves_to_make

  ; multiply by 2 by shifting once
  lsl r2

  add moves_to_make, r2

  ; grab units position
  ldd r2, Y+3
  add moves_to_make, r2
  rjmp after_remaining_move_parsed

left_move:
  ; moves_to_make is the number of moves to make
  ; dial_pos is the dial position to update

  ; check if we've run out of moves
  tst moves_to_make
  breq after_moves

  ; check if the position is currently 0
  cpi dial_pos, 0
  brne left_move_dec ; if its not zero, skip this next instruction
  ; if it is zero, we're going to move to 100 instead before running the decrement
  ldi dial_pos, 100
left_move_dec:
  ; use 1 of the moves from moves_to_make on dial_pos
  dec dial_pos
  dec moves_to_make

  cpi dial_pos, 0
  brne left_move
  rcall inc_pseudo_word ; increment the zero counts if we moved on to a zero

  ; unconditional jump back to the top
  rjmp left_move

right_move:
  ; moves_to_make is the number of moves to make
  ; dial_pos is the dial position to update
  ; check if we've run out of moves
  tst moves_to_make
  breq after_moves

  ; check if the position is currently 99
  cpi dial_pos, 99
  brne right_move_inc ; if its not 99, skip this next instruction
  ; if it is zero, we're going to move to 0xFF instead before running the increment
  ; 0xFF just means it will roll over to zero when incremented
  ldi dial_pos, 0xFF
right_move_inc:
  ; use 1 of the moves from moves_to_make on dial_pos
  inc dial_pos
  dec moves_to_make

  cpi dial_pos, 0
  brne right_move
  rcall inc_pseudo_word ; increment the zero counts if we moved on to a zero

  ; unconditional jump back to the top
  rjmp right_move

add_pseudo_word:
  ; add the value of r6 to the pseudo 16-bit register of r5:r4
  add r4, r6
  brcc add_pseudo_word_no_carry
  inc r5 ; there was carry so inc high byte
add_pseudo_word_no_carry:
  ret

inc_pseudo_word:
  ; inc the value of the pseudo 16-bit register of r5:r4
  push r16
  ldi r16, 1
  add r4, r16
  brne inc_pseudo_word_no_carry
  inc r5 ; there was carry so inc high byte
inc_pseudo_word_no_carry:
  pop r16
  ret