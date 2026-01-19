TESTING ?= 0

SRCS := src/main.S src/spi.S src/leds.S src/external_flash.S src/timer.S src/aoc_day1.S src/memory_defs.S src/util.S
ifeq ($(TESTING),1)
SRCS += src/leds_testing.S
endif

all: main.hex

main.hex: main.elf
	avr-objcopy -O ihex -R .eeprom $^ $@

main.elf: $(SRCS)
	avr-gcc -mmcu=attiny85 $^ -o $@

%.flash.bin: %.txt
	cp $< $@
	truncate -s 131072 $@

.PHONY: upload
upload: main.hex
	avrdude -c arduino -P /dev/ttyACM0 -p t85 -U flash:w:$^:i  -F -b 19200

.PHONY: clean
clean:
	rm -f main.elf main.hex *.flash.bin