# test-env/examples/Makefile
# ცალკე Makefile examples/ საქაღალდისთვის.
# უბრალოდ მიუთითე ზედა Makefile-ზე:
#
#   cd examples
#   make -f ../Makefile run-hello
#
# ან გამოიყენე ეს ფაილი, როგორც self-contained:

ASM       := nasm
LD        := ld
ASM_FLAGS := -f elf64 -g -F dwarf

ASM_SRCS  := $(wildcard *.asm)
ASM_BINS  := $(ASM_SRCS:.asm=)

.PHONY: all clean help run-% debug-%

all: $(ASM_BINS)

%.o: %.asm
	$(ASM) $(ASM_FLAGS) $< -o $@

%: %.o
	$(LD) $< -o $@

run-%: %
	-@./$<; echo "exit: $$?"

debug-%: %
	gdb -q ./$<

clean:
	rm -f *.o $(ASM_BINS)

help:
	@echo "examples/Makefile"
	@echo "  all          - ააწყვე ყველა .asm"
	@echo "  <name>       - ააწყვე კონკრეტული"
	@echo "  run-<name>   - გაუშვი"
	@echo "  debug-<name> - gdb"
	@echo "  clean        - წაშალე"