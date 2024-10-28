# driver philosophy: if it's more than a single load or store, or
# if it isn't blindingly obvious what it does (e.g. "magical stores"),
# make it a driver function. otherwise, it's unnecessary.

# e.g. loading from display_mouse_held or changing display_tm_scx are
# both so simple and obvious that they don't need a driver function.
# but frame sync is "sw zero, display_sync" which is just baffling.

.include "display_vars_2251_0925.asm"
.include "display_constants_2251_0925.asm"
.include "macros.asm"

# -------------------------------------------------------------------------------------------------
# Display control and frame sync
# -------------------------------------------------------------------------------------------------

# void display_init(int msPerFrame, bool enableFB, bool enableTM)
#   Initialize the display, putting it into enhanced mode, and resetting everything.
#   This should be the first thing you call after any non-display-related setup!
display_init:
	sll a0, a0, DISPLAY_MODE_MS_SHIFT
	beq a1, 0, _no_fb
		or a0, a0, DISPLAY_MODE_FB_ENABLE
	_no_fb:

	beq a2, 0, _no_tm
		or a0, a0, DISPLAY_MODE_TM_ENABLE
	_no_tm:
	or  a0, a0, DISPLAY_MODE_ENHANCED
	sw  a0, display_ctrl

	# reset everything! you might think we should do this *first*, but we
	# don't actually know if the display is in enhanced mode before the
	# above store.
	sw zero, display_reset

	# finally force a display update to clear the display.
	sw zero, display_sync
jr ra

# -------------------------------------------------------------------------------------------------

# void display_enable_fb()
#   enable the framebuffer if it isn't already.
display_enable_fb:
	lw t0, display_ctrl
	or t0, t0, DISPLAY_MODE_FB_ENABLE
	sw t0, display_ctrl
jr ra

# -------------------------------------------------------------------------------------------------

# void display_disable_fb()
#   disable the framebuffer if it's enabled.
#   if the tilemap is not enabled, this has no effect. (at least one has to be enabled.)
display_disable_fb:
	lw  t0, display_ctrl
	and t1, t0, DISPLAY_MODE_TM_ENABLE
	beq t1, 0, _return

	# god I wish MARS could do constant expressions.
	li  t1, DISPLAY_MODE_FB_ENABLE
	not t1, t1
	and t0, t0, t1
	sw  t0, display_ctrl
_return:
jr ra

# -------------------------------------------------------------------------------------------------

# void display_enable_tm()
#   enable the tilemap if it isn't already.
display_enable_tm:
	lw t0, display_ctrl
	or t0, t0, DISPLAY_MODE_TM_ENABLE
	sw t0, display_ctrl
jr ra

# -------------------------------------------------------------------------------------------------

# void display_disable_tm()
#   disable the tilemap if it's enabled.
#   if the framebuffer is not enabled, this has no effect. (at least one has to be enabled.)
display_disable_tm:
	lw  t0, display_ctrl
	and t1, t0, DISPLAY_MODE_FB_ENABLE
	beq t1, 0, _return

	# god I wish MARS could do constant expressions.
	li  t1, DISPLAY_MODE_TM_ENABLE
	not t1, t1
	and t0, t0, t1
	sw  t0, display_ctrl
_return:
jr ra

# -------------------------------------------------------------------------------------------------

# void display_finish_frame()
#   call this at the end of each frame to display the graphics, update
#   input, and wait the appropriate amount of time until the next frame.
display_finish_frame:
	sw zero, display_sync
	lw zero, display_sync
jr ra

# -------------------------------------------------------------------------------------------------
# Input
# -------------------------------------------------------------------------------------------------

# sets %reg to 1 if %key is being held, 0 if not
.macro display_is_key_held %reg, %key
	li %reg, %key
	sw %reg, display_key_held
	lw %reg, display_key_held
.end_macro

# -------------------------------------------------------------------------------------------------

