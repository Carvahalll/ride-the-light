-- Keyboard input + both-brakes edge detection.
-- LEFT brake  → left arrow
-- RIGHT brake → right arrow
-- Restart     → SPACE (any state) or LEFT+RIGHT simultaneously (game-over only, edge-triggered)
-- Pointer     → click/hold left half of screen = steer left, right half = steer right (web: mouse only)

local Input = {}

local both_prev = false
local ptr_steer = 0   -- from mouse/touch: -1, 0, or +1

function Input.reset()
    both_prev = false
    ptr_steer = 0
end

function Input.pointerDown(x, screen_w)
    ptr_steer = (x < screen_w / 2) and 1 or -1
end

function Input.pointerUp()
    ptr_steer = 0
end

-- Returns: steer (-1 left, +1 right, 0 none), restart_triggered (bool)
function Input.poll(alive)
    local left  = love.keyboard.isDown("left")
    local right = love.keyboard.isDown("right")

    local steer = ptr_steer
    if left  then steer = steer + 1 end   -- left brake → steer left (cam_x positive)
    if right then steer = steer - 1 end   -- right brake → steer right
    steer = math.max(-1, math.min(1, steer))

    local both_now = left and right
    local restart  = false
    if not alive then
        -- edge-triggered: only fires on the frame both go from not-both to both
        if both_now and not both_prev then
            restart = true
        end
    end
    both_prev = both_now

    return steer, restart
end

return Input
