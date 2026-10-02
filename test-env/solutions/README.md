# solutions/ — აქ წერ დავალებებს

**ეს საქაღალდე თავიდან ცარიელია. ეს განზრახ არის.**

არც ერთი ამოხსნა არ არის მოცემული — არც აქ, არც `run-tests.sh`-ში.
კოდს შენ წერ, ტესტი კი მხოლოდ ამოწმებს და, თუ არ გამოვიდა, გაიდლაინს
გაჩვენებს.

## სამუშაო ნაკადი

```bash
cd test-env
./run-tests.sh --list              # რა დავალებებია და რომელი ფაილია საჭირო
./run-tests.sh --new w1d1_exit42   # შექმნის ცარიელ ჩონჩხს (მხოლოდ კომენტარები)
$EDITOR solutions/w1d1_exit42.asm
./run-tests.sh w1d1_exit42         # შეამოწმე
./run-tests.sh --guide w1d1_exit42 # არ გამოვიდა? იდეები, gdb, ხშირი შეცდომები
```

`<id>` ზუსტად უნდა ემთხვეოდეს ცხრილში მოცემულ სახელს — `w1d4` არ არის
სწორი, `w1d4_sum_1_to_100` არის. თუ შეცდი, ტესტი შემოგთავაზებს ვარიანტებს.

## ფაილების სახელები — ზუსტად id-ია

ტესტი ფაილს **ზუსტად ამ სახელით** ეძებს (`--list` გაჩვენებს):

| id | ფაილი | რას ამოწმებს |
| --- | --- | --- |
| `w1d1_exit42` | `w1d1_exit42.asm` | exit code = 42 |
| `w1d2_arith` | `w1d2_arith.asm` | exit code = 30 |
| `w1d2_div_remainder` | `w1d2_div_remainder.asm` | exit code = 2 |
| `w1d3_hello` | `w1d3_hello.asm` | stdout = `Hello` |
| `w1d3_georgian` | `w1d3_georgian.asm` | stdout = `გამარჯობა სამყარო` |
| `w1d4_sum_1_to_100` | `w1d4_sum_1_to_100.asm` | exit code = 186 |
| `w1d4_array_max` | `w1d4_array_max.asm` | exit code = 42 |
| `w1d5_print_int` | `w1d5_print_int.asm` | stdout = `5050` |
| `w2d1_add_function` | `w2d1_add_function.asm` | exit code = 30 |
| `w2d2_factorial` | `w2d2_factorial.asm` | exit code = 120 |
| `w2d3_strlen` | `w2d3_strlen.asm` | exit code = 11 |
| `w2d4_popcount` | `w2d4_popcount.asm` | exit code = 6 |
| `w2d4_is_power_of_two` | `w2d4_is_power_of_two.asm` | exit code = 1 |
| `w2d4_xor_swap` | `w2d4_xor_swap.asm` | exit code = 20 |
| `w2d5_calculator` | `w2d5_calculator.asm` | 5 შემთხვევა stdin-იდან |
| `w3d2_sum_array` | `w3d2_sum_array.asm` | stdout = `15` |
| `w3d2_to_upper` | `w3d2_to_upper.asm` | stdout = `HELLO, ASM` |
| `w3d3_sum_ids` | `w3d3_sum_ids.asm` | stdout = `60` |
| `w3d4_simd_add` | `w3d4_simd_add.asm` | stdout = `48.00` |
| `w4d1_bufov` | `w4d1_vuln.c` + `w4d1_exploit.py` | მარკერი `SECRET_REACHED` |

ხუთი დავალება (`w3d1`, `w3d5`, `w4d2`, `w4d3`, `w4d4`) ავტომატურად არ
შემოწმდება — ტესტი მათთვის კრიტერიუმებს და gdb-ის ნაბიჯებს გაჩვენებს.

## წესები, რომლებიც ღირს დაიმახსოვრო

- **არ დააკოპირო.** ხელით აკრიფე — სწავლა აქ ხდება.
- **ყოველი ამოხსნა gdb-ში გაიარე.** მუშა კოდი ≠ გაგებული კოდი.
- **ფაილი ცარიელია?** ტესტი ამას ცალკე ამოიცნობს და შეცდომებს არ აყენებს.
- **უსასრულო ციკლი?** ტესტი 10 წამში წყვეტს და გეტყვის — ტერმინალი არ ჩერდება.
- **ტერმინი გაუგებარია?** (`rip`, `rsp`, `ABI`, `alignment`…) →
  [`../../GLOSSARY.md`](../../GLOSSARY.md). ეს არ არის სირცხვილი — სწორედ ამიტომ
  არსებობს ლექსიკონი.

სრული გაიდლაინები: [`../GUIDELINES.md`](../GUIDELINES.md)
