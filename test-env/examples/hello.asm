; test-env/examples/hello.asm
; I კვირა, III დღე: Hello World
; Build:  nasm -f elf64 -g -F dwarf hello.asm -o hello.o
;         ld hello.o -o hello
; Run:    ./hello

global _start

section .data
    msg     db "Hello, Assembly!", 10
    msg_len equ $ - msg

section .text
_start:
    ; write(1, msg, msg_len)
    mov rax, 1              ; sys_write
    mov rdi, 1              ; fd = stdout
    mov rsi, msg            ; buf
    mov rdx, msg_len        ; count
    syscall

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall