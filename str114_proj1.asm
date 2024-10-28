# YOUR NAME HERE
# YOUR USERNAME HERE

# set to 1 to become invulnerable
.eqv INVULNERABILITY 1

.include "display_2251_0925.asm"
.include "proj1_constants.asm"
.include "proj1_graphics.asm"
.include "proj1_levels.asm"
.include "proj1_nesfont.asm"

.data
	# boolean, is the game over?
	game_over: .word 0

	# boolean, did they win?
	goal_reached: .word 0

	# how many frames until the next goo update
	goo_timer: .word GOO_DELAY

	# object arrays
	object_type:  .byte 0:MAX_OBJECTS
	player_x:
	object_x:     .byte 0:MAX_OBJECTS
	player_y:
	object_y:     .byte 0:MAX_OBJECTS
	player_vx:
	object_vx:    .byte 0:MAX_OBJECTS
	player_vy:
	object_vy:    .byte 0:MAX_OBJECTS
	player_move_timer:
	object_timer: .byte 0:MAX_OBJECTS

	# direction they're currently facing/moving in
	player_dir:      .byte DIR_S

	# the "main" direction, determined by the first direction they faced when
	# they were last stationary, or by only key held when they let go of that key
	player_main_dir: .byte DIR_S

	# how many pumpkins the player has
	player_pumpkins: .word 0

	# player's health
	player_health: .word 9

	# player's invulnerability frames - 0 is normal, >0 means invulnerable
	player_iframes: .word 0

	# A pair of arrays, indexed by direction, to turn a direction into x/y deltas.
	# e.g. direction_delta_x[DIR_E] is 1, because moving east increments X by 1.
	#                         N  E  S  W
	direction_delta_x: .byte  0  1  0 -1
	direction_delta_y: .byte -1  0  1  0

	# collision probe deltas for two points "in front" of an object,
	# indexed by object direction
	#                     N  E  S  W
	colprobe_dx_a: .byte -3  4 -3 -5
	colprobe_dy_a: .byte -5 -3  4 -3
	#                     N  E  S  W
	colprobe_dx_b: .byte  3  4  3 -5
	colprobe_dy_b: .byte -5  3  4  3

	# backup of the tilemap for use in the goo algorithm
	.align 2
	prev_tm: .half 0:N_TM_TILES
.text

.include "proj1_editor.asm" ################### EDITOR ###################

.globl main
main:
	# initialize display
	li  a0, 15 # ms/frame
	li  a1, 1  # enable framebuffer
	li  a2, 1  # enable tilemap
	jal display_init

	jal load_graphics
	#jal editor_load_graphics ################### EDITOR ###################

	#la  a0, test_level
	la  a0, level_1
	jal load_map

	_loop:
		#jal editor_check_input ################### EDITOR ###################

		jal update_goo_if_needed
		jal update_objects
		jal update_camera

		#jal editor_draw_cursor ################### EDITOR ###################

		jal draw_objects
		jal draw_hud

		jal display_finish_frame
		jal display_clear_auto_sprites
		jal display_clear_text_sprites
	lw t0, game_over
	beq t0, 0, _loop

	jal show_game_over_message
	# exit
	li v0, 10
	syscall

#-----------------------------------------

load_graphics:
push ra
	la  a0, bg_tileset
	li  a1, BG_TILESET_START
	li  a2, BG_TILESET_SIZE
	jal display_load_tm_gfx

	la  a0, bg_palette
	li  a1, BG_PALETTE_START
	li  a2, BG_PALETTE_SIZE
	jal display_load_palette

	la  a0, sprite_tileset
	li  a1, SPRITE_TILESET_START
	li  a2, SPRITE_TILESET_SIZE
	jal display_load_sprite_gfx

	la  a0, sprite_palette
	li  a1, SPRITE_PALETTE_START
	li  a2, SPRITE_PALETTE_SIZE
	jal display_load_palette

	jal load_nes_font_sprite

	# text sprites will be 0-63 (so they're on top)
	li a0, 0
	li a1, 64
	jal display_set_text_sprites

	# normal sprites will be 64-255
	li a0, 64
	li a1, 255
	jal display_set_auto_sprites
