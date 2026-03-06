love.graphics.setDefaultFilter("nearest", "nearest")

local auth_ui = require("src.auth_ui")
local api = require("src.api")

-- Global Game State
gameState = "auth" -- "auth" or "game"

-- Assets and Map
local assets = {}
local quads = {}
local map = {}
local TILE_SIZE = 16
local SCALE = 4
local MAP_WIDTH = 32
local MAP_HEIGHT = 24
local camera = {x = 0, y = 0}

-- Player and Farm
local player = {x = 100, y = 100, speed = 120}
local farm_grid = {}
local seeds = 10

function love.load()
    -- Tileset Loading
    local tileset_path = "assets/images/tileset_16px.png"
    local forest_path = "assets/images/tileset_forest_32px.png"
    
    assets.tileset = love.graphics.newImage(tileset_path)
    assets.forest = love.graphics.newImage(forest_path)

    local tw, th = assets.tileset:getDimensions()
    quads.grass = love.graphics.newQuad(32, 96, 16, 16, tw, th)
    quads.soil = love.graphics.newQuad(0, 96, 16, 16, tw, th)
    quads.tree = love.graphics.newQuad(0, 0, 32, 64, assets.forest:getDimensions())

    -- Map init
    for y = 1, MAP_HEIGHT do
        map[y] = {}
        for x = 1, MAP_WIDTH do
            map[y][x] = { tile = "grass", decoration = nil }
            if math.random() < 0.08 then map[y][x].decoration = "tree" end
        end
    end

    -- Farm init
    for fy = 1, 8 do
        farm_grid[fy] = {}
        for fx = 1, 8 do
            farm_grid[fy][fx] = {type = "grass", growth = 0}
        end
    end
end

function love.update(dt)
    if gameState == "auth" then
        -- Auth updates (none for now, mostly handled by input)
    elseif gameState == "game" then
        updateGame(dt)
    end
end

function updateGame(dt)
    -- Movement
    local dx, dy = 0, 0
    if love.keyboard.isDown("w", "up") then dy = -1 end
    if love.keyboard.isDown("s", "down") then dy = 1 end
    if love.keyboard.isDown("a", "left") then dx = -1 end
    if love.keyboard.isDown("d", "right") then dx = 1 end
    
    player.x = player.x + dx * player.speed * dt
    player.y = player.y + dy * player.speed * dt

    -- Camera
    camera.x = player.x - love.graphics.getWidth() / (2 * SCALE)
    camera.y = player.y - love.graphics.getHeight() / (2 * SCALE)
end

function love.draw()
    if gameState == "auth" then
        auth_ui.draw()
    elseif gameState == "game" then
        drawGame()
    end
end

function drawGame()
    love.graphics.clear(0.1, 0.3, 0.1)
    love.graphics.push()
    love.graphics.scale(SCALE, SCALE)
    love.graphics.translate(-camera.x, -camera.y)

    -- Draw World
    for y = 1, MAP_HEIGHT do
        for x = 1, MAP_WIDTH do
            local tx, ty = (x-1)*TILE_SIZE, (y-1)*TILE_SIZE
            love.graphics.draw(assets.tileset, quads.grass, tx, ty)
            if map[y][x].decoration == "tree" then
                love.graphics.draw(assets.forest, quads.tree, tx - 8, ty - 48)
            end
        end
    end

    -- Draw Player
    love.graphics.setColor(1, 0.8, 0.4)
    love.graphics.rectangle("fill", player.x, player.y, 12, 20)
    love.graphics.setColor(1, 1, 1)

    love.graphics.pop()
    
    love.graphics.print("Welcome, " .. (api.user and api.user.fullName or "Farmer"), 10, 10)
    love.graphics.print("Press ESC to exit", 10, 30)
end

function love.textinput(t)
    if gameState == "auth" then
        auth_ui.textinput(t)
    end
end

function love.keypressed(key)
    if gameState == "auth" then
        auth_ui.keypressed(key)
    else
        if key == "escape" then love.event.quit() end
    end
end

function love.mousepressed(x, y, button)
    if gameState == "auth" then
        auth_ui.mousepressed(x, y, button)
    end
end
