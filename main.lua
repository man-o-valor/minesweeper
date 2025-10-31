-- main.lua
local gameCanvas
local scale = 1
local tileset
local tileQuad
local TILE_SIZE = 16
local TILES_PER_ROW = 18
local CANVAS_PIXELS = TILE_SIZE * TILES_PER_ROW
local mineDensity = 18
local mines = {}
local flags = {}
local hints = {}
local boardDepth = {}
local hoverTx, hoverTy
local newBoard, blankHints
local particles = {}

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
    flagTile = love.graphics.newQuad(TILE_SIZE, 0, TILE_SIZE, TILE_SIZE, tileset:getDimensions())

    local windowW, windowH = love.graphics.getDimensions()
    scale = math.min(math.floor(windowW / CANVAS_PIXELS), math.floor(windowH / CANVAS_PIXELS))
    if scale < 1 then
        scale = 1
    end

    for ty = 0, TILES_PER_ROW * TILES_PER_ROW - 1 do
        table.insert(boardDepth, 2)
    end
    makeBoard()
end

function love.resize(w, h)
    scale = math.min(math.floor(w / CANVAS_PIXELS), math.floor(h / CANVAS_PIXELS))
    if scale < 1 then
        scale = 1
    end
end

function love.draw()
    -- render to the canvas
    love.graphics.setCanvas(gameCanvas)
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
            if flags[tileId] then
                love.graphics.draw(tileset, flagTile, x, y)
            end
        end
    end

    if hoverTx and hoverTy then
        love.graphics.setColor(1, 1, 1, 0.40)
        love.graphics.rectangle('fill', hoverTx * TILE_SIZE, hoverTy * TILE_SIZE, TILE_SIZE, TILE_SIZE)
        love.graphics.setColor(1, 1, 1, 1)
    end

    for i = 1, #particles do
        local particle = particles[i]
        love.graphics.draw(tileset, particle.sprite, particle.x, particle.y, particle.rot / 10,
            1 - (particle.age / particle.life), 1 - (particle.age / particle.life), 8, 8)
    end

    love.graphics.setCanvas()

    local windowW, windowH = love.graphics.getDimensions()
    local x = math.floor((windowW - (CANVAS_PIXELS * scale)) / 2)
    local y = math.floor((windowH - (CANVAS_PIXELS * scale)) / 2)
    love.graphics.draw(gameCanvas, x, y, 0, scale, scale)
end

function love.update(dt)
    local windowW, windowH = love.graphics.getDimensions()
    local screenX = math.floor((windowW - (CANVAS_PIXELS * scale)) / 2)
    local screenY = math.floor((windowH - (CANVAS_PIXELS * scale)) / 2)

    -- mouse hover
    local mx, my = love.mouse.getPosition()
    if mx >= screenX and mx < screenX + (CANVAS_PIXELS * scale) and my >= screenY and my < screenY +
        (CANVAS_PIXELS * scale) then
        local localX = math.floor((mx - screenX) / scale)
        local localY = math.floor((my - screenY) / scale)
        hoverTx = math.floor(localX / TILE_SIZE)
        hoverTy = math.floor(localY / TILE_SIZE)
        if hoverTx < 0 then
            hoverTx = 0
        end
        if hoverTx >= TILES_PER_ROW then
            hoverTx = TILES_PER_ROW - 1
        end
        if hoverTy < 0 then
            hoverTy = 0
        end
        if hoverTy >= TILES_PER_ROW then
            hoverTy = TILES_PER_ROW - 1
        end
    else
        hoverTx = nil
        hoverTy = nil
    end
    -- mouse hover end
    handleParticles()
end