pop ra
jr ra

#-----------------------------------------

# loads the data from the array pointed to by a0 into the tilemap
load_map:
push ra
push s0
push s1
push s2
	move s0, a0 # s0 is the array

	li s1, 0
	_row_loop:
	bge s1, 32, _break1
	
		li s2, 0
		_col_loop:
		bge s2, 32, _break2
			
			mul t0, s1, 32 
			add t0, t0, s2
			add t0, t0, s0
			lb a0, (t0)
			
			jal char_to_tile_type
			move a0, s2
			move a1, s1
			move a2, v0
			jal place_tile
			
			
			mul t0, s1, 32 
			add t0, t0, s2
			add t0, t0, s0
			lb a0, (t0)
			jal char_to_obj_type
			
			beq v0, OBJ_EMPTY, _endIf
				# a0 = (col * 8) + 4
				mul t0, s2, 8
				add t0, t0, 4
				move a0, t0
				# a1 = (row * 8) + 4
				mul t0, s1, 8
				add t0, t0, 4
				move a1, t0
				# a2 = v0
				move a2, v0
				jal new_object
			_endIf:
			
		add s2, s2, 1
		j _col_loop 
		_break2:
		
	add s1, s1, 1	
	j _row_loop
	_break1:

	

pop s2
pop s1
pop s0
pop ra
jr ra

#-----------------------------------------

# a0 = character from the map data
# returns one of the TILE_ constants
char_to_tile_type:
push ra
	beq a0, '#', _caseBrick
	beq a0, 'g', _caseGoo
	beq a0, 'e', _caseGooEdge
	beq a0, '%', _caseGoal
	
	j _default
	
	_caseBrick: 
	
	li v0, TILE_BRICK
	j _break 
	
	_caseGoo:
	
	li v0, TILE_GOO
	j _break
	
	_caseGooEdge: 
	
	li v0, TILE_GOO_EDGE
	j _break
	
	_caseGoal: 
	
	li v0, TILE_GOAL
	j _break
	
	_default:
		li v0, TILE_EMPTY
	
	_break: 
pop ra
jr ra

#-----------------------------------------

# a0 = character from the map data
# returns one of the OBJ_ constants, or OBJ_EMPTY to indicate no object there
char_to_obj_type:
push ra

	beq a0, '$', _casePlayer
	beq a0, 'o', _casePumpkin
	
	j _default
	
	_casePlayer:
		li v0, OBJ_PLAYER
		j _break
		
	_casePumpkin:
		li v0, OBJ_PUMPKIN
		j _break
	
	_default: 
		li v0, OBJ_EMPTY
	
	_break:
pop ra
jr ra

#-----------------------------------------

# places a tile in the grid square
# a0 = x
# a1 = y
# a2 = the kind of tile to place
place_tile:
	# display_tm_table[y * 64 + x * 2] = kind
	mul a1, a1, 64
	mul a0, a0, 2
	add t0, a0, a1
	sb  a2, display_tm_table(t0)
jr ra

#-----------------------------------------

# gets the tile at a position
# a0 = x
# a1 = y
get_tile:
	# return display_tm_table[y * 64 + x * 2]
	mul a1, a1, 64
	mul a0, a0, 2
	add t0, a0, a1
	lbu v0, display_tm_table(t0)
jr ra

#-----------------------------------------

is_solid_tile:
push ra
	jal get_tile

	beq v0, TILE_BRICK, _solid
	li v0, 0
	j _return
	_solid:
		li v0, 1
_return:
pop ra
jr ra

#-----------------------------------------

