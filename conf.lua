local CANVAS_PIXELS = require("main")

function love.conf(t)
    t.window.width = 864
    t.window.height = 864
    t.window.resizable = true
    t.window.minwidth = 288
    t.window.minheight = 288
    t.window.title = "Minesweeper"

    -- Enable integer scaling (pixel perfect)
    t.window.highdpi = false
    t.window.usedpiscale = false
end
