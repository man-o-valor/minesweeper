-- main.lua
local gameCanvas
local scale = 1
local tileset
local tileQuad
local TILE_SIZE = 16
local TILES_PER_ROW = 18
local CANVAS_PIXELS = TILE_SIZE * TILES_PER_ROW
local mines = {}
local hints = {}
local boardDepth = {}

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    gameCanvas = love.graphics.newCanvas(CANVAS_PIXELS, CANVAS_PIXELS)
    gameCanvas:setFilter('nearest', 'nearest')
    tileset = love.graphics.newImage('assets/minesweeper.png')
    tileset:setFilter('nearest', 'nearest')

    -- covering tile quad
    coverTile = love.graphics.newQuad(0, 0, TILE_SIZE, TILE_SIZE, tileset:getDimensions())
    -- hint quads
    hintTiles = {love.graphics.newQuad(TILE_SIZE * 4, TILE_SIZE * 2, TILE_SIZE * 5, TILE_SIZE * 3,
        tileset:getDimensions()),
                 love.graphics.newQuad(TILE_SIZE * 2, 0, TILE_SIZE * 3, TILE_SIZE, tileset:getDimensions()),
                 love.graphics.newQuad(TILE_SIZE * 3, 0, TILE_SIZE * 4, TILE_SIZE, tileset:getDimensions()),
                 love.graphics.newQuad(TILE_SIZE * 4, 0, TILE_SIZE * 5, TILE_SIZE, tileset:getDimensions()),
                 love.graphics.newQuad(TILE_SIZE * 2, TILE_SIZE, TILE_SIZE * 3, TILE_SIZE * 2, tileset:getDimensions()),
                 love.graphics.newQuad(TILE_SIZE * 3, TILE_SIZE, TILE_SIZE * 4, TILE_SIZE * 2, tileset:getDimensions()),
                 love.graphics.newQuad(TILE_SIZE * 4, TILE_SIZE, TILE_SIZE * 5, TILE_SIZE * 2, tileset:getDimensions()),
                 love.graphics
        .newQuad(TILE_SIZE * 2, TILE_SIZE * 2, TILE_SIZE * 3, TILE_SIZE * 3, tileset:getDimensions()),
                 love.graphics
        .newQuad(TILE_SIZE * 3, TILE_SIZE * 2, TILE_SIZE * 4, TILE_SIZE * 3, tileset:getDimensions()),
                 love.graphics.newQuad(TILE_SIZE, TILE_SIZE, TILE_SIZE * 2, TILE_SIZE * 2, tileset:getDimensions())}
    -- flag quad
    flagTile = love.graphics.newQuad(TILE_SIZE, 0, TILE_SIZE * 2, TILE_SIZE, tileset:getDimensions())

    local windowW, windowH = love.graphics.getDimensions()
    scale = math.min(math.floor(windowW / CANVAS_PIXELS), math.floor(windowH / CANVAS_PIXELS))
    if scale < 1 then
        scale = 1
    end

    for ty = 0, TILES_PER_ROW * TILES_PER_ROW - 1 do
        if (math.random() < 0.15) then
            table.insert(mines, true)
        else
            table.insert(mines, false)
        end
        table.insert(boardDepth, 1)
        -- math.random(0, 2)
    end
    local totalTiles = TILES_PER_ROW * TILES_PER_ROW
    for i = 1, totalTiles do
        local idx0 = i - 1
        local tx = idx0 % TILES_PER_ROW
        local ty = math.floor(idx0 / TILES_PER_ROW)
        local count = 0
        for dy = -1, 1 do
            for dx = -1, 1 do
                if not (dx == 0 and dy == 0) then
                    local nx = tx + dx
                    local ny = ty + dy
                    if nx >= 0 and nx < TILES_PER_ROW and ny >= 0 and ny < TILES_PER_ROW then
                        local nIndex = ny * TILES_PER_ROW + nx + 1
                        if mines[nIndex] then
                            count = count + 1
                        end
                    end
                end
            end
        end
        -- mine tiles get 9
        if mines[i] then
            count = 9
        end
        table.insert(hints, count)
    end
end

function love.resize(w, h)
    scale = math.min(math.floor(w / CANVAS_PIXELS), math.floor(h / CANVAS_PIXELS))
    if scale < 1 then
        scale = 1
    end
end

function love.draw()
    love.graphics.setCanvas(gameCanvas)
    -- draw cover tiles
    for ty = 0, TILES_PER_ROW - 1 do
        for tx = 0, TILES_PER_ROW - 1 do
            local x = tx * TILE_SIZE
            local y = ty * TILE_SIZE
            local tileId = ty * TILES_PER_ROW + tx + 1
            if (boardDepth[tileId] == 2) then
                love.graphics.draw(tileset, coverTile, x, y)
            elseif (boardDepth[tileId] == 1) then
                love.graphics.draw(tileset, hintTiles[hints[tileId] + 1], x, y)
            end
        end
    end
    love.graphics.setCanvas()

    -- draw canvas to screen
    local windowW, windowH = love.graphics.getDimensions()
    local x = math.floor((windowW - (CANVAS_PIXELS * scale)) / 2)
    local y = math.floor((windowH - (CANVAS_PIXELS * scale)) / 2)
    love.graphics.draw(gameCanvas, x, y, 0, scale, scale)
end

return CANVAS_PIXELS
