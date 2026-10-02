; test-env/examples/georgian.asm
; I კვირა, III დღე: ქართული ტექსტი UTF-8-ში
; Build:  nasm -f elf64 -g -F dwarf georgian.asm -o georgian.o
;         ld georgian.o -o georgian
; Run:    ./georgian

global _start

section .data
    ; ფაილი UTF-8 უნდა იყოს!
    msg     db "გამარჯობა, სამყარო!", 10
    msg_len equ $ - msg

    ; შენიშვნა: 18 სიმბოლო × 3 ბაიტი = 54 ბაიტი + 1 newline = 55
    ; msg_len ავტომატურად სწორია

section .text
_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, msg_len
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall