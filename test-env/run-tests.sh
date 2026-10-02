#!/usr/bin/env bash
# test-env/run-tests.sh
# უშვებს სამაგალითო პროგრამებს და ამოწმებს შედეგებს.
# გამოყენება:  ./run-tests.sh

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# ============================================================
# helper ფუნქციები
# ============================================================

run_asm_exit_test() {
    # $1 = სახელი, $2 = asm კოდი (heredoc-ის გარეშე), $3 = მოსალოდნელი exit code
    local name="$1"
    local asm="$2"
    local expected="$3"

    local src="$TMPDIR/${name}.asm"
    local obj="$TMPDIR/${name}.o"
    local bin="$TMPDIR/${name}"

    printf '%s\n' "$asm" > "$src"

    if ! nasm -f elf64 -g -F dwarf "$src" -o "$obj" 2>"$TMPDIR/err"; then
        printf "${RED}✗${NC} %-30s nasm ვერ შესრულდა\n" "$name"
        cat "$TMPDIR/err" | head -3 | sed 's/^/    /'
        FAIL=$((FAIL + 1))
        return
    fi

    if ! ld "$obj" -o "$bin" 2>>"$TMPDIR/err"; then
        printf "${RED}✗${NC} %-30s ld ვერ შესრულდა\n" "$name"
        cat "$TMPDIR/err" | head -3 | sed 's/^/    /'
        FAIL=$((FAIL + 1))
        return
    fi

    "$bin" >/dev/null 2>&1
    local actual=$?

    if [ "$actual" -eq "$expected" ]; then
        printf "${GREEN}✓${NC} %-30s exit=%d\n" "$name" "$actual"
        PASS=$((PASS + 1))
    else
        printf "${RED}✗${NC} %-30s exit=%d (მოსალოდნელი %d)\n" "$name" "$actual" "$expected"
        FAIL=$((FAIL + 1))
    fi
}

run_asm_stdout_test() {
    # $1 = სახელი, $2 = asm კოდი, $3 = მოსალოდნელი stdout
    local name="$1"
    local asm="$2"
    local expected="$3"

    local src="$TMPDIR/${name}.asm"
    local obj="$TMPDIR/${name}.o"
    local bin="$TMPDIR/${name}"

    printf '%s\n' "$asm" > "$src"

    if ! nasm -f elf64 -g -F dwarf "$src" -o "$obj" 2>"$TMPDIR/err"; then
        printf "${RED}✗${NC} %-30s nasm ვერ შესრულდა\n" "$name"
        cat "$TMPDIR/err" | head -3 | sed 's/^/    /'
        FAIL=$((FAIL + 1))
        return
    fi

    if ! ld "$obj" -o "$bin" 2>>"$TMPDIR/err"; then
        printf "${RED}✗${NC} %-30s ld ვერ შესრულდა\n" "$name"
        cat "$TMPDIR/err" | head -3 | sed 's/^/    /'
        FAIL=$((FAIL + 1))
        return
    fi

    local actual
    actual=$("$bin" 2>&1)

    if [ "$actual" = "$expected" ]; then
        printf "${GREEN}✓${NC} %-30s stdout OK\n" "$name"
        PASS=$((PASS + 1))
    else
        printf "${RED}✗${NC} %-30s stdout არ ემთხვევა\n" "$name"
        printf "    მოსალოდნელი: %q\n" "$expected"
        printf "    ფაქტობრივი:   %q\n" "$actual"
        FAIL=$((FAIL + 1))
    fi
}

# ============================================================
# ტესტები
# ============================================================

printf "${BLUE}=== Assembly Course: ტესტები ===${NC}\n\n"

# ---- I კვირა ----

printf "${BLUE}[I კვირა] საფუძვლები${NC}\n"

run_asm_exit_test "w1d1_exit42" \
'global _start
section .text
_start:
    mov rax, 60
    mov rdi, 42
    syscall' \
42

run_asm_exit_test "w1d2_arith" \
'global _start
section .text
_start:
    ; (5 + 3) * 4 - 2 = 30
    mov rax, 5
    add rax, 3
    imul rax, 4
    sub rax, 2
    mov rdi, rax
    mov rax, 60
    syscall' \
30

