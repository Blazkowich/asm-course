# harness/ — ტესტის დრაივერები

ეს საქაღალდე `run-tests.sh`-ს ეკუთვნის. **აქ ამოხსნები არ არის.**

C interop-ის დავალებებში შენ **მხოლოდ asm ფუნქციას** წერ. ვინმემ ხომ უნდა
გამოიძახოს ის და დაბეჭდოს შედეგი — სწორედ ეს არის driver. ის შენს კოდს
`extern`-ით უკავშირდება, ამიტომ ფუნქციის სახელი და არგუმენტების ტიპები
ზუსტად უნდა ემთხვეოდეს.

| driver | რომელ დავალებას | შენი ფუნქციის სიგნატურა |
| --- | --- | --- |
| `w3d2_sum_array.c` | `w3d2_sum_array` | `long sum_array(int *arr, unsigned long n)` |
| `w3d2_to_upper.c` | `w3d2_to_upper` | `void to_upper(char *s)` |
| `w3d3_sum_ids.c` | `w3d3_sum_ids` | `long sum_ids(struct Item *arr, unsigned long n)` |
| `w3d4_simd_add.c` | `w3d4_simd_add` | `void add_float(float *dst, float *a, float *b, unsigned long n)` |

**ამ ფაილებს ნუ შეცვლი** — თუ შეცვლი, ტესტი სხვა რამეს შეამოწმებს და
შედეგი აღარაფერს ნიშნავს. დრაივერის წაკითხვა კი სასარგებლოა: ის გაჩვენებს,
როგორ იძახებს C asm ფუნქციას (ეს III კვირის მთავარი უნარია).

ხელით (ტესტის გარეშე) ასე აწყობ და უშვებ:

```
nasm -f elf64 -g -F dwarf solutions/w3d2_sum_array.asm -o /tmp/sum.o
gcc -no-pie -g harness/w3d2_sum_array.c /tmp/sum.o -o /tmp/sum
/tmp/sum
```
