AS := riscv64-unknown-elf-as
LD := riscv64-unknown-elf-ld
CC := riscv64-unknown-elf-gcc

QEMU := qemu-system-riscv64
GDB := gdb-multiarch

SRC_DIR := src
BUILD_DIR := build
OBJ_DIR := $(BUILD_DIR)/obj
BIN_DIR := $(BUILD_DIR)/bin
BIN := $(BIN_DIR)/entry.elf

ARCH_COMP := -march=rv64gc -mabi=lp64

LDFLAGS := --fatal-warnings -Map=$(BUILD_DIR)/output.map --build-id -nostdlib
ASFLAGS := --fatal-warnings
CFLAGS := -g -Wall -Wextra -pedantic -Werror
CPPFLAGS := -Iinclude -MMD -MP

ALL_CFLAGS := $(CFLAGS) -nostartfiles -nodefaultlibs -ffreestanding $(CPPFLAGS)

LD_SCRIPT := fib.ld

AS_OBJS := $(patsubst %.s, $(OBJ_DIR)/%.o, $(wildcard *.s))

C_SRC := $(wildcard $(SRC_DIR)/*.c)
C_OBJS := $(patsubst $(SRC_DIR)/%.c, $(OBJ_DIR)/%.o, $(C_SRC))

ALL_OBJS := $(AS_OBJS) $(C_OBJS)

all: $(BIN)

run: $(BIN)
	$(QEMU) \
	-machine virt \
	-cpu rv64,pmp=false \
	-smp 1 \
	-m 128M \
	-serial mon:stdio \
	-nographic \
	-bios none \
	-kernel $< \
	-d guest_errors \
	-s \
	-S

dbg:
	$(GDB) $(BIN) -x x.cfg -ex "target remote :1234"

$(BIN): $(ALL_OBJS) $(LD_SCRIPT) | $(BIN_DIR)
	@$(LD) $(LDFLAGS) -T$(LD_SCRIPT) -o $@ $(ALL_OBJS)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)
	@$(CC) $(ALL_CFLAGS) -c -o $@ $<

$(OBJ_DIR)/%.o: %.s | $(OBJ_DIR)
	@$(AS) $(ASFLAGS) -o $@ $<

$(BIN_DIR) $(OBJ_DIR):
	@mkdir -p $@

clean:
	@rm -rf $(BUILD_DIR)/*

.PHONY: all clean run dbg

-include $(ALL_OBJS:.o=.d)
