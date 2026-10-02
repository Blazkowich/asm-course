# III კვირა: C-თან კავშირი და რეალური კოდი

> **დონე:** საშუალო (I და II კვირები აუცილებელია)
> **დრო:** ~10 საათი
> **მიზანი:** დააკავშირო Assembly და C, გაიგო რეალური compiler-ის კოდი.

---

## 🧭 სანამ დაიწყებ

- C-ის საბაზისო ცოდნა დაგჭირდება (`int`, `struct`, pointer, ფუნქცია).
  თუ არ იცი — გაიარე 30-წუთიანი tutorial, მერე დაბრუნდი.
- დარწმუნდი, რომ II კვირის checklist სრულად გაქვს.
- ამ კვირაში **პირველად** დაინახავ libc ფუნქციებს asm-დან.
  მთავარი ცნება: **stack alignment** — თუ არასწორია, `printf` ჩავარდება.

---

## I დღე: Compiler-ის გენერირებული asm

### 1. როგორ ვნახოთ

```bash
gcc -S -masm=intel -O0 -fno-asynchronous-unwind-tables -o out.s test.c
gcc -S -masm=intel -O2 -fno-asynchronous-unwind-tables -o out.s test.c
```

````

- `-S`: შეაჩერე asm-ზე
- `-masm=intel`: Intel სინტაქსი (ნაგულისხმევი AT&T არის: `mov %rdi, %rax`,
  მიმღები მარჯვნივ)
- `-fno-asynchronous-unwind-tables`: ამოაგდებს `.cfi_*` ხმაურს

ალტერნატივა: **godbolt.org** (Compiler Explorer). აირჩიე C, x86-64 gcc,
დააყენე `-O0` / `-O2` და ქვედა ფანჯარაში ხედავ asm-ს ხაზობრივი ფერებით.

### 2. `-O0` vs `-O2`

```c
int add(int a, int b) { return a + b; }
```

**`-O0`** (არაოპტიმიზებული, დაახლოებით ასეთი გამოდის):

```nasm
add:
    push rbp
    mov  rbp, rsp
    mov  DWORD PTR [rbp-4], edi
    mov  DWORD PTR [rbp-8], esi
    mov  edx, DWORD PTR [rbp-4]
    mov  eax, DWORD PTR [rbp-8]
    add  eax, edx
    pop  rbp
    ret
```

**`-O2`:**

```nasm
add:
    lea  eax, [rdi+rsi]
    ret
```

დასკვნა:

- `-O0`: ყოველი ცვლადი stack-ზეა (`[rbp-N]`), ყოველი ხაზი "პირდაპირ"
  ითარგმნება. გასაგებად წასაკითხია და **სწავლისთვის საუკეთესოა**
- `-O2`: ყველაფერი რეგისტრებშია, ფუნქციები შესაძლოა ჩაიშალოს (inline),
  ციკლები გადალაგდეს, არითმეტიკა `lea`-ით ან shift-ით ჩანაცვლდეს.
  ხანდახან კოდი თავდაპირველისგან სრულიად განსხვავებულად გამოიყურება

### 3. ტიპიური პატერნები

| C კოდი              | რას ეძებ asm-ში                                   |
| ------------------- | ------------------------------------------------- |
| `if (a > b)`        | `cmp` + `jle` (საპირისპირო პირობა)                |
| `for` / `while`     | უკან მიმართული `jmp`/`jcc`                        |
| `arr[i]` (int)      | `[rdi + rax*4]`                                   |
| `s->field`          | `[rdi + offset]`                                  |
| `x * 5`             | `lea eax, [rdi + rdi*4]`                          |
| `x / 2` (signed)    | `shr` + `add` + `sar` (ნიშნის კორექტირებით)       |
| ფუნქციის გამოძახება | არგუმენტები `rdi, rsi, ...`, `call`, შედეგი `rax` |
| `switch`            | ხშირად jump table (მისამართების მასივი)           |
| `x % 2 == 0`        | `test al, 1` / `and`                              |

