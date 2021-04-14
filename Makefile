PROJECT = asteroids
TARGET = $(PROJECT).gba

BUILD = build
SRC = src
TRIPLE = arm-none-eabi
CPU = arm7tdmi

CC = arm-none-eabi-gcc
LD = arm-none-eabi-ld
AS = arm-none-eabi-as
OBJCOPY = arm-none-eabi-objcopy

CFLAGS = -c -g -O0 -Wall -Wextra -Werror -mthumb -mthumb-interwork -mcpu=$(CPU) -mtune=$(CPU) -ffast-math -fomit-frame-pointer -std=gnu11
ASFLAGS = -c -mthumb -mthumb-interwork -g
LDFLAGS = -g -Map=$(BUILD)/asteroids.map

AS_OBJECTS = \
	$(BUILD)/entry.o

CC_OBJECTS = \
	$(BUILD)/logging.o \
	$(BUILD)/bios.o \
	$(BUILD)/memory.o \
	$(BUILD)/data.o \
	$(BUILD)/interrupt.o \
	$(BUILD)/savedata.o \
	$(BUILD)/keypad.o \
	$(BUILD)/mgba.o \
	$(BUILD)/main.o \
	$(BUILD)/common.o

LDSCRIPT = src/linker.ld


all: mkbuilddir $(BUILD)/$(TARGET)

mkbuilddir:
	mkdir -p $(BUILD)

$(BUILD)/$(TARGET): $(BUILD)/$(TARGET).elf
	$(OBJCOPY) -O binary $< $@

$(BUILD)/$(TARGET).elf: $(LDSCRIPT) $(AS_OBJECTS) $(CC_OBJECTS)
	$(LD) -o $@ $(LDFLAGS) -T$^

$(AS_OBJECTS): $(BUILD)/%.o: src/%.s
	$(AS) -o $@ $(ASFLAGS) $<

$(CC_OBJECTS): $(BUILD)/%.o: src/%.c
	$(CC) -o $@ $(CFLAGS) $<

dockerbuild:
	docker build --tag asteroids-gba/build --file docker/Dockerfile.build docker
	docker run --rm --mount type=bind,src=$(shell pwd),dst=/project asteroids-gba/build


.PHONY: clean
clean:
	rm -rf $(BUILD)
	if docker image inspect asteroids-gba/build >/dev/null 2>&1; then docker rmi asteroids-gba/build; fi