# sets %reg to 1 if %key was pressed on this frame, 0 if not
.macro display_is_key_pressed %reg, %key
	li %reg, %key
	sw %reg, display_key_pressed
	lw %reg, display_key_pressed
.end_macro

# -------------------------------------------------------------------------------------------------

# sets %reg to 1 if %key was released on this frame, 0 if not
.macro display_is_key_released %reg, %key
	li %reg, %key
	sw %reg, display_key_released
	lw %reg, display_key_released
.end_macro

# -------------------------------------------------------------------------------------------------
# Palette
# -------------------------------------------------------------------------------------------------

# void display_load_palette(int* palette, int startIndex, int numColors)
#   Loads palette entries into palette RAM. Each palette entry is a word in the format
#   0xRRGGBB, e.g. 0xFF0000 is pure red, 0x00FF00 is pure green, etc.
#   a0 is the address of palette array to load (use la for this argument).
#   a1 is the first color index to load it into. don't forget, index 0 is the background color!
#   a2 is the number of colors to load. shouldn't be < 1 or > 256, or else weird shit happens
display_load_palette:
	mul a1, a1, 4
	la  t0, display_palette_ram
	add a1, a1, t0

	_loop:
		lw t0, (a0)
		sw t0, (a1)
		add a0, a0, 4
		add a1, a1, 4
	sub a2, a2, 1
	bgt a2, 0, _loop
jr ra

# -------------------------------------------------------------------------------------------------
# Framebuffer
# -------------------------------------------------------------------------------------------------

# void display_set_pixel(int x, int y, int color)
#   sets 1 pixel to a given color. valid colors are in the range [0, 255].
#   (0, 0) is in the top LEFT, and Y increases DOWNWARDS!
display_set_pixel:
	blt a0, 0, _return
	bge a0, DISPLAY_W, _return
	blt a1, 0, _return
	bge a1, DISPLAY_H, _return

	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	sb  a2, display_fb_ram(t0)
_return:
jr  ra

# -------------------------------------------------------------------------------------------------

# void display_draw_hline(int x, int y, int width, int color)
#   draws a horizontal line on the framebuffer starting at (x, y) and going to (x + width - 1, y).
.globl display_draw_hline
display_draw_hline:
	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	la  t1, display_fb_ram
	add t0, t0, t1

	_loop:
		sb  a3, (t0)
		inc t0
	dec  a2
	bnez a2, _loop
jr ra

# -------------------------------------------------------------------------------------------------

# void display_draw_hline(int x, int y, int height, int color)
#   draws a vertical line on the framebuffer starting at (x, y) and going to (x, y + height - 1).
display_draw_vline:
	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	la  t1, display_fb_ram
	add t0, t0, t1

	_loop:
		sb  a3, (t0)
		add t0, t0, DISPLAY_W
	dec  a2
	bnez a2, _loop
jr ra

# -------------------------------------------------------------------------------------------------

# void display_draw_line(int x1, int y1, int x2, int y2, int color: v1)
#   NAUGHTY: uses v1 as the color argument, er, vargument. sue me.
#   Bresenham's line algorithm, integer error version adapted from wikipedia
#   not SUPER fast, use display_draw_hline/display_draw_vline if you only need those directions
.globl display_draw_line
display_draw_line:
	# dx:t0 =  abs(x2-x1);
	sub t0, a2, a0
	abs t0, t0

	# sx:t1 = x1<x2 ? 1 : -1;
	slt t1, a0, a2 # 1 if true, 0 if not
	add t1, t1, t1 # 2 if true, 0 if not
	sub t1, t1, 1  # 1 if true, -1 if not

	# dy:t2 = -abs(y2-y1);
	sub t2, a3, a1
	abs t2, t2
	neg t2, t2

	# sy:t3 = y1<y2 ? 1 : -1;
	slt t3, a1, a3
	add t3, t3, t3
	sub t3, t3, 1

	# err:t4 = dx+dy;
	add t4, t0, t2

	_loop:
		# plot(x1, y1);
		sll t7, a1, DISPLAY_W_SHIFT
		add t7, t7, a0
		sb  v1, display_fb_ram(t7)

		# if(x1==x2 && y1==y2) break;
		bne a0, a2, _continue
		beq a1, a3, _return

		_continue:
			add t5, t4, t4 # e2:t5 = 2*err;

			# if(e2 >= dy)
			blt t5, t2, _dx
				add t4, t4, t2 # err += dy;
				add a0, a0, t1 # x1 += sx;

			_dx:
				# if(e2 <= dx)
				bgt t5, t0, _loop
					add t4, t4, t0 # err += dx;
					add a1, a1, t3 # y1 += sy;

	j _loop
