#include "bios.h"

struct bios_div_result bios_div(const int32_t numerator, const int32_t denominator) {
    struct bios_div_result result;
    asm (
        "mov r0, %[rnumerator]\n"
        "mov r1, %[rdenominator]\n"
        "swi 0x06\n"
        "mov %[rresultdiv], r0\n"
        "mov %[rresultmod], r1\n"
        : [rresultdiv] "=r" (result.div), [rresultmod] "=r" (result.mod)
        : [rnumerator] "r" (numerator), [rdenominator] "r" (denominator)
        : "r0", "r1", "r3"
    );
    return result;
}

void bios_halt() {
    while (true) {
        // asm volatile (
        //     "swi 0x02"
        // );
    }
}
