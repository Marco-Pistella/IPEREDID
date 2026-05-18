	.386
	SEGMENT CODE USE16
	ASSUME	CS:CODE,DS:CODE

	DOS_MAX_LEN_PATH	EQU	7Fh
	EDID_LEN		EQU	80h
	N_EDID			EQU	8h
	IPEREDID_ID1		EQU	4F3Eh
	IPEREDID_ID2		EQU	4E24h
	IPEREDID_ID3		EQU	4E25h

	ORG 	100h
	SAVID 	PROC

	jmp	install
new_int_10:
	pushf
	cmp	ax,IPEREDID_ID1
	jne	no_iperedid_id
	cmp	bx,IPEREDID_ID3
	jne	test_installed
	push	cs
	pop	es
	mov	di,OFFSET EDID_data
	mov	ax,4Fh
	popf
	iret
test_installed:
	cmp	bx,IPEREDID_ID2
	jne	no_iperedid_id
	mov	ax,4Fh
	popf
	iret
no_iperedid_id:
	cmp	ax,4F15h
	jne	go_int_10
	cmp	bl,1h
	ja	go_int_10
	cmp	cx,N_EDID - 1h
	ja	go_int_10
	mov	ax,1h
	shl	ax,cl
	test	cs: byte ptr [bios_controller_support],al
	je	valid_bios_support
	mov	ax,4F15h
	popf
	iret
valid_bios_support:
	test	cs: byte ptr [monitor_controller_support],al
	je	valid_monitor_support
	mov	ax,14Fh
	popf
	iret
valid_monitor_support:
	test	cs: byte ptr [iperedid_controller_enable],al
	jne	ok_override_0
	mov	ax,4F15h
	jmp	go_int_10
ok_override_0:
	test	cs: byte ptr [iperedid_controller_override],al
	jne	ok_override_1
	mov	ax,4F15h
	jmp	go_int_10
ok_override_1:
	or	bl,bl
	jne	func_1
	mov	ax,4Fh
	mov	bx,103h
	popf
	iret
func_1:
	push	ds
	push	cs
	pop	ds
	push	si
	push	di
	push	cx	
	imul	si,cx,EDID_LEN
	add	si,OFFSET Edid_data
	cld
	mov	cx,EDID_LEN
	rep	movsb
	mov	ax,4Fh
	pop	cx
	pop	di
	pop	si
	pop	ds
	popf
	iret
go_int_10:
	popf
	pushf
	call 	cs: dword ptr [old_int_10_off]
	iret
old_int_10_off:
	DW	?
old_int_10_seg:
	DW	?
new_int_10_off:
	DW	?
new_int_10_seg:
	DW	?

bios_controller_support:
	DB	0h
monitor_controller_support:
	DB	0h
iperedid_controller_override:
	DB	0h
iperedid_controller_enable:
	DB	0h

EDID_data:
	DB	EDID_LEN * N_EDID DUP (0h)
install:
	mov	dx,OFFSET dos_message_1
	mov	ah,9h
	int	21h
	mov	si,OFFSET void_buffer
	call	Get_Args
	lodsb
	or	al,al
	je	go_install
	cmp	al,1h
	jne	test_command_2
	mov	si,ds: word ptr [si]
	lodsw
	cmp	ds: byte ptr [si],0h
	jne	help_iperedid
	and	ah,0DFh
	cmp	ax,'U/'
	jne	check_status
	mov	ax,IPEREDID_ID1
	mov	bx,IPEREDID_ID2
	int	10h
	cmp	ax,4Fh
	jne	iperedid_fail_install
	mov	ax,IPEREDID_ID1
	mov	bx,IPEREDID_ID3
	int	10h
	cmp	ax,4Fh
	jne	iperedid_fail_install
	push	0
	pop	fs
	mov	dx,OFFSET dos_message_21
	mov	eax,fs: dword ptr [10h * 4]
	cmp	eax,es: dword ptr [new_int_10_off]
	jne	fail_uninstall
	mov	ah,49h
	int	21h
	jc	fail_uninstall
	lds	dx,es: dword ptr [old_int_10_off]
	mov	ax,2510h
	int	21h
	push	cs
	pop	ds
	mov	dx,OFFSET dos_message_22
