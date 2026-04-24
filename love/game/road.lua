local C = require("game.constants")

local Road = {}

-- Project (lane_frac, z) → screen (sx, sy, scale)
-- lane_frac: -0.5 (left edge) … +0.5 (right edge)
-- z: 0 (near) … 1 (horizon)
function Road.project(lane_frac, z, cam_x)
    local half_w   = C.ROAD_HALF_BOT + (C.ROAD_HALF_TOP - C.ROAD_HALF_BOT) * z
    local screen_y = C.HORIZON_Y + (C.H - C.HORIZON_Y) * (1.0 - z)
    local center_x = C.W / 2 + cam_x * (1.0 - z)
    local screen_x = center_x + lane_frac * half_w * 2
    local scale    = math.max(0, 1.0 - z)
    return screen_x, screen_y, scale
end

local function ex(frac, z, cam_x)
    return Road.project(frac, z, cam_x)
end

function Road.draw(cam_x, road_offset)
    local p  = C.COL.PURPLE
    local ro = C.COL.ROAD

    -- Road fill
    love.graphics.setColor(ro[1], ro[2], ro[3], 1)
    local lx0 = ex(-0.5, 0.999, cam_x)
    local rx0 = ex( 0.5, 0.999, cam_x)
    local lx1 = ex(-0.5, 0.001, cam_x)
    local rx1 = ex( 0.5, 0.001, cam_x)
    love.graphics.polygon("fill", lx0, C.HORIZON_Y, rx0, C.HORIZON_Y, rx1, C.H, lx1, C.H)

    -- Horizontal grid lines
    local z_off = (road_offset * 0.005) % C.STRIPE_Z_STEP
    local z = z_off
    while z < 0.97 do
        local lx = ex(-0.5, z, cam_x)
        local rx = ex( 0.5, z, cam_x)
        local sy = C.HORIZON_Y + (C.H - C.HORIZON_Y) * (1.0 - z)
        local brightness = 55 * (1 - z)^2
        if brightness > 3 then
            local t = brightness / 55
            love.graphics.setColor(p[1]*t, p[2]*t, p[3]*t)
            love.graphics.setLineWidth(math.max(1, 6 * (1 - z)))
            love.graphics.line(lx, sy, rx, sy)
        end
        z = z + C.STRIPE_Z_STEP
    end

    -- Lane dashes
    for lane = 1, C.NUM_OBJ_LANES - 1 do
        local frac = (lane / C.NUM_OBJ_LANES) - 0.5
        local prev_x, prev_y
        for si = 0, C.NUM_ROAD_SEGS do
            local z2 = si / C.NUM_ROAD_SEGS
            local sx2 = ex(frac, z2, cam_x)
            local sy2 = C.HORIZON_Y + (C.H - C.HORIZON_Y) * (1.0 - z2)
            if prev_x and si % 2 == 0 then
                local bright = 140 * (1 - z2)
                local t = bright / 140
                love.graphics.setColor(p[1]*t, p[2]*t, p[3]*t)
                love.graphics.setLineWidth(math.max(1, 4 * (1 - z2)))
                love.graphics.line(prev_x, prev_y, sx2, sy2)
            end
            prev_x, prev_y = sx2, sy2
        end
    end

    -- Road edges (neon cyan)
    for _, side in ipairs({-0.5, 0.5}) do
        local prev_x, prev_y
        for si = 0, C.NUM_ROAD_SEGS do
            local z2  = si / C.NUM_ROAD_SEGS
            local sx2 = ex(side, z2, cam_x)
            local sy2 = C.HORIZON_Y + (C.H - C.HORIZON_Y) * (1.0 - z2)
            if prev_x then
                local bright = (1 - z2)
                love.graphics.setColor(0, bright, bright)
                love.graphics.setLineWidth(math.max(1, 10 * (1 - z2)))
                love.graphics.line(prev_x, prev_y, sx2, sy2)
            end
            prev_x, prev_y = sx2, sy2
        end
    end

    love.graphics.setLineWidth(1)
end

return Road
