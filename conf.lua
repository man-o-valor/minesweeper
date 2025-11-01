local CANVAS_PIXELS = require("main")

function love.conf(t)
    t.window.width = 864
    t.window.height = 864
    t.window.resizable = true
    t.window.minwidth = 288
    t.window.minheight = 288
    t.window.title = "Minesweeper"

    t.window.highdpi = false
    t.window.usedpiscale = false

    t.window.vsync = false
end
