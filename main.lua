-- main.lua
local gameCanvas
local scale = 1
local tileset
local tileQuad
local TSIZE = 16
local TILES_PER_ROW = 18
local CANVAS_PIXELS = TSIZE * TILES_PER_ROW
local mineDensity = 18
local mineCount = 0
local flagCount = 0
local timeStarted
local clock
local face = 1
local faceGaspTime = 0
local boop = 0
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
local gameActive = false
local showMines = false
local timeOfEnd = math.huge
local gameEndState = "menu"
local bannerSoundPlayed = false
local photosensitive = true
local sfx = true
local showUI = true

function love.load()
    math.randomseed(os.time())
    love.graphics.setDefaultFilter('nearest', 'nearest')
    gameCanvas = love.graphics.newCanvas(CANVAS_PIXELS, CANVAS_PIXELS)
    uiCanvas = love.graphics.newCanvas(CANVAS_PIXELS + TSIZE * 12, CANVAS_PIXELS)
    staticCanvas = love.graphics.newCanvas(CANVAS_PIXELS, CANVAS_PIXELS)
    -- Load the static effect shader
    staticShader = love.graphics.newShader('assets/static.glsl')
    tileset = love.graphics.newImage('assets/minesweeper.png')
    tileset:setFilter('nearest', 'nearest')
    logoimg = love.graphics.newImage('assets/logo.png')
    logoimg:setFilter('nearest', 'nearest')

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
    love.graphics.newQuad(TSIZE * 4, TSIZE * 8, TSIZE, TSIZE, tileset:getDimensions()), -- !
    love.graphics.newQuad(TSIZE * 6, TSIZE * 10, TSIZE, TSIZE, tileset:getDimensions()), -- X
    love.graphics.newQuad(TSIZE * 7, TSIZE * 10, TSIZE, TSIZE, tileset:getDimensions()), -- Z
    love.graphics.newQuad(TSIZE * 5, TSIZE * 11, TSIZE, TSIZE, tileset:getDimensions()), -- space
    love.graphics.newQuad(TSIZE * 6, TSIZE * 11, TSIZE, TSIZE, tileset:getDimensions()), -- left mouse
    love.graphics.newQuad(TSIZE * 7, TSIZE * 11, TSIZE, TSIZE, tileset:getDimensions()), -- right mouse
    love.graphics.newQuad(TSIZE * 5, TSIZE * 12, TSIZE, TSIZE, tileset:getDimensions()), -- :
    love.graphics.newQuad(TSIZE * 6, TSIZE * 12, TSIZE, TSIZE, tileset:getDimensions()), -- D
    love.graphics.newQuad(TSIZE * 7, TSIZE * 12, TSIZE, TSIZE, tileset:getDimensions()), -- G
    love.graphics.newQuad(TSIZE * 5, TSIZE * 13, TSIZE, TSIZE, tileset:getDimensions()), -- F
    love.graphics.newQuad(TSIZE * 6, TSIZE * 13, TSIZE, TSIZE, tileset:getDimensions()), -- photosensitivity
    love.graphics.newQuad(TSIZE * 7, TSIZE * 13, TSIZE, TSIZE, tileset:getDimensions()), -- sfx
    love.graphics.newQuad(TSIZE * 5, TSIZE * 14, TSIZE, TSIZE, tileset:getDimensions()), -- yes
    love.graphics.newQuad(TSIZE * 6, TSIZE * 14, TSIZE, TSIZE, tileset:getDimensions()), -- no
    love.graphics.newQuad(TSIZE * 7, TSIZE * 14, TSIZE, TSIZE, tileset:getDimensions()), -- dash
    love.graphics.newQuad(TSIZE * 5, TSIZE * 15, TSIZE, TSIZE, tileset:getDimensions())} -- k

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

    logo = love.graphics.newQuad(0, 0, 180, 76, logoimg:getDimensions())

    sevsegorigin = {TSIZE * 8, TSIZE * 5}
    sevsegs = {love.graphics.newQuad(sevsegorigin[1], sevsegorigin[2], 12, 21, tileset:getDimensions()),
               love.graphics.newQuad(sevsegorigin[1] + 12, sevsegorigin[2], 12, 21, tileset:getDimensions()),
               love.graphics.newQuad(sevsegorigin[1] + 12 * 2, sevsegorigin[2], 12, 21, tileset:getDimensions()),
               love.graphics.newQuad(sevsegorigin[1] + 12 * 3, sevsegorigin[2], 12, 21, tileset:getDimensions()),
               love.graphics.newQuad(sevsegorigin[1] + 12 * 4, sevsegorigin[2], 12, 21, tileset:getDimensions()),
               love.graphics.newQuad(sevsegorigin[1] + 12 * 5, sevsegorigin[2], 12, 21, tileset:getDimensions()),
               love.graphics.newQuad(sevsegorigin[1] + 12 * 6, sevsegorigin[2], 12, 21, tileset:getDimensions()),
               love.graphics.newQuad(sevsegorigin[1] + 12 * 7, sevsegorigin[2], 12, 21, tileset:getDimensions()),
               love.graphics.newQuad(sevsegorigin[1] + 12 * 8, sevsegorigin[2], 12, 21, tileset:getDimensions()),
               love.graphics.newQuad(sevsegorigin[1] + 12 * 9, sevsegorigin[2], 12, 21, tileset:getDimensions()),
               love.graphics.newQuad(sevsegorigin[1] + 12 * 12, sevsegorigin[2], 12, 21, tileset:getDimensions())}
    flagseg = love.graphics.newQuad(sevsegorigin[1] + 12 * 10, sevsegorigin[2], 12, 21, tileset:getDimensions())
    timeseg = love.graphics.newQuad(sevsegorigin[1] + 12 * 11, sevsegorigin[2], 12, 21, tileset:getDimensions())

    faces = {love.graphics.newQuad(TSIZE * 8, TSIZE * 7, 24, 24, tileset:getDimensions()),
             love.graphics.newQuad(TSIZE * 10, TSIZE * 7, 24, 24, tileset:getDimensions()),
             love.graphics.newQuad(TSIZE * 12, TSIZE * 7, 24, 24, tileset:getDimensions()),
             love.graphics.newQuad(TSIZE * 14, TSIZE * 7, 24, 24, tileset:getDimensions()),
             love.graphics.newQuad(TSIZE * 8, TSIZE * 9, 24, 24, tileset:getDimensions()),
             love.graphics.newQuad(TSIZE * 10, TSIZE * 9, 24, 24, tileset:getDimensions()),
             love.graphics.newQuad(TSIZE * 12, TSIZE * 9, 24, 24, tileset:getDimensions()),
             love.graphics.newQuad(TSIZE * 14, TSIZE * 9, 24, 24, tileset:getDimensions()),
             love.graphics.newQuad(TSIZE * 5, TSIZE * 0, 32, 32, tileset:getDimensions()),
             love.graphics.newQuad(TSIZE * 8, TSIZE * 11, 24, 24, tileset:getDimensions()),
             love.graphics.newQuad(TSIZE * 10, TSIZE * 11, 24, 24, tileset:getDimensions()),
             love.graphics.newQuad(TSIZE * 12, TSIZE * 11, 24, 24, tileset:getDimensions())}

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
    showUI = w / (scale * 288) >= 5 / 3
