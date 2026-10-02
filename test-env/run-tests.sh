#!/usr/bin/env bash
# test-env/run-tests.sh
#
# თვითშემოწმების ხელსაწყო. ის არ შეიცავს ამოხსნებს:
#   * კითხულობს მხოლოდ შენს ფაილებს solutions/ საქაღალდიდან
#   * აწყობს, უშვებს და ადარებს შედეგს მოსალოდნელს
#   * თუ არ გამოვიდა — აძლევს იდეას, gdb-ის ნაბიჯებს და მიუთითებს GUIDELINES.md-ზე
#
# გამოყენება:
#   ./run-tests.sh                 ყველა შემოწმება
#   ./run-tests.sh w1d4 w2d2       მხოლოდ მითითებული
#   ./run-tests.sh --list          სია: რა არსებობს და რა ფაილია საჭირო
#   ./run-tests.sh --guide w1d4    სრული გაიდლაინი ერთი დავალებისთვის
#   ./run-tests.sh --progress      პროგრესი კვირების მიხედვით
#   ./run-tests.sh --new w1d4      შექმნის ცარიელ ჩონჩხს (მხოლოდ კომენტარები)
#   ./run-tests.sh --help          დახმარება

set -u

# ============================================================
# მდებარეობები
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOLUTIONS_DIR="$SCRIPT_DIR/solutions"
HARNESS_DIR="$SCRIPT_DIR/harness"
GUIDE_FILE="$SCRIPT_DIR/GUIDELINES.md"

if [ "${PWD:-}" = "$SCRIPT_DIR" ]; then
    CMD="./run-tests.sh"
else
    CMD="$SCRIPT_DIR/run-tests.sh"
fi

BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT INT TERM

# ============================================================
# ფერები (მხოლოდ ტერმინალში)
# ============================================================

