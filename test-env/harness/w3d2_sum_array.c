/* test-env/harness/w3d2_sum_array.c
 *
 * ტესტის დრაივერი — ეს არ არის სავარჯიშოს ამოხსნა.
 * შენი ფუნქციაა solutions/w3d2_sum_array.asm-ში; ეს ფაილი მხოლოდ იძახებს
 * მას და შედეგს ბეჭდავს. ამ ფაილს არ არედიტებ.
 *
 * ხელით აწყობა:
 *   nasm -f elf64 -g -F dwarf solutions/w3d2_sum_array.asm -o /tmp/sum.o
 *   gcc -no-pie -g harness/w3d2_sum_array.c /tmp/sum.o -o /tmp/sum
 *   /tmp/sum
 */

#include <stdio.h>

/* System V AMD64: arr → rdi, n → rsi, დაბრუნება → rax */
extern long sum_array(int *arr, unsigned long n);

int main(void) {
    int arr[5] = {1, 2, 3, 4, 5};

    /* ბოლო ხაზია საჭირო — ტესტი სწორედ მას ადარებს */
    printf("%ld\n", sum_array(arr, 5));
    return 0;
}
