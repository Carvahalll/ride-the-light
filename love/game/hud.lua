local C = require("game.constants")

local HUD = {}

local font_big, font_small, font_tiny, font_huge

function HUD.load()
    font_huge  = love.graphics.newFont(88)
    font_big   = love.graphics.newFont(52)
    font_small = love.graphics.newFont(26)
    font_tiny  = love.graphics.newFont(18)
end

local function setCol(t, a)
    love.graphics.setColor(t[1], t[2], t[3], a or 1)
end

function HUD.draw(score, speed, combo, gt)
    -- Score — top left
    local sc_str = tostring(math.floor(score))
    sc_str = sc_str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")

    love.graphics.setFont(font_big)
    love.graphics.setColor(0, 0.22, 0.08, 1)
    love.graphics.print(sc_str, 31, 15)
    setCol(C.COL.GREEN)
    love.graphics.print(sc_str, 28, 12)

    -- Speed — top right
    local kmh = tostring(math.floor(speed * 22))
    love.graphics.setFont(font_tiny)
    love.graphics.setColor(0.35, 0.24, 0.59, 1)
    love.graphics.print("KM/H", C.W - 215, 14)
    love.graphics.setFont(font_small)
    setCol(C.COL.PURPLE2)
    love.graphics.print(kmh, C.W - 215, 38)

    -- Speed bar
    local bar_max = 330
    local bar_w   = math.floor(bar_max * math.min(1, speed / 16))
    love.graphics.setColor(0.07, 0.03, 0.15, 1)
    love.graphics.rectangle("fill", C.W - 215, 78, bar_max, 13, 4)
    if bar_w > 0 then
        setCol(C.COL.PURPLE2)
        love.graphics.rectangle("fill", C.W - 215, 78, bar_w, 13, 4)
    end

    -- Combo
    if combo > 1 then
        local t  = math.min(combo, 8) / 8
        local g  = C.COL.GREEN
        local y2 = C.COL.YELLOW
        love.graphics.setColor(
            y2[1]*t + g[1]*(1-t),
            y2[2]*t + g[2]*(1-t),
            y2[3]*t + g[3]*(1-t), 1)
        love.graphics.setFont(font_small)
        love.graphics.print("x"..combo.."  COMBO", 28, 95)
    end

    -- Player hitbox square
    local hx  = C.HITBOX_CX
    local sq  = C.HITBOX_HALF
    local sqy = C.HITBOX_Y
    local cy_col = C.COL.CYAN
    for i = 4, 1, -1 do
        local inf   = i * 5
        local alpha = 0.35 * i / 4
        love.graphics.setColor(cy_col[1]*i/4, cy_col[2]*i/4, cy_col[3]*i/4, alpha)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line",
            hx - sq - inf, sqy - inf, sq*2 + inf*2, sq*2 + inf*2, 4)
    end
    setCol(C.COL.CYAN)
    love.graphics.rectangle("fill", hx - sq, sqy, sq*2, sq*2, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(4)
    love.graphics.line(hx - 6, sqy + sq, hx + 6, sqy + sq)
    love.graphics.line(hx, sqy + sq - 6, hx, sqy + sq + 6)
    love.graphics.setLineWidth(1)
end

function HUD.drawGameOver(score, gt)
    love.graphics.setColor(0, 0, 0, 0.82)
    love.graphics.rectangle("fill", 0, 0, C.W, C.H)

    local cx = C.W / 2
    local cy = C.H / 2

    local flk = 0.80 + 0.20 * math.sin(gt * 24)
    local pk  = C.COL.PINK
    love.graphics.setFont(font_huge)
    love.graphics.setColor(0.31, 0, 0.18, 1)
    for _, d in ipairs({{-4,-4},{4,4},{-4,4},{4,-4}}) do
        love.graphics.printf("GAME  OVER", cx - 400 + d[1], cy - 175 + d[2], 800, "center")
    end
    love.graphics.setColor(pk[1]*flk, pk[2]*flk, pk[3]*flk, 1)
    love.graphics.printf("GAME  OVER", cx - 400, cy - 175, 800, "center")

    local sc_str = tostring(math.floor(score))
    sc_str = sc_str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    love.graphics.setFont(font_big)
    setCol(C.COL.GREEN)
    love.graphics.printf("SCORE   "..sc_str, cx - 400, cy - 20, 800, "center")

    love.graphics.setFont(font_small)
    love.graphics.setColor(0.47, 0.31, 0.75, 1)
    love.graphics.printf(
        "BOTH BRAKES or SPACE  ·  restart          ESC  ·  quit",
        cx - 450, cy + 82, 900, "center")

    for i = 0, 4 do
        local a = math.max(0, 85 - i*16) / 85
        love.graphics.setColor(pk[1]*a, pk[2]*a, pk[3]*a, 1)
        love.graphics.setLineWidth(4)
        love.graphics.line(0, cy - 235 + i*3, C.W, cy - 235 + i*3)
        love.graphics.line(0, cy + 148 - i*3, C.W, cy + 148 - i*3)
    end
    love.graphics.setLineWidth(1)
end

return HUD
