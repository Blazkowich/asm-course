# გარემოს მომზადება

**მიზანი:** 4 კვირის განმავლობაში გქონდეს სტაბილური, გამართული Linux გარემო,
სადაც `nasm`, `ld`, `gcc`, `gdb`, `objdump`, `strace` მუშაობს.

აირჩიე **ერთი** ვარიანტი ქვემოთ.

---

## ვარიანტი 1: Docker (რეკომენდირებული დამწყებთათვის)

**უპირატესობა:** არ ეხება შენს სისტემას, სუფთაა, განმეორებადი.

### 1.1 Docker-ის დაყენება

- **Windows:** [Docker Desktop](https://www.docker.com/products/docker-desktop)
  (აუცილებელია WSL2 backend ჩართული იყოს)
- **Linux:** `sudo apt install docker.io` (Ubuntu/Debian)

შემოწმება:

```bash
docker --version
# უნდა დაიბეჭდოს: Docker version 20.x.x ან უფრო ახალი
```

### 1.2 კურსის გარემოს ჩაშვება

```bash
cd test-env
docker build -t asm-course .
docker run --rm -it -v "$PWD/..:/work" asm-course
```

ახლა კონტეინერში ხარ. შიგნით:

```bash
cd /work
nasm --version
gcc --version
gdb --version
```

თუ ყველა ბეჭდავს ვერსიას — მზადაა.

### 1.3 კოდის რედაქტირება

გირჩევ, ფაილები შექმნა **შენს host სისტემაზე** (VS Code, Vim, ნებისმიერი
რედაქტორი) `./work` საქაღალდეში, რომელიც კონტეინერს მიბმულია.

---

## ვარიანტი 2: WSL2 (Windows)

### 2.1 WSL2-ის ჩართვა

PowerShell-ში (ადმინისტრატორის უფლებებით):

```powershell
wsl --install -d Ubuntu-22.04
```

გადატვირთე კომპიუტერი. პირველი გაშვებისას შექმენი Linux მომხმარებელი.

### 2.2 ინსტრუმენტების დაყენება

WSL ტერმინალში:

```bash
sudo apt update
sudo apt install -y nasm gcc gdb binutils strace make git
```

### 2.3 VS Code ინტეგრაცია (სასურველი)

Windows-ზე დააყენე VS Code + გაფართოება **WSL**.
WSL ტერმინალში გაუშვი `code .` — გაიხსნება VS Code Linux ფაილებზე.

---

## ვარიანტი 3: Native Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y nasm gcc gdb binutils strace make git
```

Fedora-სთვის:

```bash
sudo dnf install -y nasm gcc gdb binutils strace make git
```

---

## § 4. ინსტრუმენტების შემოწმება

გაუშვი `test-env/verify.sh` ან ხელით:

```bash
nasm -v              # NASM version 2.x
ld --version         # GNU ld 2.x
gcc --version        # gcc 11+
gdb --version        # gdb 12+
objdump --version    # binutils
strace -V            # strace 5+
```

თუ რომელიმე არ არსებობს → დააყენე შესაბამისი პაკეტი.

### 4.1 პირველი ტესტი

შექმენი `hello.asm`:

```nasm
global _start
section .text
_start:
    mov rax, 60      ; sys_exit
    mov rdi, 42      ; exit code
    syscall
```

ააწყვე და გაუშვი:

```bash
nasm -f elf64 -g -F dwarf hello.asm -o hello.o
ld hello.o -o hello
./hello
echo $?              # უნდა დაბეჭდოს: 42
```

თუ `42` დაინახე — გარემო მზადაა. 🎉

### 4.2 gdb-ის კონფიგურაცია

შექმენი `~/.gdbinit`:

```bash
echo "set disassembly-flavor intel" > ~/.gdbinit
```

ამის შემდეგ gdb ყოველთვის Intel სინტაქსს გამოიყენებს.

---

## § 5. ხშირი პრობლემები

| სიმპტომი                        | მიზეზი                    | გამოსავალი                                |
| ------------------------------- | ------------------------- | ----------------------------------------- |
| `nasm: command not found`       | არ არის დაყენებული        | `sudo apt install nasm`                   |
| `ld: cannot find -lc`           | libc არ ჩანს              | `sudo apt install libc6-dev`              |
| `gdb` არ აჩვენებს წყაროს ხაზებს | `-g -F dwarf` აკლია       | ააწყვე ისევ სწორი flags-ით                |
| `Permission denied` Docker-ში   | Docker daemon-ის უფლებები | `sudo usermod -aG docker $USER` + relogin |
| WSL: ფაილები ნელია              | ფაილები `/mnt/c/...`-შია  | გადაიტანე `~/work`-ში                     |
| `movaps` crash                  | stack alignment           | `push rbp` გამოძახებამდე                  |

### 5.1 როგორ გავიგო, რომელი ბიბლიოთეკა მაკლია

```bash
ldd ./prog          # აჩვენებს, რომელ .so ფაილებს ეძებს
```

### 5.2 Docker-ში ფაილების შენახვა

```bash
# კონტეინერიდან გასვლის გარეშე შექმენი ფაილი /work-ში
# შენს host-ზე ის გამოჩნდება ./ (ანუ asm-course/-ში)
```

---

## § 6. რედაქტორის რეკომენდაცია

- **VS Code** + გაფართოებები: `NASM` (syntax), `GDB Debugger`
- **Vim/Neovim** + `asm-lsp` (syntax + autocomplete)
- **Sublime Text** + `NASM x86 Assembly` package

თუ VS Code-ს იყენებ, `launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug asm",
      "type": "cppdbg",
      "request": "launch",
      "program": "${workspaceFolder}/prog",
      "MIMode": "gdb",
      "miDebuggerPath": "/usr/bin/gdb",
      "externalConsole": false
    }
  ]
}
```

---

## § 7. Build-ის ავტომატიზაცია

შექმენი `Makefile` პროექტის ძირში:

```makefile
ASM  := nasm
LD   := ld
AFLAGS := -f elf64 -g -F dwarf
LFLAGS :=

%.o: %.asm
	$(ASM) $(AFLAGS) $< -o $@

%: %.o
	$(LD) $(LFLAGS) $< -o $@

run: %
	./$<; echo "exit: $$?"

clean:
	rm -f *.o prog hello
```

გამოყენება:

```bash
make hello        # ააწყობს
make run hello    # გაუშვებს და დაბეჭდავს exit code-ს
make clean        # წაშლის .o და binaries
```

---

## ✅ Setup Checklist

- [ ] Docker/WSL2/Native გარემო არჩეულია
- [ ] `nasm`, `ld`, `gcc`, `gdb`, `objdump`, `strace` დაყენებულია
- [ ] `~/.gdbinit`-ში `set disassembly-flavor intel` ჩაწერილია
- [ ] `hello.asm` ააწყო და `./hello; echo $?` დაბეჭდა `42`
- [ ] gdb-ში შედი, `stepi` გააკეთე და `rax` ნახე