if [ -t 1 ]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'; DIM=$'\033[2m'; BOLD=$'\033[1m'; NC=$'\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; DIM=''; BOLD=''; NC=''
fi

# ============================================================
# მანიფესტი — მხოლოდ საკონტროლო მონაცემები, არავითარი კოდი.
#
#   id | კვირა | ფაილი solutions/-ში | შემოწმება | მოსალოდნელი |
#   სათაური | იდეა (ერთი ხაზი) | gdb-ით გადამოწმება | წყარო
#
# შემოწმების ტიპები:
#   exit       — პროგრამის exit code უნდა ემთხვეოდეს
#   stdout     — გამოსავლის ბოლო არაცარიელი ხაზი უნდა ემთხვეოდეს
#   stdin      — შეყვანა=>მოსალოდნელი წყვილები, გამოყოფილი @@-ით
#   c_interop  — შენი asm ფუნქცია + harness/-ის C driver
#   bufov      — w4d1_vuln.c + w4d1_exploit.py
#   manual     — ავტომატურად ვერ შემოწმდება, გაძლევს კრიტერიუმებს
# ============================================================

manifest() {
    cat <<'MANIFEST'
w1d1_exit42|1|w1d1_exit42.asm|exit|42|exit 42|exit syscall-ს სამი ნაწილი აქვს: rax=60, rdi=კოდი, syscall — სამივე ერთად უნდა იყოს|stepi სამჯერ და ყოველ ნაბიჯზე ნახე rax და rdi|01-week1-fundamentals.md § I დღე
w1d2_arith|1|w1d2_arith.asm|exit|30|(5+3)*4-2 = 30|დაიწყე rax=5-ით და ოპერაციები იმ თანმიმდევრობით ჩაწერე, როგორც ფრჩხილები მოითხოვს; ყოველ ნაბიჯზე rax იცვლება|stepi ყოველ ინსტრუქციაზე და p $rax — ნახე შუალედური შედეგები|01-week1-fundamentals.md § II დღე
w1d2_div_remainder|1|w1d2_div_remainder.asm|exit|2|100 / 7 — ნაშთი|div-მდე rdx უნდა იყოს ზუსტად 0, თორემ SIGFPE მოგივა ან არასწორი შედეგი; გაყოფის შედეგი rax-შია, ნაშთი rdx-ში|stepi div-ის შემდეგ: p $rax უნდა იყოს 14 და p $rdx უნდა იყოს 2|01-week1-fundamentals.md § II დღე
w1d3_hello|1|w1d3_hello.asm|stdout|Hello|"Hello" write-ით|write-ს ოთხი რეგისტრი სჭირდება: rax=1, rdi=1, rsi=მისამართი, rdx=სიგრძე; msg არის მისამართი, [msg] კი შიგთავსი|x/8cb &msg — ნახე, რომ ბაიტები ზუსტად იმ ტექსტია|01-week1-fundamentals.md § III დღე
w1d3_georgian|1|w1d3_georgian.asm|stdout|გამარჯობა სამყარო|ქართული ტექსტი UTF-8-ში|ქართული ასო UTF-8-ში 3 ბაიტია — სიგრძე ხელით ნუ ჩაწერ, არამედ დაითვალე ლეიბლიდან|x/32xb &msg — დათვალე ბაიტები და შეადარე msg_len-ს|01-week1-fundamentals.md § III დღე
w1d4_sum_1_to_100|1|w1d4_sum_1_to_100.asm|exit|186|1..100 ჯამი|exit code მხოლოდ 8 ბიტია, ამიტომ 5050 & 255 = 186; თუ 0 გამოვიდა — ციკლი არ შესრულდა, შეამოწმე rcx-ის საწყისი მნიშვნელობა და cmp/jle|ციკლის შემდეგ p $rax უნდა იყოს 5050 (0x13ba), exit code კი მისი დაბალი ბაიტი|01-week1-fundamentals.md § IV დღე
w1d4_array_max|1|w1d4_array_max.asm|exit|42|მასივის მაქსიმუმი|სცენარი: dq 5, 17, -3, 42, 8 — პასუხი 42; საწყისი max აიღე პირველი ელემენტიდან და შედარება signed გააკეთე (jg/jl), თორემ -3 „დიდი“ აღმოჩნდება|x/5dg &arr — დაადასტურე, რომ 42 მართლა მაქსიმუმია|01-week1-fundamentals.md § IV დღე
w1d5_print_int|1|w1d5_print_int.asm|stdout|5050|print_int — რიცხვი ტექსტად|1..100 ჯამი გამოიტანე ტექსტად: ციფრები 10-ზე გაყოფით მიიღება და შებრუნებულად გამოდის, ამიტომ ბუფერი ბოლოდან აავსე ან შემდეგ შეაბრუნე|write-მდე ნახე ბუფერი: x/8cb &buf — უნდა ეწეროს 5050|01-week1-fundamentals.md § V დღე
w2d1_add_function|2|w2d1_add_function.asm|exit|30|add(10, 20)|სცენარი: rdi=10, rsi=20; არგუმენტები პირველი ორი რეგისტრით მოდის, დაბრუნება rax-ით; call თვითონ დებს დაბრუნების მისამართს სტეკზე|x/4gx $rsp call-ის წინ და შემდეგ — ნახე, რა დაემატა სტეკს|02-week2-stack-functions.md § I დღე
w2d2_factorial|2|w2d2_factorial.asm|exit|120|factorial(5) = 120|სცენარი: n=5; რეკურსიაში rdi caller-saved-ია, ამიტომ ყოველ დონეზე მნიშვნელობა push/pop-ით შეინახე; base case (n<=1) აუცილებელია, თორემ უსასრულო რეკურსია|x/8gx $rsp ყოველ call-ზე — დაინახავ ჩარჩოების ჯაჭვს სტეკზე|02-week2-stack-functions.md § II დღე
w2d3_strlen|2|w2d3_strlen.asm|exit|11|strlen("Hello World") = 11|სცენარი: NUL-ით დამთავრებული "Hello World"; repne scasb-ს წინ rcx უნდა იყოს -1 და სიგრძე rcx-იდან გამოდის; ხელით ციკლის ვერსია ცალკე შეამოწმე|დასრულებისას p $rcx და p $rdi — ნახე, სად გაჩერდა და რატომ; x/16cb $rdi-ით ნახე NUL ბაიტი|02-week2-stack-functions.md § III დღე
w2d4_popcount|2|w2d4_popcount.asm|exit|6|popcount(0b10110111) = 6|სცენარი: rax=0b10110111; სამი გზა არსებობს — ციკლი shift/test-ით, x & (x-1) ხრიკი, ან CPU-ს popcnt ინსტრუქცია|p/t $rax რომ ნახო ორობითი სახე და ხელით გადათვალო ერთიანები|02-week2-stack-functions.md § IV დღე
w2d4_is_power_of_two|2|w2d4_is_power_of_two.asm|exit|1|is_power_of_two(64) → 1|სცენარი: rax=64, დააბრუნე 1 თუ ხარისხია, 0 თუ არა; სიმძლავრეს ზუსტად ერთი 1-იანი ბიტი აქვს — იფიქრე, რას აკეთებს x & (x-1), და 0 ცალკე გაითვალისწინე|შეამოწმე ორივე მხარე: 64 → 1, ხოლო 65 ან 0 → 0|02-week2-stack-functions.md § IV დღე
w2d4_xor_swap|2|w2d4_xor_swap.asm|exit|20|xor-ით ორი რიცხვის გაცვლა|სცენარი: დაიწყე rax=10, rbx=20, გაცვალე xor-ით და exit-ით დააბრუნე ახალი rax (მოსალოდნელია 20); სამი ნაბიჯი მკაცრად თანმიმდევრობით უნდა იყოს|xor-ის შემდეგ p $rax და p $rbx — მნიშვნელობები უნდა შეიცვალოს ადგილებით|02-week2-stack-functions.md § IV დღე
w2d5_calculator|2|w2d5_calculator.asm|stdin|12 + 30=>42@@100 - 58=>42@@6 * 7=>42@@84 / 2=>42@@5 - 20=>-15|კალკულატორი (მინი პროექტი)|ჯაჭვია: read → atoi → ოპერატორი → atoi → itoa; atoi-მ ახალი pointer-იც უნდა დააბრუნოს (rdx-ში), თორემ ვერ იპოვი, სად მთავრდება რიცხვი; დაბეჭდე მხოლოდ შედეგი|read-ის შემდეგ x/16cb &input — ნახე newline და ოპერატორის პოზიცია|02-week2-stack-functions.md § V დღე
w3d1_compiler_asm|3|-|manual|-|C-ის asm-ის კითხვა|დაწერე 5 პატარა C ფუნქცია (ჯამი, ციკლი, if, მასივზე წვდომა, struct) და თითოეულის asm აუხსენი საკუთარ თავს ხაზ-ხაზ|შეადარე gcc -S -O0 და gcc -S -O2 შედეგები გვერდიგვერდ|03-week3-c-interop.md § I დღე
w3d2_sum_array|3|w3d2_sum_array.asm|c_interop|15|sum_array(int*, size_t) C-დან|driver გიძახებს {1,2,3,4,5}-ით; int-ის ელემენტი 4 ბაიტია, ამიტომ ინდექსირება *4-ით ხდება და არა *8-ით; მეორე არგუმენტი rsi-ში მოდის|break sum_array და info registers rdi rsi — შეადარე მისამართი მასივის დასაწყისს|03-week3-c-interop.md § II დღე
w3d2_to_upper|3|w3d2_to_upper.asm|c_interop|HELLO, ASM|to_upper(char*) C-დან|ASCII-ში პატარა და დიდი ასოს შორის სხვაობა 0x20-ია, მაგრამ ჯერ შეამოწმე, რომ სიმბოლო ასოა — თორემ სასვენ ნიშანსაც შეცვლი|break to_upper და x/s $rdi — სტრიქონი შეცვლამდე და შემდეგ|03-week3-c-interop.md § II დღე
w3d3_sum_ids|3|w3d3_sum_ids.asm|c_interop|60|struct-ების მასივის id-ების ჯამი|struct {int id; char flag; double value;} padding-ის გამო 16 ბაიტია — ელემენტებს შორის ნაბიჯი 16-ის ჯერადია და არა 13; driver 3 ელემენტს აწვდის id=10,20,30|p sizeof(struct Item) C-ში და შეადარე შენს ხელით გამოთვლას|03-week3-c-interop.md § III დღე
w3d4_simd_add|3|w3d4_simd_add.asm|c_interop|48.00|float მასივების შეკრება SSE-ით|driver 6 ელემენტიან მასივებს აწვდის; 4 float ერთ 16-ბაიტიან xmm რეგისტრში ეტევა, დარჩენილი 2 კი tail-ია და ცალკე სკალარულ ციკლს მოითხოვს|xmm-ის ნახვა: p $xmm0.v4_float — ოთხივე float ერთდროულად|03-week3-c-interop.md § IV დღე
w3d5_segfault|3|-|manual|-|segfault-ის გამოძიება|დაწერე განზრახ გატეხილი პროგრამა (მაგ. წაკითხვა მისამართ 0-იდან) და იპოვე მიზეზი gdb-ით|run → x/i $rip, info registers, bt — გაიგე სამივე ბრძანების როლი|03-week3-c-interop.md § V დღე
w4d1_bufov|4|w4d1_vuln.c|bufov|SECRET_REACHED|buffer overflow → secret|ორი ფაილი გჭირდება: solutions/w4d1_vuln.c (64-ბაიტიანი buffer + secret ფუნქცია) და solutions/w4d1_exploit.py (payload); secret-მა უნიკალური მარკერი უნდა დაბეჭდოს, რომ ტესტმა დაადგინოს — კონტროლი მართლა იქ მოხვდა|break vulnerable, run < payload, info frame — ნახე saved rip-ის ზუსტი მისამართი და გამოთვალე offset|04-week4-reverse-engineering.md § I დღე
w4d2_crackme|4|-|manual|-|crackme-ის ამოხსნა|აიღე 2-3 მარტივი crackme და თითოეულზე ჩამოწერე: რა შემოწმება იყო და როგორ გვერდი აუარე|Ghidra-ს decompiler-ის შედეგი შეადარე შენს asm ანალიზს — სად ემთხვევა და სად არა|04-week4-reverse-engineering.md § II დღე
w4d3_jit|4|-|manual|-|.NET JIT-ის asm|დაწერე C#-ში მარტივი ციკლი და DOTNET_JitDisasm-ით ნახე JIT-ის გენერირებული კოდი|იპოვე 3 განსხვავება შენს ხელნაწერ NASM ვერსიასთან: null check, bounds check, offset|04-week4-reverse-engineering.md § III დღე
w4d4_final|4|-|manual|-|ფინალური პროექტი|აირჩიე ერთი პროექტი (მინი shell, brainfuck, base64, Game of Life) და გამოიყენე ყველა ნასწავლი: syscalls, stack, ბიტური ოპერაციები|წარდგენის ფორმატი 04-week4 § „პროექტის წარდგენა“-შია|04-week4-reverse-engineering.md § IV-V დღე
MANIFEST
}

# ============================================================
# დამხმარე ფუნქციები
# ============================================================

roman() {
    case "$1" in
        1) echo "I" ;;
        2) echo "II" ;;
        3) echo "III" ;;
        4) echo "IV" ;;
        *) echo "$1" ;;
    esac
}