fail_uninstall:
	mov	ah,9h
	int	21h
	mov	ax,4C00h
	int	21h
check_status:
	cmp	ax,'S/'
	jne	help_iperedid
	mov	ax,IPEREDID_ID1
	mov	bx,IPEREDID_ID2
	int	10h
	cmp	ax,4Fh
	jne	iperedid_fail_install
	mov	ax,IPEREDID_ID1
	mov	bx,IPEREDID_ID3
	int	10h
	cmp	ax,4Fh
	jne	iperedid_fail_install
	mov	ah,9h
	mov	dx,OFFSET dos_message_05
	int	21h
	mov	ax,1h
loop_status_iperedid:
	mov	si,OFFSET dos_message_06
	pusha
	mov	ah,9h
	mov	dx,si
	int	21h
	popa
	inc	ds: byte ptr [si+11h]
	mov	dx,OFFSET dos_message_08
	test	es: byte ptr [di-1h],al
	je	no_enable
	mov	dx,OFFSET dos_message_07
no_enable:
	pusha
	mov	ah,9h
	int	21h
	popa
	mov	dx,OFFSET dos_message_08a
	test	es: byte ptr [di-2h],al
	je	no_override
	mov	dx,OFFSET dos_message_07a
no_override:
	pusha
	mov	ah,9h
	int	21h
	popa
	mov	dx,OFFSET dos_message_08b
	test	es: byte ptr [di-4h],al
	je	no_bios
	mov	dx,OFFSET dos_message_07b
no_bios:
	pusha
	mov	ah,9h
	int	21h
	popa
	mov	dx,OFFSET dos_message_08c
	test	es: byte ptr [di-3h],al
	je	no_monitor
	mov	dx,OFFSET dos_message_07c
no_monitor:
	pusha
	mov	ah,9h
	int	21h
	popa
	add	ax,ax
	or	ah,ah
	je	loop_status_iperedid
	mov	ax,4C00h
	int	21h
test_command_2:
	cmp	al,2h
	je	load_edid
help_iperedid:
	mov	dx,OFFSET dos_message_4
	mov	ah,9h
	int	21h
	mov	ax,4C00h
	int	21h
load_edid:
	lodsw
	xchg	ax,bx
	mov	ax,ds: word ptr [bx]
	or	ah,ah
	jne	help_iperedid
	cmp	al,'0'
	jb	help_iperedid
	cmp	al,'7'
	ja	help_iperedid
	sub	al,'0'
	mov	ds: byte ptr [edid_controller],al
	lodsw
	xchg	ax,bx
	mov	ax,ds: word ptr [bx]
	cmp	al,'/'
	jne	read_edid
	and	ah,0DFh
	cmp	ah,'A'
	jb	help_iperedid
	cmp	ah,'C'
	ja	help_iperedid
	cmp	ds: byte ptr [bx+2],0h
	jne	help_iperedid
	mov	ds: byte ptr [edid_command],ah
	mov	ax,IPEREDID_ID1
	mov	bx,IPEREDID_ID2
	int	10h
	cmp	ax,4Fh
	je	iperedid_installed
iperedid_fail_install:
	mov	dx,OFFSET dos_message_3
	mov	ah,9h
	int	21h
	mov	ax,4C00h
	int	21h
iperedid_installed:
	mov	ax,IPEREDID_ID1
	mov	bx,IPEREDID_ID3
	int	10h
	cmp	ax,4Fh
	jne	iperedid_fail_install
	mov	si,OFFSET dos_message_10
	mov	al,ds: byte ptr [edid_controller]
	add	ds: byte ptr [si+0Ch],al
	mov	dx,OFFSET dos_message_10
	mov	ah,9h
	int	21h
	mov	ah,ds: byte ptr [edid_command]
	mov	al,1h
	mov	cl,ds: byte ptr [edid_controller]
	shl	al,cl
	cmp	ah,'C'
	jne	valid_command
	test	es: byte ptr [di-1h],al
	jne	valid_command
	mov	ah,9h
	mov	dx,OFFSET dos_message_14
	int	21h
	mov	ax,4C00h
	int	21h
