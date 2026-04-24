local Sparks = {}

local SPARK_COLORS = {
    {1, 0.90, 0},        -- yellow
    {0.16, 1, 0.47},     -- green2
    {1, 1, 0.71},        -- warm white
}

local Spark = {}
Spark.__index = Spark

function Spark.new(x, y)
    local s    = setmetatable({}, Spark)
    local a    = love.math.random() * math.pi * 2
    local sp   = love.math.random(120, 440)
    s.x, s.y   = x, y
    s.vx, s.vy = math.cos(a)*sp, math.sin(a)*sp
    s.life     = love.math.random() * 0.45 + 0.3
    s.max_life = s.life
    s.color    = SPARK_COLORS[love.math.random(#SPARK_COLORS)]
    return s
end

function Spark:update(dt)
    self.x    = self.x + self.vx * dt
    self.y    = self.y + self.vy * dt
    self.vy   = self.vy + 270 * dt
    self.life = self.life - dt
    return self.life > 0
end

function Spark:draw()
    local a = self.life / self.max_life
    local r = math.max(1, 5 * a)
    local c = self.color
    love.graphics.setColor(c[1]*a, c[2]*a, c[3]*a, a)
    love.graphics.circle("fill", self.x, self.y, r)
end

-- Burst: spawn n sparks at (x, y), append to list
function Sparks.burst(list, x, y, n)
    for _ = 1, (n or 22) do
        list[#list+1] = Spark.new(x, y)
    end
end

-- Update all sparks in-place, remove dead ones. Returns same list.
function Sparks.update(list, dt)
    local i = 1
    while i <= #list do
        if list[i]:update(dt) then
            i = i + 1
        else
            list[i] = list[#list]
            list[#list] = nil
        end
    end
end

function Sparks.draw(list)
    for _, sp in ipairs(list) do
        sp:draw()
    end
end

return Sparks
