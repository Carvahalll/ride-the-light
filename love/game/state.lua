local C = require("game.constants")

local State = {}

function State.new()
    return {
        objects     = {},
        sparks      = {},
        score       = 0,
        speed       = C.INITIAL_SPEED,
        obs_timer   = 0,
        coin_timer  = 0,
        gate_timer  = 0,
        speed_timer = 0,
        road_offset = 0,
        alive       = true,
        combo       = 0,
        combo_timer = 0,
        cam_x       = 0,
        gt          = 0,   -- global time (seconds since game start)
    }
end

return State
