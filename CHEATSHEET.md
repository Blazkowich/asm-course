# Assembly Cheatsheet (x86-64, NASM)

სწრაფი ცნობარი. ბეჭდე და მაგიდაზე დაიდე.

---

## რეგისტრები

### 64-ბიტიანი ზოგადი რეგისტრები

| 64         | 32           | 16           | 8            | ტრადიციული როლი              |
| ---------- | ------------ | ------------ | ------------ | ---------------------------- |
| `rax`      | `eax`        | `ax`         | `al`/`ah`    | დაბრუნება, syscall ნომერი    |
| `rbx`      | `ebx`        | `bx`         | `bl`/`bh`    | callee-saved                 |
| `rcx`      | `ecx`        | `cx`         | `cl`/`ch`    | მთვლელი, 4-ე არგ.            |
| `rdx`      | `edx`        | `dx`         | `dl`/`dh`    | 3-ე არგ., `mul`/`div`        |
| `rsi`      | `esi`        | `si`         | `sil`        | 2-ე არგ.                     |
| `rdi`      | `edi`        | `di`         | `dil`        | 1-ლი არგ.                    |
| `rbp`      | `ebp`        | `bp`         | `bpl`        | frame pointer (callee-saved) |
| `rsp`      | `esp`        | `sp`         | `spl`        | stack pointer (callee-saved) |
| `r8`-`r15` | `r8d`-`r15d` | `r8w`-`r15w` | `r8b`-`r15b` | დამატებითი                   |

### სპეციალური

| რეგისტრი | დანიშნულება             |
| -------- | ----------------------- |
| `rip`    | ინსტრუქციის მისამართი   |
| `rflags` | ZF, SF, CF, OF, DF, ... |

---

## Syscall (x86-64 Linux)

| რეგისტრი                               | რა                         |
| -------------------------------------- | -------------------------- |
| `rax`                                  | syscall ნომერი / დაბრუნება |
| `rdi`, `rsi`, `rdx`, `r10`, `r8`, `r9` | არგუმენტები 1-6            |

**ხშირი syscalls:**

| #   | სახელი  | არგუმენტები       |
| --- | ------- | ----------------- |
| 0   | `read`  | fd, buf, count    |
| 1   | `write` | fd, buf, count    |
| 2   | `open`  | path, flags, mode |
| 3   | `close` | fd                |
| 60  | `exit`  | status            |

`syscall` ანგრევს: `rcx`, `r11`.

---

## Calling convention (System V AMD64)

### არგუმენტები

`rdi`, `rsi`, `rdx`, `rcx`, `r8`, `r9` (მე-7+ → stack)

### დაბრუნება

`rax` (და `rdx` თუ 128 ბიტი)

### Caller-saved (volatile)

`rax`, `rcx`, `rdx`, `rsi`, `rdi`, `r8`, `r9`, `r10`, `r11`

### Callee-saved (non-volatile)

`rbx`, `rbp`, `r12`, `r13`, `r14`, `r15`, `rsp`

### Stack alignment

`call`-ის მომენტში `rsp` უნდა იყოს 16-ის ჯერადი. ფუნქციაში შესვლისას
`rsp ≡ 8 (mod 16)`.

---

## ძირითადი ინსტრუქციები

### მონაცემთა გადაადგილება

```nasm
mov  dst, src              ; dst = src
movzx dst, src             ; zero-extend
movsx dst, src             ; sign-extend
movsxd rax, ebx            ; 32→64 sign-extend
lea  rax, [expr]           ; მისამართის გამოთვლა (memory არ იკითხება)
push rax                   ; rsp -= 8; [rsp] = rax
pop  rax                   ; rax = [rsp]; rsp += 8
```

### არითმეტიკა

```nasm
add  dst, src              ; dst += src
sub  dst, src              ; dst -= src
inc  dst                   ; dst++
dec  dst                   ; dst--
neg  dst                   ; dst = -dst
mul  src                   ; rdx:rax = rax * src (unsigned)
imul dst, src              ; dst *= src (signed, 2-operand)
imul dst, src, imm         ; dst = src * imm
div  src                   ; rax = rdx:rax / src; rdx = ნაშთი (unsigned)
idiv src                   ; signed
```

### ლოგიკური

```nasm
and  dst, src              ; bitwise AND
or   dst, src              ; bitwise OR
xor  dst, src              ; bitwise XOR
not  dst                   ; bitwise NOT
test dst, src              ; AND (შედეგს არ ინახავს, flags აყენებს)
```

### ცვლა / ბრუნვა

```nasm
shl  dst, n                ; მარცხნივ (× 2^n)
shr  dst, n                ; მარჯვნივ (unsigned)
sar  dst, n                ; მარჯვნივ (signed)
rol  dst, n                ; ბრუნვა მარცხნივ
ror  dst, n                ; ბრუნვა მარჯვნივ
shl  dst, cl               ; ცვლადი რაოდენობა (მხოლოდ cl)
```