end

function love.draw()
    love.graphics.clear(0.06, 0.07, 0.11)
    love.graphics.setCanvas(uiCanvas)
    love.graphics.clear(0.06, 0.07, 0.11)
    local mineCounter = mineCount - flagCount
    if newBoard then
        mineCounter = -1
    end
    if mineCounter > 99 then
        love.graphics.draw(tileset, sevsegs[math.floor(mineCounter / 100) + 1], 24, 16)
    else
        love.graphics.draw(tileset, sevsegs[11], 24, 16)
    end
    if mineCounter > 9 then
        love.graphics.draw(tileset, sevsegs[math.floor((mineCounter % 100) / 10) + 1], 36, 16)
    else
        love.graphics.draw(tileset, sevsegs[11], 36, 16)
    end
    if mineCounter > -1 then
        love.graphics.draw(tileset, sevsegs[mineCounter % 10 + 1], 48, 16)
    else
        love.graphics.draw(tileset, sevsegs[11], 48, 16)
    end
    love.graphics.draw(tileset, flagseg, 60, 16)

    if gameEndState == "playing" then
        clock = math.min(math.floor(love.timer.getTime() - timeStarted), 999)
    end
    if newBoard then
        clock = -1
    end
    if clock > 99 then
        love.graphics.draw(tileset, sevsegs[math.floor(clock / 100) + 1], 24, 64)
    else
        love.graphics.draw(tileset, sevsegs[11], 24, 64)
    end
    if clock > 9 then
        love.graphics.draw(tileset, sevsegs[math.floor((clock % 100) / 10) + 1], 36, 64)
    else
        love.graphics.draw(tileset, sevsegs[11], 36, 64)
    end
    if clock > -1 then
        love.graphics.draw(tileset, sevsegs[clock % 10 + 1], 48, 64)
    else
        love.graphics.draw(tileset, sevsegs[11], 48, 64)
    end
    love.graphics.draw(tileset, timeseg, 60, 64)

    if gameEndState == "won" then
        face = 4 + (4 * (math.floor(love.timer.getTime() * 2) % 2))
    elseif gameEndState == "lost" then
        face = 3 + (4 * (math.floor(love.timer.getTime() * 5) % 2))
    elseif love.timer.getTime() - boop > 10 then
        face = 11 + math.floor(love.timer.getTime()) % 2
    elseif love.timer.getTime() - faceGaspTime > 0 and love.timer.getTime() - faceGaspTime < 1 then
        if love.timer.getTime() - faceGaspTime < 0.1 then
            face = 6
        else
            face = 2
        end
    else
        if math.floor(love.timer.getTime() * 10) % 20 == 7 then
            face = 5
        else
            face = 1
        end
    end

    love.graphics.draw(tileset, faces[9], 416, 16)
    love.graphics.draw(tileset, faces[face], 444, 20, 0, -1, 1)

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
                if gameEndState == "won" and 2 * tx - ty + TILES_PER_ROW < ((love.timer.getTime() - timeOfEnd) * 16) -
                    ((3 * tx - 37 * ty) % 4 - 2) then
                    local hash = math.floor(math.min(math.floor(
                        ((love.timer.getTime() - timeOfEnd) * 16) - ((3 * tx - 37 * ty) % 4 - 2)) -
                                                         (2 * tx - ty + TILES_PER_ROW), 7) / 2) + 1
                    love.graphics.draw(tileset, grassTiles[hash], x, y)
                    if mines[tileId] then
                        if (tx + ty + math.floor((love.timer.getTime() - timeOfEnd) * 2)) % 2 == 1 then
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

    --[[if gameEndState == "lost" and love.timer.getTime()-timeOfEnd > 1.5 then
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
    if gameEndState == "won" and love.timer.getTime()-timeOfEnd > 1.5 then
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
    if love.timer.getTime() - timeOfEnd > 3 then
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

    if gameEndState == 'menu' then
        love.graphics.draw(logoimg, logo, 54, 36)
        if math.floor(love.timer.getTime() * 2) % 2 == 0 then
            love.graphics.draw(tileset, bannerTiles[3], TSIZE * 1.5, TSIZE * 11, 0, 15, 1)
            love.graphics.draw(tileset, bannerTiles[1], TSIZE * 1, TSIZE * 11)
            love.graphics.draw(tileset, bannerTiles[2], TSIZE * 1, TSIZE * 11)
            love.graphics.draw(tileset, bannerTiles[4], TSIZE * 16, TSIZE * 11)
            love.graphics.draw(tileset, bannerTiles[5], TSIZE * 16, TSIZE * 11)
            love.graphics.draw(tileset, letterTiles[28], TSIZE * 1.5, TSIZE * 11)
            love.graphics.draw(tileset, letterTiles[10], TSIZE * 2.5, TSIZE * 11)
            love.graphics.draw(tileset, letterTiles[11], TSIZE * 3.5, TSIZE * 11)
            love.graphics.draw(tileset, letterTiles[8], TSIZE * 4.5, TSIZE * 11)
            love.graphics.draw(tileset, letterTiles[5], TSIZE * 5.5, TSIZE * 11)
            love.graphics.draw(tileset, letterTiles[5], TSIZE * 6.5, TSIZE * 11)
            love.graphics.draw(tileset, letterTiles[13], TSIZE * 8.5, TSIZE * 11)
            love.graphics.draw(tileset, letterTiles[9], TSIZE * 9.5, TSIZE * 11)
            love.graphics.draw(tileset, letterTiles[1], TSIZE * 10.5, TSIZE * 11)
            love.graphics.draw(tileset, letterTiles[29], TSIZE * 12.5, TSIZE * 11)
            love.graphics.draw(tileset, letterTiles[8], TSIZE * 13.5, TSIZE * 11)
            love.graphics.draw(tileset, letterTiles[1], TSIZE * 14.5, TSIZE * 11)
            love.graphics.draw(tileset, letterTiles[28], TSIZE * 15.5, TSIZE * 11)
        end
        love.graphics.draw(tileset, bannerTiles[3], TSIZE * 0, TSIZE * 15, 0, 2, 2)
        love.graphics.draw(tileset, bannerTiles[4], TSIZE * 2, TSIZE * 15)
        love.graphics.draw(tileset, bannerTiles[5], TSIZE * 2, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[24], TSIZE * 0, TSIZE * 15)
        love.graphics.draw(tileset, letterTiles[25], TSIZE * 0, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[27 - (photosensitive == true and 1 or photosensitive == false and 0)],
            TSIZE * 1, TSIZE * 15)
        love.graphics.draw(tileset, letterTiles[27 - (sfx == true and 1 or sfx == false and 0)], TSIZE * 1, TSIZE * 16)
    elseif newBoard then
        love.graphics.draw(tileset, bannerTiles[1], TSIZE * 3, TSIZE * 15)
        love.graphics.draw(tileset, bannerTiles[2], TSIZE * 3, TSIZE * 16)
        love.graphics.draw(tileset, bannerTiles[3], TSIZE * 4, TSIZE * 15, 0, 10, 2)
        love.graphics.draw(tileset, bannerTiles[4], TSIZE * 14, TSIZE * 15)
        love.graphics.draw(tileset, bannerTiles[5], TSIZE * 14, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[18], TSIZE * 5.5, TSIZE * 15)
        love.graphics.draw(tileset, letterTiles[16], TSIZE * 6.5, TSIZE * 15)
        love.graphics.draw(tileset, letterTiles[20], TSIZE * 7.5, TSIZE * 15)
        love.graphics.draw(tileset, letterTiles[21], TSIZE * 9.5, TSIZE * 15)
        love.graphics.draw(tileset, letterTiles[6], TSIZE * 10.5, TSIZE * 15)
        love.graphics.draw(tileset, letterTiles[22], TSIZE * 11.5, TSIZE * 15)
        love.graphics.draw(tileset, letterTiles[15], TSIZE * 4.5, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[17], TSIZE * 5.5, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[19], TSIZE * 6.5, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[20], TSIZE * 7.5, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[23], TSIZE * 9.5, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[2], TSIZE * 10.5, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[13], TSIZE * 11.5, TSIZE * 16)
        love.graphics.draw(tileset, letterTiles[22], TSIZE * 12.5, TSIZE * 16)
    end

    for i = 1, #particles do
        local particle = particles[i]
        if particle.sprite == logo then
            love.graphics.draw(logoimg, particle.sprite, particle.x - 90 + TSIZE / 2, particle.y - 38 + TSIZE / 2,
                particle.rot / 10, 1, 1, 8, 8)
        else
            love.graphics.draw(tileset, particle.sprite, particle.x - TSIZE / 2, particle.y - TSIZE / 2,
                particle.rot / 10, 1 - (particle.age / particle.life), 1 - (particle.age / particle.life), 8, 8)
        end
    end

    if love.timer.getTime() - timeOfEnd < 0.5 and love.timer.getTime() - timeOfEnd > 0 and photosensitive then
        love.graphics.setColor(1, 1, 1, 1 - (love.timer.getTime() - timeOfEnd) * 2)
        love.graphics.rectangle('fill', 0, 0, TSIZE * TILES_PER_ROW, TSIZE * TILES_PER_ROW)
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.setCanvas()

    local windowW, windowH = love.graphics.getDimensions()
    local x = math.floor((windowW - (CANVAS_PIXELS * scale)) / 2)
    local y = math.floor((windowH - (CANVAS_PIXELS * scale)) / 2)
    -- apply shake offsets when drawing canvas to screen
    if (showUI) then
        love.graphics.draw(uiCanvas, x - TSIZE * 6 * scale, y, 0, scale, scale)
    end
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
    if --[[timeOfEnd == 360 or ]] love.timer.getTime() - timeOfEnd > 3 and not bannerSoundPlayed then
        playsound(bannersound, 80, 120)
        bannerSoundPlayed = true
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
                timeOfEnd = love.timer.getTime()
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
            timeOfEnd = love.timer.getTime()
            knockOffFlags()
            playsound(winsound, 80, 120)
        end
    end
end

function love.keypressed(key)
    boop = love.timer.getTime()
    if gameEndState == "menu" then
        gameEndState = "playing"
        gameActive = true
        local particle = {
            x = 54 + 90,
            y = 36 + 38,
            rot = 0,
            sprite = logo,
            life = math.random(6, 15) * 120,
            age = 0,
            vx = math.random(-3, 3) / 50,
            vy = math.random(-3, 0) / 50,
            vr = math.random(-2, 2) / 100
        }
        table.insert(particles, particle)
    else
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
        if key == 'z' then
            local mx, my = love.mouse.getPosition()
            digOrFlag(mx, my, 1)
        end
        if key == 'x' or key == 'space' then
            local mx, my = love.mouse.getPosition()
            digOrFlag(mx, my, 2)
        end
    end
end

function love.mousepressed(mx, my, button)
    boop = love.timer.getTime()
    if gameEndState == "menu" then
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
        if button == 1 then
            if tileId == 271 or tileId == 272 then
                photosensitive = not photosensitive
            end
            if tileId == 289 or tileId == 290 then
                sfx = not sfx
            end
        end
    else
        digOrFlag(mx, my, button)
    end
end

function makeBoard()
    newBoard = true
    blankHints = 0
    mineCount = 0
    timeStarted = love.timer.getTime()
    mines = {}
    hints = {}
    for ty = 0, TILES_PER_ROW * TILES_PER_ROW - 1 do
        if (math.random() < mineDensity / 100) then
            table.insert(mines, true)
            mineCount = mineCount + 1
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

function boardFlood()
    local boardNeedsFlood = true
    while boardNeedsFlood do
        boardNeedsFlood = false
        for i = 1, TILES_PER_ROW * TILES_PER_ROW do
            local idx0 = i - 1
            local tx = idx0 % TILES_PER_ROW
            local ty = math.floor(idx0 / TILES_PER_ROW)
            local reveal = 0
            if boardDepth[i] == 1 and hints[i] == 0 then
                for dy = -1, 1 do
                    for dx = -1, 1 do
                        if not (dx == 0 and dy == 0) then
                            local nx = tx + dx
                            local ny = ty + dy
                            if nx >= 0 and nx < TILES_PER_ROW and ny >= 0 and ny < TILES_PER_ROW then
                                local nIndex = ny * TILES_PER_ROW + nx + 1
                                if boardDepth[nIndex] == 2 then
                                    reveal = nIndex
                                    newParticle(nx * TSIZE + 8, ny * TSIZE + 8, coverTile)
                                    if flags[nIndex] then
                                        local fx = (nIndex - 1) % TILES_PER_ROW
                                        local fy = math.floor((nIndex - 1) / TILES_PER_ROW)
                                        newParticle(fx * TSIZE + TSIZE / 2, fy * TSIZE + TSIZE / 2, flagTile)
                                        flags[nIndex] = false
                                        playsound(unflagsound, 80, 120)
                                        flagCount = flagCount - 1
                                    end
                                    break
                                end
                            end
                        end
                    end
                    if reveal > 0 then
                        break
                    end
                end
                if reveal > 0 then
                    boardDepth[reveal] = 1
                    digShakeCount = digShakeCount + 1
                    boardNeedsFlood = true
                end
            end
        end
    end
end

function newParticle(x, y, sprite)
    local particle = {}
    particle.x = x + TSIZE / 2
    particle.y = y + TSIZE / 2
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
                particle.x = particle.x + particle.vx * love.timer.getDelta() * 240
                particle.y = particle.y + particle.vy * love.timer.getDelta() * 240
                particle.rot = particle.rot + particle.vr * love.timer.getDelta() * 240
                particle.vy = particle.vy + 0.005 * love.timer.getDelta() * 240 -- gravity
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
    flagCount = 0
    for i = 1, #flags do
        if flags[i] then
            local fx = (i - 1) % TILES_PER_ROW
            local fy = math.floor((i - 1) / TILES_PER_ROW)
            newParticle(fx * TSIZE + TSIZE / 2, fy * TSIZE + TSIZE / 2, flagTile)
            flags[i] = false
            playsound(unflagsound, 80, 120)
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
    timeOfEnd = math.huge
    bannerSoundPlayed = false
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
    playsound(explodesound, 80, 120)
    glitch:setLooping(true)
    if sfx then
        glitch:play()
    end
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

function digOrFlag(mx, my, button)
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
                    if flags[tileId] then
                        newParticle(tx * TSIZE + 8, ty * TSIZE + 8, flagTile)
                        playsound(unflagsound, 80, 120)
                        flagCount = flagCount - 1
                        flags[tileId] = not flags[tileId]
                    elseif mineCount - flagCount > 0 then
                        playsound(flagsound, 80, 120)
                        flagCount = flagCount + 1
                        flags[tileId] = not flags[tileId]
                    end
                end
            else
                -- dig
                if not flags[tileId] and boardDepth[tileId] == 2 then
                    faceGaspTime = love.timer.getTime()
                    if newBoard then
                        knockOffFlags() -- Knock off all flags on first dig
                        while digShakeCount == 0 do
                            digShakeCount = 0
                            makeBoard()
                            boardDepth[tileId] = 1
                            boardFlood()
                        end
                    end
                    newParticle(tx * TSIZE + 8, ty * TSIZE + 8, coverTile)
                    if not newBoard then
                        boardDepth[tileId] = 1
                        boardFlood()
                    end
                    newBoard = false
                    playDigSound()
                    if hints[tileId] > 0 and hints[tileId] < 9 then
                        playsound(hintsounds[hints[tileId]], 100, 100)
                    end
                elseif boardDepth[tileId] == 1 and hints[tileId] >= 1 and hints[tileId] < 9 then
                    faceGaspTime = love.timer.getTime()
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
                    local highestSound = -1
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
                                                boardFlood()
                                            end
                                            if hints[nId] > highestSound and hints[nId] < 9 then
                                                highestSound = hints[nId]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if highestSound > -1 then
                            playDigSound()
                            if highestSound > 0 then
                                playsound(hintsounds[highestSound], 100, 100)
                            end
                        end
                    end
                end
            end
        end
    end
end

function playDigSound()
    if (digShakeCount > 2) then
        playsound(bigdigsound, 80, 120)
    else
        playsound(digsound, 80, 120)
    end
end

function playsound(sound, minPitch, maxPitch)
    if sfx then
        local sfx = sound:clone()
        sfx:setPitch(math.random(minPitch, maxPitch) / 100)
        sfx:play()
    end
end

return CANVAS_PIXELS
