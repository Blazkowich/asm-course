; test-env/examples/c_interop.asm
; III კვირა, II დღე: asm ფუნქცია C-დან გამოსაძახებლად
;
; Build:
;   nasm -f elf64 -g -F dwarf c_interop.asm -o c_interop.o
;   gcc -no-pie -g main.c c_interop.o -o c_interop
; Run:  ./c_interop

default rel

global  sum_array
global  to_upper

extern  printf

section .rodata
    fmt db "sum = %d", 10, 0

section .text

; int sum_array(const int *arr, long n)
; rdi = arr, rsi = n -> eax = ჯამი
sum_array:
    xor  eax, eax           ; sum = 0
    xor  rcx, rcx           ; i = 0
.loop:
    cmp  rcx, rsi
    jge  .done
    add  eax, [rdi + rcx*4] ; sum += arr[i]
    inc  rcx
    jmp  .loop
.done:
    ret

; void to_upper(char *s)
; rdi = s
to_upper:
    test rdi, rdi
    jz   .done
.loop:
    mov  al, [rdi]
    test al, al             ; null terminator?
    jz   .done
    cmp  al, 'a'
    jb   .next
    cmp  al, 'z'
    ja   .next
    sub  al, 0x20           ; 'a' → 'A'
    mov  [rdi], al
.next:
    inc  rdi
    jmp  .loop
.done:
    ret