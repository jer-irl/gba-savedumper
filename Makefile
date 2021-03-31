PROJECT = asteroids
TARGET = $(PROJECT).gba

BUILD = build
SRC = src
TRIPLE = arm-none-eabi
CPU = arm7tdmi

CC = arm-none-eabi-gcc
LD = arm-none-eabi-ld
AS = $(CC)
OBJCOPY = arm-none-eabi-objcopy

CFLAGS = -c -g -O0 -Wall -Wextra -Werror -mthumb -mthumb-interwork -mcpu=$(CPU) -mtune=$(CPU) -ffast-math -fomit-frame-pointer -mthumb -mthumb-interwork
ASFLAGS = -c -mthumb -mthumb-interwork
LDFLAGS = -g -Map=$(BUILD)/asteroids.map

CC_OBJECTS = \
	$(BUILD)/main.o

AS_OBJECTS = \
	$(BUILD)/entry.o \
	$(BUILD)/header.o

LDSCRIPT = src/linker.ld


all: mkbuilddir $(BUILD)/$(TARGET)

mkbuilddir:
	mkdir -p $(BUILD)

$(BUILD)/$(TARGET): $(BUILD)/$(TARGET).elf
	$(OBJCOPY) -O binary $< $@

$(BUILD)/$(TARGET).elf: $(LDSCRIPT) $(CC_OBJECTS) $(AS_OBJECTS)
	$(LD) -o $@ $(LDFLAGS) -T$^

$(CC_OBJECTS): $(BUILD)/%.o: src/%.c
	$(CC) -o $@ $(CFLAGS) $<

$(AS_OBJECTS): $(BUILD)/%.o: src/%.S
	$(AS) -o $@ $(ASFLAGS) $<

dockerbuild:
	docker build --tag asteroids-gba/build --file docker/Dockerfile.build docker
	docker run --rm --mount type=bind,src=$(shell pwd),dst=/project asteroids-gba/build


.PHONY: clean
clean:
	rm -rf $(BUILD)
	docker rmi asteroids-gba/build