valid_command:
	mov	dx,OFFSET dos_message_13
	mov	bx,-2h
	cmp	ah,'C'
	je	exec_command
	mov	bl,-4h
	mov	dx,OFFSET dos_message_11
	cmp	ah,'A'
	je	exec_command
	mov	dx,OFFSET dos_message_12
	mov	bl,-3h
exec_command:		
	xor	es: byte ptr [bx+di],al
	pusha
	mov	ah,9h
	int	21h
	popa
	mov	dx,OFFSET dos_message_15
	test	es: byte ptr [bx+di],al
	jne	view_status
	mov	dx,OFFSET dos_message_16
view_status:	
	mov	ah,9h
	int	21h
	mov	ax,4C00h
	int	21h
read_edid:
	mov	ax,3D00h
	mov	dx,bx
	int	21h
	jnc	valid_io
fail_dos_io:
	mov	dx,OFFSET dos_message_18
	mov	ah,9h
	int	21h
	mov	ax,4C00h
	int	21h
valid_io:
	xchg	ax,bx
	mov	ah,3Fh
	mov	cx,EDID_LEN + 1h
	mov	dx,OFFSET void_buffer
	int	21h
	jc	fail_dos_io
	cmp	ax,EDID_LEN
	jne	fail_edid
	mov	ah,3Eh
	int	21h
	jc	fail_dos_io
	mov	ax,IPEREDID_ID1
	mov	bx,IPEREDID_ID2
	int	10h
	cmp	ax,4Fh
	jne	iperedid_fail_install
	mov	ax,IPEREDID_ID1
	mov	bx,IPEREDID_ID3
	int	10h
	cmp	ax,4Fh
	jne	iperedid_fail_install
	mov	al,1h
	movzx	cx,ds: byte ptr [edid_controller]
	shl	al,cl
	or	es: byte ptr [di-1],al
	or	es: byte ptr [di-2],al
	cld
	imul	cx,EDID_LEN
	add	di,cx
	mov	si,OFFSET void_buffer
	mov	cx,EDID_LEN
	rep	movsb
	mov	si,OFFSET dos_message_20
	mov	al,ds: byte ptr [edid_controller]
	add	ds: byte ptr [si+1Fh],al
	mov	ah,9h
	mov	dx,OFFSET dos_message_20
	int	21h
	mov	ax,4C00h
	int	21h
fail_edid:
	mov	ah,9h
	mov	dx,OFFSET dos_message_19
	int	21h
	mov	ax,4C00h
	int	21h
go_install:
	mov	ax,IPEREDID_ID1
	mov	bx,IPEREDID_ID2
	int	10h
	cmp	ax,4Fh
	jne	not_installed
	mov	dx,OFFSET dos_message_2
	mov	ah,9h
	int	21h
	mov	ax,4C00h
	int	21h
not_installed:
	push	0h
	pop	fs
	push	fs: dword ptr [10h * 4h]
	pop	ds: dword ptr [old_int_10_off]
	mov	dx,OFFSET new_int_10
	mov	ds: word ptr [new_int_10_off],dx
	mov	ds: word ptr [new_int_10_seg],ds
	mov	ax,2510h
	int	21h
	mov	ah,9h
	mov	dx,OFFSET dos_message_17
	int	21h
	mov 	dx,OFFSET install + 0Fh
	int	27h

;#############################################################################

;	DS:SI = Puntatore all'area di memoria in cui stoccare i puntatori agli
;		argomenti passati attraverso la linea di comando (il primo
;               byte rappresenta il numero di argomenti)

Get_Args:

