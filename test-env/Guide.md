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
    ├── verify.sh          (chmod +x)
    ├── run-tests.sh       (chmod +x)
    ├── quickstart.sh      (chmod +x)
    ├── Makefile
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
docker build -t asm-course .
docker run --rm -it -v "$PWD/..:/work" asm-course
# კონტეინერში:
cd /work/test-env
./verify.sh
./run-tests.sh
```

### ლოკალურად (თუ ინსტრუმენტები გაქვს)

```bash
cd asm-course/test-env/examples
make hello                 # ააწყვე
make run-hello             # გაუშვი
make debug-factorial       # gdb-ში
make                       # ყველა
make clean                 # წაშალე
```

## 📋 რას ამოწმებს `verify.sh`

1. **არქიტექტურა** — x86-64?
2. **ინსტრუმენტები** — nasm, ld, gcc, gdb, objdump, strace, make, python3
3. **კონფიგურაცია** — `~/.gdbinit`-ში Intel syntax?
4. **ფუნქციური ტესტები** — hello.asm build+run, C↔asm interop

## რას ამოწმებს `run-tests.sh`

| კვირა | ტესტი                     | მოსალოდნელი             |
| ----- | ------------------------- | ----------------------- |
| I     | `exit 42`                 | exit=42                 |
| I     | `(5+3)*4-2`               | exit=30                 |
| I     | `100 / 7` ნაშთი           | exit=2                  |
| I     | `"Hello"` write           | stdout="Hello"          |
| I     | 1..100 ჯამი               | exit=186 (5050 mod 256) |
| I     | მასივის max               | exit=42                 |
| II    | `add(10,20)`              | exit=30                 |
| II    | `5!`                      | exit=120                |
| II    | `popcount(0b10110111)`    | exit=6                  |
| II    | `is_power_of_two(64)`     | exit=1                  |
| III   | `sum_array({1..5})` C-დან | stdout="15"             |
| IV    | buffer overflow → secret  | "SECRET_REACHED"        |

## შემდეგი ნაბიჯი

დაასრულე ფაილების შექმნა და გაუშვი:

```bash
chmod +x test-env/*.sh
cd test-env
./quickstart.sh
```