_return:
jr ra

# -------------------------------------------------------------------------------------------------

# void display_fill_rect(int x, int y, int width, int height, int color: v1)
#   NAUGHTY: uses v1 as the color argument, er, vargument. sue me.
#   fills a rectangle of pixels (x, y) to (x + width - 1, y + height - 1) with a solid color.
display_fill_rect:
	# turn w/h into x2/y2
	add a2, a2, a0
	add a3, a3, a1

	# turn y1/y2 into addresses
	la  t0, display_fb_ram
	sll a1, a1, DISPLAY_W_SHIFT
	add a1, a1, t0
	add a1, a1, a0
	sll a3, a3, DISPLAY_W_SHIFT
	add a3, a3, t0

	move t0, a1
	_loop_y:
		move t1, t0
		move t2, a0
		_loop_x:
			sb   v1, (t1)
			inc t1
		inc t2
		blt t2, a2, _loop_x
	add t0, t0, DISPLAY_W
	blt t0, a3, _loop_y
jr ra

# -------------------------------------------------------------------------------------------------

# void display_fill_rect_fast(int x, int y, int width, int height, int color: v1)
#   NAUGHTY: uses v1 as the color argument, er, vargument. sue me.
#   same as display_fill_rect, but works faster for rectangles whose X and width are multiples
#   of 4. IF X IS NOT A MULTIPLE OF 4, IT WILL CRASH. IF WIDTH IS NOT A MULTIPLE OF 4, IT WILL
#   DO WEIRD THINGS.
display_fill_rect_fast:
	# duplicate color across v1
	and v1, v1, 0xFF
	mul v1, v1, 0x01010101
	add a2, a2, a0 # a2 = x2
	add a3, a3, a1 # a3 = y2

	# t0 = display base address
	la t0, display_fb_ram

	# a1 = start address
	sll a1, a1, DISPLAY_W_SHIFT
	add a1, a1, t0
	add a1, a1, a0

	# a3 = end address
	sll a3, a3, DISPLAY_W_SHIFT
	add a3, a3, t0

	# t0 = current row's start address
	move t0, a1
	_loop_y:
		move t1, t0 # t1 = current address
		move t2, a0 # t2 = current x
		_loop_x:
			sw   v1, (t1)
			add t1, t1, 4
		add t2, t2, 4
		blt t2, a2, _loop_x
	add t0, t0, DISPLAY_W
	blt t0, a3, _loop_y
jr ra

# -------------------------------------------------------------------------------------------------
# Tilemap
# -------------------------------------------------------------------------------------------------

# void display_set_tile(int tx, int ty, int tileIndex, int flags)
#   sets the tile at *tile* coordinates (tx, ty) to the given tile index and flags.
display_set_tile:
	mul a1, a1, BYTES_PER_TM_ROW
	mul a0, a0, TM_ENTRY_SIZE
	add a1, a1, a0
	sb a2, display_tm_table(a1)
	sb a3, display_tm_table + 1(a1)
jr ra

# TODO: display_fill_tilemap
# TODO: display_fill_tilemap_rect
# TODO: some stuff to help with infinite scrolling

# -------------------------------------------------------------------------------------------------
# Graphics data
# -------------------------------------------------------------------------------------------------

