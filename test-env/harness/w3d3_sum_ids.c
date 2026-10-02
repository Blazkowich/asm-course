/* test-env/harness/w3d3_sum_ids.c
 *
 * ტესტის დრაივერი — ეს არ არის სავარჯიშოს ამოხსნა.
 * struct-ს აქ ვაცხადებთ, რომ ზუსტად იგივე ლეიაუტი იყოს, რასაც asm-ში
 * ხვდები. შენი ფუნქციაა solutions/w3d3_sum_ids.asm-ში. ამ ფაილს არ არედიტებ.
 *
 * ხელით აწყობა:
 *   nasm -f elf64 -g -F dwarf solutions/w3d3_sum_ids.asm -o /tmp/ids.o
 *   gcc -no-pie -g harness/w3d3_sum_ids.c /tmp/ids.o -o /tmp/ids
 *   /tmp/ids
 */

#include <stdio.h>

/* sizeof(struct Item) == 16: int(4) + char(1) + 3 ბაიტი padding + double(8) */
struct Item {
    int    id;
    char   flag;
    double value;
};

/* System V AMD64: arr → rdi, n → rsi, დაბრუნება → rax */
extern long sum_ids(struct Item *arr, unsigned long n);

int main(void) {
    struct Item items[3] = {
        {10, 'a', 1.5},
        {20, 'b', 2.5},
        {30, 'c', 3.5}
    };

    /* ზომა პირველ ხაზზე ბეჭდდება, შედეგი კი ბოლოს — ტესტი ბოლო ხაზს ადარებს */
    printf("sizeof(struct Item) = %zu\n", sizeof(struct Item));
    printf("%ld\n", sum_ids(items, 3));
    return 0;
}
