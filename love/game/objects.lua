local C    = require("game.constants")
local Road = require("game.road")

local Objects = {}

-- Discrete size tables (mirrors pygame OBS_SIZES / COIN_SIZES)
local OBS_SIZES  = {4,8,12,16,22,28,36,46,58,72,88,104,120}
local COIN_SIZES = {3,5,7,10,14,18,22,28,34}

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
    self.color = (kind == 'obstacle') and randcol(C.OBS_COLORS) or C.COL.YELLOW
    return self
end

function RoadObject:laneFrac()
    return (self.lane / (C.NUM_OBJ_LANES - 1)) - 0.5
end

function RoadObject:update(dt)
    self.z     = self.z - self.speed * (1.0 - self.z + 0.08) * dt
    self.pulse = self.pulse + dt * 5.0
end

function RoadObject:isHit(cam_x)
    if self.z >= C.OBJ_HIT_Z then return false end
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

-- ── Module-level spawn helpers ────────────────────────────────────────────────

function Objects.newObstacle(speed) return RoadObject.new(speed, 'obstacle') end
function Objects.newCoin(speed)     return RoadObject.new(speed, 'coin')     end

return Objects