# void display_load_tm_gfx(int* src, int firstDestTile, int numTiles)
#   loads numTiles tiles of graphics into the tilemap graphics area.
#   a0 is the address of the array from which the graphics will be copied.
#   a1 is the first tile in the graphics area that will be overwritten.
#   a2 is the number of tiles to copy. Shouldn't be < 0.
display_load_tm_gfx:
	mul a1, a1, BYTES_PER_TILE
	la  t0, display_tm_gfx
	add a1, a1, t0
	mul a2, a2, BYTES_PER_TILE
j PRIVATE_tilecpy

# -------------------------------------------------------------------------------------------------

# void display_load_sprite_gfx(int* src, int firstDestTile, int numTiles)
#   loads numTiles tiles of graphics into the sprite graphics area.
#   a0 is the address of the array from which the graphics will be copied.
#   a1 is the first tile in the graphics area that will be overwritten.
#   a2 is the number of tiles to copy. Shouldn't be < 0.
display_load_sprite_gfx:
	mul a1, a1, BYTES_PER_TILE
	la  t0, display_spr_gfx
	add a1, a1, t0
	mul a2, a2, BYTES_PER_TILE
j PRIVATE_tilecpy

# -------------------------------------------------------------------------------------------------

# PRIVATE FUNCTION, DO NOT CALL!!!!!!!
#  like memcpy, but (src, dest, bytes) instead of (dest, src, bytes).
#  also assumes number of bytes is a nonzero multiple of 4
#  a0 = source
#  a1 = target
#  a2 = number of bytes
PRIVATE_tilecpy:
	_loop:
		lw t0, (a0)
		sw t0, (a1)
		add a0, a0, 4
		add a1, a1, 4
		sub a2, a2, 4
	bgt a2, 0, _loop
jr ra

# -------------------------------------------------------------------------------------------------
# Text
# -------------------------------------------------------------------------------------------------

# Very simple text system.
# There can be 1 font loaded at any given time. A font consists of a translation table that
# translates from 32-based ASCII (that is, char - 32, because 32 is the first printable
# ASCII character) to tile indexes, and a set of graphics which it is responsible for loading
# into either tilemap or sprite graphics RAM.

# Font should probably also call display_set_font_xlate_table when loaded.

.data
	font_xlate_table:   .word 0

	# range of sprite indexes used by the sprite text functions
	text_sprites_start: .word 0
	text_sprites_end:   .word N_SPRITES

	# index of most-recently-allocated sprite (== text_sprites_end if none allocated)
	# this is DECREMENTED to allocate sprites, and when it is < text_sprites_start,
	# there are no sprites left.
	text_sprites_cur:   .word 0
.text

PRIVATE_font_xlate_table_not_set:
	print_str "FATAL: font translation table has not been set.\n"
	li v0, 10
	syscall

# -------------------------------------------------------------------------------------------------

# void display_set_font_xlate_table(ubyte* table)
#   Sets the font translation table. Must be called before any other text function will work.
display_set_font_xlate_table:
	sw a0, font_xlate_table
jr ra

# -------------------------------------------------------------------------------------------------

.macro XLATE_CHAR %dest, %src, %xlate
	blt  %src, 32, _nonprintable
	ble  %src, 126, _printable

	_nonprintable:
		li %src, ' '
	_printable:

	# %dest = tile number = translation_table[ch - 32]
	sub  %src, %src, 32
	add  %src, %src, %xlate
	lbu  %dest, (%src)
.end_macro

# -------------------------------------------------------------------------------------------------

# int display_xlate_char(int c)
#   translates a character using the current font translation table. if the given
#   character is not printable, treats it as a space.
#   returns the tile index of that character's graphics.
display_xlate_char:
	lw  t9, font_xlate_table
	beq t9, 0, PRIVATE_font_xlate_table_not_set

	XLATE_CHAR v0, a0, t9
jr ra

# -------------------------------------------------------------------------------------------------