### 4. რჩევა

1. დაწერე პატარა C ფუნქცია
2. **ჯერ თავად იწინასწარმეტყველე**, რას დააგენერირებს
3. შეადარე რეალურ გამოსავალს
4. ყოველი ხაზი ახსენი: რას აკეთებს, რატომ ამ რეგისტრში

`-O2`-ის კითხვისას თუ რაიმე გაუგებარია, გამორთე ერთი ოპტიმიზაცია და ნახე
რა იცვლება (`-O1`, `-fno-inline`).

### 🧪 დავალება

დაწერე 5 მარტივი C ფუნქცია:

1. ჯამი — `int add(int a, int b)`
2. ციკლი — `int sum_to(int n)`
3. `if` — `int max(int a, int b)`
4. მასივზე წვდომა — `int get(int *arr, int i)`
5. struct — `struct Point { int x, y; }; int manhattan(struct Point *p)`

თითოეულის asm აუხსენი საკუთარ თავს ხაზ-ხაზ (ორივე `-O0` და `-O2`).

---

## II დღე: C ↔ Assembly

### 1. `main` და libc-ის გამოყენება

აქამდე გვქონდა `_start`. თუ გინდა `printf`, `malloc` და სხვა libc
ფუნქციები, უმარტივესი გზაა gcc-ით დალინკვა და `main`-ის გამოყენება
(gcc თვითონ ამატებს `_start`-ს, რომელიც libc-ს ინიციალიზებას აკეთებს და
`main`-ს იძახებს).

```bash
nasm -f elf64 prog.asm -o prog.o
gcc -no-pie prog.o -o prog
```

`-no-pie` აადვილებს აბსოლუტურ მისამართებს. პროგრამა `exit`-ის გარეშე
შეიძლება `main`-იდან `ret`-ით დასრულდეს (`eax` = exit code).

### 2. `printf` გამოძახება

```nasm
default rel                 ; RIP-ზე დამოკიდებული მისამართვა
extern printf
global main

section .rodata
fmt db "Result: %d", 10, 0  ; null-terminated

section .text
main:
    push rbp                ; alignment-ს ასწორებს (rsp ≡ 8 -> 0 mod 16)
    mov  rbp, rsp

    lea  rdi, [fmt]         ; 1-ლი არგუმენტი: ფორმატი
    mov  esi, 42            ; მე-2: %d-ის მნიშვნელობა
    xor  eax, eax           ; variadic ფუნქცია: al = ვექტორული რეგისტრების რაოდენობა
    call printf wrt ..plt

    xor  eax, eax           ; return 0
    pop  rbp
    ret
```

**რატომ მნიშვნელოვანია თითოეული დეტალი:**

- **`xor eax, eax` printf-ის წინ:** variadic ფუნქციები (`printf`) `al`-ში
  ელიან xmm რეგისტრების რაოდენობას. თუ `al` ნაგავია, შეიძლება crash მიიღო.
- **Alignment:** `main`-ში შესვლისას `rsp ≡ 8 (mod 16)`. `push rbp` → `≡ 0`.
  `call printf` უსაფრთხოა. თუ ლოკალურ ცვლადებს გამოყოფ (`sub rsp, N`),
  N 16-ის ჯერადი უნდა იყოს.
- **`wrt ..plt`:** დინამიკურად დალინკვადი ფუნქციის გამოძახების ფორმა
  PIE/PLT-თან თავსებადობისთვის.
- **Callee-saved რეგისტრები:** `printf` გამოძახების შემდეგ `rax`, `rcx`,
  `rdx`, `rsi`, `rdi`, `r8`-`r11` დაკარგულია. თუ გჭირდება, შეინახე
  `rbx`/`r12`-`r15`-ში.

### 2.1 `extern` / `global`

```nasm
global my_func       ; სხვა ფაილებისთვის (C-ისთვის) ხილვადი
extern puts          ; სხვა ადგილას განსაზღვრულია, linker იპოვის
```

