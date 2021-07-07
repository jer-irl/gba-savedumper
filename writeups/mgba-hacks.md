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
