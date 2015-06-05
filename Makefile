
all: bin/emails.com

bin/emails.com: src/emails.asm gen/char_table.asm src/buffer_util.asm src/buffers.asm src/const.inc src/debug.asm src/find_emails.asm src/init.asm src/io.asm src/fsm.asm
	fasm src/emails.asm bin/emails.com

gen/char_table.asm: gen/gen_table
	gen/gen_table >gen/char_table.asm

gen/gen_table: src/gen_table.c
	clang src/gen_table.c -o gen/gen_table