# void display_draw_text_tm(int tx, int ty, char* str)
#   draws a string of text on the tilemap with no flags set.
display_draw_text_tm:
	li a3, 0
j display_draw_text_tm_flags

# -------------------------------------------------------------------------------------------------

# void display_draw_text_tm_flags(int tx, int ty, char* str, int flags)
#   draws a string of text on the tilemap with the given flags on each tile.
display_draw_text_tm_flags:
	# t9 = translation table base
	lw  t9, font_xlate_table
	beq t9, 0, PRIVATE_font_xlate_table_not_set

	# a1 = destination address
	mul a1, a1, BYTES_PER_TM_ROW
	mul a0, a0, TM_ENTRY_SIZE
	add a1, a1, a0
	la  t0, display_tm_table
	add a1, a1, t0

	# loop over each character in the string
	_loop:
		# t0 = ch
		lbu  t0, (a2)

		# exit loop if zero terminator
		beqz t0, _return

		XLATE_CHAR t0, t0, t9

		# set tile entry
		sb   t0, 0(a1)
		sb   a3, 1(a1)

	add a1, a1, TM_ENTRY_SIZE # next tile entry
	inc a2                    # next character in the string
	j   _loop

_return:
jr ra

# -------------------------------------------------------------------------------------------------

.data
	# temp buffer for holding ASCII representation of int string
	# (way oversized but whatever)
	display_int_str_buffer:     .byte 0:49
	display_int_str_buffer_end: .byte 0

	# special-case for -2^31
	.eqv INT_MIN -2147483648
	display_int_min_str: .asciiz "-2147483648"
	.eqv INT_MIN_STR_LEN 11
.text

# -------------------------------------------------------------------------------------------------

# PRIVATE FUNCTION, DO NOT CALL!!!!!!!
# (char*, int) PRIVATE_int_to_string(int value)
#   interprets a0 as a signed integer and converts it to a string.
#   returns v0 = pointer to first character, v1 = number of characters produced, not including
#   the zero terminator
#   (note: v0 may point to a string constant, so don't uh, change the returned string. at all.)
PRIVATE_int_to_string:
	# v0 = destination address
	la v0, display_int_str_buffer_end
	# I'm paranoid
	sb zero, (v0)

	# if a0 == INT_MIN...
	bne a0, INT_MIN, _else
		# special case for INT_MIN cause it breaks shit otherwise
		la v0, display_int_min_str
		li v1, INT_MIN_STR_LEN
	j _endif
	_else:
		# t9 = "is negative?"
		li t9, 0
		# if a0 is negative...
		bgez a0, _endif_neg
			# negate it
			neg a0, a0

			# remember
			li t9, 1
		_endif_neg:

		# produce the digits from least- to most-significant
		_loop:
			div  a0, a0, 10
			mfhi t0 # extract least sig digit into t0
			mflo a0 # keep upper digits in a0

			# convert t0 to ascii and put in buffer
			add t0, t0, '0'
			dec v0
			sb  t0, (v0)
		bnez a0, _loop

		# was it negative?
		beq t9, 0, _not_negative
			# put a - in the buffer
			li  t0, '-'
			dec v0
			sb  t0, (v0)
		_not_negative:

		# now v0 points to first character of string.
		# calculate number of characters
		la  v1, display_int_str_buffer_end
		sub v1, v1, v0
	_endif:
jr ra

# -------------------------------------------------------------------------------------------------

# void display_draw_int_tm(int tx, int ty, int value)
#   converts value to a string (interpreted as a signed int), then draws it as text
#   on the tilemap.
display_draw_int_tm:
push ra
push s0
push s1
	move s0, a0
	move s1, a1

	# convert int to string
	move a0, a2
	jal  PRIVATE_int_to_string

	# now v0 points to the string
	move a0, s0
	move a1, s1
	move a2, v0
	jal  display_draw_text_tm
pop s1
pop s0
pop ra
jr ra

# TODO: display_draw_int_tm_flags