### კონტროლი

```nasm
cmp  a, b                  ; a - b, flags აყენებს
jmp  label                 ; უპირობო
je / jz   label            ; თუ ტოლია (ZF=1)
jne / jnz label            ; თუ არ არის ტოლი
jl  label                  ; signed: a < b
jle label                  ; signed: a <= b
jg  label                  ; signed: a > b
jge label                  ; signed: a >= b
jb  label                  ; unsigned: a < b
jbe label                  ; unsigned: a <= b
ja  label                  ; unsigned: a > b
jae label                  ; unsigned: a >= b
call label                 ; push rip; jmp label
ret                        ; pop rip
```

### სტრიქონები

```nasm
cld                        ; DF = 0 (წინ)
std                        ; DF = 1 (უკან)
movsb                      ; [rdi] = [rsi]; rsi++, rdi++
stosb                      ; [rdi] = al; rdi++
lodsb                      ; al = [rsi]; rsi++
scasb                      ; cmp al, [rdi]; rdi++
rep                        ; გაიმეორე rcx ჯერ
repe / repz                ; გაიმეორე სანამ rcx≠0 და ZF=1
repne / repnz              ; გაიმეორე სანამ rcx≠0 და ZF=0
```

### ბიტური

```nasm
bt   rax, n                ; CF = bit n
bts  rax, n                ; bit n = 1
btr  rax, n                ; bit n = 0
btc  rax, n                ; bit n toggle
popcnt rax, rbx            ; rax = ბიტების რაოდენობა (SSE4.2)
bsf  rax, rbx              ; ყველაზე დაბალი ჩართული ბიტის ინდექსი
bsr  rax, rbx              ; ყველაზე მაღალი ჩართული ბიტის ინდექსი
```

---

## მეხსიერება

### მისამართვა

```
[ base + index*scale + disp ]
```

- `scale`: 1, 2, 4, 8
- `index` ≠ `rsp`

```nasm
mov eax, [rbx + rcx*4 + 8]
lea rax, [rbx + rcx*4 + 8]  ; მხოლოდ გამოთვლა
```

### ზომები

| NASM | ზომა  | ბაიტი |
| ---- | ----- | ----- |
| `db` | byte  | 1     |
| `dw` | word  | 2     |
| `dd` | dword | 4     |
| `dq` | qword | 8     |

```nasm
mov byte  [rbx], 1
mov word  [rbx], 1
mov dword [rbx], 1
mov qword [rbx], 1
```

### სექციები

| სექცია    | რა                                     |
| --------- | -------------------------------------- |
| `.text`   | კოდი (read+exec)                       |
| `.data`   | ინიციალიზებული მონაცემები (read+write) |
| `.rodata` | მხოლოდ წაკითხი (read-only)             |
| `.bss`    | ნულით ინიციალიზებული (read+write)      |

---

## NASM სინტაქსი

### სექციები და ლეიბლები

```nasm
global _start              ; გარედან ხილვადი
extern printf              ; გარედან შემოსული

section .data
    msg db "Hello", 10
    msg_len equ $ - msg    ; სიგრძე
    arr dd 1, 2, 3, 4

section .bss
    buf resb 64

section .text
_start:
    ; კოდი
```

### ლოკალური ლეიბლები

```nasm
func:
.loop:                     ; = func.loop
    jmp .loop
```

### კომენტარები

```nasm
; ერთხაზიანი
```

---

## ტიპიური პატერნები

### if/else

```nasm
    cmp  rax, rbx
    jle  .else
    ; then
    jmp  .end
.else:
    ; else
.end:
```

### for ციკლი

```nasm
    mov  rcx, 0
.loop:
    cmp  rcx, 10
    jge  .done
    ; სხეული
    inc  rcx
    jmp  .loop
.done:
```

### ოპტიმიზებული ციკლი

```nasm
    mov  rcx, 0
.loop:
    ; სხეული
    inc  rcx
    cmp  rcx, 10
    jl   .loop
```

### ფუნქცია

```nasm
my_func:
    push rbp
    mov  rbp, rsp
    sub  rsp, 32           ; ლოკალურებისთვის

    ; ...

    mov  rsp, rbp          ; ან: leave
    pop  rbp
    ret
```

### რიცხვის დაბეჭდვა (itoa)

```nasm
; input: rax = n
; output: buffer შევსებული, rax = სიგრძე
itoa:
    lea  rsi, [buf + 20]   ; ბოლოდან
    mov  rcx, 10
    xor  rdx, rdx
.loop:
    div  rcx
    add  dl, '0'
    dec  rsi
    mov  [rsi], dl
    xor  rdx, rdx
    test rax, rax
    jnz  .loop
    ; rsi = დასაწყისი
    ret
```

