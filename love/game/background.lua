local C    = require("game.constants")
local Road = require("game.road")

local Background = {}
local _time = 0

-- Pilatus/Rigi silhouette, extended ±150 px beyond screen for parallax headroom.
-- Flat array of (x, y) pairs; first and last pairs are bottom corners.
local MOUNTAIN = {
   -150, 260,   -- bottom-left corner (off screen)
   -150,  80,   -- left ridge start
     70, 138,
    190,  55,   -- Pilatus Kulm (main peak)
    265,  94,
    345,  70,
    425, 108,
    505,  44,   -- Esel (secondary peak)
    585,  84,
    665, 118,
    745,  84,
    835,  60,
    915,  94,
   1005,  74,
   1095, 108,
   1185,  54,   -- Rigi-like bump on the right
   1430,  84,   -- right ridge end
   1430, 260,   -- bottom-right corner (off screen)
}

local function drawMountains(cam_x)
    local px = cam_x * 0.035   -- gentle parallax

    -- Build polygon with parallax applied to x-values only
    local poly = {}
    for i = 1, #MOUNTAIN, 2 do
        poly[#poly+1] = MOUNTAIN[i] + px
        poly[#poly+1] = MOUNTAIN[i+1]
    end

    -- Fill with deep purple
    love.graphics.setColor(0.07, 0.01, 0.16, 1)
    love.graphics.polygon("fill", poly)

    -- Glow ridge: draw only the ridge (skip first and last bottom-corner pairs)
    -- poly[1],poly[2] = bottom-left; poly[n-1],poly[n] = bottom-right
    local n = #poly
    local ridge = {}
    for i = 3, n - 2 do
        ridge[#ridge+1] = poly[i]
    end

    for pass = 3, 1, -1 do
        love.graphics.setColor(0.55, 0.0, 1.0, 0.18 * pass / 3)
        love.graphics.setLineWidth(pass * 3.5)
        love.graphics.line(ridge)
    end
    love.graphics.setColor(0.65, 0.10, 1.0, 0.85)
    love.graphics.setLineWidth(1.5)
    love.graphics.line(ridge)
    love.graphics.setLineWidth(1)
end

local function drawLake(cam_x)
    -- Road edges at near-camera (z≈0) and near-horizon (z≈0.97)
    local lx_near, ly_near = Road.project(-0.5, 0.001, cam_x)
    local rx_near, ry_near = Road.project( 0.5, 0.001, cam_x)
    local lx_far,  ly_far  = Road.project(-0.5, 0.97,  cam_x)
    local rx_far,  ry_far  = Road.project( 0.5, 0.97,  cam_x)

    -- Lake fill: dark teal quads flanking the road.
    -- Near the bottom the road fills the full screen; the lake widens toward the horizon.
    love.graphics.setColor(0.0, 0.22, 0.30, 0.92)

    love.graphics.polygon("fill",
        0,       C.H,
        lx_near, ly_near,
        lx_far,  ly_far,
        0,       ly_far)

    love.graphics.polygon("fill",
        C.W,     C.H,
        rx_near, ry_near,
        rx_far,  ry_far,
        C.W,     ry_far)

    -- Shimmer: 8 horizontal neon-cyan lines within the lake area
    love.graphics.setLineWidth(1)
    for i = 1, 8 do
        local t     = i / 9.0
        local sy    = ly_far  + (ly_near - ly_far)  * t
        local lx_at = lx_far  + (lx_near - lx_far)  * t
        local rx_at = rx_far  + (rx_near - rx_far)  * t
        local alpha = math.max(0.0, 0.07 + 0.10 * math.sin(_time * 1.3 + i * 1.4))
        love.graphics.setColor(0.0, 0.9, 1.0, alpha)
        if lx_at > 4 then
            love.graphics.line(0, sy, lx_at - 2, sy)
        end
        if rx_at < C.W - 4 then
            love.graphics.line(rx_at + 2, sy, C.W, sy)
        end
    end
    love.graphics.setLineWidth(1)
end

function Background.update(dt)
    _time = _time + dt
end

function Background.draw(cam_x)
    drawMountains(cam_x)
    drawLake(cam_x)
end

return Background