show_game_over_message:
push ra
	# game is over, show either a congratulations or a consolation
	jal display_disable_tm # will work because FB is on

	lw t0, goal_reached
	beq t0, 0, _bad_end
		li a0, 2
		li a1, 60
		lstr a2, "congratulations!"
		jal display_draw_text_sprites
	j _exit
	_bad_end:
		li a0, 20
		li a1, 60
		lstr a2, "aw sorry :("
		jal display_draw_text_sprites
	_exit:

	jal display_finish_frame
pop ra
jr ra

#-----------------------------------------

update_goo_if_needed:
push ra

	

	lw t0, goo_timer
	beq t0, 0, _else
			
		sub t0, t0, 1
		sw t0, goo_timer
		
	j _endIf
	_else:
		li t1, GOO_DELAY
		sw t1, goo_timer
		
		jal update_goo
	_endIf:

pop ra
jr ra

#-----------------------------------------

copy_tm_to_prev_tm:
push ra
	li t9, 0
	_loop:
		# this is an *unrolled* loop. instead of copying just one word on each iteration,
		# we copy several. this greatly reduces the overhead of the increments and branches.
		mul t1, t9, 32
		lw t0, display_tm_table(t1)
		sw t0, prev_tm(t1)
		lw t0, display_tm_table + 4(t1)
		sw t0, prev_tm + 4(t1)
		lw t0, display_tm_table + 8(t1)
		sw t0, prev_tm + 8(t1)
		lw t0, display_tm_table + 12(t1)
		sw t0, prev_tm + 12(t1)
		lw t0, display_tm_table + 16(t1)
		sw t0, prev_tm + 16(t1)
		lw t0, display_tm_table + 20(t1)
		sw t0, prev_tm + 20(t1)
		lw t0, display_tm_table + 24(t1)
		sw t0, prev_tm + 24(t1)
		lw t0, display_tm_table + 28(t1)
		sw t0, prev_tm + 28(t1)
	inc t9
	blt t9, 64, _loop
pop ra
jr ra

#-----------------------------------------

update_goo:
push ra
push s0
    jal copy_tm_to_prev_tm

    li s0, 0
    _loop:
        mul t2, s0, 2
        lb t3, prev_tm(t2)
        #generating random number
			li a0, 0
			li a1, 100
			li v0, 42
			syscall
        bne t3, TILE_GOO_EDGE, _gooEdgeIf
        	bge v0, GOO_EXPAND_PROBABILITY, _expand
				li t4, TILE_GOO
				sb t4, display_tm_table(t3)
	            #left
	            lb t1, prev_tm + -2(t2)
	            bne t1, TILE_EMPTY, _endif_L
	                li t4, TILE_GOO_EDGE
	                sb t4, display_tm_table + -2(t2)
	            _endif_L:
	            
	            #right
	            lb t1, prev_tm + 2(t2)
	            bne t1, TILE_EMPTY, _endIf_R
	            	li t4, TILE_GOO_EDGE
	            	sb t4, display_tm_table + 2(t2)
	            _endIf_R:
	            
	            #above
	            lb t1, prev_tm + -64(t2)
	            bne t1, TILE_EMPTY, _endIf_A
	            	li t4, TILE_GOO_EDGE
	            	sb t4, display_tm_table + -64(t2) 
	            _endIf_A:
	            
	            #below
	            lb t1, prev_tm + 64(t2)
	            bne t1, TILE_EMPTY, _endIf_B
	            	li t4, TILE_GOO_EDGE
	            	sb t4, display_tm_table + 64(t2)
	            _endIf_B:
	    	_expand:
        _gooEdgeIf:

    add s0, s0, 1
    blt s0, N_TM_TILES, _loop

    print_str "update! "
pop s0
pop ra
jr ra
#-----------------------------------------

# a0 = x, a1 = y, a2 = type
# returns index in v0
new_object:
push ra
	# use v0 as the loop index; loop until the object at that index is not active
	li v0, 0
	beq a2, OBJ_PLAYER, _spawn # special case for player
	inc v0 # skip slot 0

	_loop:
		lbu t0, object_type(v0)
		beq t0, OBJ_EMPTY, _spawn
	inc v0
	blt v0, MAX_OBJECTS, _loop

	# no free objects found! exit
	print_str "ran out of objects!\n"
	li v0, 10
	syscall

