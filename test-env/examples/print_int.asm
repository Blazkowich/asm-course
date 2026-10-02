; test-env/examples/print_int.asm
; I კვირა, V დღე: int → ASCII კონვერტაცია
; Build:  nasm -f elf64 -g -F dwarf print_int.asm -o print_int.o
;         ld print_int.o -o print_int
; Run:    ./print_int

global _start

section .bss
    buf resb 32

section .text

; print_int(rax = n)
; ანგრევს: rax, rbx, rcx, rdx, rsi, rdi, r8
print_int:
    push rbp
    mov  rbp, rsp

    lea  rsi, [buf + 31]    ; ბოლო პოზიცია
    mov  byte [rsi], 10     ; newline
    mov  rcx, 10            ; divisor
    xor  r8, r8             ; digit count = 0
    mov  rbx, rax           ; n

    ; თუ n == 0, სპეციალური შემთხვევა
    test rbx, rbx
    jnz  .loop
    dec  rsi
    mov  byte [rsi], '0'
    inc  r8
    jmp  .print

.loop:
    xor  rdx, rdx
    mov  rax, rbx
    div  rcx                ; rax = n/10, rdx = n%10
    add  dl, '0'
    dec  rsi
    mov  [rsi], dl
    inc  r8
    mov  rbx, rax
    test rbx, rbx
    jnz  .loop

.print:
    mov  rax, 1             ; sys_write
    mov  rdi, 1             ; stdout
    mov  rdx, r8
    inc  rdx                ; + newline
    syscall

    pop  rbp
    ret

_start:
    mov  rax, 5050
    call print_int

    mov  rax, 0
    call print_int

    mov  rax, 42
    call print_int

    mov  rax, 60
    xor  rdi, rdi
    syscall