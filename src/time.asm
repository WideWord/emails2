
proc get_timestamp uses bx cx dx
	mov ah, 2ch
	int 21h

	mov ah, 0
	mov al, cl
	mov bx, 60
	push dx
	mul bx
	pop dx
	mov ch, 0
	mov cl, dh
	add ax, cx

	mov bx, 100
	push dx
	mul bx
	pop dx
	mov dh, 0
	add ax, dx

	ret
endp

proc print_ms
	mov dx, 0
	mov cx, 100
	idiv cx
	stdcall print_int, ax

	push ax
	push dx
	mov ah, 02h
	mov dl, '.'
	int 21h
	pop dx
	pop ax

	stdcall print_int, dx
	ret
endp
