
.eqv EDITOR_CURSOR_TILE 255
.eqv EDITOR_CURSOR_FLAGS 0x40

.data
	editor_tile: .word TILE_BRICK
	# screen position of cursor sprite, -100 means offscreen
	editor_cx:   .word -100
	editor_cy:   .word -100
	# tile coordinates that cursor is over
	editor_ctx:   .word 0
	editor_cty:   .word 0
	# maps from tile type to character for printing out map data
	editor_tilechars: .ascii " #ge%???????????????????????????????????????????"

	# arrays used for switching tiles to place
	.eqv EDITOR_NUMTILES 4
	editor_tilekeys: .byte KEY_1      KEY_2      KEY_3    KEY_4
	editor_keytiles: .byte TILE_EMPTY TILE_BRICK TILE_GOO TILE_GOAL

	cursor_gfx: .byte
		0x01 0x01 0x01 0x00 0x00 0x01 0x01 0x01
		0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x01
		0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x01
		0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
		0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
		0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x01
		0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x01
		0x01 0x01 0x01 0x00 0x00 0x01 0x01 0x01
.text

########################################################################################
########################################################################################
####################################   EDITOR   ########################################
########################################################################################
########################################################################################

editor_load_graphics:
push ra
	la  a0, cursor_gfx
	li  a1, EDITOR_CURSOR_TILE
	li  a2, 1
	jal display_load_sprite_gfx
pop ra
jr ra

#-----------------------------------------

editor_check_input:
push ra
	lw  t0, display_mouse_x
	blt t0, 0, _else
		# pan around
#		lw t0, display_mouse_wheel_x
#		beq t0, 0, _endif_wheel_x
#			lw   t1, display_tm_scx
#			add  t1, t1, t0
#			maxi t1, t1, 0
#			mini t1, t1, 128
#			sw   t1, display_tm_scx
#		_endif_wheel_x:
#
#		lw t0, display_mouse_wheel_y
#		beq t0, 0, _endif_wheel_y
#			lw   t1, display_tm_scy
#			add  t1, t1, t0
#			maxi t1, t1, 0
#			mini t1, t1, 128
#			sw   t1, display_tm_scy
#		_endif_wheel_y:

		# first figure out the tile coords that we're over
		# ctx = (display_mouse_x + display_tm_scx) / 8
		lw  t0, display_mouse_x
		lw  t4, display_tm_scx
		add t0, t0, t4
		div t0, t0, TILE_W
		sw  t0, editor_ctx

		# cty = (display_mouse_y + display_tm_scy) / 8
		lw  t1, display_mouse_y
		lw  t5, display_tm_scy
		add t1, t1, t5
		div t1, t1, TILE_H
		sw  t1, editor_cty

		# now compute the screen pos based on that
		# cx = (editor_ctx * 8) - display_tm_scy
		mul t0, t0, 8
		sub t0, t0, t4
		sw  t0, editor_cx

		# cy = (editor_cty * 8) - display_tm_scy
		mul t1, t1, 8
		sub t1, t1, t5
		sw  t1, editor_cy

		# check for a click
		lw  t0, display_mouse_held
		and t0, t0, MOUSE_LBUTTON
		beq t0, 0, _endif

			lw  a0, editor_ctx
			lw  a1, editor_cty
			lw  a2, editor_tile
			jal place_tile
	j _endif
	_else:
		li t0, -100
		sw t0, editor_cx
		sw t0, editor_cy
	_endif:

	# now do keyboard

	# numbers change tile
	li t6, 0
	_keyloop:
		lb t0, editor_tilekeys(t6)
		sw t0, display_key_pressed
		lw t0, display_key_pressed
		beq t0, 0, _endif_num
			lb t0, editor_keytiles(t6)
			sw t0, editor_tile
		_endif_num:
	add t6, t6, 1
	blt t6, EDITOR_NUMTILES, _keyloop

	# P prints the map data
	display_is_key_pressed t0, KEY_P
	beq t0, 0, _endif_p
		jal editor_print_map
	_endif_p:
pop ra
jr ra

#-----------------------------------------

editor_draw_cursor:
push ra
	lw  a0, editor_cx
	beq a0, -100, _return
	lw  a1, editor_cy
	li  a2, EDITOR_CURSOR_TILE
	li  a3, EDITOR_CURSOR_FLAGS
	jal display_draw_sprite
_return:
pop ra
jr ra

#-----------------------------------------

editor_print_map:
push ra
	print_str "\n\n.ascii\n"
	la t9, display_tm_table # t9 is tilemap pointer

	li t7, 0 # t7 is row
	_row_loop:
		print_str "\t\t\""

		li t6, 0 # t6 is col
		_col_loop:
			# get tile, convert to char, output
			lb  t0, (t9)
			lb  a0, editor_tilechars(t0)
			li  v0, 11
			syscall

			add t9, t9, 2
		add t6, t6, 1
		blt t6, N_TM_COLUMNS, _col_loop

		print_str "\"\n"
	add t7, t7, 1
	blt t7, N_TM_ROWS, _row_loop
pop ra
jr ra