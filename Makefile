PROJECTS = gba-savedump gba-saveedit
ROMS = $(addsuffix .gba,$(PROJECTS))
ELFS = $(addsuffix .elf,$(PROJECTS))

BUILDDIR = build
TARGET_ROMS = $(addprefix $(BUILDDIR)/,$(ROMS))
TARGET_ELFS = $(addprefix $(BUILDDIR)/,$(ELFS))

TRIPLE = arm-none-eabi
CPU = arm7tdmi

CC = arm-none-eabi-gcc
LD = arm-none-eabi-ld
AS = arm-none-eabi-as
OBJCOPY = arm-none-eabi-objcopy

CFLAGS = -c -g -O0 -Wall -Wextra -Werror -mthumb -mthumb-interwork -mcpu=$(CPU) -mtune=$(CPU) -ffast-math -fomit-frame-pointer -std=gnu11 -Iinclude
ASFLAGS = -c -mthumb -mthumb-interwork -g
ARFLAGS = -crs
LDFLAGS = -g -Lbuild/

LDSCRIPT = scripts/linker.ld
LIB_SRCS = $(wildcard lib/*.c lib/*.s)
LIB_OBJS = $(addprefix $(BUILDDIR)/,$(subst .c,.o,$(subst .s,.o,$(LIB_SRCS))))


.PHONY: all
all: $(TARGET_ROMS) | $(BUILDDIR)

$(BUILDDIR): $(BUILDDIR)/

$(BUILDDIR)/:
	mkdir -p $(BUILDDIR)

$(TARGET_ROMS): %.gba: %.elf | $(BUILDDIR)
	$(OBJCOPY) -O binary $< $@

define app_dependencies

endef

.SECONDEXPANSION:
$(TARGET_ELFS): $(BUILDDIR)/%.elf: $(LDSCRIPT) $(LIB_OBJS) $(BUILDDIR)/%/$$(subst .c,.o,$$(shell ls apps/%))
	$(LD) -o $@ $(LDFLAGS) -Map=$(basename $@).map -T$^

$(BUILDDIR)/%.o: %.s
	mkdir -p $(@D)
	$(AS) -o $@ $(ASFLAGS) $<

$(BUILDDIR)/%.o: %.c
	mkdir -p $(@D)
	$(CC) -o $@ $(CFLAGS) $<

$(BUILDDIR)/%.o: apps/%.c
	mkdir -p $(@D)
	$(CC) -o $@ $(CFLAGS) $<

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)