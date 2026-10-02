#!/usr/bin/env bash
# test-env/verify.sh
# ამოწმებს, ყველა საჭირო ინსტრუმენტი დაყენებულია თუ არა.
# გამოყენება:  ./verify.sh

set -u

# ფერები
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

PASS=0
FAIL=0

check_tool() {
    local name="$1"
    local cmd="$2"
    local version_flag="${3:---version}"

    if command -v "$cmd" >/dev/null 2>&1; then
        local ver
        ver=$("$cmd" "$version_flag" 2>&1 | head -n1 | tr -d '\n')
        printf "${GREEN}✓${NC} %-12s %s\n" "$name" "$ver"
        PASS=$((PASS + 1))
    else
        printf "${RED}✗${NC} %-12s ${RED}ვერ მოიძებნა${NC}\n" "$name"
        FAIL=$((FAIL + 1))
    fi
}

check_arch() {
    local arch
    arch=$(uname -m)
    if [ "$arch" = "x86_64" ]; then
        printf "${GREEN}✓${NC} %-12s %s\n" "arch" "$arch"
        PASS=$((PASS + 1))
    else
        printf "${YELLOW}!${NC} %-12s %s ${YELLOW}(x86-64 სავარაუდოა)${NC}\n" "arch" "$arch"
    fi
}

check_gdbinit() {
    if [ -f "$HOME/.gdbinit" ] && grep -q "intel" "$HOME/.gdbinit" 2>/dev/null; then
        printf "${GREEN}✓${NC} %-12s Intel სინტაქსი ჩართულია\n" ".gdbinit"
        PASS=$((PASS + 1))
    else
        printf "${YELLOW}!${NC} %-12s ${YELLOW}არ არის კონფიგურირებული${NC}\n" ".gdbinit"
        printf "    გამოსავალი: echo 'set disassembly-flavor intel' >> ~/.gdbinit\n"
    fi
}

check_hello() {
    local tmpdir
    tmpdir=$(mktemp -d)
    cat > "$tmpdir/hello.asm" <<'EOF'
global _start
section .text
_start:
    mov rax, 60
    mov rdi, 42
    syscall
EOF

    if nasm -f elf64 -g -F dwarf "$tmpdir/hello.asm" -o "$tmpdir/hello.o" 2>/dev/null \
       && ld "$tmpdir/hello.o" -o "$tmpdir/hello" 2>/dev/null; then
        "$tmpdir/hello"
        local code=$?
        if [ "$code" -eq 42 ]; then
            printf "${GREEN}✓${NC} %-12s build+run მუშაობს (exit=%d)\n" "hello.asm" "$code"
            PASS=$((PASS + 1))
        else
            printf "${RED}✗${NC} %-12s exit=%d (მოსალოდნელი 42)\n" "hello.asm" "$code"
            FAIL=$((FAIL + 1))
        fi
    else
        printf "${RED}✗${NC} %-12s build ვერ შესრულდა\n" "hello.asm"
        FAIL=$((FAIL + 1))
    fi
    rm -rf "$tmpdir"
}

check_c_interop() {
    local tmpdir
    tmpdir=$(mktemp -d)
    cat > "$tmpdir/asm.s" <<'EOF'
default rel
global add_numbers
section .text
add_numbers:
    lea eax, [rdi + rsi]
    ret
EOF
    cat > "$tmpdir/main.c" <<'EOF'
#include <stdio.h>
extern int add_numbers(int a, int b);
int main(void) { printf("%d\n", add_numbers(3, 4)); return 0; }
EOF

    if nasm -f elf64 "$tmpdir/asm.s" -o "$tmpdir/asm.o" 2>/dev/null \
       && gcc -no-pie "$tmpdir/main.c" "$tmpdir/asm.o" -o "$tmpdir/prog" 2>/dev/null; then
        local out
        out=$("$tmpdir/prog")
        if [ "$out" = "7" ]; then
            printf "${GREEN}✓${NC} %-12s C ↔ asm მუშაობს\n" "C interop"
            PASS=$((PASS + 1))
        else
            printf "${RED}✗${NC} %-12s გამოსავალი: '%s' (მოსალოდნელი '7')\n" "C interop" "$out"
            FAIL=$((FAIL + 1))
        fi
    else
        printf "${RED}✗${NC} %-12s build ვერ შესრულდა\n" "C interop"
        FAIL=$((FAIL + 1))
    fi
    rm -rf "$tmpdir"
}

# ============================================================
echo
printf "${BLUE}=== Assembly Course: გარემოს შემოწმება ===${NC}\n"
echo

printf "${BLUE}[1] არქიტექტურა${NC}\n"
check_arch
echo

printf "${BLUE}[2] ინსტრუმენტები${NC}\n"
check_tool "nasm"    nasm    -v
check_tool "ld"      ld
check_tool "gcc"     gcc
check_tool "gdb"     gdb
check_tool "objdump" objdump
check_tool "strace"  strace  -V
check_tool "make"    make
check_tool "python3" python3
echo

printf "${BLUE}[3] კონფიგურაცია${NC}\n"
check_gdbinit
echo

printf "${BLUE}[4] ფუნქციური ტესტები${NC}\n"
check_hello
check_c_interop
echo

# ============================================================
if [ "$FAIL" -eq 0 ]; then
    printf "${GREEN}=== ყველაფერი მზადაა! ===${NC}\n"
    printf "   გააგრძელე: 01-week1-fundamentals.md\n"
    exit 0
else
    printf "${RED}=== %d პრობლემა მოიძებნა ===${NC}\n" "$FAIL"
    printf "   ნახე 00-setup.md § 5 „ხშირი პრობლემები“\n"
    exit 1
fi