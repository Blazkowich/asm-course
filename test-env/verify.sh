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
    # გარემოს შემოწმება — ეს არ არის სავარჯიშოს ამოხსნა.
    # განზრახ სხვა რიცხვს ვიყენებთ, რომ I კვირის დავალების პასუხი არ გასცეს.
    local tmpdir
    tmpdir=$(mktemp -d)
    cat > "$tmpdir/smoke.asm" <<'EOF'
global _start
section .text
_start:
    mov rax, 60
    mov rdi, 7
    syscall
EOF

    if nasm -f elf64 -g -F dwarf "$tmpdir/smoke.asm" -o "$tmpdir/smoke.o" 2>/dev/null \
       && ld "$tmpdir/smoke.o" -o "$tmpdir/smoke" 2>/dev/null; then
        "$tmpdir/smoke"
        local code=$?
        if [ "$code" -eq 7 ]; then
            printf "${GREEN}✓${NC} %-12s build+run მუშაობს (exit=%d)\n" "nasm+ld" "$code"
            PASS=$((PASS + 1))
        else
            printf "${RED}✗${NC} %-12s exit=%d (მოსალოდნელი 7)\n" "nasm+ld" "$code"
            FAIL=$((FAIL + 1))
        fi
    else
        printf "${RED}✗${NC} %-12s build ვერ შესრულდა\n" "nasm+ld"
        FAIL=$((FAIL + 1))
    fi
    rm -rf "$tmpdir"
}

check_c_interop() {
    # აქაც განზრახ მარტივი, არასავარჯიშო ფუნქციაა — მიზანი მხოლოდ იმის
    # დადასტურებაა, რომ nasm + gcc ერთად ლინკავს.
    local tmpdir
    tmpdir=$(mktemp -d)
    cat > "$tmpdir/asm.s" <<'EOF'
default rel
global scale_by_ten
section .text
scale_by_ten:
    imul eax, edi, 10
    ret
EOF
    cat > "$tmpdir/main.c" <<'EOF'
#include <stdio.h>
extern int scale_by_ten(int x);
int main(void) { printf("%d\n", scale_by_ten(7)); return 0; }
EOF

    if nasm -f elf64 "$tmpdir/asm.s" -o "$tmpdir/asm.o" 2>/dev/null \
       && gcc -no-pie "$tmpdir/main.c" "$tmpdir/asm.o" -o "$tmpdir/prog" 2>/dev/null; then
        local out
        out=$("$tmpdir/prog")
        if [ "$out" = "70" ]; then
            printf "${GREEN}✓${NC} %-12s C ↔ asm მუშაობს\n" "nasm+gcc"
            PASS=$((PASS + 1))
        else
            printf "${RED}✗${NC} %-12s გამოსავალი: '%s' (მოსალოდნელი '70')\n" "nasm+gcc" "$out"
            FAIL=$((FAIL + 1))
        fi
    else
        printf "${RED}✗${NC} %-12s build ვერ შესრულდა\n" "nasm+gcc"
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

printf "${BLUE}[4] ტულჩეინის შემოწმება (ეს სავარჯიშოები არ არის)${NC}\n"
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