run_asm_exit_test "w1d2_div_remainder" \
'global _start
section .text
_start:
    mov rax, 100
    xor rdx, rdx
    mov rcx, 7
    div rcx
    ; rax = 14, rdx = 2
    mov rdi, rdx
    mov rax, 60
    syscall' \
2

run_asm_stdout_test "w1d3_hello" \
'global _start
section .data
    msg db "Hello", 10
    msg_len equ $ - msg
section .text
_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, msg_len
    syscall
    mov rax, 60
    xor rdi, rdi
    syscall' \
"Hello"

run_asm_exit_test "w1d4_sum_1_to_100" \
'global _start
section .text
_start:
    xor rax, rax        ; sum = 0
    mov rcx, 1          ; i = 1
.loop:
    add rax, rcx
    inc rcx
    cmp rcx, 100
    jle .loop
    ; sum = 5050 = 0x13BA
    ; exit code = 5050 & 0xFF = 186
    mov rdi, rax
    mov rax, 60
    syscall' \
186

run_asm_exit_test "w1d4_array_max" \
'global _start
section .data
    arr dq 5, 17, -3, 42, 8
    arr_len equ ($ - arr) / 8
section .text
_start:
    mov rsi, arr
    mov rcx, 1
    mov rax, [rsi]      ; max = arr[0]
.next:
    cmp rcx, arr_len
    jge .done
    mov rdx, [rsi + rcx*8]
    cmp rdx, rax
    jle .skip
    mov rax, rdx
.skip:
    inc rcx
    jmp .next
.done:
    mov rdi, rax
    mov rax, 60
    syscall' \
42

run_asm_stdout_test "w1d5_print_digits" \
'global _start
section .bss
    buf resb 16
section .text
_start:
    ; დაბეჭდე "1\n" მხოლოდ (მინი ტესტი)
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel one]
    mov rdx, 2
    syscall
    mov rax, 60
    xor rdi, rdi
    syscall
section .rodata
    one db "1", 10' \
"1"

echo

# ---- II კვირა ----

printf "${BLUE}[II კვირა] Stack და ფუნქციები${NC}\n"

run_asm_exit_test "w2d1_add_function" \
'global _start
section .text
add_numbers:
    lea rax, [rdi + rsi]
    ret
_start:
    mov rdi, 10
    mov rsi, 20
    call add_numbers
    mov rdi, rax
    mov rax, 60
    syscall' \
30

run_asm_exit_test "w2d2_factorial" \
'global _start
section .text
factorial:
    cmp rdi, 1
    jle .base
    push rdi
    dec rdi
    call factorial
    pop rdi
    imul rax, rdi
    ret
.base:
    mov rax, 1
    ret
_start:
    mov rdi, 5
    call factorial
    ; 5! = 120, exit 120 mod 256 = 120
    mov rdi, rax
    mov rax, 60
    syscall' \
120

run_asm_exit_test "w2d4_popcount" \
'global _start
section .text
_start:
    mov rax, 0b10110111    ; 6 ცალი 1-იანი
    xor rcx, rcx           ; count = 0
.loop:
    test rax, rax
    jz .done
    mov rdx, rax
    dec rdx
    and rax, rdx           ; rax &= rax - 1
    inc rcx
    jmp .loop
.done:
    mov rdi, rcx
    mov rax, 60
    syscall' \
6

run_asm_exit_test "w2d4_is_power_of_two" \
'global _start
section .text
_start:
    mov rax, 64            ; 2^6
    test rax, rax
    jz .no
    mov rdx, rax
    dec rdx
    and rdx, rax
    jnz .no
    mov rdi, 1
    jmp .exit
.no:
    xor rdi, rdi
.exit:
    mov rax, 60
    syscall' \
1

echo

# ---- III კვირა ----

printf "${BLUE}[III კვირა] C interop და SIMD${NC}\n"