# ერთი დავალების მონაცემები: week|file|check|expect|title|hint|verify|source
row_for() {
    local want="$1"
    local id week file check expect title hint verify source
    while IFS='|' read -r id week file check expect title hint verify source; do
        [ -z "$id" ] && continue
        if [ "$id" = "$want" ]; then
            printf '%s|%s|%s|%s|%s|%s|%s|%s\n' \
                "$week" "$file" "$check" "$expect" "$title" "$hint" "$verify" "$source"
            return 0
        fi
    done < <(manifest)
    return 1
}

all_ids() {
    local id week file check expect title hint verify source
    while IFS='|' read -r id week file check expect title hint verify source; do
        [ -z "$id" ] && continue
        printf '%s\n' "$id"
    done < <(manifest)
}

# თუ id ნაწილობრივ დაემთხვა (მაგ. w1d4), ვთავაზობთ სრულ ვარიანტებს.
suggest_ids() {
    local want="$1" id week file check expect title hint verify source
    while IFS='|' read -r id week file check expect title hint verify source; do
        [ -z "$id" ] && continue
        case "$id" in "$want"*) printf ' %s' "$id" ;; esac
    done < <(manifest)
}

unknown_id() {
    local want="$1" sug
    sug="$(suggest_ids "$want")"
    printf '%s!%s უცნობი id: %s\n' "$YELLOW" "$NC" "$want"
    if [ -n "$sug" ]; then
        printf '     %sიგულისხმე?%s%s\n' "$DIM" "$NC" "$sug"
        printf '     %s(id უნდა იყოს ზუსტი — სრული სია: %s --list)%s\n' "$DIM" "$CMD" "$NC"
    else
        printf '     %sსრული სია: %s --list%s\n' "$DIM" "$CMD" "$NC"
    fi
}

