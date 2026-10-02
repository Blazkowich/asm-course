/* test-env/examples/main.c
 * C მხარე c_interop.asm-ისთვის.
 *
 * Build:
 *   nasm -f elf64 -g -F dwarf c_interop.asm -o c_interop.o
 *   gcc -no-pie -g main.c c_interop.o -o c_interop
 * Run:  ./c_interop
 */

#include <stdio.h>

extern int  sum_array(const int *arr, long n);
extern void to_upper(char *s);

int main(void) {
    int data[] = {1, 2, 3, 4, 5};
    printf("sum_array = %d\n", sum_array(data, 5));

    char text[] = "hello, World! 123";
    to_upper(text);
    printf("to_upper  = %s\n", text);

    return 0;
}