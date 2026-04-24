local C = {}

-- Screen (logical)
C.W = 1280
C.H = 720

-- Perspective geometry
C.HORIZON_Y      = 0
C.ROAD_HALF_BOT  = C.W * 0.50
C.ROAD_HALF_TOP  = C.W * 0.004

-- Steering
C.CAM_X_MAX      = C.W * 0.50
C.CAM_STEER_SPD  = 1.5
C.CAM_RETURN_SPD = 2.0

-- Lanes
C.NUM_OBJ_LANES  = 5

-- Gameplay
C.INITIAL_SPEED      = 6.0
C.SPEED_INCREMENT    = 0.55
C.OBSTACLE_INTERVAL  = 2.0
C.COIN_INTERVAL      = 2.5

-- Object z-lifecycle
C.OBJ_SPAWN_Z = 0.98
C.OBJ_HIT_Z   = 0.03
C.OBJ_CULL_Z  = -0.02

-- Player hitbox (screen-space, fixed position)
C.HITBOX_HALF     = 36
C.HITBOX_Y        = C.H - 10 - C.HITBOX_HALF * 2
C.HITBOX_CX       = C.W / 2
C.HITBOX_COLLIDE_PX = C.HITBOX_HALF

-- Colours (r,g,b in 0-1 range for Love2D)
local function rgb(r,g,b) return r/255, g/255, b/255 end

C.COL = {
    BG          = {rgb(  2,   0,  10)},
    ROAD        = {rgb(  5,   3,  16)},
    CYAN        = {rgb(  0, 255, 255)},
    CYAN2       = {rgb(  0, 180, 210)},
    PINK        = {rgb(255,   0, 180)},
    YELLOW      = {rgb(255, 230,   0)},
    GREEN       = {rgb(  0, 255,  80)},
    GREEN2      = {rgb( 40, 255, 120)},
    PURPLE      = {rgb(160,   0, 255)},
    PURPLE2     = {rgb(200,  60, 255)},
    ORANGE      = {rgb(255,  80,   0)},
    WHITE       = {rgb(230, 220, 255)},
    RED         = {rgb(255,  10,  60)},
}

C.OBS_COLORS = { C.COL.PINK, C.COL.ORANGE, C.COL.RED }

-- Road grid
C.STRIPE_Z_STEP = 0.09
C.NUM_ROAD_SEGS = 16

return C