### 3. asm ფუნქცია C-დან გამოსაძახებლად

C მხარე:

```c
#include <stdio.h>
#include <stddef.h>

extern int sum_array(const int *arr, size_t n);

int main(void) {
    int data[] = {1, 2, 3, 4, 5};
    printf("%d\n", sum_array(data, 5));
    return 0;
}
```

ASM მხარის კონტრაქტი: `rdi = arr`, `rsi = n`, შედეგი `eax`. ელემენტებს
`int` ტიპის გამო `[rdi + rcx*4]`-ით კითხულობ.

Build:

```bash
nasm -f elf64 sum.asm -o sum.o
gcc -no-pie main.c sum.o -o prog
```

**ტიპების ზომა:** `int` = 4 ბაიტი (`eax`), `size_t`/pointer = 8 ბაიტი
(`rax`), `char` = 1 ბაიტი. არგუმენტი `int` ტიპისაა → გამოიყენე `edi`,
არა `rdi`. 32-ბიტიანი არგუმენტის ზედა ნაწილი ნაგავი შეიძლება იყოს.

### 4. C# ანალოგია

თუ C#-დან native ფუნქციას იძახებ, **P/Invoke** (`[DllImport]`) ზუსტად ამ
calling convention-ით მუშაობს (Linux-ზე System V). marshaling ამ დეტალს
უმალავს, მაგრამ ქვემოთ იგივე რეგისტრებია.

### 🧪 დავალება

1. დაწერე asm ფუნქცია `sum_array(int*, size_t)` და გამოიძახე C-ის
   `main`-იდან.
2. გამოიძახე `printf` asm-იდან.
3. დაწერე asm ფუნქცია `void to_upper(char *s)` და გამოიძახე C-იდან.

### 🐛 ხშირი შეცდომები

- **`printf`-მდე `xor eax, eax` არ გააკეთე** → crash ან უცნაური შედეგი.
- **`sub rsp, N` სადაც N კენტია** → alignment გატყდა → `movaps` crash.
- **`int` არგუმენტს `rdi`-ით კითხულობ** (`edi` ნაცვლად) → ზედა 32 ბიტი
  ნაგავია.
- **`printf`-ის შემდეგ `rsi`/`rdi` გამოიყენე** → ისინი caller-saved-ია.

---

## III დღე: მეხსიერების განლაგება

### 1. გასწორება (alignment)

CPU უფრო სწრაფად (და ზოგჯერ ექსკლუზიურად) მუშაობს ისეთ მონაცემებთან,
რომლის მისამართი მისივე ზომის ჯერადია:

| ტიპი                      | ზომა | გასწორება |
| ------------------------- | ---- | --------- |
| `char`                    | 1    | 1         |
| `short`                   | 2    | 2         |
| `int`, `float`            | 4    | 4         |
| `long`, `double`, pointer | 8    | 8         |

### 2. struct padding

```c
struct S {
    int    id;      // offset 0,  ზომა 4
    char   flag;    // offset 4,  ზომა 1
                    // padding: 3 ბაიტი (offset 5-7)
    double value;   // offset 8,  ზომა 8
};                  // სულ: 16 ბაიტი
```

წესები:

1. თითოეული ველი თავის გასწორების ჯერად offset-ზეა
2. struct-ის მთლიანი ზომა მისი ყველაზე დიდი ველის გასწორების ჯერადია
   (ბოლოში ემატება padding)
3. **ველების რიგს მნიშვნელობა აქვს:** `{char, double, char}` = 24 ბაიტი,
   ხოლო `{double, char, char}` = 16

შეამოწმე `offsetof(struct S, flag)` და `sizeof(struct S)`.

### 3. მასივი struct-ებისგან

ელემენტის მისამართი: `base + i * sizeof(S)`. თუ ზომა 1, 2, 4, 8-ია,
scale-ს პირდაპირ იყენებ. 16 ან 24-ის შემთხვევაში scale მიუწვდომელია:

```nasm
; rbx = base, rcx = i, struct ზომა 16
mov  rax, rcx
shl  rax, 4                 ; i * 16
; ან: imul rax, rcx, 16
mov  edx, [rbx + rax + 0]   ; .id
movsx r8d, byte [rbx + rax + 4]   ; .flag
movsd xmm0, [rbx + rax + 8] ; .value (double)
```

### 4. Pointer arithmetic

C-ში `p + 1` ზრდის მისამართს `sizeof(*p)`-ით. asm-ში ასეთი ავტომატიზმი
არ არის: **ზომა შენ უნდა გაამრავლო**. ეს ყველაზე ხშირი შეცდომაა `int*`-ის
გავლისას (`+1` მის ნაცვლად `+4`).

### 5. C# ანალოგები

```csharp
[StructLayout(LayoutKind.Sequential)]
struct S { public int Id; public byte Flag; public double Value; }

int size = Unsafe.SizeOf<S>();                       // 16
IntPtr off = Marshal.OffsetOf<S>(nameof(S.Flag));    // 4
```

- `LayoutKind.Sequential`: ველები გამოცხადების რიგით, padding-ით C-ის მსგავსად
- `LayoutKind.Explicit` + `[FieldOffset]`: offset-ები ხელით
- `Span<T>`: ფაქტობრივად **pointer + length** წყვილია, ანუ ორი რეგისტრი
  (`rdi`, `rsi`)
- `ref` / `ref struct`: ელემენტის მისამართი

### 6. Debug

```
(gdb) p sizeof(struct S)
(gdb) p &((struct S*)0)->flag        ; offset-ის ფანდი
(gdb) x/16xb &arr[0]                 ; padding ბაიტები ხილულია
```

### 🧪 დავალება

1. ააგე struct `{int id; char flag; double value;}`.
2. გამოთვალე ზომა ხელით (16 ბაიტი).
3. შეამოწმე `sizeof`-ით.
4. დაწერე asm კოდი, რომელიც ამ struct-ის მასივს გადის და `id`-ებს აჯამებს.

---

## IV დღე: SIMD შესავალი

### 1. რა არის SIMD

**Single Instruction, Multiple Data**: ერთი ინსტრუქცია ერთდროულად რამდენიმე
მნიშვნელობაზე მუშაობს.

x86-64-ზე **SSE2 ყოველთვის არის**. 16 რეგისტრი `xmm0`-`xmm15`, თითო 128 ბიტი:

```
xmm0:  [ float | float | float | float ]     4 × 32 ბიტი
       [   double    |    double      ]      2 × 64 ბიტი
       [ 16 × int8 ] ან [ 8 × int16 ] ან [ 4 × int32 ] ...
```

უფრო ახალი: **AVX/AVX2** (`ymm`, 256 ბიტი), **AVX-512** (`zmm`, 512 ბიტი).
ეს გზამკვლევი SSE-ით შემოიფარგლება.

### 2. ძირითადი ინსტრუქციები

| ინსტრუქცია                | მოქმედება                                                        |
| ------------------------- | ---------------------------------------------------------------- |
| `movups xmm0, [mem]`      | 4 float ჩატვირთვა, **unaligned**                                 |
| `movaps xmm0, [mem]`      | იგივე, მაგრამ მისამართი **16-ის ჯერადი** უნდა იყოს (თორემ crash) |
| `movss`                   | 1 float (scalar)                                                 |
| `addps xmm0, xmm1`        | 4 float-ის პარალელური შეკრება                                    |
| `subps`, `mulps`, `divps` | გამოკლება, გამრავლება, გაყოფა                                    |
| `addss`                   | მხოლოდ 1 float                                                   |
| `movups [mem], xmm0`      | შენახვა                                                          |
| `pxor xmm0, xmm0`         | ნულით შევსება                                                    |
| `cvtsi2ss xmm0, eax`      | int → float                                                      |
| `cvttss2si eax, xmm0`     | float → int (ჭრით)                                               |

სუფიქსები: `ps` = packed single (4 float), `pd` = packed double,
`ss` = scalar single, `sd` = scalar double.

### 3. float-ების გადაცემა ფუნქციაში

System V ABI-ში float/double არგუმენტები `xmm0`-`xmm7`-ში გადაეცემა,
ინტეგერებისგან **დამოუკიდებლად**:

```c
float f(int a, float b, float c);   // a -> edi, b -> xmm0, c -> xmm1
// დაბრუნება -> xmm0
```

### 4. მასივების დამატება ბლოკებად

```
C = A + B,  N ელემენტი, 4-ის ბლოკებით:

i = 0
while i + 4 <= N:
    xmm0 = load(A + i)
    xmm1 = load(B + i)
    xmm0 = xmm0 + xmm1
    store(C + i, xmm0)
    i += 4
// დარჩენილი (N mod 4) ელემენტი: ჩვეულებრივი scalar ციკლი
```

ბოლო ნაწილი (tail/remainder) აუცილებელია, როცა `N` 4-ის ჯერადი არ არის.

```nasm
movups xmm0, [rdi + rcx*4]      ; rdi = A, ინდექსი rcx (ელემენტებში)
movups xmm1, [rsi + rcx*4]      ; rsi = B
addps  xmm0, xmm1
movups [rdx + rcx*4], xmm0      ; rdx = C
add    rcx, 4
```

### 5. პრაქტიკული შენიშვნები

- `float` მონაცემები განსაზღვრე `dd 1.5, 2.5, ...` (NASM-ში `dd` + წილადი = float)
- float-ების დაბეჭდვა `printf`-ით: `double`-ზე გადაყვანა სჭირდება
  (`cvtss2sd`) და `al = 1` (1 xmm რეგისტრი)
- **horizontal sum:** `haddps` (SSE3), ერთი რეგისტრის 4 ელემენტის შეკრება
- ბევრი compiler `-O3`-ზე ასეთ ციკლს ავტომატურად ვექტორიზებს
  (auto-vectorization). შეგიძლია `gcc -O3 -S`-ით ნახო

### 6. C# ანალოგი

`System.Numerics.Vector<T>` და `System.Runtime.Intrinsics`
(`Vector128<float>`, `Sse.Add`) ზუსტად ამავე ინსტრუქციებს გამოიყენებს.
ბევრი .NET-ის ბიბლიოთეკა (მაგ. `string.IndexOf`, `Array.Sort`) შიგნით
SIMD-ს იყენებს.

### 🧪 დავალება

1. დაამატე ორი float მასივი 4-4 ელემენტიანი ბლოკებით SSE-ით.
2. გაუმკლავდი დარჩენილ ელემენტებს (tail).
3. სცადე `movaps` vs `movups` — ნახე როდის ვარდება.

---

## V დღე: Debugging

### 1. gdb: ძირითადი ბრძანებები

```
gdb ./prog
(gdb) set disassembly-flavor intel
(gdb) break main            ; ან break *0x401000, break file.asm:12
(gdb) run
(gdb) stepi / si            ; ერთი ინსტრუქცია (call-შიც შედის)
(gdb) nexti / ni            ; ერთი ინსტრუქცია (call-ს გადაახტება)
(gdb) continue / c
(gdb) finish                ; ფუნქციის დასრულებამდე
(gdb) info registers        ; ყველა რეგისტრი
(gdb) p/x $rax              ; ერთი რეგისტრი hex-ში
(gdb) x/8gx $rsp            ; stack: 8 qword hex-ში
(gdb) x/10i $rip            ; შემდეგი 10 ინსტრუქცია
(gdb) x/s <addr>            ; სტრიქონი
(gdb) display/i $rip        ; ყოველ ნაბიჯზე აჩვენე მიმდინარე ინსტრუქცია
(gdb) layout asm            ; ან: layout regs
(gdb) watch *(long*)0x...   ; watchpoint: როცა მეხსიერება შეიცვლება
(gdb) bt                    ; backtrace
(gdb) info proc mappings
```

**`~/.gdbinit`-ში ჩაწერე:**

