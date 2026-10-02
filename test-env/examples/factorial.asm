; test-env/examples/factorial.asm
; II კვირა, II დღე: რეკურსია
; Build:  nasm -f elf64 -g -F dwarf factorial.asm -o factorial.o
;         ld factorial.o -o factorial
; Run:    ./factorial; echo $?

global _start

section .text

; factorial(rdi = n) -> rax = n!
factorial:
    cmp  rdi, 1
    jle  .base
    push rdi
    dec  rdi
    call factorial
    pop  rdi
    imul rax, rdi
    ret
.base:
    mov  rax, 1
    ret

_start:
    mov  rdi, 5
    call factorial          ; rax = 120
    mov  rdi, rax
    mov  rax, 60
    syscall                 ; exit(120)