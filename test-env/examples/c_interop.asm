; test-env/examples/c_interop.asm
; III კვირა, II დღე: asm ფუნქცია C-დან გამოსაძახებლად
;
; Build:
;   nasm -f elf64 -g -F dwarf c_interop.asm -o c_interop.o
;   gcc -no-pie -g main.c c_interop.o -o c_interop
; Run:  ./c_interop