# გამოსავლის ბოლო არაცარიელი ხაზი, ცარიელი ადგილების გარეშე.
# ასე "Hello\n" და "Hello" ერთნაირად ითვლება.
last_line() {
    printf '%s\n' "$1" | grep -v '^[[:space:]]*$' | tail -n 1 \
        | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# ფაილში არის თუ არა კოდი (და არა მხოლოდ კომენტარები/ცარიელი ხაზები)
has_code() {
    grep -qvE '^[[:space:]]*(;.*)?$' "$1"
}

BUILD_ERR=""
BUILD_STAGE=""

# $1 = .asm წყარო, $2 = გამოსული binary. ავსებს BUILD_ERR/BUILD_STAGE-ს.
asm_build() {
    local src="$1" out="$2"
    local base obj
    base="$(basename "${src%.asm}")"
    obj="$BUILD_DIR/$base.o"
    BUILD_ERR=""; BUILD_STAGE=""

    if ! nasm -f elf64 -g -F dwarf "$src" -o "$obj" 2>"$BUILD_DIR/nasm.err"; then
        BUILD_STAGE="nasm"
        BUILD_ERR="$(head -n 3 "$BUILD_DIR/nasm.err")"
        return 1
    fi
    if ! ld "$obj" -o "$out" 2>"$BUILD_DIR/ld.err"; then
        BUILD_STAGE="ld"
        BUILD_ERR="$(head -n 3 "$BUILD_DIR/ld.err")"
        return 1
    fi
    # ld წარმატებით მთავრდება მაშინაც, როცა _start არ არსებობს — ეს ხშირი
    # დამწყების შეცდომაა, ამიტომ ცალკე ვიჭერთ.
    if grep -q "entry symbol" "$BUILD_DIR/ld.err" 2>/dev/null; then
        BUILD_STAGE="nostart"
        BUILD_ERR="$(head -n 3 "$BUILD_DIR/ld.err")"
        return 1
    fi
    return 0
}

print_build_error() {
    case "$BUILD_STAGE" in
        nasm)
            printf '     %s↳ nasm-მა ვერ ააწყო. შეცდომა ზუსტად მიუთითებს ხაზს და სვეტს.%s\n' "$DIM" "$NC"
            ;;
        ld)
            printf '     %s↳ ld-მა ვერ დაალინკა (ჩვეულებრივ გამოუყენებელი ან ორმაგი სიმბოლო).%s\n' "$DIM" "$NC"
            ;;
        nostart)
            printf '     %s↳ დაუკავშირებელი _start: ფაილში უნდა იყოს "global _start" და ლეიბლი "_start:".%s\n' "$DIM" "$NC"
            ;;
        cc)
            printf '     %s↳ gcc-მა ვერ ააწყო ან ვერ დაალინკა — ფუნქციის სახელი და არგუმენტების ტიპები driver-ს უნდა ემთხვეოდეს.%s\n' "$DIM" "$NC"
            ;;
    esac
    if [ -n "$BUILD_ERR" ]; then
        printf '%s\n' "$BUILD_ERR" | sed 's/^/       /'
    fi
}

tool_ok() { command -v "$1" >/dev/null 2>&1; }

# პროგრამის გაშვება ლიმიტით. უსასრულო ციკლი დამწყების ყველაზე ხშირი
# ხაფანგია — ამით ტერმინალი არ ჩერდება, შედეგს კი ცხადად დავწერთ.
run_guarded() {
    if tool_ok timeout; then
        timeout 10 "$@"
    else
        "$@"
    fi
}

# თუ გაშვება ლიმიტმა შეწყვიტა, ცხადი ახსნა დავაბრუნოთ
timeout_note() {
    if [ "$1" -eq 124 ]; then
        printf 'პროგრამა 10 წამში არ დასრულდა — უსასრულო ციკლი ჩანს'
    fi
}

# ============================================================
# შემოწმებები
# ============================================================

CASE_DETAIL=""

check_exit() {
    local bin="$1" want="$2" actual note
    run_guarded "$bin" >/dev/null 2>&1
    actual=$?
    CASE_DETAIL=""
    if [ "$actual" -eq "$want" ]; then
        return 0
    fi
    note="$(timeout_note "$actual")"
    if [ -n "$note" ]; then
        CASE_DETAIL="$note"
    else
        CASE_DETAIL="exit code = $actual, მოსალოდნელი = $want"
    fi
    return 1
}

check_stdout() {
    local bin="$1" want="$2" actual rc note
    actual="$(run_guarded "$bin" 2>&1)"
    rc=$?
    actual="$(last_line "$actual")"
    CASE_DETAIL=""
    note="$(timeout_note "$rc")"
    if [ -n "$note" ]; then
        CASE_DETAIL="$note"
        return 1
    fi
    if [ "$actual" != "$want" ]; then
        CASE_DETAIL="მივიღე '$actual', მოსალოდნელი '$want'"
        return 1
    fi
    if [ "$rc" -ne 0 ]; then
        CASE_DETAIL="ტექსტი სწორია, მაგრამ პროგრამა $rc კოდით დასრულდა — დაამატე სუფთა გასვლა (rax=60)"
        return 1
    fi
    return 0
}

