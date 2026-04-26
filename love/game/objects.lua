local C    = require("game.constants")
local Road = require("game.road")

local Objects = {}

-- Discrete size tables (mirrors pygame OBS_SIZES / COIN_SIZES)
local OBS_SIZES  = {4,8,12,16,22,28,36,46,58,72,88,104,120}
local COIN_SIZES = {3,5,7,10,14,18,22,28,34}

-- Uses image alpha as a mask; outputs the current draw color (ignores pixel RGB).
local SILHOUETTE_SHADER = love.graphics.newShader([[
    vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
        float a = Texel(tex, uv).a;
        if (a < 0.01) { discard; }
        return vec4(color.rgb, color.a * a);
    }
]])

local swan_img = nil   -- loaded by Objects.load()

local function nearest(val, lst)
    local best, bd = lst[1], math.huge
    for _, v in ipairs(lst) do
        local d = math.abs(v - val)
        if d < bd then best, bd = v, d end
    end
    return best
end

local function randcol(t) return t[love.math.random(#t)] end

-- ── Glow helpers (CPU, no shader yet) ─────────────────────────────────────────
-- Draws concentric transparent rects/circles to fake a glow halo.

local function drawRectGlow(col, x, y, w, h, passes, spread)
    passes = passes or 4
    spread = spread or 6
    for i = passes, 1, -1 do
        local inf   = i * spread
        local alpha = 0.55 * (i / passes)^1.5
        love.graphics.setColor(col[1], col[2], col[3], alpha)
        love.graphics.rectangle("fill",
            x - w/2 - inf, y - h - inf, w + inf*2, h + inf*2, math.max(2, w*0.12))
    end
    love.graphics.setColor(col[1], col[2], col[3], 1)
    love.graphics.rectangle("fill", x - w/2, y - h, w, h, math.max(2, w*0.12))
    -- bright centre
    love.graphics.setColor(
        math.min(1, col[1]+0.5),
        math.min(1, col[2]+0.5),
        math.min(1, col[3]+0.5), 0.9)
    love.graphics.rectangle("fill",
        x - w/2 + w/5, y - h + h/5, w*3/5, h*3/5, 2)
end

local function drawCircleGlow(col, cx, cy, r, passes, spread)
    passes = passes or 4
    spread = spread or 5
    for i = passes, 1, -1 do
        local gr    = r + i * spread
        local alpha = 0.82 * (i / passes)^1.6
        love.graphics.setColor(col[1], col[2], col[3], alpha)
        love.graphics.circle("fill", cx, cy, gr)
    end
    love.graphics.setColor(col[1], col[2], col[3], 1)
    love.graphics.circle("fill", cx, cy, r)
    love.graphics.setColor(
        math.min(1, col[1]+0.55),
        math.min(1, col[2]+0.55),
        math.min(1, col[3]+0.55), 1)
    love.graphics.circle("fill", cx, cy, math.max(1, r/3))
end

-- ── Gate (Kapellbrücke) drawing ───────────────────────────────────────────────

local function drawGate(sx_l, sy_l, sx_r, sy_r, scale, col)
    if scale < 0.015 then return end

    local sy     = (sy_l + sy_r) / 2
    local road_w = sx_r - sx_l
    local pw     = math.max(3, math.floor(22 * scale))
    local ph     = math.floor(scale * C.H * 0.65)
    local beam_h = math.max(2, math.floor(16 * scale))

    local function glowRect(x, y, w, h)
        for i = 4, 1, -1 do
            local inf = i * 6 * scale
            love.graphics.setColor(col[1], col[2], col[3], 0.14 * i / 4)
            love.graphics.rectangle("fill", x - inf, y - inf, w + inf * 2, h + inf * 2)
        end
        love.graphics.setColor(col[1], col[2], col[3], 1)
        love.graphics.rectangle("fill", x, y, w, h)
    end

    glowRect(sx_l - pw / 2, sy - ph,  pw,     ph)
    glowRect(sx_r - pw / 2, sy - ph,  pw,     ph)
    glowRect(sx_l,          sy - ph,  road_w, beam_h)

    local apex_x = (sx_l + sx_r) / 2
    local apex_y = sy - ph - math.floor(50 * scale)
    love.graphics.setColor(col[1], col[2], col[3], 0.50)
    love.graphics.polygon("fill", sx_l, sy - ph, apex_x, apex_y, sx_r, sy - ph)
    love.graphics.setColor(col[1], col[2], col[3], 1)
    love.graphics.setLineWidth(math.max(1, 2 * scale))
    love.graphics.polygon("line", sx_l, sy - ph, apex_x, apex_y, sx_r, sy - ph)
    love.graphics.setLineWidth(1)

    -- Wasserturm (octagonal tower above apex)
    local tr = math.max(3, math.floor(32 * scale))
    local tx = apex_x
    local ty = apex_y - tr * 0.8
    for i = 4, 1, -1 do
        love.graphics.setColor(col[1], col[2], col[3], 0.16 * i / 4)
        love.graphics.circle("fill", tx, ty, tr + i * 6 * scale)
    end
    love.graphics.setColor(col[1], col[2], col[3], 1)
    love.graphics.circle("fill", tx, ty, tr)
end

-- ── RoadObject ────────────────────────────────────────────────────────────────

local RoadObject = {}
RoadObject.__index = RoadObject

function RoadObject.new(speed, kind)
    local self = setmetatable({}, RoadObject)
    self.lane  = love.math.random(0, C.NUM_OBJ_LANES - 1)
    self.z     = C.OBJ_SPAWN_Z
    self.speed = speed
    self.kind  = kind
    self.pulse = love.math.random() * math.pi * 2
    if     kind == 'obstacle' then self.color = randcol(C.OBS_COLORS)
    elseif kind == 'swan'     then self.color = C.COL.SNOW
    elseif kind == 'gate'     then self.color = C.COL.AMBER
    else                           self.color = C.COL.YELLOW  -- coin
    end
    if kind == 'swan' then
        -- Start at one road edge, drift across to the other
        local side       = love.math.random(0, 1) == 0 and -1 or 1
        self.lane_frac   = side * 0.45
        self.lane_vel    = -side * (0.10 + love.math.random() * 0.12)
    end
    return self
end

function RoadObject:laneFrac()
    if self.lane_frac then return self.lane_frac end
    return (self.lane / (C.NUM_OBJ_LANES - 1)) - 0.5
end

function RoadObject:update(dt)
    self.z     = self.z - self.speed * (1.0 - self.z + 0.08) * dt
    self.pulse = self.pulse + dt * 5.0
    if self.lane_frac then
        self.lane_frac = self.lane_frac + self.lane_vel * dt
        if self.lane_frac > 0.46 then
            self.lane_frac = 0.46
            self.lane_vel  = -math.abs(self.lane_vel)
        elseif self.lane_frac < -0.46 then
            self.lane_frac = -0.46
            self.lane_vel  =  math.abs(self.lane_vel)
        end
    end
end

function RoadObject:isHit(cam_x)
    if self.z >= C.OBJ_HIT_Z then return false end
    if self.kind == 'gate'    then return false end
    local half_w   = C.ROAD_HALF_BOT + (C.ROAD_HALF_TOP - C.ROAD_HALF_BOT) * self.z
    local center_x = C.W / 2 + cam_x * (1.0 - self.z)
    local obj_sx   = center_x + self:laneFrac() * half_w * 2
    return math.abs(obj_sx - C.HITBOX_CX) < C.HITBOX_COLLIDE_PX
end

function RoadObject:offScreen()
    return self.z < C.OBJ_CULL_Z
end

function RoadObject:draw(cam_x)
    if self.z <= 0.005 then return end
    local sx, sy, scale = Road.project(self:laneFrac(), self.z, cam_x)
    if scale < 0.015 then return end

    local pulse = 0.78 + 0.22 * math.sin(self.pulse)
    local col   = {self.color[1]*pulse, self.color[2]*pulse, self.color[3]*pulse}

    if self.kind == 'obstacle' then
        local pw = nearest(math.floor(110 * scale), OBS_SIZES)
        local ph = nearest(math.floor(155 * scale), OBS_SIZES)
        if pw < 4 or ph < 4 then return end

        drawRectGlow(col, sx, sy, pw, ph)

        -- Windshield cutout
        if pw > 18 then
            love.graphics.setColor(C.COL.BG[1], C.COL.BG[2], C.COL.BG[3], 1)
            love.graphics.rectangle("fill",
                sx - pw/2 + pw/5, sy - ph + ph/8, pw*3/5, ph/3, 2)
            love.graphics.setColor(col[1], col[2], col[3], 1)
            love.graphics.setLineWidth(math.max(1, 4*scale))
            love.graphics.rectangle("line",
                sx - pw/2 + pw/5, sy - ph + ph/8, pw*3/5, ph/3, 2)
        end

        -- Headlights
        if pw > 12 then
            local hl_r = math.max(2, math.floor(5*scale))
            local yl   = {1, 0.86, 0.39}
            drawCircleGlow(yl, sx - pw/2 + hl_r + 2, sy - hl_r - 2, hl_r, 3, 4)
            drawCircleGlow(yl, sx + pw/2 - hl_r - 2, sy - hl_r - 2, hl_r, 3, 4)
        end

    elseif self.kind == 'swan' then
        if swan_img and scale >= 0.03 then
            local iw      = swan_img:getWidth()
            local ih      = swan_img:getHeight()
            local draw_sc = (160 * scale) / iw
            local draw_h  = ih * draw_sc
            -- Flip to face direction of travel
            local flip    = (self.lane_vel and self.lane_vel > 0) and -1 or 1
            love.graphics.setShader(SILHOUETTE_SHADER)
            love.graphics.setColor(pulse, pulse, pulse, 0.95)
            love.graphics.draw(swan_img, sx, sy - draw_h,
                0, flip * draw_sc, draw_sc, iw / 2, 0)
            love.graphics.setShader()
        end

    elseif self.kind == 'gate' then
        local lx, ly = Road.project(-0.5, self.z, cam_x)
        local rx, ry = Road.project( 0.5, self.z, cam_x)
        drawGate(lx, ly, rx, ry, scale, col)

    else  -- coin
        local cr = nearest(math.floor(32 * scale), COIN_SIZES)
        if cr < 3 then return end

        drawCircleGlow(col, sx, sy, cr)

        -- Spinning ellipse overlay
        local spin_w = math.max(1, math.floor(cr * 2 * math.abs(math.sin(self.pulse))))
        if spin_w > 4 then
            love.graphics.setColor(0.67, 0.51, 0, 1)
            love.graphics.setLineWidth(math.max(1, math.floor(6*scale)))
            love.graphics.ellipse("line", sx, sy, spin_w/2, cr)
        end
    end
end

-- ── Module-level load / spawn helpers ────────────────────────────────────────

function Objects.load()
    local ok, img = pcall(love.graphics.newImage, "assets/obstacles/swan.png", {mipmaps = true})
    if ok then
        img:setFilter("linear", "linear", 16)
        swan_img = img
    end
end

function Objects.newObstacle(speed, active_objects)
    -- 30% chance a swan waddles onto the road instead of a car
    local kind = (love.math.random() < 0.30) and 'swan' or 'obstacle'
    local obj  = RoadObject.new(speed, kind)

    -- Re-roll the lane until it doesn't overlap a live swan (cars only).
    -- Each lane covers ±0.13 of lane_frac space; two retries are enough.
    if kind == 'obstacle' and active_objects then
        local lane_spacing = 1.0 / (C.NUM_OBJ_LANES - 1)
        for attempt = 1, C.NUM_OBJ_LANES do
            local frac     = obj:laneFrac()
            local blocked  = false
            for _, o in ipairs(active_objects) do
                if o.kind == 'swan' and math.abs(o.lane_frac - frac) < lane_spacing * 0.6 then
                    blocked = true
                    break
                end
            end
            if not blocked then break end
            obj.lane = (obj.lane + 1) % C.NUM_OBJ_LANES
        end
    end

    return obj
end
function Objects.newCoin(speed)  return RoadObject.new(speed, 'coin') end
function Objects.newGate(speed)  return RoadObject.new(speed, 'gate') end

return Objects