;#############################################################################

	pusha
	xor	bx,bx
	push	si
	inc	si
	mov	di,81h
	movzx	cx,ds: byte ptr [di-1h]
	or	cl,cl
	je	exit_get_args
	mov	al,' '
another_arg:
	rep	scasb
	je	exit_get_args
	inc	bx
	mov	ds: word ptr [si],di
	dec	ds: word ptr [si]
	inc	si
	inc	si
	repne	scasb
	jne	set_final_string
	mov	ds: byte ptr [di-1h],ch
	jmp	another_arg
set_final_string:
	mov	ds: byte ptr [di],ch
exit_get_args:
	pop	si
	mov	ds: byte ptr [si],bl
	popa
	ret

dos_message_1:
	DB	'IperEDID V1.1 by M.Pistella (15/01/2026)',0Dh,0Ah,'$'
dos_message_2:
	DB	'Error 01: IperEDID already installed',0Dh,0Ah,'$'
dos_message_3:
	DB	'Error 02: IperEDID not installed',0Dh,0Ah,'$'
dos_message_4:
	DB	0Dh,0Ah,'Use: IperEDID.COM - Install IperEDID as TSR',0Dh,0Ah
	DB	'     IperEDID.COM <Controller [0..7]> <128 byte EDID binary file>',0Dh,0Ah
	DB	'     IperEDID.COM <Controller [0..7]> <Command: /A|B|C>',0Dh,0Ah
	DB	'     IperEDID.COM </S> - View status',0Dh,0Ah
	DB	'     IperEDID.COM </U> - Uninstall IperEdid',0Dh,0Ah,0Dh,0Ah
	DB	'Commands: A = Switch VESA BIOS 4F15h support',0Dh,0Ah
	DB	'          B = Switch monitor EDID support',0Dh,0Ah
	DB	'          C = Switch override IperEDID support',0Dh,0Ah,'$'
dos_message_05:
	DB	0Dh,0Ah,'Status: Controller Load EDID Override Disable BIOS Disable Monitor',0Dh,0Ah
	DB      '        ----------------------------------------------------------',0Dh,0Ah,'$'
dos_message_06:
	DB	'                 0$'
dos_message_07:
	DB      '       YES$'
dos_message_08:
	DB      '        NO$'
dos_message_07a:
	DB      '      YES$'
dos_message_08a:
	DB      '       NO$'
dos_message_07b:
	DB      '          YES$'
dos_message_08b:
	DB      '           NO$'
dos_message_07c:
	DB      '             YES',0Dh,0Ah,'$'
dos_message_08c:
	DB      '              NO',0Dh,0Ah,'$'
dos_message_09:
	DB	0Dh,0Ah,'$'
dos_message_10:
	DB	'Controller: 0 - $'
dos_message_11:
	DB	'Vesa BIOS EDID support disabled:$'
dos_message_12:
	DB	'Monitor EDID support disabled:$'
dos_message_13:
	DB	'IperEDID override:$'
dos_message_14:
	DB 	'Not handled by IperEDID',0Dh,0Ah,'$'
dos_message_15:
	DB	' Yes',0Dh,0Ah,'$'
dos_message_16:
	DB	' No',0Dh,0Ah,'$'
dos_message_17:
	DB	'Installed',0Dh,0Ah,'$'
dos_message_18:
	DB	'Error 03: DOS I/O',0Dh,0Ah,'$'
dos_message_19:
	DB	'Error 04: Invalid EDID file',0Dh,0Ah,'$'
dos_message_20:
	DB	'EDID file loaded on controller 0',0Dh,0Ah,'$'
dos_message_21:
	DB	'Can''t uninstall IperEDID',0Dh,0Ah,'$'
dos_message_22:
	DB	'IperEDID uninstalled from memory',0Dh,0Ah,'$'

edid_controller:
	DB	?
edid_command:
	DB	?
void_buffer:
	DB	?

	SAVID	ENDP
	CODE	ENDS
	END	SAVID