# expect ფორმატი: "შეყვანა=>მოსალოდნელი@@შეყვანა=>მოსალოდნელი"
check_stdin() {
    local bin="$1" expect="$2"
    local rest="$expect" spec input want actual rc note
    CASE_DETAIL=""
    while [ -n "$rest" ]; do
        spec="${rest%%@@*}"
        if [ "$spec" = "$rest" ]; then rest=""; else rest="${rest#*@@}"; fi
        [ -z "$spec" ] && continue
        input="${spec%%=>*}"
        want="${spec##*=>}"
        actual="$(printf '%s\n' "$input" | run_guarded "$bin" 2>/dev/null)"
        rc=$?
        note="$(timeout_note "$rc")"
        if [ -n "$note" ]; then
            CASE_DETAIL="შეყვანა '$input' → $note"
            return 1
        fi
        actual="$(last_line "$actual")"
        if [ "$actual" != "$want" ]; then
            CASE_DETAIL="შეყვანა '$input' → მივიღე '$actual', მოსალოდნელი '$want'"
            return 1
        fi
    done
    return 0
}

# $1 = შენი .asm, $2 = harness/-ის driver.c, $3 = მოსალოდნელი stdout
check_c_interop() {
    local src="$1" driver="$2" want="$3"
    local obj="$BUILD_DIR/$(basename "${src%.asm}").o"
    local bin="$BUILD_DIR/$(basename "${src%.asm}").interop"
    CASE_DETAIL=""

    if [ ! -f "$driver" ]; then
        CASE_DETAIL="ტესტის driver ვერ მოიძებნა: $driver"
        return 2
    fi
    if ! nasm -f elf64 -g -F dwarf "$src" -o "$obj" 2>"$BUILD_DIR/nasm.err"; then
        BUILD_ERR="$(head -n 3 "$BUILD_DIR/nasm.err")"; BUILD_STAGE="nasm"
        return 3
    fi
    if ! gcc -no-pie -g -w "$driver" "$obj" -o "$bin" 2>"$BUILD_DIR/cc.err"; then
        BUILD_ERR="$(head -n 3 "$BUILD_DIR/cc.err")"; BUILD_STAGE="cc"
        return 3
    fi
    local actual rc note
    actual="$(run_guarded "$bin" 2>&1)"
    rc=$?
    note="$(timeout_note "$rc")"
    if [ -n "$note" ]; then
        CASE_DETAIL="$note"
        return 1
    fi
    actual="$(last_line "$actual")"
    if [ "$actual" = "$want" ]; then
        return 0
    fi
    CASE_DETAIL="მივიღე '$actual', მოსალოდნელი '$want'"
    return 1
}

check_bufov() {
    local vuln="$SOLUTIONS_DIR/w4d1_vuln.c"
    local exploit="$SOLUTIONS_DIR/w4d1_exploit.py"
    local bin="$BUILD_DIR/vuln"
    CASE_DETAIL=""

    if [ ! -f "$exploit" ]; then
        CASE_DETAIL="ვერ მოიძებნა solutions/w4d1_exploit.py (payload-ის გენერატორი)"
        return 2
    fi
    if ! gcc -fno-stack-protector -z execstack -no-pie -w \
             -o "$bin" "$vuln" 2>"$BUILD_DIR/cc.err"; then
        # ძველი gets()-ის გარეშე ხშირად gnu89 საჭიროა
        if ! gcc -std=gnu89 -fno-stack-protector -z execstack -no-pie -w \
                 -o "$bin" "$vuln" 2>>"$BUILD_DIR/cc.err"; then
            CASE_DETAIL="gcc-მა ვერ ააწყო — იხილე gcc-ის შეტყობინება"
            BUILD_ERR="$(head -n 3 "$BUILD_DIR/cc.err")"; BUILD_STAGE="cc"
            return 3
        fi
    fi
    if ! tool_ok python3; then
        CASE_DETAIL="python3 ვერ მოიძებნა — exploit.py ვერ გაეშვება"
        return 2
    fi

    local out
    if tool_ok setarch; then
        out="$(python3 "$exploit" 2>/dev/null | run_guarded setarch -R "$bin" 2>&1 || true)"
    else
        out="$(python3 "$exploit" 2>/dev/null | run_guarded "$bin" 2>&1 || true)"
    fi

    if printf '%s' "$out" | grep -qE "SECRET_REACHED|reached secret"; then
        return 0
    fi
    CASE_DETAIL="payload-მა secret-მდე ვერ მიაღწია — სავარაუდოდ offset არასწორია"
    return 1
}

# ============================================================
# ერთი დავალების გაშვება
# ============================================================

PASS=0; FAIL=0; TODO=0; MANUAL=0

