function love.conf(t)
    t.window.title   = "Ride the Light"
    t.window.width   = 1280
    t.window.height  = 720
    t.window.vsync   = 1
    t.window.msaa    = 0   -- we'll do glow via shader, not MSAA
    t.window.resizable = false

    t.modules.audio   = true
    t.modules.sound   = true
    t.modules.physics = false
    t.modules.touch   = false
    t.modules.joystick = false
    t.modules.video   = false
end