---

## gdb ბრძანებები

| ბრძანება            | რა                                  |
| ------------------- | ----------------------------------- |
| `run` / `r`         | გაუშვი                              |
| `break *addr` / `b` | breakpoint                          |
| `stepi` / `si`      | ერთი ინსტრუქცია (შედის call-ში)     |
| `nexti` / `ni`      | ერთი ინსტრუქცია (გამოტოვებს call-ს) |
| `continue` / `c`    | გააგრძელე                           |
| `info registers`    | ყველა რეგისტრი                      |
| `info reg rax rdi`  | კონკრეტული                          |
| `p/x $rax`          | hex-ში                              |
| `p $eflags`         | flags                               |
| `x/s &msg`          | სტრიქონი                            |
| `x/16xb &buf`       | 16 ბაიტი hex                        |
| `x/8gx $rsp`        | stack 8 qword                       |
| `x/10i $rip`        | 10 ინსტრუქცია                       |
| `layout asm`        | TUI asm                             |
| `layout regs`       | TUI რეგისტრები                      |
| `bt`                | backtrace                           |
| `finish`            | ფუნქციის დასრულებამდე               |

### x ფორმატი

`x/<count><format><size>`

- **format:** `x` (hex), `d` (dec), `s` (string), `i` (instruction)
- **size:** `b` (1), `h` (2), `w` (4), `g` (8)

---

## Build ბრძანებები

### NASM + ld (pure asm)

```bash
nasm -f elf64 -g -F dwarf prog.asm -o prog.o
ld prog.o -o prog
./prog; echo $?
```

### NASM + gcc (C interop)

```bash
nasm -f elf64 -g -F dwarf prog.asm -o prog.o
gcc -no-pie prog.o -o prog
./prog
```

### C → asm

```bash
gcc -S -masm=intel -O0 -fno-asynchronous-unwind-tables out.s test.c
gcc -S -masm=intel -O2 -fno-asynchronous-unwind-tables out.s test.c
```

### Debugging

```bash
objdump -d -M intel prog
strace ./prog
ltrace ./prog
strings prog
```

---

## ASCII / UTF-8

- `'0'` = 0x30, `'9'` = 0x39
- `'A'` = 0x41, `'Z'` = 0x5A
- `'a'` = 0x61, `'z'` = 0x7A
- newline = 0x0A, null = 0x00

**ASCII → ციფრი:** `sub al, '0'`
**ციფრი → ASCII:** `add al, '0'`

**ASCII → დიდი:** `and al, 0xDF` (მხოლოდ `'a'`-`'z'`)
**ASCII → პატარა:** `or al, 0x20` (მხოლოდ `'A'`-`'Z'`)

**UTF-8:** ASCII 1 ბაიტი, ქართული 3 ბაიტი. არასდროს არ გამოიყენო
ბაიტური ოპერაციები UTF-8 ტექსტზე!

---

## ხშირი შეცდომები

| ❌                                         | ✅                                   |
| ------------------------------------------ | ------------------------------------ |
| `div`-მდე `rdx` არ გაანულე                 | `xor rdx, rdx`                       |
| `mov [a], [b]`                             | `mov rax, [b]; mov [a], rax`         |
| `mov eax, 5` და `rax`-ის ზედა ნაწილს ელოდე | 32-bit write ანულებს ზედას           |
| `jl` unsigned-ზე                           | `jb` unsigned-ზე                     |
| `syscall`-ის შემდეგ `rcx` გამოიყენე        | `syscall` ანგრევს `rcx`, `r11`       |
| `printf`-მდე `xor eax, eax` არ გააკეთე     | variadic: `al` = xmm count           |
| `sub rsp, 12` (16-ის ჯერადი არა)           | `sub rsp, 16`                        |
| `call`-ის შემდეგ `rsp` არ აღადგინე         | `pop` შესაბამისი `push`-ისთვის       |
| `msg` და `[msg]` არევა                     | `lea rax, [msg]` vs `mov rax, [msg]` |

---

## CPU flags

| Flag | სახელი    | როდის                     |
| ---- | --------- | ------------------------- |
| ZF   | Zero      | შედეგი = 0                |
| SF   | Sign      | უარყოფითი                 |
| CF   | Carry     | unsigned overflow         |
| OF   | Overflow  | signed overflow           |
| DF   | Direction | string ops-ის მიმართულება |

---

## CPUID / შესაძლებლობები

```bash
grep flags /proc/cpuinfo | head -1
# ნახე: sse2, sse4_2, avx, avx2, ...
```

`popcnt` საჭიროებს `sse4_2`-ს.