run_one() {
    local id="$1"
    local row week file check expect title hint verify source
    if ! row="$(row_for "$id")"; then
        unknown_id "$id"
        return 2
    fi
    IFS='|' read -r week file check expect title hint verify source <<< "$row"

    local label
    label="$(printf '%-22s' "$id")"

    # --- ხელით შესამოწმებელი ---
    if [ "$check" = "manual" ]; then
        printf '%s○%s %s %s\n' "$YELLOW" "$NC" "$label" "$title"
        printf '     %s↳ ამოცანა: %s%s\n' "$DIM" "$hint" "$NC"
        printf '     ↳ გადამოწმება: %s\n' "$verify"
        printf '     ↳ წყარო: %s\n' "$source"
        MANUAL=$((MANUAL + 1))
        return 0
    fi

    local src="$SOLUTIONS_DIR/$file"

    # --- ჯერ არ დაწერილა ---
    if [ ! -f "$src" ]; then
        printf '%s○%s %s ჯერ არ არის დაწერილი\n' "$YELLOW" "$NC" "$label"
        printf '     ↳ შექმენი: solutions/%s   (სწრაფად: %s --new %s)\n' "$file" "$CMD" "$id"
        printf '     ↳ გაიდლაინი: %s --guide %s\n' "$CMD" "$id"
        TODO=$((TODO + 1))
        return 0
    fi

    if ! has_code "$src"; then
        printf '%s○%s %s ფაილი არსებობს, მაგრამ კოდი ჯერ არ არის\n' "$YELLOW" "$NC" "$label"
        printf '     ↳ გაიდლაინი: %s --guide %s\n' "$CMD" "$id"
        TODO=$((TODO + 1))
        return 0
    fi

    # --- შემოწმება ---
    local rc=1
    CASE_DETAIL=""
    BUILD_ERR=""
    BUILD_STAGE=""
    case "$check" in
        bufov)
            check_bufov; rc=$?
            ;;
        c_interop)
            case "$id" in
                w3d2_sum_array) check_c_interop "$src" "$HARNESS_DIR/w3d2_sum_array.c" "$expect"; rc=$? ;;
                w3d2_to_upper)  check_c_interop "$src" "$HARNESS_DIR/w3d2_to_upper.c"  "$expect"; rc=$? ;;
                w3d3_sum_ids)   check_c_interop "$src" "$HARNESS_DIR/w3d3_sum_ids.c"   "$expect"; rc=$? ;;
                w3d4_simd_add)  check_c_interop "$src" "$HARNESS_DIR/w3d4_simd_add.c"  "$expect"; rc=$? ;;
                *) CASE_DETAIL="ამ დავალებისთვის driver არ არის განსაზღვრული"; rc=2 ;;
            esac
            ;;
        *)
            local bin="$BUILD_DIR/$id"
            if ! asm_build "$src" "$bin"; then
                printf '%s✗%s %s აწყობა ვერ მოხერხდა\n' "$RED" "$NC" "$label"
                print_build_error
                printf '     ↳ გაიდლაინი: %s --guide %s\n' "$CMD" "$id"
                FAIL=$((FAIL + 1))
                return 0
            fi
            case "$check" in
                exit)   check_exit   "$bin" "$expect"; rc=$? ;;
                stdout) check_stdout "$bin" "$expect"; rc=$? ;;
                stdin)  check_stdin  "$bin" "$expect"; rc=$? ;;
                *)      CASE_DETAIL="უცნობი შემოწმების ტიპი: $check"; rc=2 ;;
            esac
            ;;
    esac

    if [ "$rc" -eq 0 ]; then
        printf '%s✓%s %s გავიდა\n' "$GREEN" "$NC" "$label"
        printf '     %s↳ გაიღრმავე: %s%s\n' "$DIM" "$verify" "$NC"
        PASS=$((PASS + 1))
        return 0
    fi

    # --- ჩავარდა ან ვერ შემოწმდა ---
    if [ "$rc" -eq 2 ]; then
        printf '%s!%s %s ვერ შემოწმდა\n' "$YELLOW" "$NC" "$label"
    else
        printf '%s✗%s %s არ გამოვიდა\n' "$RED" "$NC" "$label"
    fi
    [ -n "$CASE_DETAIL" ] && printf '     ↳ შედეგი: %s\n' "$CASE_DETAIL"
    if [ "$rc" -eq 3 ]; then
        print_build_error
    fi
    printf '     ↳ იდეა: %s\n' "$hint"
    printf '     ↳ გადამოწმება: %s\n' "$verify"
    printf '     ↳ სრული გაიდლაინი: %s --guide %s\n' "$CMD" "$id"
    if [ "$rc" -eq 2 ]; then
        MANUAL=$((MANUAL + 1))
    else
        FAIL=$((FAIL + 1))
    fi
    return 0
}

# ============================================================
# ქვებრძანებები
# ============================================================

usage() {
    cat <<EOF
Assembly Course · თვითშემოწმება

გამოყენება:
  $CMD                     გაუშვი ყველა შემოწმება
  $CMD <id> [<id> ...]     მხოლოდ მითითებული (მაგ. w1d1_exit42 w2d2_factorial)
  $CMD --list              სია: id, ფაილი, მოსალოდნელი შედეგი
  $CMD --guide [<id>]      გაიდლაინი (იდეები, gdb, ხშირი შეცდომები)
  $CMD --progress          პროგრესი კვირების მიხედვით
  $CMD --new <id>          შექმნის ცარიელ ჩონჩხს (მხოლოდ კომენტარები)
  $CMD --help              ეს დახმარება

id უნდა იყოს ზუსტი — „w1d1“ არა, „w1d1_exit42“ კი. თუ შეცდი, ტესტი
შემოგთავაზებს სწორ ვარიანტებს.

სად ვწერ კოდს:
  solutions/<id>.asm       აქ.  ტესტი მხოლოდ შენს ფაილებს კითხულობს.

რას აკეთებს ტესტი:
  1. აწყობს შენს .asm-ს (nasm + ld)
  2. უშვებს და ადარებს exit code-ს ან stdout-ს
  3. თუ არ გამოვიდა — აძლევს იდეას და gdb-ის ნაბიჯებს, ამოხსნას კი არა

შენიშვნა: stdout-ის შედარებისას ტესტი იღებს გამოსავლის ბოლო არაცარიელ
ხაზს და ცარიელ ადგილებს აცლის — ამიტომ დამატებითი newline ან space
შედეგს არ გააფუჭებს.
EOF
}

