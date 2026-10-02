; test-env/examples/print_int.asm
; I კვირა, V დღე: int → ASCII კონვერტაცია
; Build:  nasm -f elf64 -g -F dwarf print_int.asm -o print_int.o
;         ld print_int.o -o print_int
; Run:    ./print_int