_spawn:
	# initialize its fields
	sb a0,   object_x(v0)
	sb a1,   object_y(v0)
	sb a2,   object_type(v0)
	sb zero, object_vx(v0)
	sb zero, object_vy(v0)
	sb zero, object_timer(v0)
pop ra
jr ra

#-----------------------------------------

.data
object_update_methods: .word
	0 # dummy entry
	update_player
	update_pumpkin
	update_splash
.text

update_objects:
push ra
push s0
	# update player first, so that they interact with the objects
	# as they were shown on the most recent frame
	li s0, 0
	_loop:
		lbu t0, object_type(s0)
		mul t0, t0, 4
		lw  t0, object_update_methods(t0)
		beq t0, 0, _skip
			move a0, s0
			jalr t0
		_skip:
	inc s0
	blt s0, MAX_OBJECTS, _loop
pop s0
pop ra
jr ra

#-----------------------------------------

.data
object_draw_methods: .word
	0 # for OBJ_EMPTY, they'll be skipped
	draw_player
	draw_pumpkin
	draw_splash
.text

draw_objects:
push ra
push s0
	# loop backwards to draw player last and therefore on top
	li s0, MAX_OBJECTS
	sub s0, s0, 1
	_loop:
		lbu t0, object_type(s0)
		mul t0, t0, 4
		lw  t0, object_draw_methods(t0)
		beq t0, 0, _skip
			move a0, s0
			jalr t0
		_skip:
	dec s0
	bge s0, 0, _loop
pop s0
pop ra
jr ra

#-----------------------------------------

update_player:
push ra
	jal player_check_input

	# if moving, move them
	lb  t0, player_move_timer
	bne t0, 0, _endif_move
		# if player_check_collision() == 0, move the player
		jal player_check_collision
		bne v0, 0, _endif_move
			lbu t0, player_x
			lb  t1, player_vx
			add t0, t0, t1
			sb  t0, player_x

			lbu t0, player_y
			lb  t1, player_vy
			add t0, t0, t1
			sb  t0, player_y
	_endif_move:

	# check what they're standing on
	lbu a0, player_x
	div a0, a0, 8
	lbu a1, player_y
	div a1, a1, 8
	jal get_tile

	beq v0, TILE_GOO, _goo
	beq v0, TILE_GOO_EDGE, _goo
	beq v0, TILE_GOAL, _goal
	j _break
	_goo:
		jal hurt_player
		j _break
	_goal:
		li t0, 1
		sw t0, goal_reached
		sw t0, game_over
		j _break
	_break:

	# update iframes
	lw   t0, player_iframes
	dec  t0
	maxi t0, t0, 0
	sw   t0, player_iframes
pop ra
jr ra

#-----------------------------------------

hurt_player:
push ra
	bne zero, INVULNERABILITY, _return

	# if in iframes, ignore damage
	lw  t0, player_iframes
	bne t0, 0, _return

	# decrement health
	lw   t0, player_health
	dec  t0
	maxi t0, t0, 0
	sb   t0, player_health

	# if health reached 0, game over
	beq t0, 0, _game_over
		# set iframes
		li t0, PLAYER_HURT_IFRAMES
		sw t0, player_iframes
	j _return
	_game_over:
		# set game_over to true
		li t0, 1
		sw t0, game_over
_return:
pop ra
jr ra

#-----------------------------------------

player_check_input:
push ra
	# t1 is 0 if no direction keys are held
	display_is_key_held t0, KEY_W
	display_is_key_held t1, KEY_A
	display_is_key_held t2, KEY_S
	display_is_key_held t3, KEY_D
	or t1, t1, t0
	or t2, t2, t3
	or t1, t1, t2

	# if they are already moving...
	lbu t0, player_move_timer
	bne t0, 0, _not_moving
		beq t1, 0, _all_released
			# no, they're still holding some key.
			jal player_check_wasd_moving

			# set velocity according to direction
			lb  t1, player_dir
			lb  t0, direction_delta_x(t1)
			sb  t0, player_vx
			lb  t0, direction_delta_y(t1)
			sb  t0, player_vy
		j _endif_released
		_all_released:
			# released everything, reset move timer and velocity
			li t0, PLAYER_MOVE_DELAY
			sb t0, player_move_timer
			sb zero, player_vx
			sb zero, player_vy
		_endif_released:
	j _endif_moving
	_not_moving:
		# if no keys pressed, don't even bother
		beq t1, 0, _endif_moving
			# at least one key is pressed. determine direction
			jal player_check_wasd_stationary

			# decrement move timer
			lbu t0, player_move_timer
			dec t0
			maxi t0, t0, 0
			sb  t0, player_move_timer
	_endif_moving:

	jal player_check_throw
pop ra
jr ra

#-----------------------------------------

.data
	# in each of the 4 directions, there are 2 "side" keys to be checked.
	# e.g. when facing north, we need to check for left and right.
	# additionally, we need to check the opposite direction in a slightly
	# different way.
	#                                   N     E     S     W
	player_wasd_key_continue: .byte KEY_W KEY_D KEY_S KEY_A
	player_wasd_key_a:        .byte KEY_A KEY_W KEY_A KEY_W
	player_wasd_dir_a:        .byte DIR_W DIR_N DIR_W DIR_N
	player_wasd_key_b:        .byte KEY_D KEY_S KEY_D KEY_S
	player_wasd_dir_b:        .byte DIR_E DIR_S DIR_E DIR_S
	player_wasd_key_opp:      .byte KEY_S KEY_A KEY_W KEY_D
	player_wasd_dir_opp:      .byte DIR_S DIR_W DIR_N DIR_E

.text

# this is only called if at least one direction key is being pressed.
player_check_wasd_moving:
push ra
	# first check the keys to "the side" of whatever direction the player is facing
	lb t9, player_main_dir

	# t1 = holding first key
	lb t1, player_wasd_key_a(t9)
	sw t1, display_key_held
	lw t1, display_key_held

	# t2 = holding second key
	lb t2, player_wasd_key_b(t9)
	sw t2, display_key_held
	lw t2, display_key_held

	# if holding a == holding b (both pressed or neither pressed)
	bne t1, t2, _differ
		# check for opposite direction
		lb  t1, player_wasd_key_opp(t9)
		sw  t1, display_key_held
		lw  t1, display_key_held
		beq t1, 0, _else_opp
			# pressing opposite direction
			lb t0, player_wasd_dir_opp(t9)
			sb t0, player_dir
		j _endif
		_else_opp:
			# not pressing opposite direction
			# dir = main_dir
			sb t9, player_dir
	j _endif
	_differ:
	# if holding a,
	beq t1, 0, _else
		# dir = direction_a
		lb t0, player_wasd_dir_a(t9)
		sb t0, player_dir
	j _endif
	_else:
		# dir = direction_b
		lb t0, player_wasd_dir_b(t9)
		sb t0, player_dir
	_endif:

	# then, see if we need to update the main direction, if they
	# let go of that key
	lb  t1, player_wasd_key_continue(t9)
	sw  t1, display_key_held
	lw  t1, display_key_held
	bne t1, 0, _return
		# main_dir = dir
		lb t0, player_dir
		sb t0, player_main_dir
	_return:
pop ra
jr ra

#-----------------------------------------

player_check_wasd_stationary:
push ra
	# SOME key has to win. but chances are low that they go from
	# stationary to moving by hitting two directions on the exact
	# same frame.

	display_is_key_held t0, KEY_D
	beq t0, 0, _else_d
		li  t0, DIR_E
		sb  t0, player_dir
		sb  t0, player_main_dir
	j _endif
	_else_d:
	display_is_key_held t0, KEY_A
	beq t0, 0, _else_a
		li  t0, DIR_W
		sb  t0, player_dir
		sb  t0, player_main_dir
	j _endif
	_else_a:
	display_is_key_held t0, KEY_W
	beq t0, 0, _else_w
		li  t0, DIR_N
		sb  t0, player_dir
		sb  t0, player_main_dir
	j _endif
	_else_w:
	display_is_key_held t0, KEY_S
	beq t0, 0, _endif
		li  t0, DIR_S
		sb  t0, player_dir
		sb  t0, player_main_dir
	_endif:
