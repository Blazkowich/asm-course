# test-env/Makefile
# სამაგალითო Makefile კურსისთვის.
# გამოყენება:
#   make                     - ყველა .asm აწყობს (C interop-ის გარეშე)
#   make prog                - კონკრეტული binary
#   make run-prog            - გაუშვი და აჩვენე exit code
#   make debug-prog          - გაუშვი gdb-ში
#   make verify              - ამოწმებს გარემოს
#   make test                - უშვებს ყველა ტესტს
#   make clean               - წაშლის .o და binaries

# --- კონფიგურაცია ---
ASM        := nasm
LD         := ld
CC         := gcc
GDB        := gdb
OBJDUMP    := objdump

ASM_FLAGS  := -f elf64 -g -F dwarf
LD_FLAGS   :=
CC_FLAGS   := -no-pie -g

# .asm ფაილები (auto-detect)
ASM_SRCS   := $(wildcard *.asm)
ASM_BINS   := $(ASM_SRCS:.asm=)

# .c ფაილები (C interop)
C_SRCS     := $(wildcard *.c)
C_BINS     := $(C_SRCS:.c=)

.PHONY: all clean run-% debug-% disasm-% verify test help

# --- ნაგულისხმევი სამიზნე ---
all: $(ASM_BINS)

# --- Assembly → object → binary ---
%.o: %.asm
	$(ASM) $(ASM_FLAGS) $< -o $@

%: %.o
	$(LD) $(LD_FLAGS) $< -o $@

# --- C ფაილები ---
%: %.c
	$(CC) $(CC_FLAGS) $< -o $@

# --- გაშვება ---
# გამოყენება: make run-prog  (prog = ფაილის სახელი .asm-ის გარეშე)
run-%: %
	@echo "=== $< ==="
	-@./$<; echo "exit: $$?"

# --- Debug ---
debug-%: %
	$(GDB) -q ./$<

# --- Disassembly ---
disasm-%: %
	$(OBJDUMP) -d -M intel --no-show-raw-insn $< | less

# --- გარემოს შემოწმება ---
verify:
	@bash verify.sh

# --- ტესტები ---
test:
	@bash run-tests.sh

# --- დასუფთავება ---
clean:
	rm -f *.o $(ASM_BINS) $(C_BINS)
	rm -rf *.dSYM

# --- დახმარება ---
help:
	@echo "ხელმისაწვდომი სამიზნეები:"
	@echo "  all          - ააწყვე ყველა .asm ფაილი"
	@echo "  <name>       - ააწყვე კონკრეტული binary (name.asm → name)"
	@echo "  run-<name>   - გაუშვი და აჩვენე exit code"
	@echo "  debug-<name> - გაუშვი gdb-ში"
	@echo "  disasm-<name>- disassembly (objdump)"
	@echo "  verify       - შეამოწმე გარემო"
	@echo "  test         - გაუშვი ტესტები"
	@echo "  clean        - წაშალე არტეფაქტები"
	@echo "  help         - ეს დახმარება"