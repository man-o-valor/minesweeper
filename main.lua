-- main.lua
local gameCanvas
local scale = 1
local tileset
local tileQuad
local TSIZE = 16
local TILES_PER_ROW = 18
local CANVAS_PIXELS = TSIZE * TILES_PER_ROW
local mineDensity = 18
local mines = {}
local flags = {}
local hints = {}
local glitches = {}
local boardDepth = {}
local hoverTx, hoverTy
local newBoard, blankHints
local particles = {}
local shakeX, shakeY = 0, 0
local shakeLength, shakeLife, shakeStrength = 0, 0, 0
local digShakeCount = 0
local gameActive = true
local showMines = false
local timeSinceEnd = 0
local gameEndState = "playing"

function love.load()
    math.randomseed(os.time())
    love.graphics.setDefaultFilter('nearest', 'nearest')
    gameCanvas = love.graphics.newCanvas(CANVAS_PIXELS, CANVAS_PIXELS)
    staticCanvas = love.graphics.newCanvas(CANVAS_PIXELS, CANVAS_PIXELS)
    -- Load the static effect shader
    staticShader = love.graphics.newShader('assets/static.glsl')
    tileset = love.graphics.newImage('assets/minesweeper.png')
    tileset:setFilter('nearest', 'nearest')

    -- covering tile quad
    coverTile = love.graphics.newQuad(TSIZE * 0, TSIZE * 0, TSIZE, TSIZE, tileset:getDimensions())
    -- hint quads
    hintTiles = {love.graphics.newQuad(TSIZE * 4, TSIZE * 2, TSIZE, TSIZE, tileset:getDimensions()), -- 0
    love.graphics.newQuad(TSIZE * 2, 0, TSIZE, TSIZE, tileset:getDimensions()), -- 1
    love.graphics.newQuad(TSIZE * 3, 0, TSIZE, TSIZE, tileset:getDimensions()), -- 2
    love.graphics.newQuad(TSIZE * 4, 0, TSIZE, TSIZE, tileset:getDimensions()), -- 3
    love.graphics.newQuad(TSIZE * 2, TSIZE, TSIZE, TSIZE, tileset:getDimensions()), -- 4
    love.graphics.newQuad(TSIZE * 3, TSIZE, TSIZE, TSIZE, tileset:getDimensions()), -- 5
    love.graphics.newQuad(TSIZE * 4, TSIZE, TSIZE, TSIZE, tileset:getDimensions()), -- 6
    love.graphics.newQuad(TSIZE * 2, TSIZE * 2, TSIZE, TSIZE, tileset:getDimensions()), -- 7
    love.graphics.newQuad(TSIZE * 3, TSIZE * 2, TSIZE, TSIZE, tileset:getDimensions()), -- 8
    love.graphics.newQuad(TSIZE, TSIZE, TSIZE, TSIZE, tileset:getDimensions())} -- mine
    -- flag quad
    flagTile = love.graphics.newQuad(TSIZE, 0, TSIZE, TSIZE, tileset:getDimensions())
    -- revealed mine quad
    revealedMineTile = love.graphics.newQuad(TSIZE, TSIZE * 2, TSIZE, TSIZE, tileset:getDimensions())
    -- glitch quads
    glitchTiles = {love.graphics.newQuad(TSIZE * 0, TSIZE * 3, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 0, TSIZE * 4, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 0, TSIZE * 5, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 1, TSIZE * 3, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 1, TSIZE * 4, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 1, TSIZE * 5, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 2, TSIZE * 3, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 2, TSIZE * 4, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 2, TSIZE * 5, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 3, TSIZE * 3, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 3, TSIZE * 4, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 3, TSIZE * 5, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 4, TSIZE * 3, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 4, TSIZE * 4, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 4, TSIZE * 5, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 5, TSIZE * 3, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 5, TSIZE * 4, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 5, TSIZE * 5, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 6, TSIZE * 3, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 6, TSIZE * 4, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 6, TSIZE * 5, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 7, TSIZE * 3, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 7, TSIZE * 4, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 7, TSIZE * 5, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 2, TSIZE * 6, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 2, TSIZE * 7, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 4, TSIZE * 6, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 4, TSIZE * 7, TSIZE, TSIZE, tileset:getDimensions())}

    outlineTile = love.graphics.newQuad(TSIZE * 0, TSIZE * 6, TSIZE + 2, TSIZE + 2, tileset:getDimensions())

    bannerTiles = {love.graphics.newQuad(TSIZE * 2, TSIZE * 6, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 2, TSIZE * 7, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 3, TSIZE * 6, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 4, TSIZE * 6, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 4, TSIZE * 7, TSIZE, TSIZE, tileset:getDimensions())}

    letterTiles = {love.graphics.newQuad(TSIZE * 5, TSIZE * 6, TSIZE, TSIZE, tileset:getDimensions()), -- Y
    love.graphics.newQuad(TSIZE * 5, TSIZE * 7, TSIZE, TSIZE, tileset:getDimensions()), -- L
    love.graphics.newQuad(TSIZE * 5, TSIZE * 8, TSIZE, TSIZE, tileset:getDimensions()), -- W
    love.graphics.newQuad(TSIZE * 6, TSIZE * 6, TSIZE, TSIZE, tileset:getDimensions()), -- O
    love.graphics.newQuad(TSIZE * 6, TSIZE * 7, TSIZE, TSIZE, tileset:getDimensions()), -- S
    love.graphics.newQuad(TSIZE * 6, TSIZE * 8, TSIZE, TSIZE, tileset:getDimensions()), -- I
    love.graphics.newQuad(TSIZE * 7, TSIZE * 6, TSIZE, TSIZE, tileset:getDimensions()), -- U
    love.graphics.newQuad(TSIZE * 7, TSIZE * 7, TSIZE, TSIZE, tileset:getDimensions()), -- E
    love.graphics.newQuad(TSIZE * 7, TSIZE * 8, TSIZE, TSIZE, tileset:getDimensions()), -- N
    love.graphics.newQuad(TSIZE * 5, TSIZE * 9, TSIZE, TSIZE, tileset:getDimensions()), -- P
    love.graphics.newQuad(TSIZE * 6, TSIZE * 9, TSIZE, TSIZE, tileset:getDimensions()), -- R
    love.graphics.newQuad(TSIZE * 7, TSIZE * 9, TSIZE, TSIZE, tileset:getDimensions()), -- T
    love.graphics.newQuad(TSIZE * 5, TSIZE * 10, TSIZE, TSIZE, tileset:getDimensions()), -- A
    love.graphics.newQuad(TSIZE * 4, TSIZE * 8, TSIZE, TSIZE, tileset:getDimensions())} -- !

    grassTiles = {love.graphics.newQuad(TSIZE * 0, TSIZE * 8, TSIZE, TSIZE, tileset:getDimensions()),
                  love.graphics.newQuad(TSIZE * 1, TSIZE * 8, TSIZE, TSIZE, tileset:getDimensions()),
                  love.graphics.newQuad(TSIZE * 2, TSIZE * 8, TSIZE, TSIZE, tileset:getDimensions()),
                  love.graphics.newQuad(TSIZE * 3, TSIZE * 8, TSIZE, TSIZE, tileset:getDimensions())}
    flowerTiles = {love.graphics.newQuad(TSIZE * 0, TSIZE * 9, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 1, TSIZE * 9, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 2, TSIZE * 9, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 3, TSIZE * 9, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 4, TSIZE * 9, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 0, TSIZE * 10, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 1, TSIZE * 10, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 2, TSIZE * 10, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 3, TSIZE * 10, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 4, TSIZE * 10, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 0, TSIZE * 11, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 1, TSIZE * 11, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 2, TSIZE * 11, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 3, TSIZE * 11, TSIZE, TSIZE, tileset:getDimensions()),
                   love.graphics.newQuad(TSIZE * 4, TSIZE * 11, TSIZE, TSIZE, tileset:getDimensions())}

    local windowW, windowH = love.graphics.getDimensions()
    scale = math.min(math.floor(windowW / CANVAS_PIXELS), math.floor(windowH / CANVAS_PIXELS))
    if scale < 1 then
        scale = 1
    end

    for ty = 0, TILES_PER_ROW * TILES_PER_ROW - 1 do
        table.insert(boardDepth, 2)
    end

    digsound = love.audio.newSource("assets/dig.wav", "static")
    bigdigsound = love.audio.newSource("assets/bigdig.wav", "static")
    flagsound = love.audio.newSource("assets/flag.wav", "static")
    unflagsound = love.audio.newSource("assets/unflag.wav", "static")
    hintsounds = {love.audio.newSource("assets/reveal1.wav", "static"),
                  love.audio.newSource("assets/reveal2.wav", "static"),
                  love.audio.newSource("assets/reveal3.wav", "static"),
                  love.audio.newSource("assets/reveal4.wav", "static"),
                  love.audio.newSource("assets/reveal5.wav", "static"),
                  love.audio.newSource("assets/reveal6.wav", "static"),
                  love.audio.newSource("assets/reveal7.wav", "static"),
                  love.audio.newSource("assets/reveal8.wav", "static")}
    explodesound = love.audio.newSource("assets/explosion.wav", "static")
    winsound = love.audio.newSource("assets/win.wav", "static")
    bannersound = love.audio.newSource("assets/banner.wav", "static")
    glitch = love.audio.newSource("assets/glitch.wav", "stream")

    makeBoard()
