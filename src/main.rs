#![feature(asm)]
#![feature(naked_functions)]
#![no_std]
#![no_main]
#![feature(core_intrinsics)]

#[naked]
#[no_mangle]
#[link_section = ".entry"]
pub unsafe extern "C" fn _start() {
    asm!(r#"
        .arm
        b init_gba
        .space 188
    "#, options(noreturn));
}

#[naked]
#[no_mangle]
pub unsafe extern "C" fn init_gba() -> ! {
    asm!(r#"
        .arm
        mov r0, #0x1f
        msr cpsr_c, r0

        @ Set stack pointer.
        ldr sp, =0x3007F00

        @ call Rust `main`
        ldr r2, =main
        bx r2

        @ `main` should never return.
        1: b 1b
    "#, options(noreturn));
}

#[no_mangle]
pub extern "C" fn main() {
    let input = 0x04000000 as *mut i32;
    let screen_buffer = 0x06000000 as *mut i16;
    unsafe {
        input.write_volatile(0x0403);

        screen_buffer.offset(120 + 80 * 240).write_volatile(0x001f);
        screen_buffer.offset(136 + 80 * 240).write_volatile(0x03e0);
        screen_buffer.offset(120 + 96 * 240).write_volatile(0x7c00);
    }
    loop {}
}

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    // XXX: Marked safe by rust-lang/rust#72204
    core::intrinsics::abort();
}
