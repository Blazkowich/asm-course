/* test-env/harness/w3d4_simd_add.c
 *
 * ტესტის დრაივერი — ეს არ არის სავარჯიშოს ამოხსნა.
 * შენი ფუნქციაა solutions/w3d4_simd_add.asm-ში. ამ ფაილს არ არედიტებ.
 *
 * მასივები 16-ბაიტიანად გასწორებულია, ამიტომ movaps-იც იმუშავებს —
 * მაგრამ მხოლოდ მაშინ, თუ შენც სწორად იყენებ.
 *
 * ხელით აწყობა:
 *   nasm -f elf64 -g -F dwarf solutions/w3d4_simd_add.asm -o /tmp/simd.o
 *   gcc -no-pie -g harness/w3d4_simd_add.c /tmp/simd.o -o /tmp/simd
 *   /tmp/simd
 */

#include <stdio.h>

/* System V AMD64: dst → rdi, a → rsi, b → rdx, n → rcx */
extern void add_float(float *dst, float *a, float *b, unsigned long n);

/* 16-ბაიტიანი გასწორება — movaps-ისთვის აუცილებელი პირობა */
static float a[6] __attribute__((aligned(16)))   = {1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f};
static float b[6] __attribute__((aligned(16)))   = {2.0f, 3.0f, 4.0f, 5.0f, 6.0f, 7.0f};
static float dst[6] __attribute__((aligned(16))) = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f};

int main(void) {
    unsigned long i;
    double total = 0.0;

    add_float(dst, a, b, 6);

    /* შედეგი: {3,5,7,9,11,13} → ჯამი 48.00 */
    for (i = 0; i < 6; i++) {
        total += dst[i];
    }

    /* ბოლო ხაზია საჭირო — ტესტი სწორედ მას ადარებს */
    printf("%.2f\n", total);
    return 0;
}
