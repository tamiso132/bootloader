DEBUG_OUT := target/amd64/debug/bootloader
SRC_ROOT = $(abspath .)

default:run

run:build_debug qemu

qemu:
	qemu-system-x86_64 -drive format=raw,file=${DEBUG_OUT}.bin -s -S --no-reboot -monitor stdio -d in_asm -m 1024M

build_debug:
	@cargo build --target ${SRC_ROOT}/targets/amd64/amd64.json
	@cp ${DEBUG_OUT} ${DEBUG_OUT}.not_stripped
	@objcopy $(DEBUG_OUT) ${DEBUG_OUT}.bin -O binary

