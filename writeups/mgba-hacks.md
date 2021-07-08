# mGBA Hacks

During the development of this project, I utilized the [open source](https://github.com/mgba-emu/mgba) emulator [mGBA](http://mgba.io) to run ROM image artifacts for my custom application.
This was a huge help over using real hardware.
I leaned heavily on mGBA's debugging and logging features, and it was much quicker not having to re-flash hardware every time a code change is made.

That said, mGBA's goals are to make classic games playable on unofficial hardware, and 100% emulation accuracy of hardware details that don't affect gameplay are a non-goal.
Correctly emulating cartride-swapping and applications that utilize it isn't well supported, and I had to introduce a few hacks to get it to work.

Also interestingly, mGBA offers extensions to GBA applications that allow them to log directly to the internal mGBA console (that doesn't exist on a real GBA).
In this document, I will briefly describe how that is accomplished as well so that readers won't have to dig through code to figure out this functionality.

## Logging to Console

A close read of the [GBA memory map](https://mgba-emu.github.io/gbatek/#gbamemorymap) will reveal that much of the address space is unused.
mGBA claims a small portion of that unused space for itself, and implements "fake" hardware that interacts with those addresses.
This fake hardware is implemented from the emulator side [here](https://github.com/mgba-emu/mgba/blob/ece0e168ef857c1f3af9e9edc97f61de62b87029/src/gba/io.c#L573-L582) with the logging functionality being implemented [here](https://github.com/mgba-emu/mgba/blob/d9627e36234a3b03ac283d09412e5853e849c2ef/src/gba/gba.c#L561-L573).

That's fine, but we are interested in utilizing the feature from the application side.
Conveniently, the mGBA repository also gives an example of how to utilize this feature from a homebrew game.
This is in the form of an extension to the commonly used `libgba` project.
mGBA's extension lives [in its tree](https://github.com/mgba-emu/mgba/tree/d9627e36234a3b03ac283d09412e5853e849c2ef/opt/libgba), and I'll go through a few of the interesting parts here.

First we get some constant definitions (in yucky but portable C-style macros)

```{c}
#define MGBA_LOG_FATAL 0
#define MGBA_LOG_ERROR 1
#define MGBA_LOG_WARN 2
#define MGBA_LOG_INFO 3
#define MGBA_LOG_DEBUG 4
// ...
#define REG_DEBUG_ENABLE (vu16*) 0x4FFF780
#define REG_DEBUG_FLAGS (vu16*) 0x4FFF700
#define REG_DEBUG_STRING (char*) 0x4FFF600
```

The `MGBA_LOG_*` log levels are just a glorified enum as far as I can tell, but the `REG_DEBUG_*` definitions are more interesting.
From the application perspective `REG_DEBUG_ENABLE` and `REG_DEBUG_FLAGS` operate like other memory-mapped registers in the GBA.
The application code makes memory reads and writes (of particular sizes and values) to those addresses, and somewhere in the CPU these directives get caught and redirected to more specialized hardware components.
mGBA's implementation of these particular hardware components is linked above.
The size of these reads and writes is very important, and care must be taken to ensure the correct machine code gets generated.
Generally, careful typing and casting as done in the macro definitions will be sufficient, but still be careful!
As a side note, there are many times where the byte length of a memory R/W operation will be very significant.
For example, when interacting with video RAM (VRAM), all writes must be at least 16 bits and aligned to the 2 byte barrier, or else data gets dropped and overwritten ([see here](https://mgba-emu.github.io/gbatek/#address-bus-width-and-cpu-readwrite-access-widths)).

Also note that these registers are marked `volatile`.
This is important to ensure that the compiler doesn't get too cheeky with us, and try to optimize out memory operations that would have predictable results if these addresses corresponded to RAM and not to magic hardware.

With those registers available to our code, the application must activate mGBA debug logging by writing a magic value (`0xc0de`) to `REG_DEBUG_ENABLE`.
If mGBA debug logging is available and successfully activated, a 16 bit read from the same `REG_DEBUG_ENABLE` register will return the magic result `0x1dea`.

```{c}
bool mgba_open(void) {
    *REG_DEBUG_ENABLE = 0xC0DE;
    return *REG_DEBUG_ENABLE == 0x1DEA;
}
```

Very cute!

Now, a null-terminated string of up to 1KiB - 1 ascii characters can be written to the buffer beginning at `REG_DEBUG_STRING`.
Finally, when the message is written and ready, a 16 bit write of 0x100 OR'd with the desired log level value will kick the emulator into motion.
The emulator will read and log the buffer, and then zero out the buffer for the next use.

```{c}
ssize_t mgba_stdout_write(struct _reent* r __attribute__((unused)), void* fd __attribute__((unused)), const char* ptr, size_t len) {
    if (len > 0x100) {
        len = 0x100;
    }
    strncpy(REG_DEBUG_STRING, ptr, len);
    *REG_DEBUG_FLAGS = MGBA_LOG_INFO | 0x100;
    return len;
}
```

In case the application wants to disable this feature at the emulator level, this can be accomplished by writing `0` to `REG_DEBUG_ENABLE`.

```{c}
void mgba_close(void) {
    *REG_DEBUG_ENABLE = 0;
}
```

In the spirit of going it alone, and instead of reusing provided code like a good developer, I implemented this functionality from scratch [here](/src/mgba.c)

## Faulty Multiboot Detection

One feature of the Nintendo DS (NDS) that is often celebrated is its [ability](https://en-americas-support.nintendo.com/app/answers/detail/a_id/3910/~/how-to-play-multiplayer-with-one-game-card) for local multiplayer between multiple systems with only one copy of a particular game cartridge.
For example, when playing Mario Kart DS, with one copy of the game, multiple people can play a limited multiplayer mode with one "leader" system with the game card installed, and one or more "follower" systems which run a minimal local version of the game.

The GBA actually has a similar feature called "multiboot," with the small limitation that the GBA requires a link cable to be used for all multiplayer interaction, rather than NDS-like wireless interaction.
The actual protocol for uploading programs from the leader to followers' device RAM is pretty complicated and only partially implemented in the GBA BIOS, and I won't get into it here, but the [gory details](https://mgba-emu.github.io/gbatek/#biosmultibootsinglegamepak) are pretty interesting.

### mGBA's Multiboot False Positive

For this project, the most important part is the fact that the [ROM image header](https://mgba-emu.github.io/gbatek/#gbacartridgeheader) has some properties that mGBA [tries to detect](https://github.com/mgba-emu/mgba/blob/558f644fd3e6bd514b26e74a6f3ac1aa0046ffee/src/gba/gba.c#L634) when starting.

```{c}
static const size_t GBA_MB_MAGIC_OFFSET = 0xC0;
```

As documented in the GBATEK reference, this `GBA_MB_MAGIC_OFFSET` into the ROM image header is entry point for multiboot followers.
mGBA looks at this address in the ROM image and tries to determine if it is a branch instruction into RAM, which would indicate the image is for multiboot.
If the data at this offset is an ARM branch instruction, the emulator will check its branch offset immediate argument to determine if we're in a multiboot image (more on this later).
If the data at this offset cannot be interpreted as an ARM branch, the emulator then scans then next 80 possible ARM instruction slots for instructions loading an address pointing to device RAM into a register.
Because the first 80 instructions in the ROM image could pretty safely be assumed to be for application setup, it seems unlikely that this code would be loading from RAM unless in a multiboot scenario.
My application does load an immediate value into a register in preparation for the jump to device RAM code, and so trips this detection without workarounds.

```{arm}
.func init
init:
    mov r0, $IRQ_MODE
    msr cpsr_fc, r0
    ldr sp, =IRQ_STACK

    mov r0, $SYS_MODE
    msr cpsr_fc, r0
    ldr sp, =SYS_STACK

    bl copy_code_to_wram

    @ Branch to gba_main(), switching to THUMB state
    ldr r0, =gba_main @ Problematic load
    orr r0, $1
    mov lr, pc
    bx r0
    b init
.endfunc
```

### My Workaround

This code ends up immediately after the header in the ROM image, so the problematic load instruction causes mGBA to mis-classify the ROM image as for multiboot.
The workaround I used exploits some sanity-checking by mGBA with some un-sane ARM code.
Some mGBA code is reproduced and annotated below.

```{c}
    // Read and decode instruction at 0xc0 in ROM image
    if (vf->seek(vf, GBA_MB_MAGIC_OFFSET, SEEK_SET) < 0) {
        return false;
    }
    uint32_t signature;
    if (vf->read(vf, &signature, sizeof(signature)) != sizeof(signature)) {
        return false;
    }
    uint32_t opcode;
    LOAD_32(opcode, 0, &signature);
    struct ARMInstructionInfo info;
    ARMDecodeARM(opcode, &info);
    // If this instruction is a branch...
    if (info.branchType == ARM_BRANCH) {
        // If the immediate argument is <=0 (IMPORTANT)
        if (info.op1.immediate <= 0) {
            return false; // return MULTIBOOT == false
        } else if // ...
    }
```

This suggests the simple workaround I used, which is inserting a simple dead/unused branch instruction at `0xc0` with an immediate offset of 0.
The only tricky this was that the only way I figured out how to get the assembler to emit the desired instruction was to manually encode the instruction as hexadecimal and include it that way.  The final result immediately following the ROM header was [this line](https://github.com/jeresch/gba-savedumper/blob/f8e214208b0ae757749a65e097bd3471a6b1bb6c/src/entry.s#L44-L45).

```{arm}
@ Fool mgba MB detection
.word 0xEA000000 @ b 0
```

With this change, mGBA no longer misinterpreted my ROM image, and didn't randomly jump away from my code.