do_list() {
    # ⚠️ printf სვეტის სიგანეს ბაიტებით ითვლის, ქართული ასო კი 2 ბაიტია,
    # თუმცა ეკრანზე 1 უჯრას იკავებს — ამიტომ სათაურს ASCII-ით ვწერთ
    # (გასწორება ზუსტია), ხოლო ქართული ახსნა ქვემოთ, ლეგენდაშია.
    # კვირა ცალკე სვეტად არ გვჭირდება: id-ის დასაწყისი (w1, w2, …) სწორედ
    # კვირაა, პროგრესს კი `--progress` აჩვენებს.
    printf '%s%-22s %-24s %s%s\n' "$BOLD" "id" "file" "expected" "$NC"
    local id week file check expect title hint verify source want
    while IFS='|' read -r id week file check expect title hint verify source; do
        [ -z "$id" ] && continue
        want="$expect"
        [ "$check" = "manual" ] && want="(ხელით)"
        [ "$check" = "exit" ] && want="exit=$expect"
        [ "$check" = "stdin" ] && want="5 შემთხვევა stdin-იდან"
        if [ "$file" = "-" ]; then
            printf '%-22s %-24s %s\n' "$id" "—" "$want"
        else
            printf '%-22s %-24s %s\n' "$id" "$file" "$want"
        fi
    done < <(manifest)
    echo
    printf '%sსულ %s დავალება.  სვეტები: id · file = ფაილი solutions/-ში · expected = მოსალოდნელი შედეგი.%s\n' \
        "$DIM" "$(all_ids | wc -l | tr -d ' ')" "$NC"
    printf '%s(id-ის დასაწყისი = კვირა: w1… = I კვირა.)%s\n' "$DIM" "$NC"
}

extract_guide() {
    local id="$1"
    [ -f "$GUIDE_FILE" ] || return 1
    awk -v id="$id" '
        /^## / {
            if (found) exit
            if (substr($0, 4, length(id)) == id) {
                rest = substr($0, 4 + length(id), 1)
                if (rest == "" || rest == " " || rest == "-" || rest == "·" || rest == ":") {
                    found = 1
                    next
                }
            }
        }
        found { print }
    ' "$GUIDE_FILE"
}

do_guide() {
    local id="${1:-}"
    if [ -z "$id" ]; then
        echo "აირჩიე დავალება: $CMD --guide <id>"
        echo
        do_list
        return 0
    fi
    local row week file check expect title hint verify source
    if ! row="$(row_for "$id")"; then
        unknown_id "$id"
        return 1
    fi
    IFS='|' read -r week file check expect title hint verify source <<< "$row"

    printf '%s════ %s · %s%s\n' "$BOLD" "$id" "$title" "$NC"
    [ "$file" != "-" ] && printf 'ფაილი:     solutions/%s\n' "$file"
    printf 'კვირა:     %s\n' "$(roman "$week")"
    case "$check" in
        exit)      printf 'შემოწმება: exit code = %s\n' "$expect" ;;
        stdout)    printf 'შემოწმება: stdout = %s\n' "$expect" ;;
        stdin)     printf 'შემოწმება: 5 შემთხვევა stdin-იდან\n' ;;
        c_interop) printf 'შემოწმება: asm ფუნქცია C-იდან, stdout = %s\n' "$expect" ;;
        bufov)     printf 'შემოწმება: overflow → %s\n' "$expect" ;;
        manual)    printf 'შემოწმება: ხელით (ავტომატურად არ შემოწმდება)\n' ;;
    esac
    printf 'იდეა:      %s\n' "$hint"
    printf 'შემდეგი:   %s\n' "$verify"
    printf 'წყარო:     %s\n' "$source"
    echo
    local section
    section="$(extract_guide "$id")"
    if [ -n "$section" ]; then
        printf '%s\n' "$section"
    else
        printf '%s(სრული გაიდლაინი ჯერ არ არის დაწერილი — ნახე %s)%s\n' \
            "$DIM" "$(basename "$GUIDE_FILE")" "$NC"
    fi
    echo
    printf '%sგაუშვი შემოწმება: %s %s%s\n' "$DIM" "$CMD" "$id" "$NC"
}

do_progress() {
    local week id week2 file check expect title hint verify source
    local started total pct filled bar i
    for week in 1 2 3 4; do
        started=0; total=0
        while IFS='|' read -r id week2 file check expect title hint verify source; do
            [ -z "$id" ] && continue
            [ "$week2" != "$week" ] && continue
            [ "$file" = "-" ] && continue
            total=$((total + 1))
            if [ -f "$SOLUTIONS_DIR/$file" ] && has_code "$SOLUTIONS_DIR/$file"; then
                started=$((started + 1))
            fi
        done < <(manifest)
        [ "$total" -eq 0 ] && continue
        pct=$((started * 100 / total))
        filled=$((started * 10 / total))
        bar=""
        i=0
        while [ "$i" -lt 10 ]; do
            if [ "$i" -lt "$filled" ]; then bar="${bar}█"; else bar="${bar}░"; fi
            i=$((i + 1))
        done
        printf '[%s კვირა]  %s  %d/%d  (%d%%)\n' "$(roman "$week")" "$bar" "$started" "$total" "$pct"
    done
    echo
    printf '%s"დაწყებული" ნიშნავს, რომ ფაილში კოდი უკვე წერია — გავლას კი %s ამოწმებს.%s\n' \
        "$DIM" "$CMD" "$NC"
}

