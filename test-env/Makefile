# test-env/Makefile
# სამაგალითო Makefile კურსისთვის.
# გამოყენება:
#   make                     - ყველა .asm აწყობს (C interop-ის გარეშე)
#   make prog                - კონკრეტული binary
#   make run-prog            - გაუშვი და აჩვენე exit code
#   make debug-prog          - გაუშვი gdb-ში
#   make verify              - ამოწმებს გარემოს
#   make test                - თვითშემოწმება (solutions/-იდან)
#   make list                - ყველა დავალება და საჭირო ფაილი
#   make progress            - პროგრესი კვირების მიხედვით
#   make guide ID=w1d1_exit42  - გაიდლაინი ერთი დავალებისთვის
#   make new ID=w1d1_exit42    - ცარიელი ჩონჩხის შექმნა solutions/-ში
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

.PHONY: all clean run-% debug-% disasm-% verify test list progress guide new help

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
# ტესტი solutions/ საქაღალდიდან კითხულობს შენს კოდს; ამოხსნები მასში არ არის.
test:
	@bash run-tests.sh

list:
	@bash run-tests.sh --list

progress:
	@bash run-tests.sh --progress

# გამოყენება: make guide ID=w1d1_exit42
guide:
	@test -n "$(ID)" || { echo "მიუთითე ID:  make guide ID=w1d1_exit42"; exit 1; }
	@bash run-tests.sh --guide $(ID)

# გამოყენება: make new ID=w1d1_exit42
new:
	@test -n "$(ID)" || { echo "მიუთითე ID:  make new ID=w1d1_exit42"; exit 1; }
	@bash run-tests.sh --new $(ID)

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
	@echo "  test         - თვითშემოწმება (solutions/-იდან)"
	@echo "  list         - ყველა დავალება და საჭირო ფაილი"
	@echo "  progress     - პროგრესი კვირების მიხედვით"
	@echo "  guide ID=... - გაიდლაინი (მაგ. make guide ID=w1d1_exit42)"
	@echo "  new ID=...   - ცარიელი ჩონჩხი (მაგ. make new ID=w1d1_exit42)"
	@echo "  clean        - წაშალე არტეფაქტები"
	@echo "  help         - ეს დახმარება"