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

CFLAGS = -c -g -O0 -Wall -Wextra -Werror -mthumb -mthumb-interwork -mcpu=$(CPU) -mtune=$(CPU) -ffast-math -fomit-frame-pointer -mthumb -mthumb-interwork
ASFLAGS = -c -mthumb -mthumb-interwork
LDFLAGS = -g -Map=$(BUILD)/asteroids.map

AS_OBJECTS = \
	$(BUILD)/main.o

LDSCRIPT = src/main.ld


all: mkbuilddir $(BUILD)/$(TARGET)

mkbuilddir:
	mkdir -p $(BUILD)

$(BUILD)/$(TARGET): $(BUILD)/$(TARGET).elf
	$(OBJCOPY) -O binary $< $@

$(BUILD)/$(TARGET).elf: $(LDSCRIPT) $(AS_OBJECTS)
	$(LD) -o $@ $(LDFLAGS) -T$^

$(AS_OBJECTS): $(BUILD)/%.o: src/%.s
	$(AS) -o $@ $(ASFLAGS) $<

dockerbuild:
	docker build --tag asteroids-gba/build --file docker/Dockerfile.build docker
	docker run --rm --mount type=bind,src=$(shell pwd),dst=/project asteroids-gba/build


.PHONY: clean
clean:
	rm -rf $(BUILD)
	if docker image inspect asteroids-gba/build >/dev/null 2>&1; then docker rmi asteroids-gba/build; fi