do_new() {
    local id="${1:-}"
    if [ -z "$id" ]; then
        printf '%s!%s მიუთითე id: %s --new w1d4\n' "$YELLOW" "$NC" "$CMD"
        return 1
    fi
    local row week file check expect title hint verify source
    if ! row="$(row_for "$id")"; then
        unknown_id "$id"
        return 1
    fi
    IFS='|' read -r week file check expect title hint verify source <<< "$row"
    if [ "$file" = "-" ]; then
        printf '%s!%s %s ავტომატური ფაილი არ სჭირდება — ნახე: %s --guide %s\n' \
            "$YELLOW" "$NC" "$id" "$CMD" "$id"
        return 1
    fi
    mkdir -p "$SOLUTIONS_DIR"
    local src="$SOLUTIONS_DIR/$file"
    if [ -f "$src" ]; then
        printf '%s!%s ფაილი უკვე არსებობს: solutions/%s\n' "$YELLOW" "$NC" "$file"
        return 1
    fi
    {
        printf '; %s — %s\n' "$id" "$title"
        printf '; კვირა %s · წყარო: %s\n' "$(roman "$week")" "$source"
        printf ';\n'
        printf '; ეს ფაილი განზრახ ცარიელია — აქ არაფერია დაწერილი შენ მაგივრად.\n'
        printf '; დაწერე კოდი, მერე გაუშვი:  %s %s\n' "$CMD" "$id"
        printf '; გაიდლაინი:                  %s --guide %s\n' "$CMD" "$id"
        printf ';\n'
        printf '; TODO: აქ იწყება შენი კოდი.\n'
    } > "$src"
    printf '%s✓%s შეიქმნა solutions/%s (მხოლოდ კომენტარები)\n' "$GREEN" "$NC" "$file"
    printf '%s  გაიდლაინი: %s --guide %s%s\n' "$DIM" "$CMD" "$id" "$NC"
}

# ============================================================
# მთავარი
# ============================================================

main() {
    local mode="run"
    local -a ids=()

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)     usage; exit 0 ;;
            --list)        do_list; exit 0 ;;
            --progress)    do_progress; exit 0 ;;
            --guide)       mode="guide"; shift; ids=("${1:-}"); break ;;
            --new)         mode="new"; shift; ids=("${1:-}"); break ;;
            -*)            printf '%s!%s უცნობი პარამეტრი: %s\n\n' "$YELLOW" "$NC" "$1"; usage; exit 2 ;;
            *)             ids+=("$1") ;;
        esac
        shift
    done

    case "$mode" in
        guide) do_guide "${ids[0]:-}"; exit $? ;;
        new)   do_new   "${ids[0]:-}"; exit $? ;;
    esac

    # --- ჯერ id-ების შემოწმება, რომ შეცდომა გასაგები იყოს ---
    local vid bad=0
    if [ "${#ids[@]}" -gt 0 ]; then
        for vid in "${ids[@]}"; do
            if ! row_for "$vid" >/dev/null 2>&1; then
                unknown_id "$vid"
                bad=1
            fi
        done
        [ "$bad" -eq 1 ] && exit 2
    fi

    # --- ინსტრუმენტების შემოწმება ---
    local missing=""
    local t
    for t in nasm ld gcc; do
        tool_ok "$t" || missing="$missing $t"
    done
    if [ -n "$missing" ]; then
        printf '%s✗ ინსტრუმენტები ვერ მოიძებნა:%s%s\n' "$RED" "$missing" "$NC"
        printf '  გაუშვი ./verify.sh ან ნახე 00-setup.md § 5 „ხშირი პრობლემები“.\n'
        printf '  %s(სიისა და გაიდლაინების ნახვა მაინც შეგიძლია: %s --list)%s\n' "$DIM" "$CMD" "$NC"
        exit 2
    fi

    printf '%s=== Assembly Course · თვითშემოწმება ===%s\n' "$BOLD" "$NC"
    printf '%sსამუშაო საქაღალდე: solutions/   ·   ამოხსნები ტესტში არ არის%s\n\n' "$DIM" "$NC"

    mkdir -p "$SOLUTIONS_DIR"

    local last_week="" id week
    if [ "${#ids[@]}" -eq 0 ]; then
        while IFS='|' read -r id week file check expect title hint verify source; do
            [ -z "$id" ] && continue
            if [ "$week" != "$last_week" ]; then
                [ -n "$last_week" ] && echo
                printf '%s[%s კვირა]%s\n' "$BLUE" "$(roman "$week")" "$NC"
                last_week="$week"
            fi
            run_one "$id"
        done < <(manifest)
    else
        for id in "${ids[@]}"; do
            if row_for "$id" >/dev/null 2>&1; then
                week="$(row_for "$id" | cut -d'|' -f1)"
                if [ "$week" != "$last_week" ]; then
                    [ -n "$last_week" ] && echo
                    printf '%s[%s კვირა]%s\n' "$BLUE" "$(roman "$week")" "$NC"
                    last_week="$week"
                fi
            fi
            run_one "$id"
        done
    fi

    echo
    printf '%s=== შედეგი ===%s\n' "$BOLD" "$NC"
    printf '  %sგავიდა:%s      %d\n' "$GREEN" "$NC" "$PASS"
    printf '  %sჩავარდა:%s     %d\n' "$RED" "$NC" "$FAIL"
    printf '  ჯერ არ არის: %d\n' "$TODO"
    printf '  ხელით:       %d\n' "$MANUAL"
    echo

    if [ "$FAIL" -gt 0 ]; then
        printf '%sშემდეგი ნაბიჯი: აირჩიე ერთი ჩავარდნილი დავალება და ნახე გაიდლაინი:%s\n' "$BOLD" "$NC"
        printf '  %s --list      (რომ ნახო id-ები)\n' "$CMD"
        printf '  %s --guide <id>\n' "$CMD"
        exit 1
    fi
    if [ "$TODO" -gt 0 ]; then
        printf '%sყველა დაწერილი დავალება გავიდა. გააგრძელე: %s --list%s\n' "$GREEN" "$CMD" "$NC"
        exit 0
    fi
    printf '%sყველაფერი გავიდა. კარგი მუშაობა!%s\n' "$GREEN" "$NC"
    exit 0
}

main "$@"
