/* test-env/harness/w3d2_to_upper.c
 *
 * ტესტის დრაივერი — ეს არ არის სავარჯიშოს ამოხსნა.
 * შენი ფუნქციაა solutions/w3d2_to_upper.asm-ში; ეს ფაილი ქმნის სტრიქონს,
 * გიძახებს და შედეგს ბეჭდავს. ამ ფაილს არ არედიტებ.
 *
 * ხელით აწყობა:
 *   nasm -f elf64 -g -F dwarf solutions/w3d2_to_upper.asm -o /tmp/up.o
 *   gcc -no-pie -g harness/w3d2_to_upper.c /tmp/up.o -o /tmp/up
 *   /tmp/up
 */

#include <stdio.h>

/* System V AMD64: სტრიქონის მისამართი → rdi, დაბრუნებული მნიშვნელობა არ არის */
extern void to_upper(char *s);

int main(void) {
    /* ჩაწერადი მასივია (არა სტრიქონის ლიტერალი) — შენ ცვლი მას ადგილზე */
    char text[] = "Hello, Asm";

    to_upper(text);

    /* ბოლო ხაზია საჭირო — ტესტი სწორედ მას ადარებს */
    printf("%s\n", text);
    return 0;
}
