# Cardinal directions.
.eqv DIR_N 0
.eqv DIR_E 1
.eqv DIR_S 2
.eqv DIR_W 3

# Tile types.
.eqv TILE_EMPTY    0
.eqv TILE_BRICK    1
.eqv TILE_GOO      2
.eqv TILE_GOO_EDGE 3
.eqv TILE_GOAL     4

# Goo constants.
.eqv GOO_DELAY 60 # frames
.eqv GOO_EXPAND_PROBABILITY 18 # percent

# Object types.
.eqv OBJ_EMPTY   0
.eqv OBJ_PLAYER  1
.eqv OBJ_PUMPKIN 2
.eqv OBJ_SPLASH  3

# Other object constants.
.eqv MAX_OBJECTS 50
.eqv PLAYER_MOVE_DELAY 5 # frames
.eqv PLAYER_HURT_IFRAMES 60 # frames
.eqv SPLASH_LIFETIME 120 # frames

# Camera position is player position plus these offsets.
.eqv CAMERA_OFFSET_X -64
.eqv CAMERA_OFFSET_Y -64

# Camera position upper limits.
.eqv CAMERA_MAX_X 128 # MAP_TILE_W - SCREEN_TILE_W
.eqv CAMERA_MAX_Y 128 # MAP_TILE_H - SCREEN_TILE_H