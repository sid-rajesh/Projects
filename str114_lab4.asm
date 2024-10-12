# YOUR NAME HERE
# YOUR USERNAME HERE

.include "display_2251_0925.asm"
.include "lab4_graphics.asm"

# maximum number of particles that can be around at one time
.eqv MAX_PARTICLES 100

# limits on particle positions
.eqv PARTICLE_X_MIN -700  # "-7.00"
.eqv PARTICLE_X_MAX 12799 # "127.99"
.eqv PARTICLE_Y_MIN -700  # "-7.00"
.eqv PARTICLE_Y_MAX 12799 # "127.99"

# gravitational constant
.eqv GRAVITY 7 # "0.07"

# velocity randomization constants
.eqv VEL_RANDOM_MAX 200 # "2.00"
.eqv VEL_RANDOM_MAX_OVER_2 100 # "1.00"
# some assemblers let you do calculations on constants, but not the one in MARS! :/
# hence the awkward OVER_2 constant here

.data
	# position of the emitter (which the user has control over)
	emitter_x: .word 64
	emitter_y: .word 10

	# parallel arrays of particle properties
	particle_active: .byte 0:MAX_PARTICLES # "boolean" (0 or 1)
	particle_x:      .half 0:MAX_PARTICLES # signed
	particle_y:      .half 0:MAX_PARTICLES # signed
	particle_vx:     .half 0:MAX_PARTICLES # signed
	particle_vy:     .half 0:MAX_PARTICLES # signed
.text

.globl main
main:
	# initialize display
	li  a0, 15 # ms/frame
	li  a1, 1  # enable framebuffer (not using it for this lab tho)
	li  a2, 0  # disable tilemap
	jal display_init

	jal load_graphics

	_loop:
		jal display_clear_auto_sprites

		jal check_input
		jal update_particles
		jal draw_particles
		jal draw_emitter

		jal display_finish_frame
	j _loop

	# exit (should never get here, but I'm superstitious okay)
	li v0, 10
	syscall

#-----------------------------------------

load_graphics:
push ra
	la  a0, emitter_gfx
	li  a1, EMITTER_TILE
	li  a2, N_EMITTER_TILES
	jal display_load_sprite_gfx

	la  a0, particle_gfx
	li  a1, PARTICLE_TILE
	li  a2, N_PARTICLE_TILES
	jal display_load_sprite_gfx

	la  a0, particle_palette
	li  a1, PARTICLE_PALETTE_OFFSET
	li  a2, PARTICLE_PALETTE_SIZE
	
	li t0, 0x4287F5
    sw t0, display_palette_ram
 
	jal display_load_palette
pop ra
jr ra

#-----------------------------------------

# returns the array index of the first free particle slot,
# or -1 if there are no free slots.
find_free_particle:
push ra
	# use v0 as the loop index; loop until the particle at that index is not active
	li v0, 0
	_loop:
		lb t0, particle_active(v0)
		beq t0, 0, _return
	add v0, v0, 1
	blt v0, MAX_PARTICLES, _loop

	# no free particles found!
	li v0, -1
_return:
pop ra
jr ra

#-----------------------------------------


draw_emitter:

push ra

	# display_draw_sprite(emitter_x - 3, emitter_y - 3, EMITTER_TILE, 0x40);
	lw a0, emitter_x
	sub a0, a0, 3
	
	lw a1, emitter_y
	sub a1, a1, 3
	
	li a2, EMITTER_TILE
	li a3, 0x40
	
	jal display_draw_sprite
	

pop ra
jr ra



#-----------------------------------------


check_input:

push ra

	lw t0, display_mouse_x
	lw t1, display_mouse_y
	
	beq t0, -1, _ifBranch
		sw t0, emitter_x
		sw t1, emitter_y
	
		lw t0, display_mouse_held           
		and t0, t0, MOUSE_LBUTTON          
		beq t0, 0, _endIf                   
			jal spawn_particle
		_endIf:
	_ifBranch:
pop ra
jr ra

#-----------------------------------------
spawn_particle:
push ra
push s0
	jal find_free_particle               
	move s0, v0                          
	beq s0, -1, _endIf        
		# particle_active[s0] = 1           
		li t2, 1
		sb t2, particle_active(s0)
	
		# rest of function uses half arrays, so multiply it by 2
		mul s0, s0, 2
		
		# particle_x[s0] = emitter_x * 100
		lw t0, emitter_x
		mul t0, t0, 100
		sh t0, particle_x(s0)

		# particle_y[s0] = emitter_y * 100
		lw t0, emitter_y
		mul t0, t0, 100
		sh t0, particle_y(s0)
		
		# particle_vx[s0] = 0
		#sh zero, particle_vx(s0)
		
		# particle_vy[s0] = 0
		#sh zero, particle_vy(s0) 
		
		
		# Generate random particle_vx
	    li a0, 0              
	    li a1, VEL_RANDOM_MAX
	    li v0, 42
	    syscall
	    sub v0, v0, VEL_RANDOM_MAX_OVER_2
	    sh v0, particle_vx(s0)
	
	    # Generate random particle_vy
	    li a0, 0              
	    li a1, VEL_RANDOM_MAX
	    li v0, 42    
	    syscall
	    sub v0, v0, VEL_RANDOM_MAX_OVER_2  
	    sub v0, v0, GRAVITY
	    sh v0, particle_vy(s0)
	
	_endIf:
pop s0
pop ra
jr ra

#-----------------------------------------
draw_particles: 

push ra
push s0
	# for(int i = 0; i < MAX_PARTICLES; i++)
	li s0, 0
	_pLoop:
		# if(particle_active[i] != 0) {
		lb t0, particle_active(s0)
		beq t0, zero, _endIf
		
			# i = i * 2
			mul t0, s0, 2
		
			# a0 = particle_x[i] / 100 - 7
			lh a0, particle_x(t0)
			div a0, a0, 100
			sub a0, a0, 7
			
			# a1 = particle_y[i] / 100 - 7
			lh a1, particle_y(t0)
			div a1, a1, 100
			sub a1, a1, 7
			
			# a2 = 161
			li a2, 161
			
			# a3 = 0x88
			li a3, 0x88
			
			# display_draw_sprite()
			jal display_draw_sprite
		_endIf:
		
	add s0, s0, 1
	blt s0, MAX_PARTICLES, _pLoop
pop s0
pop ra
jr ra

#-----------------------------------------
update_particles:
push ra
push s0

	# for(int i = 0; i < MAX_PARTICLES; i++)
	li s0, 0
	_pLoop:
		# if(particle_active[i] != 0) {
		lb t0, particle_active(s0)
		beq t0, zero, _endIf
		
			# i = i * 2
			mul t0, s0, 2
		
			#particle_vy[i] += GRAVITY
			lh a0, particle_vy(t0)
			add a0, a0, GRAVITY
			sh a0, particle_vy(t0)
			
			
			#particle_x[i] += particle_vx[i]
			lh a1, particle_x(t0)
			lh a2, particle_vx(t0)
			add a1, a1, a2
			sh a1, particle_x(t0)
			
			
			#particle_y[i] += particle_vy[i]
			lh a3, particle_y(t0)
			add, a3, a3, a0
			sh a3, particle_y(t0)
			
			
			blt a1, PARTICLE_X_MIN, _then
			bgt a1, PARTICLE_X_MAX, _then
			blt a3, PARTICLE_Y_MIN, _then
			bgt a3, PARTICLE_Y_MAX, _then
			j _endIf
			
			_then: 
				#particle_active[i] = 0
				sb zero, particle_active(s0)
			
		_endIf:
			
	add s0, s0, 1
	blt s0, MAX_PARTICLES, _pLoop
				
pop s0
pop ra
jr ra