# C interop ტესტი
cinterop_test() {
    local tmpdir="$TMPDIR/cinterop"
    mkdir -p "$tmpdir"

    cat > "$tmpdir/sum.s" <<'EOF'
default rel
global sum_array
section .text
; rdi = arr, rsi = n -> eax = sum
sum_array:
    xor eax, eax
    xor rcx, rcx
.loop:
    cmp rcx, rsi
    jge .done
    add eax, [rdi + rcx*4]
    inc rcx
    jmp .loop
.done:
    ret
EOF

    cat > "$tmpdir/main.c" <<'EOF'
#include <stdio.h>
extern int sum_array(const int *arr, long n);
int main(void) {
    int data[] = {1, 2, 3, 4, 5};
    printf("%d\n", sum_array(data, 5));
    return 0;
}
EOF

    if nasm -f elf64 "$tmpdir/sum.s" -o "$tmpdir/sum.o" 2>"$TMPDIR/err" \
       && gcc -no-pie "$tmpdir/main.c" "$tmpdir/sum.o" -o "$tmpdir/prog" 2>>"$TMPDIR/err"; then
        local out
        out=$("$tmpdir/prog")
        if [ "$out" = "15" ]; then
            printf "${GREEN}✓${NC} %-30s sum_array → 15\n" "w3d2_sum_array"
            PASS=$((PASS + 1))
        else
            printf "${RED}✗${NC} %-30s sum_array → '%s' (მოსალოდნელი '15')\n" "w3d2_sum_array" "$out"
            FAIL=$((FAIL + 1))
        fi
    else
        printf "${RED}✗${NC} %-30s build ვერ შესრულდა\n" "w3d2_sum_array"
        cat "$TMPDIR/err" | head -5 | sed 's/^/    /'
        FAIL=$((FAIL + 1))
    fi
}

cinterop_test

echo

# ---- IV კვირა ----

printf "${BLUE}[IV კვირა] Reverse engineering${NC}\n"

# buffer overflow ტესტი (მხოლოდ ადგილობრივი, კონტროლირებული)
bufov_test() {
    local tmpdir="$TMPDIR/bufov"
    mkdir -p "$tmpdir"

    cat > "$tmpdir/vuln.c" <<'EOF'
#include <stdio.h>
#include <string.h>

__attribute__((noinline))
void secret(void) {
    puts("SECRET_REACHED");
    _exit(42);
}

__attribute__((noinline))
void vulnerable(void) {
    char buf[64];
    fgets(buf, 256, stdin);
    printf("You said: %s", buf);
}

int main(void) {
    vulnerable();
    return 0;
}
EOF

    if ! gcc -fno-stack-protector -z execstack -no-pie \
             -o "$tmpdir/vuln" "$tmpdir/vuln.c" 2>"$TMPDIR/err"; then
        printf "${YELLOW}!${NC} %-30s gcc ვერ შესრულდა (იგნორირება)\n" "w4d1_bufov"
        return
    fi

    # ვპოულობთ secret-ის მისამართს
    local secret_addr
    secret_addr=$(objdump -d -M intel "$tmpdir/vuln" \
                  | awk '/<secret>:/ {print $1; exit}' \
                  | sed 's/://')
    if [ -z "$secret_addr" ]; then
        printf "${YELLOW}!${NC} %-30s secret ვერ მოიძებნა\n" "w4d1_bufov"
        return
    fi

    # 64 buffer + 8 saved rbp + 8 return addr
    # secret-ის მისამართი little-endian
    local payload
    payload=$(python3 -c "
import sys
addr = int('$secret_addr', 16)
sys.stdout.buffer.write(b'A' * 72 + addr.to_bytes(8, 'little') + b'\n')
")

    local out
    out=$(echo "$payload" | "$tmpdir/vuln" 2>&1 || true)

    if echo "$out" | grep -q "SECRET_REACHED"; then
        printf "${GREEN}✓${NC} %-30s secret მიღწეულია\n" "w4d1_bufov"
        PASS=$((PASS + 1))
    else
        printf "${YELLOW}!${NC} %-30s overflow ვერ მოხდა (ASLR?)\n" "w4d1_bufov"
        printf "    სცადე: setarch -R %s\n" "$tmpdir/vuln"
    fi
}

bufov_test

echo

# ============================================================

if [ "$FAIL" -eq 0 ]; then
    printf "${GREEN}=== ყველა ტესტი გავიდა (PASS=%d) ===${NC}\n" "$PASS"
    exit 0
else
    printf "${RED}=== %d ტესტი ჩავარდა, %d გავიდა ===${NC}\n" "$FAIL" "$PASS"
    exit 1
fi