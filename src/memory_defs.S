.section .bss

.balign 1

.global rgb_buf
rgb_buf:
.space 5      ;  each LED defined as 1-bit brightness, 1-bit red, 1-bit blue, 1-bit green, meaning 2 LEDs per byte, 5 bytes per strip

.global row_buf
row_buf:
.space 4      ;  holds the current row we are processing. at most 1 letter and 3 digits