pop ra
jr ra

#-----------------------------------------

player_check_throw:
push ra
push s0
push s1
	# throw a pumpkin when they have some and press space
	lw  t0, player_pumpkins
	beq t0, 0, _return
	display_is_key_pressed t0, KEY_SPACE
	beq t0, 0, _return

	# check one tile in front to see what it is
	lbu t0, player_dir
	lbu s0, player_x
	lb  t1, direction_delta_x(t0)
	mul t1, t1, 8
	add s0, s0, t1
	div s0, s0, 8

	lbu s1, player_y
	lb  t1, direction_delta_y(t0)
	mul t1, t1, 8
	add s1, s1, t1
	div s1, s1, 8

	move a0, s0
	move a1, s1
	jal  get_tile

	beq v0, TILE_BRICK, _return

		# throw!
		move a0, s0
		move a1, s1
		jal throw_pumpkin
	_return:
pop s1
pop s0
pop ra
jr ra

#-----------------------------------------

.data
	splash_offsets: .byte 0, -2, +2, -64, +64
	splash_dx:      .byte 0, -1, +1,   0,   0
	splash_dy:      .byte 0,  0,  0,  -1,  +1
.text

# a0,a1 = tile coords of where pumpkin was thrown
throw_pumpkin:
push ra
push s0
push s1
push s2
push s3
	# s2,s3 = original tile coords
	move s2, a0
	move s3, a1

	# decrement pumpkin counter
	lw  t0, player_pumpkins
	dec t0
	sw  t0, player_pumpkins

	# s1 = pointer into tilemap table
	mul a1, a1, 64
	mul a0, a0, 2
	add s1, a0, a1
	la  t0, display_tm_table
	add s1, s1, t0

	# s0 = loop counter
	li s0, 0
	_loop:
		# t0 = *(ptr + splash_offsets[i])
		lb  t0, splash_offsets(s0)
		add t0, t0, s1
		lbu t0, (t0)

		# don't spawn splashes on top of bricks or the goal
		beq t0, TILE_BRICK, _skip
		beq t0, TILE_GOAL, _skip

			# spawn a splash object at this position
			lb  t0, splash_dx(s0)
			add a0, s2, t0
			mul a0, a0, 8

			lb  t0, splash_dy(s0)
			add a1, s3, t0
			mul a1, a1, 8

			li a2, OBJ_SPLASH
			jal new_object

			li t0, SPLASH_LIFETIME
			sb t0, object_timer(v0)
		_skip:
	inc s0
	blt s0, 5, _loop
pop s3
pop s2
pop s1
pop s0
pop ra
jr ra

#-----------------------------------------

player_check_collision:
push ra
	lbu t0, player_dir

	lbu a0, player_x
	lb  t1, colprobe_dx_a(t0)
	add a0, a0, t1
	div a0, a0, 8
	lbu a1, player_y
	lb  t1, colprobe_dy_a(t0)
	add a1, a1, t1
	div a1, a1, 8
	jal is_solid_tile
	bne v0, 0, _return_1

	lbu t0, player_dir

	lbu a0, player_x
	lb  t1, colprobe_dx_b(t0)
	add a0, a0, t1
	div a0, a0, 8
	lbu a1, player_y
	lb  t1, colprobe_dy_b(t0)
	add a1, a1, t1
	div a1, a1, 8
	jal is_solid_tile
	bne v0, 0, _return_1

	li v0, 0
	j _return
_return_1:
	li v0, 1
_return:
pop ra
jr ra

#-----------------------------------------

