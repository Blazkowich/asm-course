/* test-env/examples/main.c
 * C მხარე c_interop.asm-ისთვის.
 *
 * Build:
 *   nasm -f elf64 -g -F dwarf c_interop.asm -o c_interop.o
 *   gcc -no-pie -g main.c c_interop.o -o c_interop
 * Run:  ./c_interop
 */

#include <stdio.h>

int main(void) {

}