# -------------------------------------------------------------------------------------------------

# void display_set_text_sprites(int start, int end)
#   sets sprite indexes [start, end) to be used by the text sprite system.
#   end must be >= start, and both must be in the range [0, 256].
#   if end == start, effectively disables text sprites.
display_set_text_sprites:
	tlti a0, 0   # start index negative
	tlti a1, 0   # end index negative
	tgei a0, 257 # start index > 256
	tgei a1, 257 # end index > 256
	tlt  a1, a0  # start index > end index

	sw a0, text_sprites_start
	sw a1, text_sprites_end
	sw a1, text_sprites_cur
jr ra

# -------------------------------------------------------------------------------------------------

# void display_clear_text_sprites()
#   disables all sprites in the range set by display_set_text_sprites, and resets the current
#   text sprite counter so that you can start drawing text again.
display_clear_text_sprites:
	lw t0, text_sprites_start # t0 = loop counter
	lw t1, text_sprites_end   # t1 = loop upper bound

	# reset the current sprite counter
	sw t1, text_sprites_cur

	# t2 = dest address
	mul t2, t0, SPRITE_ENTRY_SIZE
	la  t3, display_spr_table
	add t2, t2, t3

	# clear everything [start..end) instead of [start..cur), in case there are old sprites
	_loop:
	bge t0, t1, _exit
		sb zero, 3(t2) # zeroing out the flags will do
	add t2, t2, SPRITE_ENTRY_SIZE
	inc t0
	j _loop
	_exit:
jr ra

# -------------------------------------------------------------------------------------------------

# (int, int) display_draw_text_sprites(int px, int py, char* str)
#   draws a string of text using sprites with no flags set.
#   returns the sprite indexes used to draw the string as [v0, v1). If v0 == v1,
#   either the string length was 0, or it ran out of sprites.
display_draw_text_sprites:
	li a3, 0
j display_draw_text_sprites_flags

# -------------------------------------------------------------------------------------------------

# (int, int) display_draw_text_sprites_flags(int px, int py, char* str, int flags)
#   draws a string of text using sprites with the given flags on each sprite.
#   (the flags will be forced to always include BIT_ENABLE.)
#   returns the sprite indexes used to draw the string as [v0, v1). If v0 == v1,
#   either the string length was 0, or it ran out of sprites.
display_draw_text_sprites_flags:
	# t6 = current sprite index
	# t7 = start of text sprites
	lw t6, text_sprites_cur
	lw t7, text_sprites_start

	# setup return values
	move v0, t6
	move v1, t6

	# bail out if no sprites available
	blt t6, t7, _return

	# t8 = destination address ((text_sprites_cur - 1) * SPRITE_ENTRY_SIZE)
	sub t8, t6, 1
	mul t8, t8, SPRITE_ENTRY_SIZE
	la  t0, display_spr_table
	add t8, t8, t0

	# t9 = translation table base
	lw  t9, font_xlate_table
	beq t9, 0, PRIVATE_font_xlate_table_not_set

	# turn on BIT_ENABLE in the flags
	or  a3, a3, BIT_ENABLE

	# loop over each character in the string
	_loop:
	blt t6, t7, _break
		sub t6, t6, 1 # one more sprite used

		# t0 = ch
		lbu  t0, (a2)

		# exit loop if zero terminator
		beqz t0, _break

		XLATE_CHAR t0, t0, t9

		# set sprite entry
		sb   a0, 0(t8) # X
		sb   a1, 1(t8) # Y
		sb   t0, 2(t8) # tile
		sb   a3, 3(t8) # flags

	sub t8, t8, SPRITE_ENTRY_SIZE # next sprite entry
	add a2, a2, 1 # next character in the string
	add a0, a0, 8 # next X coordinate
	j _loop
	_break:

	# update the counter
	sw t6, text_sprites_cur

	# and first return value
	move v0, t6
_return:
jr ra

# -------------------------------------------------------------------------------------------------