draw_player:
push ra
	lw  t0, player_iframes
	and t0, t0, 4
	beq t0, 0, _draw
	j _return

_draw:
	lbu a0, player_x
	lw  t0, display_tm_scx
	sub a0, a0, t0
	sub a0, a0, 4

	lbu a1, player_y
	lw  t0, display_tm_scy
	sub a1, a1, t0
	sub a1, a1, 4

	lbu a2, player_dir
	add a2, a2, PLAYER_TILESET_START

	li  a3, 0x10
	jal display_draw_sprite
_return:
pop ra
jr ra

#-----------------------------------------

update_pumpkin:
push ra
	lbu t0, object_x(a0)
	lbu t1, player_x
	sub t0, t0, t1
	abs t0, t0
	bgt t0, 7, _return

	lbu t0, object_y(a0)
	lbu t1, player_y
	sub t0, t0, t1
	abs t0, t0
	bgt t0, 7, _return

		sb zero, object_type(a0)

		lw  t0, player_pumpkins
		inc t0
		sw  t0, player_pumpkins
	_return:
pop ra
jr ra

#-----------------------------------------

draw_pumpkin:
push ra
	move t9, a0

	lbu a0, object_x(t9)
	lw  t0, display_tm_scx
	sub a0, a0, t0
	sub a0, a0, 4

	lbu a1, object_y(t9)
	lw  t0, display_tm_scy
	sub a1, a1, t0
	sub a1, a1, 4

	lw  t0, display_frame_counter
	and t0, t0, 32
	beq t0, 0, _dont
		sub a1, a1, 1
	_dont:

	li  a2, PUMPKIN_TILESET_START
	li  a3, 0x10
	jal display_draw_sprite
pop ra
jr ra

#-----------------------------------------

update_splash:
push ra
push s0
	move s0, a0

	# set tile under this to empty
	lbu a0, object_x(s0)
	div a0, a0, 8
	lbu a1, object_y(s0)
	div a1, a1, 8
	li  a2, TILE_EMPTY
	jal place_tile

	# decrement timer and despawn when 0
	lbu  t0, object_timer(s0)
	dec  t0
	maxi t0, t0, 0
	sb   t0, object_timer(s0)
	bne t0, 0, _return
		sb zero, object_type(s0)
	_return:
pop s0
pop ra
jr ra

#-----------------------------------------

draw_splash:
push ra
	move t9, a0

	lbu a0, object_x(t9)
	lw  t0, display_tm_scx
	sub a0, a0, t0

	lbu a1, object_y(t9)
	lw  t0, display_tm_scy
	sub a1, a1, t0

	li  a2, SPLASH_TILESET_START
	li  a3, 0x10
	jal display_draw_sprite
pop ra
jr ra

#-----------------------------------------

update_camera:
push ra
	# calculate player_x + CAMERA_OFFSET_X and clamp it to [0, CAMERA_MAX_X]
	lbu  t0, player_x
	add  t0, t0, CAMERA_OFFSET_X
	maxi t0, t0, 0
	mini t0, t0, CAMERA_MAX_X
	sw   t0, display_tm_scx

	# similar for camera Y
	lbu  t0, player_y
	add  t0, t0, CAMERA_OFFSET_Y
	maxi t0, t0, 0
	mini t0, t0, CAMERA_MAX_Y
	sw   t0, display_tm_scy
pop ra
jr ra

#-----------------------------------------

draw_hud:
push ra
	li  a0, 4
	li  a1, 116
	li  a2, PUMPKIN_TILESET_START
	li  a3, 0x10
	jal display_draw_sprite

	li  a0, 15
	li  a1, 117
	lw  a2, player_pumpkins
	jal display_draw_int_sprites

	li  a0, 106
	li  a1, 117
	li  a2, HEART_TILESET_START
	li  a3, 0x10
	jal display_draw_sprite

	li  a0, 116
	li  a1, 117
	lw  a2, player_health
	jal display_draw_int_sprites
pop ra
jr ra
