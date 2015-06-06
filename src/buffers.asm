
out_buffer_cur dw buffer_out.start

buffer_size = 0x2650

struc buffer start {
	.start = start
	.size = buffer_size
	.end = .start + .size
}

buffer_in_1 buffer program_end
buffer_in_2 buffer buffer_in_1.end
buffer_out buffer buffer_in_2.end
