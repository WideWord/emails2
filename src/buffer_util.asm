
proc get_buffer_start, buffer_id
	bt [buffer_id], 0
	jc @f
		mov ax, buffer_in_1.start
		ret
	@@:
		mov ax, buffer_in_2.start
		ret
endp

proc get_buffer_end, buffer_id
	bt [buffer_id], 0
	jc @f
		mov ax, buffer_in_1.end
		ret
	@@:
		mov ax, buffer_in_2.end
		ret
endp

macro get_buffer_at_ptr_inl result, pointer {
	cmp pointer, buffer_in_1.end
	setge result
}

proc get_buffer_at_ptr, pointer
	cmp [pointer], buffer_in_1.end
	;setge al
	;xor ah, ah
	;ret

	jge @f
		mov ax, 0
		ret
	@@:
		mov ax, 1
		ret
endp