end

function love.resize(w, h)
    scale = math.min(math.floor(w / CANVAS_PIXELS), math.floor(h / CANVAS_PIXELS))
    if scale < 1 then
        scale = 1
    end
end

function love.draw()
    -- First render the static effect to its own canvas
    love.graphics.setCanvas(staticCanvas)
    love.graphics.clear()
    love.graphics.setShader(staticShader)
    staticShader:send('time', love.timer.getTime())
    love.graphics.setColor(1, 1, 1, 0.2) -- Subtle static
    love.graphics.rectangle('fill', 0, 0, CANVAS_PIXELS, CANVAS_PIXELS)
    love.graphics.setShader()

    -- render to the game canvas
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear(1, 1, 1, 1)

    -- Draw static first, but only in fully revealed areas
    love.graphics.setColor(1, 1, 1, 1)
    for ty = 0, TILES_PER_ROW - 1 do
        for tx = 0, TILES_PER_ROW - 1 do
            local tileId = ty * TILES_PER_ROW + tx + 1
            if boardDepth[tileId] == 0 then
                -- Draw static effect directly in the tile area
                love.graphics.setShader(staticShader)
                staticShader:send('time', love.timer.getTime())
                love.graphics.rectangle('fill', tx * TSIZE, ty * TSIZE, TSIZE, TSIZE)
                love.graphics.setShader()
                if math.random() < 0.05 then
                    if glitches[tileId] > 0 then
                        glitches[tileId] = 0
                    elseif math.random() < 0.5 then
                        glitches[tileId] = math.random(1, #glitchTiles)
                    end
                end
                if glitches[tileId] > 0 then
                    love.graphics.draw(tileset, glitchTiles[glitches[tileId]], tx * TSIZE, ty * TSIZE)
                end
            end
        end
    end
    for ty = 0, TILES_PER_ROW - 1 do
        for tx = 0, TILES_PER_ROW - 1 do
            local x = tx * TSIZE
            local y = ty * TSIZE
            local tileId = ty * TILES_PER_ROW + tx + 1
            if boardDepth[tileId] > 0 then
                love.graphics.draw(tileset, outlineTile, tx * TSIZE - 1, ty * TSIZE - 1)
            end
        end
    end
    for ty = 0, TILES_PER_ROW - 1 do
        for tx = 0, TILES_PER_ROW - 1 do
            local x = tx * TSIZE
            local y = ty * TSIZE
            local tileId = ty * TILES_PER_ROW + tx + 1
            if showMines and mines[tileId] and boardDepth[tileId] > 0 then
                love.graphics.draw(tileset, revealedMineTile, x, y)
            else
                if (boardDepth[tileId] == 2) then
                    love.graphics.draw(tileset, coverTile, x, y)
                elseif (boardDepth[tileId] == 1) then
                    love.graphics.draw(tileset, hintTiles[hints[tileId] + 1], x, y)
                end
                if flags[tileId] then
                    love.graphics.draw(tileset, flagTile, x, y)
                end
                if gameEndState == "won" and 2 * tx - ty + TILES_PER_ROW < (timeSinceEnd / 15) -
                    ((3 * tx - 37 * ty) % 4 - 2) then
                    local hash = math.floor(math.min(math.floor((timeSinceEnd / 15) - ((3 * tx - 37 * ty) % 4 - 2)) -
                                                         (2 * tx - ty + TILES_PER_ROW), 7) / 2) + 1
                    love.graphics.draw(tileset, grassTiles[hash], x, y)
                    if mines[tileId] then
                        if (tx + ty + math.floor(timeSinceEnd / 60)) % 2 == 1 then
                            hash = hash + 1
                        end
                        hash = hash + ((tx + ty) % 3) * 5
                        love.graphics.draw(tileset, flowerTiles[hash], x, y)
                    end
                end
            end
        end
    end

    if hoverTx and hoverTy and gameActive then
        love.graphics.setColor(1, 1, 1, 0.40)
        love.graphics.rectangle('fill', hoverTx * TSIZE, hoverTy * TSIZE, TSIZE, TSIZE)
        love.graphics.setColor(1, 1, 1, 1)
    end

    for i = 1, #particles do
        local particle = particles[i]
        love.graphics.draw(tileset, particle.sprite, particle.x, particle.y, particle.rot / 10,
            1 - (particle.age / particle.life), 1 - (particle.age / particle.life), 8, 8)
    end

    --[[if gameEndState == "lost" and timeSinceEnd > 360 then
        love.graphics.draw(tileset, bannerTiles[1], TSIZE * 5, TSIZE * 1)
        love.graphics.draw(tileset, bannerTiles[2], TSIZE * 5, TSIZE * 2)
        love.graphics.draw(tileset, bannerTiles[3], TSIZE * 6, TSIZE * 1, 0, 6, 2)
        love.graphics.draw(tileset, bannerTiles[4], TSIZE * 12, TSIZE * 1)
        love.graphics.draw(tileset, bannerTiles[5], TSIZE * 12, TSIZE * 2)
        love.graphics.draw(tileset, letterTiles[1], TSIZE * 7.5, TSIZE * 1)
        love.graphics.draw(tileset, letterTiles[4], TSIZE * 8.5, TSIZE * 1)
        love.graphics.draw(tileset, letterTiles[7], TSIZE * 9.5, TSIZE * 1)
        love.graphics.draw(tileset, letterTiles[2], TSIZE * 7, TSIZE * 2)
        love.graphics.draw(tileset, letterTiles[4], TSIZE * 8, TSIZE * 2)
        love.graphics.draw(tileset, letterTiles[5], TSIZE * 9, TSIZE * 2)
        love.graphics.draw(tileset, letterTiles[8], TSIZE * 10, TSIZE * 2)
    end
    if gameEndState == "won" and timeSinceEnd > 360 then
        love.graphics.draw(tileset, bannerTiles[1], TSIZE * 5, TSIZE * 1)
        love.graphics.draw(tileset, bannerTiles[2], TSIZE * 5, TSIZE * 2)
        love.graphics.draw(tileset, bannerTiles[3], TSIZE * 6, TSIZE * 1, 0, 6, 2)
        love.graphics.draw(tileset, bannerTiles[4], TSIZE * 12, TSIZE * 1)
        love.graphics.draw(tileset, bannerTiles[5], TSIZE * 12, TSIZE * 2)
        love.graphics.draw(tileset, letterTiles[1], TSIZE * 7.5, TSIZE * 1)
        love.graphics.draw(tileset, letterTiles[4], TSIZE * 8.5, TSIZE * 1)
        love.graphics.draw(tileset, letterTiles[7], TSIZE * 9.5, TSIZE * 1)
        love.graphics.draw(tileset, letterTiles[3], TSIZE * 7, TSIZE * 2)
        love.graphics.draw(tileset, letterTiles[6], TSIZE * 8, TSIZE * 2)
        love.graphics.draw(tileset, letterTiles[9], TSIZE * 9, TSIZE * 2)
        love.graphics.draw(tileset, letterTiles[14], TSIZE * 10, TSIZE * 2)
    end]]
    if timeSinceEnd > 720 then
        love.graphics.draw(tileset, bannerTiles[1], TSIZE * 3, TSIZE * 15)
        love.graphics.draw(tileset, bannerTiles[2], TSIZE * 3, TSIZE * 16)
        love.graphics.draw(tileset, bannerTiles[3], TSIZE * 4, TSIZE * 15, 0, 10, 2)
        love.graphics.draw(tileset, bannerTiles[4], TSIZE * 14, TSIZE * 15)
        love.graphics.draw(tileset, bannerTiles[5], TSIZE * 14, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[10], TSIZE * 5.5, TSIZE * 15)
        love.graphics.draw(tileset, letterTiles[11], TSIZE * 6.5, TSIZE * 15)
        love.graphics.draw(tileset, letterTiles[8], TSIZE * 7.5, TSIZE * 15)
        love.graphics.draw(tileset, letterTiles[5], TSIZE * 8.5, TSIZE * 15)
        love.graphics.draw(tileset, letterTiles[5], TSIZE * 9.5, TSIZE * 15)
        love.graphics.draw(tileset, letterTiles[11], TSIZE * 11.5, TSIZE * 15)
        love.graphics.draw(tileset, letterTiles[12], TSIZE * 4, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[4], TSIZE * 5, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[11], TSIZE * 7, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[8], TSIZE * 8, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[5], TSIZE * 9, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[12], TSIZE * 10, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[13], TSIZE * 11, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[11], TSIZE * 12, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[12], TSIZE * 13, TSIZE * 16)
    end

    if timeSinceEnd < 60 and timeSinceEnd > 0 then
        love.graphics.setColor(1, 1, 1, 1 - (timeSinceEnd / 60))
        love.graphics.rectangle('fill', 0, 0, TSIZE * TILES_PER_ROW, TSIZE * TILES_PER_ROW)
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.setCanvas()

    local windowW, windowH = love.graphics.getDimensions()
    local x = math.floor((windowW - (CANVAS_PIXELS * scale)) / 2)
    local y = math.floor((windowH - (CANVAS_PIXELS * scale)) / 2)
    -- apply shake offsets when drawing canvas to screen
    love.graphics.draw(gameCanvas, x + shakeX, y + shakeY, 0, scale, scale)
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
        hoverTx = math.floor(localX / TSIZE)
        hoverTy = math.floor(localY / TSIZE)
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
    if --[[timeSinceEnd == 360 or ]]timeSinceEnd == 720 then
        local sfx = bannersound:clone()
        sfx:setPitch(math.random(80, 120) / 100)
        sfx:play()
    end
    -- mouse hover end
    handleParticles()
    -- handle shake
    handleScreenShake()
    -- check for revealed mines
    if gameActive then
        for i = 1, #mines do
            if boardDepth[i] == 1 and mines[i] then
                -- revealed a mine!
                gameActive = false
                showMines = true
                gameEndState = "lost"
                explodeTileAt(i)
                break
            end
        end
        local gameWon = true
        for i = 1, #mines do
            if boardDepth[i] == 2 and not mines[i] then
                gameWon = false
                break
            end
        end
        if gameWon then
            -- won the game!
            gameActive = false
            gameEndState = "won"
            knockOffFlags()
            local sfx = winsound:clone()
            sfx:setPitch(math.random(80, 120) / 100)
            sfx:play()
        end
    end
    if not gameActive then
        timeSinceEnd = timeSinceEnd + 1
    end
end

function love.keypressed(key)
    if key == 'r' then
        resetGame()
    end
    --[[if key == 'w' then
        -- TEMP
        for i = 1, #mines do
            if boardDepth[i] == 2 and not mines[i] then
                boardDepth[i] = 1
            end
        end
    end]]
end

function love.mousepressed(mx, my, button)
    if gameActive then
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
            tx = math.floor(localX / TSIZE)
            ty = math.floor(localY / TSIZE)
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
                if boardDepth[tileId] == 2 then -- Allow flagging even on new board
                    -- flag
                    flags[tileId] = not flags[tileId]
                    if not flags[tileId] then
                        newParticle(tx * TSIZE + 8, ty * TSIZE + 8, flagTile)
                        local sfx = unflagsound:clone()
                        sfx:setPitch(math.random(80, 120) / 100)
                        sfx:play()
                    else
                        local sfx = flagsound:clone()
                        sfx:setPitch(math.random(80, 120) / 100)
                        sfx:play()
                    end
                end
            else
                -- dig
                if not flags[tileId] and boardDepth[tileId] == 2 then
                    if newBoard then
                        knockOffFlags() -- Knock off all flags on first dig
                        makeBoard()
                    end
                    while blankHints < 6 and newBoard do
                        makeBoard()
                        boardFlood(tileId)
                    end
                    boardDepth[tileId] = 1
                    newParticle(tx * TSIZE + 8, ty * TSIZE + 8, coverTile)
                    if not newBoard then
                        boardFlood(tileId)
                    end
                    newBoard = false
                    if (digShakeCount > 2) then
                        local sfx = bigdigsound:clone()
                        sfx:setPitch(math.random(80, 120) / 100)
                        sfx:play()
                    else
                        local sfx = digsound:clone()
                        sfx:setPitch(math.random(80, 120) / 100)
                        sfx:play()
                    end
                    if hints[tileId] > 0 and hints[tileId] < 9 then
                        local sfx = hintsounds[hints[tileId]]:clone()
                        sfx:play()
                    end
                elseif boardDepth[tileId] == 1 and hints[tileId] >= 1 and hints[tileId] < 9 then
                    -- chord: if enough flags are placed around a revealed hint tile, reveal all unflagged covered neighbors
                    local needed = hints[tileId]
                    local flagCount = 0
                    local tx = (tileId - 1) % TILES_PER_ROW
                    local ty = math.floor((tileId - 1) / TILES_PER_ROW)
                    for dy = -1, 1 do
                        for dx = -1, 1 do
                            if not (dx == 0 and dy == 0) then
                                local nx = tx + dx
                                local ny = ty + dy
                                if nx >= 0 and nx < TILES_PER_ROW and ny >= 0 and ny < TILES_PER_ROW then
                                    local nId = ny * TILES_PER_ROW + nx + 1
                                    if flags[nId] then
                                        flagCount = flagCount + 1
                                    end
                                end
                            end
                        end
                    end
                    local digsoundflag = false
                    if flagCount >= needed then
                        for dy = -1, 1 do
                            for dx = -1, 1 do
                                if not (dx == 0 and dy == 0) then
                                    local nx = tx + dx
                                    local ny = ty + dy
                                    if nx >= 0 and nx < TILES_PER_ROW and ny >= 0 and ny < TILES_PER_ROW then
                                        local nId = ny * TILES_PER_ROW + nx + 1
                                        if not flags[nId] and boardDepth[nId] == 2 then
                                            boardDepth[nId] = 1
                                            newParticle(nx * TSIZE + 8, ny * TSIZE + 8, coverTile)

                                            if hints[nId] == 0 then
                                                boardFlood(nId)
                                            end
                                            if hints[nId] > 0 and hints[nId] < 9 then
                                                local sfx = hintsounds[hints[nId]]:clone()
                                                sfx:play()
                                                digsoundflag = true
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if (digsoundflag) then
                            local sfx = digsound:clone()
                            sfx:setPitch(math.random(80, 120) / 100)
                            sfx:play()
                        end
                    end
                end
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
        table.insert(glitches, 0)
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
        boardFloodStep(id, 0)
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
                    newParticle(nx * TSIZE + 8, ny * TSIZE + 8, coverTile)
                    boardDepth[nIndex] = 1
                    digShakeCount = digShakeCount + 1
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

function handleScreenShake()
    if digShakeCount > 0 then
        shakeLength = 120
        shakeLife = 0
        shakeStrength = math.ceil(digShakeCount / 5)
        digShakeCount = 0
    end
    if shakeLife < shakeLength then
        shakeX = math.random(-1 * shakeStrength * (1 - (shakeLife / shakeLength)),
            shakeStrength * (1 - (shakeLife / shakeLength)))
        shakeY = math.random(-1 * shakeStrength * (1 - (shakeLife / shakeLength)),
            shakeStrength * (1 - (shakeLife / shakeLength)))
        shakeLife = shakeLife + 1
    else
        shakeX = 0
        shakeY = 0
        shakeStrength = 0
    end
end

function knockOffFlags()
    for i = 1, #flags do
        if flags[i] then
            local fx = (i - 1) % TILES_PER_ROW
            local fy = math.floor((i - 1) / TILES_PER_ROW)
            newParticle(fx * TSIZE + TSIZE / 2, fy * TSIZE + TSIZE / 2, flagTile)
            flags[i] = false
            local flagCopy = unflagsound:clone()
            flagCopy:setPitch(0.8 + math.random() * 0.4)
            flagCopy:play()
        end
    end
end

function resetGame()
    mines = {}
    hints = {}
    glitches = {}
    boardDepth = {}

    knockOffFlags()

    gameActive = true
    showMines = false
    timeSinceEnd = 0
    gameEndState = "playing"
    shakeX, shakeY = 0, 0
    shakeLength, shakeLife, shakeStrength = 0, 0, 0
    digShakeCount = 0

    for ty = 0, TILES_PER_ROW * TILES_PER_ROW - 1 do
        table.insert(boardDepth, 2)
    end
    if glitch and glitch:isPlaying() then
        glitch:stop()
    end
    makeBoard()
end

function explodeTileAt(tile)
    local sfx = explodesound:clone()
    sfx:setPitch(math.random(80, 120) / 100)
    sfx:play()
    glitch:setLooping(true)
    glitch:play()
    local tx = (tile - 1) % TILES_PER_ROW
    local ty = math.floor((tile - 1) / TILES_PER_ROW)

    knockOffFlags()

    for i = 1, #mines do
        local ix = (i - 1) % TILES_PER_ROW
        local iy = math.floor((i - 1) / TILES_PER_ROW)
        local dist = math.sqrt((tx - ix) * (tx - ix) + (ty - iy) * (ty - iy))

        -- explode with 3 different noisy radii
        if dist <= 3 + math.random(-1, 1) then
            boardDepth[i] = math.max(0, boardDepth[i] - 2)
            newParticle(ix * TSIZE + 8, iy * TSIZE + 8, coverTile)
            digShakeCount = digShakeCount + 1
        elseif dist <= 5 + math.random(-2, 2) then
            boardDepth[i] = math.max(1, boardDepth[i] - 1)
            if boardDepth[i] == 1 then
                newParticle(ix * TSIZE + 8, iy * TSIZE + 8, coverTile)
                digShakeCount = digShakeCount + 1
            end
        elseif dist <= 6 + math.random(-2, 2) then
            boardDepth[i] = math.max(1, boardDepth[i] - 1)
            if boardDepth[i] == 1 then
                newParticle(ix * TSIZE + 8, iy * TSIZE + 8, coverTile)
                digShakeCount = digShakeCount + 1
            end
        end
    end

    -- shake
    shakeLength = 240
    shakeLife = 0
    shakeStrength = 8
end

return CANVAS_PIXELS
