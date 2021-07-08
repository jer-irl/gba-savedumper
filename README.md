# GBA Save Shenanigans

This project has evolved over time, but most recently the goal is to create an on-GBA Pokemon Gen III save editor.
Continue on for a short history.

This is a personal learning project, and non-goals include

- Performance (currently compiling with -O0)
- Elegance and best practices (I'm still learning as I go)

## History of the Project

I was fortunate enough to have a 6 month gap before starting a new job during which I was able to pursue personal projects.
As a young Millenial born in 1995, to scratch a nostalgia itch I started digging into the Gameboy Advance as a development platform.
I have some WIP blog posts that may be posted one day over at [https://jeresch.github.io](https://jeresch.github.io), but in summary, it's a really cool platform for somebody who has mostly programmed for beefy Linux servers.

### Original Goals

As a child, somehow I managed to spend 50 hours playing Super Mario Advance 2 (Super Mario World port to GBA) without getting past the fourth world.
It would be a shame if the effort recorded in the save data became inaccessible.
So, I set out to dump save data from my old childhood game cartridges, and back them up in the cloud.

NOTE: This is possible already with custom hardware, or with a Nintendo DS or DS Lite.  Check out the following links.

- [homebrew app](https://digiex.net/threads/gba-backup-tool-backup-gba-saves-dump-a-gameboy-advanced-rom-using-a-nintendo-ds.9921/)
- [tutorial](https://projectpokemon.org/home/forums/topic/41730-managing-gba-saves-using-gba-backup-tool/)

But what about the nostalgic everyman who doesn't own a DS or custom hardware?
That's who I set out to help.

### Technical Approach

In normal operation, the Gameboy Advance boots into a tiny BIOS, verifies that a cartridge is inserted with a valid header, and then transfers execution control to the first address in the cartridge ROM region, which is mapped into the CPU address space.
The GBA has no real CPU cache, so there are variable costs associated with accessing the different regions of the address space.
There are two in-device RAM banks with different access latencies, and developers sometimes move performance-critical code routines from the cartridge ROM to the faster IWRAM section.
The readers who are used to an OS providing memory safety, virtual memory, etc., might be concerned about this state of affairs, and it's certainly a departure from the Linux-y experience.

With no cache, if a game cartridge is yanked during execution, the ROM region is immediately unavailable, usually leading to a crash.
However, in this project I originally aimed to exploit the fact that if code and control remain in the device's RAM internal RAM regions, an application can survive its cartridge being yanked.
In fact, an application can theoretically survive a completely different cartridge being inserted as well.

For some reason, the GBA CPU provides interrupts for cartridge insertion/removal events, but of course the handlers must be resident in device RAM to handle the interrupts.

Generally, this technique known as "cartridge-swapping" has been of minor interest, mostly as an ACE vector.
Motivated by nostalgia, I set out to use cartridge-swapping to back up save data from original and authentic GBA games for safe-keeping.

In practice, the user would perform this sequence of actions:

- Flash a custom cartridge ROM with my application.
- Insert the custom cartridge into the device and boot the system.
- Wait for code to be relocated to device RAM, and yank the custom cartridge when prompted.
- Insert an OEM cartridge and wait for the save data to be dumped to device RAM.
- Yank the OEM cartridge and reinsert the custom cartridge when prompted.
- Wait for the save data to be dumped from device RAM to the custom cartridge.

This should be feasible and device RAM is large enough, but this wasn't a simple project.

### More Programming Challenges

Much of the development of this project was done in emulators, particularly mgba.
However, these projects generally focus on getting pirated games playable on unofficial hardware, rather than actually emulating hardware details relevant only to oddball projects.
I had to include some hacks to "trick" mgba to allow development, and swapping ROM in the emulator was not easy.
Please [see my writeup](/writeups/mgba-hacks.md) for more information.

The GBA has no concept of a console or of text.
Any logging, interaction, fonts, etc has to be built from the ground up, with hardware constraints in mind.
This project used a simple bitmap video mode, but other video modes would be beneficial in the future.

Save data is not easy to access, and different game cartridges are manufactured with different save data hardware and different ways of accessing it.
This is a big pain.

Because of the way ARM and C work, relocating code at runtime and keeping it working isn't obvious or trivial.
This was accomplished with a linker script and code annotations.

### Hardware Issues and a Dead End

This all worked well until I went to try the final project on real hardware.
Everything appeared to work until reinserting the custom cartridge to retrieve the save data in RAM.
Inserting the cartridge appears to cause a power spike and a hard reset, probably because I was using flash cartridges to host the custom ROM.
I tried the EZFlash Omega, Omega DE, and the Everdrive GBA x5 mini, but none would work.

So in face of this challenge, I am planning a pivot to in-device save-editing, rather than save dumping.

## Continuing Efforts

I want to provide save editing for Pokemon Gen III games, all within the comfort of an original GBA.
This will require implementing some Pokemon-specific code, but should be satisfying when done.

Other tasks are mostly related to documentation, originally planned for my empty blog, but I think I'll put them here instead.

- [ ] Inline documentation
- [x] Document mgba challenges and hacks
- [ ] Document graphics hardware and modes
- [ ] Document save media interaction
- [ ] Document code relocation and linker scripts
- [ ] Document stack setup
- [ ] Document interrupts
- [ ] Document used BIOS functionality
- [ ] Document DMA
- [ ] Document ARM vs THUMB and this applicatioon's tradeoffs.
- [ ] Add some fun links
