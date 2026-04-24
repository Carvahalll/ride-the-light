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

-- ── Swan drawing ──────────────────────────────────────────────────────────────

local function drawSwan(sx, sy, scale, pulse)
    if scale < 0.04 then return end

    local bw = math.max(4, math.floor(90 * scale))   -- body ellipse x-radius * 2
    local bh = math.max(3, math.floor(38 * scale))   -- body ellipse y-radius * 2
    local nr = math.max(2, math.floor(24 * scale))   -- neck length
    local hr = math.max(2, math.floor(10 * scale))   -- head radius
    local p  = 0.80 + 0.20 * pulse

    -- body glow
    for i = 3, 1, -1 do
        local inf = i * 5 * scale
        love.graphics.setColor(p, 0.30 * p, 0.70 * p, 0.32 * i / 3)
        love.graphics.ellipse("fill", sx, sy - bh / 2, bw / 2 + inf, bh / 2 + inf)
    end
    love.graphics.setColor(0.94 * p, 0.84 * p, 1.0, 1)
    love.graphics.ellipse("fill", sx, sy - bh / 2, bw / 2, bh / 2)

    -- neck + head
    local neck_bx = sx - bw * 0.15
    local neck_by = sy - bh
    local nx      = sx - bw * 0.30
    local ny      = neck_by - nr

    love.graphics.setColor(0.94 * p, 0.84 * p, 1.0, 1)
    love.graphics.setLineWidth(math.max(1, math.floor(5 * scale)))
    love.graphics.line(neck_bx, neck_by, nx, ny)
    love.graphics.setLineWidth(1)

    for i = 2, 1, -1 do
        love.graphics.setColor(p, 0.30 * p, 0.70 * p, 0.40 * i / 2)
        love.graphics.circle("fill", nx, ny, hr + i * 4 * scale)
    end
    love.graphics.setColor(0.94 * p, 0.84 * p, 1.0, 1)
    love.graphics.circle("fill", nx, ny, hr)
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
        drawSwan(sx, sy, scale, math.sin(self.pulse))

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

-- ── Module-level spawn helpers ────────────────────────────────────────────────

function Objects.newObstacle(speed)
    -- 30% chance a swan waddles onto the road instead of a car
    local kind = (love.math.random() < 0.30) and 'swan' or 'obstacle'
    return RoadObject.new(speed, kind)
end
function Objects.newCoin(speed)  return RoadObject.new(speed, 'coin') end
function Objects.newGate(speed)  return RoadObject.new(speed, 'gate') end

return Objects
