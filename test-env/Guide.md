## სტრუქტურა

```
asm-course/
├── README.md
├── 00-setup.md
├── 01-week1-fundamentals.md
├── 02-week2-stack-functions.md
├── 03-week3-c-interop.md
├── 04-week4-reverse-engineering.md
├── CHEATSHEET.md
└── test-env/
    ├── Dockerfile
    ├── verify.sh          (chmod +x)  — გარემოს შემოწმება
    ├── run-tests.sh       (chmod +x)  — თვითშემოწმება (ამოხსნების გარეშე)
    ├── quickstart.sh      (chmod +x)
    ├── GUIDELINES.md      — ★ იდეები, gdb-ის ნაბიჯები, ხშირი შეცდომები
    ├── Makefile
    ├── harness/           — ტესტის C-დრაივერები (არ არედიტებ)
    ├── solutions/         — ★ აქ წერ დავალებებს (თავიდან ცარიელია)
    └── examples/
        ├── Makefile
        ├── hello.asm
        ├── georgian.asm
        ├── print_int.asm
        ├── factorial.asm
        ├── c_interop.asm
        └── main.c
```

## 🔧 გამოყენება

### Docker-ით (რეკომენდირებული)

```bash
cd asm-course/test-env
chmod +x *.sh

# ერთი ბრძანებით ყველაფერი:
./quickstart.sh

# ან ცალ-ცალკე:
docker buildx build -t asm-course .
docker run --rm -it -v "$PWD/..:/work" asm-course
# კონტეინერში:
cd /work/test-env
./verify.sh
./run-tests.sh --list
```

### ლოკალურად (თუ ინსტრუმენტები გაქვს)

```bash
cd asm-course/test-env

./run-tests.sh --list                     # ყველა დავალება და საჭირო ფაილები
./run-tests.sh --new w1d1_exit42          # შექმნის ცარიელ ჩონჩხს solutions/-ში
./run-tests.sh w1d1_exit42                # შეამოწმე ერთი დავალება
./run-tests.sh                            # ყველა
./run-tests.sh --guide w1d1_exit42        # იდეები + gdb + ხშირი შეცდომები
./run-tests.sh --progress                 # პროგრესი კვირების მიხედვით
```

`<id>` უნდა იყოს ზუსტი (`w1d1_exit42`, არა `w1d1`). შეცდომისას ტესტი
შემოგთავაზებს სწორ ვარიანტებს.

სავარჯიშო მოედანი (`examples/`) ცალკეა — იქაური `.asm` ფაილები **ცარიელი
ჩონჩხებია** (მხოლოდ კომენტარები): შიგთავსს თვითონ წერ, როცა თავისუფლად
ექსპერიმენტებ. შემოწმებადი დავალებები კი `solutions/`-შია.

```bash
cd test-env/examples
make hello                 # ააწყვე (ჩონჩხი ჯერ ცარიელია — კოდი შენ წერ)
make run-hello             # გაუშვი
make debug-factorial       # gdb-ში
make clean                 # წაშალე
```

## 📋 რას ამოწმებს `verify.sh`

1. **არქიტექტურა** — x86-64?
2. **ინსტრუმენტები** — nasm, ld, gcc, gdb, objdump, strace, make, python3
3. **კონფიგურაცია** — `~/.gdbinit`-ში Intel syntax?
4. **ფუნქციური ტესტები** — ტულჩეინი აწყობს და უშვებს პატარა პროგრამას

## 🧪 რას ამოწმებს `run-tests.sh`

**მთავარი განსხვავება ძველ ვერსიასთან:** ტესტში **ამოხსნები აღარ არის**.
ის კითხულობს მხოლოდ შენს ფაილებს `solutions/`-იდან. არ გამოვიდა? ტესტი
იდეას და gdb-ის ნაბიჯებს გაძლევს, კოდს კი არა.

| კვირა | id | რას ამოწმებს | მოსალოდნელი |
| ----- | -- | ------------ | ------------ |
| I | `w1d1_exit42` | exit 42 | exit=42 |
| I | `w1d2_arith` | (5+3)*4-2 | exit=30 |
| I | `w1d2_div_remainder` | 100 / 7 ნაშთი | exit=2 |
| I | `w1d3_hello` | `write` | stdout=`Hello` |
| I | `w1d3_georgian` | UTF-8 | stdout=`გამარჯობა სამყარო` |
| I | `w1d4_sum_1_to_100` | 1..100 ჯამი | exit=186 (5050 mod 256) |
| I | `w1d4_array_max` | მასივის max | exit=42 |
| I | `w1d5_print_int` | int → ASCII | stdout=`5050` |
| II | `w2d1_add_function` | `add(10,20)` | exit=30 |
| II | `w2d2_factorial` | `5!` | exit=120 |
| II | `w2d3_strlen` | `strlen("Hello World")` | exit=11 |
| II | `w2d4_popcount` | popcount | exit=6 |
| II | `w2d4_is_power_of_two` | 64 | exit=1 |
| II | `w2d4_xor_swap` | xor-ით გაცვლა | exit=20 |
| II | `w2d5_calculator` | კალკულატორი | 5 შემთხვევა stdin-იდან |
| III | `w3d2_sum_array` | C ↔ asm | stdout=`15` |
| III | `w3d2_to_upper` | C ↔ asm | stdout=`HELLO, ASM` |
| III | `w3d3_sum_ids` | struct-ები | stdout=`60` |
| III | `w3d4_simd_add` | SSE + tail | stdout=`48.00` |
| IV | `w4d1_bufov` | overflow → secret | მარკერი `SECRET_REACHED` |

ხუთი დავალება (`w3d1`, `w3d5`, `w4d2`, `w4d3`, `w4d4`) ავტომატურად არ
შემოწმდება — ტესტი მათთვის კრიტერიუმებსა და gdb-ის ნაბიჯებს ბეჭდავს.

**რას ნიშნავს ტესტის სიმბოლოები:**

| სიმბოლო | მნიშვნელობა |
| ------- | ----------- |
| `✓` | გავიდა |
| `✗` | არ გამოვიდა (შედეგი არ ემთხვევა) |
| `○` | ჯერ არ არის დაწერილი ან ხელით საშემოწმებელია |
| `!` | ვერ შემოწმდა (ტექნიკური მიზეზი) |

## 🔍 როგორ ვმუშაობ, როცა არ გამოდის

1. `.` არ დაგავიწყდეს: `./run-tests.sh`, არა `run-tests.sh`.
2. წაიკითხე ჩავარდნილი ხაზის ქვეშ დაბეჭდილი **იდეა** და **gdb**.
3. არ გეყო? `./run-tests.sh --guide <id>` — სრული გაიდლაინი
   (`GUIDELINES.md`-იდან).
4. ჯერ კიდევ გაუგებარია? დაუბრუნდი კვირის თეორიას: ყოველი გაიდლაინი
   მიუთითებს კონკრეტულ სექციას (`წყარო:`).

## შემდეგი ნაბიჯი

```bash
chmod +x test-env/*.sh
cd test-env
./quickstart.sh        # ან: ./verify.sh && ./run-tests.sh --list
```