function love.mousepressed(mx, my, button)
    -- compute canvas position on screen
    local windowW, windowH = love.graphics.getDimensions()
    local screenX = math.floor((windowW - (CANVAS_PIXELS * scale)) / 2)
    local screenY = math.floor((windowH - (CANVAS_PIXELS * scale)) / 2)
    local localX, localY, tx, ty
    local tileId

    -- check if click inside canvas area
    if mx >= screenX and mx < screenX + (CANVAS_PIXELS * scale) and my >= screenY and my < screenY +
        (CANVAS_PIXELS * scale) then
        localX = math.floor((mx - screenX) / scale)
        localY = math.floor((my - screenY) / scale)
        tx = math.floor(localX / TILE_SIZE)
        ty = math.floor(localY / TILE_SIZE)
        -- clamp to board
        if tx < 0 then
            tx = 0
        end
        if tx >= TILES_PER_ROW then
            tx = TILES_PER_ROW - 1
        end
        if ty < 0 then
            ty = 0
        end
        if ty >= TILES_PER_ROW then
            ty = TILES_PER_ROW - 1
        end

        tileId = ty * TILES_PER_ROW + tx + 1
    end
    if tileId ~= nil then
        if button ~= 1 then
            if not newBoard and boardDepth[tileId] == 2 then
                -- flag
                flags[tileId] = not flags[tileId]
                if not flags[tileId] then
                    newParticle(tx * TILE_SIZE + 8, ty * TILE_SIZE + 8, flagTile)
                end
            end
        else
            -- dig
            if not flags[tileId] and boardDepth[tileId] == 2 then
                if newBoard then
                    makeBoard()
                end
                while blankHints < 6 and newBoard do
                    makeBoard()
                    boardFlood(tileId)
                end
                boardDepth[tileId] = 1
                newParticle(tx * TILE_SIZE + 8, ty * TILE_SIZE + 8, coverTile)
                if not newBoard then
                    boardFlood(tileId)
                end
                newBoard = false
            end
        end
    end
end

function makeBoard()
    newBoard = true
    blankHints = 0
    mines = {}
    hints = {}
    for ty = 0, TILES_PER_ROW * TILES_PER_ROW - 1 do
        if (math.random() < mineDensity / 100) then
            table.insert(mines, true)
        else
            table.insert(mines, false)
        end
        table.insert(flags, false)
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

function boardFlood(id)
    if hints[id] == 0 then
        local new = boardFloodStep(id, 0)
    end
end

function boardFloodStep(id, layers)
    if layers > 9 then -- don't overflow!
        return nIndex
    end
    local tx = (id - 1) % TILES_PER_ROW
    local ty = math.floor((id - 1) / TILES_PER_ROW)
    local count = 0
    local nIndex
    for dy = -1, 1 do
        for dx = -1, 1 do
            local nx = tx + dx
            local ny = ty + dy
            if (not (dx == 0 and dy == 0)) and nx >= 0 and nx < TILES_PER_ROW and ny >= 0 and ny < TILES_PER_ROW then
                nIndex = ny * TILES_PER_ROW + nx + 1
                if boardDepth[nIndex] == 2 then
                    newParticle(nx * TILE_SIZE + 8, ny * TILE_SIZE + 8, coverTile)
                    boardDepth[nIndex] = 1
                end
                if hints[nIndex] == 0 then
                    blankHints = blankHints + 1
                    boardFloodStep(nIndex, layers + 1)
                end
            end
        end
    end
    return nIndex
end

function newParticle(x, y, sprite)
    local particle = {}
    particle.x = x
    particle.y = y
    particle.rot = 0
    particle.sprite = sprite

    particle.life = math.random(6, 15) * 30
    particle.age = 0
    particle.vx = math.random(-5, 5) / 50
    particle.vy = math.random(-20, 0) / 50
    particle.vr = math.random(-5, 5) / 50
    table.insert(particles, particle)
end

function handleParticles()
    for i = 1, #particles do
        if particles[i] then
            local particle = particles[i]
            particle.age = particle.age + 1
            if (particle.age > particle.life) then
                table.remove(particles, i)
                i = i - 1
            else
                particle.x = particle.x + particle.vx
                particle.y = particle.y + particle.vy
                particle.rot = particle.rot + particle.vr
                particle.vy = particle.vy + 0.005 -- gravity
            end
        end
    end
end

return CANVAS_PIXELS
