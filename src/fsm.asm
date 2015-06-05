
macro norm_si_back {
	cmp si, buffer_in_1.start - 1
	jg @f
		add si, 2 * buffer_size
	@@:
}

macro norm_si_forward {
	cmp si, buffer_in_2.end
	jl @f
		sub si, 2 * buffer_size
	@@:
}

macro norm_backward x {
	cmp x, buffer_in_1.start - 1
	jg @f
		add x, 2 * buffer_size
	@@:
}

macro norm_forward x {
	cmp x, buffer_in_2.end
	jl @f
		sub x, 2 * buffer_size
	@@:
}

proc find_email_start uses si cx bx
	
	;mov ax, [search_pos]
	;sub ax, 64
	;norm_backward ax
	;ret

	mov si, [search_pos]
	sub si, 1
	norm_backward si

	mov cx, max_username_size
	std
	mov bx, char_table


	.loop_start:
		lodsb
		xlatb
		norm_backward si
		bt ax, ct_is_allowed
		jnc .exit
	loop .loop_start
	.exit:

	add si, 2
	norm_forward si
	norm_backward si

	;cmp si, [search_pos]
	;je .fail

	mov ax, si
	ret
.fail:
	mov ax, 0
	ret
endp

proc find_email_end uses si cx bx

	;mov ax, [search_pos]
	;add ax, 2
	;norm_forward ax
	;ret

	mov si, [search_pos]
	add si, 1

	norm_si_forward

	mov cx, max_domain_size
	cld
	mov bx, char_table

	.loop_start:
		lodsb
		xlatb
		norm_si_forward
		bt ax, ct_is_allowed
		jnc .exit

		cmp si, [data_end_ptr]
		je .eof

	loop .loop_start
	.exit:

	dec si
	norm_backward si
	.eof:
	cmp si, [search_pos]
	je .fail

	mov ax, si
	ret

.fail:
	mov ax, 0
	ret
endp