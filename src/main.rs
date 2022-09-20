#![no_std]
#![no_main]
mod asm;

#[panic_handler]
unsafe fn panic_handler(info: &core::panic::PanicInfo) -> ! {
    loop {}
}