```
set disassembly-flavor intel
```

რეკომენდებული გაფართოებები: **GEF**, **pwndbg**, **peda**: ავტომატურად
აჩვენებენ რეგისტრებს, stack-ს და კოდს ყოველ ნაბიჯზე.
(ინსტალაცია ინტერნეტში გადაამოწმე.)

### 2. `objdump`

```bash
objdump -d -M intel prog                 # მთელი disassembly
objdump -d -M intel --no-show-raw-insn prog | less
objdump -s -j .data prog                 # სექციის ბაიტები
objdump -h prog                          # სექციები
```

### 3. `strace`

```bash
strace ./prog
strace -e trace=write,read ./prog
```

აჩვენებს ყველა syscall-ს არგუმენტებითა და დასაბრუნებელი მნიშვნელობებით.
ძალიან გამოდგება, როცა `write` არ მუშაობს ან `read` არასწორ ბაიტებს
აბრუნებს. ამ დონეზე `strace` აჩვენებს ზუსტად იმას, რასაც `rdi, rsi, rdx`
შეიცავდა.

### 4. Segfault-ის ტიპიური მიზეზები

| მიზეზი                                | როგორ გამოიცნობ                                       |
| ------------------------------------- | ----------------------------------------------------- |
| NULL ან ცუდი pointer-ის dereference   | gdb-ში ხაზზე `mov rax, [rbx]` და `rbx = 0`            |
| `ret` ცუდ მისამართზე (stack გაფუჭდა)  | `rip` უცნაური მნიშვნელობა (მაგ. `0x4141414141414141`) |
| `exit` არ გამოიძახე: კოდი "მიედინება" | პროგრამა მთავრდება `.text`-ის ბოლოს შემდეგ            |
| `movaps` არაგასწორებულ მისამართზე     | crash `movaps` ინსტრუქციაზე                           |
| stack alignment libc ფუნქციაში        | crash `printf` ან `puts` სიღრმეში                     |
| `.rodata`-ზე ჩაწერა                   | write read-only მისამართზე                            |

### 5. workflow segfault-ის გამოსაკვლევად

```
(gdb) run
Program received signal SIGSEGV...
(gdb) x/i $rip              ; რომელ ინსტრუქციაზე
(gdb) info registers        ; რომელ რეგისტრში არის ცუდი მისამართი
(gdb) bt                    ; ვინ გამოიძახა
(gdb) x/16gx $rsp           ; stack
```

`dmesg | tail` (Linux) ხშირად აჩვენებს segfault-ის მისამართსა და `ip`-ს.

### 6. ჩვევა

ყოველი ახალი ფუნქცია:

1. წინასწარ დაწერე კომენტარით (რა არგუმენტები, რა ბრუნდება)
2. gdb-ში გაიარე სრული ნაბიჯით
3. შეამოწმე, რომ `rsp` იგივე მნიშვნელობაზე ბრუნდება, რაც ფუნქციაში
   შესვლისას იყო
4. შეამოწმე, რომ callee-saved რეგისტრები უცვლელია

### 🧪 დავალება

1. დაწერე განზრახ segfault-იანი პროგრამა (`mov rax, [0]`).
2. იპოვე მიზეზი gdb-ით: `x/i $rip`, `info registers`, `bt`.
3. გაასწორე და ხელახლა გაუშვი.

---

## ✅ კვირის შეჯამება

**რაც უნდა შეგეძლოს III კვირის ბოლოს:**

- [ ] C კოდის გენერირებული asm-ის წაკითხვა `-O0` და `-O2`-ზე
- [ ] asm ფუნქციის გამოძახება C-დან და პირიქით (`printf`)
- [ ] struct offset-ებისა და padding-ის გამოთვლა ხელით
- [ ] `xmm` რეგისტრებით 4 float-ის პარალელური დამუშავება
- [ ] `gdb`, `objdump -M intel` და `strace` თავისუფლად გამოყენება
- [ ] segfault-ის მიზეზის პოვნა
````