# void display_draw_int_sprites(int tx, int ty, int value)
#   converts value to a string (interpreted as a signed int), then draws it as sprites.
display_draw_int_sprites:
push ra
push s0
push s1
	move s0, a0
	move s1, a1

	# convert int to string
	move a0, a2
	jal  PRIVATE_int_to_string

	# now v0 points to the string
	move a0, s0
	move a1, s1
	move a2, v0
	jal  display_draw_text_sprites
pop s1
pop s0
pop ra
jr ra

# TODO: display_draw_int_sprites_flags

# -------------------------------------------------------------------------------------------------
# Sprites
# -------------------------------------------------------------------------------------------------

# Simple sprite enqueueing system. Makes it easier to draw sprites by automatically
# keeping track of indexes and setting some common flags.

.data
	# range of sprite indexes used by the automatic sprite functions
	auto_sprites_start: .word 0
	auto_sprites_end:   .word N_SPRITES

	# index of most-recently-allocated sprite (== auto_sprites_end if none allocated)
	# this is DECREMENTED to allocate sprites, and when it is < auto_sprites_start,
	# there are no sprites left.
	auto_sprites_cur:   .word N_SPRITES
.text

# -------------------------------------------------------------------------------------------------

# void display_set_auto_sprites(int start, int end)
#   sets sprite indexes [start, end) to be used by the automatic sprite system.
#   end must be >= start, and both must be in the range [0, 256].
#   if end == start, effectively disables automatic sprites.
display_set_auto_sprites:
	tlti a0, 0   # start index negative
	tlti a1, 0   # end index negative
	tgei a0, 257 # start index > 256
	tgei a1, 257 # end index > 256
	tlt  a1, a0  # start index > end index

	sw a0, auto_sprites_start
	sw a1, auto_sprites_end
	sw a1, auto_sprites_cur
jr ra

# -------------------------------------------------------------------------------------------------

# void display_clear_auto_sprites()
#   disables all sprites in the range set by display_set_auto_sprites, and resets the current
#   auto sprite counter so that you can start drawing sprites again.
display_clear_auto_sprites:
	lw t0, auto_sprites_start # t0 = loop counter
	lw t1, auto_sprites_end   # t1 = loop upper bound

	# reset the current sprite counter
	sw t1, auto_sprites_cur

	# t2 = dest address
	mul t2, t0, SPRITE_ENTRY_SIZE
	la  t3, display_spr_table
	add t2, t2, t3

	# clear everything [start..end) instead of [start..cur), in case there are old sprites
	_loop:
	bge t0, t1, _exit
		sb zero, 3(t2) # zeroing out the flags will do
	add t2, t2, SPRITE_ENTRY_SIZE
	inc t0
	j _loop
	_exit:
jr ra

# -------------------------------------------------------------------------------------------------

# bool display_draw_sprite(int x, int y, int tile, int flags)
#   tries to allocate a sprite. if it couldn't, returns false. otherwise,
#   allocates a sprite and sets its attributes to the arguments, and returns true.
#   (the flags will be forced to always include BIT_ENABLE.)
display_draw_sprite:
	# t6 = current sprite index
	# t7 = start of auto sprites
	lw t0, auto_sprites_cur
	lw t1, auto_sprites_start

	# return false if no sprites available
	li  v0, 0
	blt t0, t1, _return

	# decrement auto_sprites_cur
	dec t0
	sw  t0, auto_sprites_cur

	# t8 = destination address (t0 * SPRITE_ENTRY_SIZE)
	mul t0, t0, SPRITE_ENTRY_SIZE
	la  t1, display_spr_table
	add t0, t0, t1

	# turn on BIT_ENABLE in the flags
	or  a3, a3, BIT_ENABLE

	# set sprite entry
	sb   a0, 0(t0) # X
	sb   a1, 1(t0) # Y
	sb   a2, 2(t0) # tile
	sb   a3, 3(t0) # flags

	# and return true
	li v0, 1
_return:
jr ra