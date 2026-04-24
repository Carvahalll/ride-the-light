-- Keyboard input + both-brakes edge detection.
-- LEFT brake  → left arrow
-- RIGHT brake → right arrow
-- Restart     → SPACE (any state) or LEFT+RIGHT simultaneously (game-over only, edge-triggered)

local Input = {}

local both_prev = false

function Input.reset()
    both_prev = false
end

-- Returns: steer (-1 left, +1 right, 0 none), restart_triggered (bool)
function Input.poll(alive)
    local left  = love.keyboard.isDown("left")
    local right = love.keyboard.isDown("right")

    local steer = 0
    if left  then steer = steer + 1 end   -- left brake → steer left (cam_x positive)
    if right then steer = steer - 1 end   -- right brake → steer right

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
