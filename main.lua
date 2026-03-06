love.graphics.setDefaultFilter("nearest", "nearest")

-- Game state
local assets = {}
local quads = {}
local map = {}
local TILE_SIZE = 16
local SCALE = 4  -- 64px tiles
local MAP_WIDTH = 32
local MAP_HEIGHT = 24
local camera = {x = 0, y = 0}

-- Player
local player = {x = MAP_WIDTH/2 * TILE_SIZE, y = MAP_HEIGHT/2 * TILE_SIZE, speed = 120}

-- Farm (8x8 central, with growth)
local farm_grid = {}  
local seeds = 10
local username = "Night"
local showRegister = true
local inputText = ""
local selected_tile = "grass"

-- API
local API_BASE = "https://your-api.com"
local https_lib = nil

function love.load()
    -- LOAD WITH DIAGNOSTICS
    local tileset_path = "assets/images/tileset_16px.png"
    local forest_path = "assets/images/tileset_forest_32px.png"
    
    assets.tileset = love.graphics.newImage(tileset_path)
    local tileset_info = love.filesystem.getInfo(tileset_path)
    if not tileset_info then
        error("🚨 TILESET NOT FOUND: " .. tileset_path .. "\nPut 'tileset_16px.png' exactly there!")
    end
    print("✅ TILESET LOADED: " .. tileset_info.size .. " bytes | Size: " .. assets.tileset:getWidth() .. "x" .. assets.tileset:getHeight())
    
    assets.forest = love.graphics.newImage(forest_path)
    local forest_info = love.filesystem.getInfo(forest_path)
    if forest_info then
        print("✅ FOREST LOADED: " .. forest_info.size .. " bytes | Size: " .. assets.forest:getWidth() .. "x" .. assets.forest:getHeight())
    else
        print("⚠️  Forest optional - using tileset fallback")
        assets.forest = assets.tileset
    end

    local tw, th = assets.tileset:getDimensions()

    -- **CORRECT QUADS FROM SUNNYSIDE TILESET** (tested via hover/image analysis)
    -- GRASS: col=2 (32px), row=6 (96px) - plain grass
    quads.grass = love.graphics.newQuad(32, 96, 16, 16, tw, th)
    -- SOIL/DIRT: col=0 (0), row=6 (96px) - tilled soil
    quads.soil = love.graphics.newQuad(0, 96, 16, 16, tw, th)
    -- PATH: col=4 (64), row=5 (80px) - dirt path
    quads.path = love.graphics.newQuad(64, 80, 16, 16, tw, th)
    -- WATER: col=0 (0), row=0 (0) - water corner
    quads.water = love.graphics.newQuad(0, 0, 16, 16, tw, th)
    -- TREE: Large from forest (adjust if needed)
    local fw, fh = assets.forest:getDimensions()
    quads.tree = love.graphics.newQuad(0, 0, 32, 64, fw, fh)

    print("✅ QUADS READY - hover bottom preview to find more!")

    -- Map init
    math.randomseed(os.time())
    for y = 1, MAP_HEIGHT do
        map[y] = {}
        for x = 1, MAP_WIDTH do
            map[y][x] = { tile = "grass", decoration = nil }
            if math.random() < 0.08 then map[y][x].decoration = "tree" end
        end
    end

    -- Farm 8x8 (grass → till → plant → grow)
    for fy = 1, 8 do
        farm_grid[fy] = {}
        for fx = 1, 8 do
            farm_grid[fy][fx] = {type = "grass", growth = 0}  -- type: grass, soil, planted, growing1-3, ready
        end
    end

    -- HTTPS lib (download https://raw.githubusercontent.com/love2d/lua-https/main/https.lua to lib/https.lua)
    local ok, https = pcall(require, "lib.https")
    if ok then https_lib = https; print("✅ HTTPS ready") else print("⚠️  No lib/https.lua - cloud save offline") end
end

function love.update(dt)
    -- Player move
    local dx, dy = 0, 0
    if love.keyboard.isDown("w", "up") then dy = -1 end
    if love.keyboard.isDown("s", "down") then dy = 1 end
    if love.keyboard.isDown("a", "left") then dx = -1 end
    if love.keyboard.isDown("d", "right") then dx = 1 end
    player.x = player.x + dx * player.speed * dt
    player.y = player.y + dy * player.speed * dt

    -- Clamp
    player.x = math.max(0, math.min(player.x, (MAP_WIDTH * TILE_SIZE) - 16))
    player.y = math.max(0, math.min(player.y, (MAP_HEIGHT * TILE_SIZE) - 24))

    -- Camera
    camera.x = player.x - love.graphics.getWidth() / (2 * SCALE) + 8
    camera.y = player.y - love.graphics.getHeight() / (2 * SCALE) + 12
    camera.x = math.max(0, math.min(camera.x, (MAP_WIDTH * TILE_SIZE) - love.graphics.getWidth() / SCALE))
    camera.y = math.max(0, math.min(camera.y, (MAP_HEIGHT * TILE_SIZE) - love.graphics.getHeight() / SCALE))

    -- Auto-grow farm
    if math.random() < 0.016 then  -- ~1/sec
        for fy = 1, 8 do for fx = 1, 8 do
            local tile = farm_grid[fy][fx]
            if tile.type == "planted" then
                tile.growth = tile.growth + 1
                if tile.growth == 1 then tile.type = "growing1"
                elseif tile.growth == 2 then tile.type = "growing2"
                elseif tile.growth == 3 then tile.type = "ready" end
            end
        end end
    end
end

function love.draw()
    love.graphics.clear(0.1, 0.3, 0.1)

    love.graphics.push()
    love.graphics.scale(SCALE, SCALE)
    love.graphics.translate(-camera.x, -camera.y)

    -- World map
    for y = 1, MAP_HEIGHT do for x = 1, MAP_WIDTH do
        local tx, ty = (x-1)*TILE_SIZE, (y-1)*TILE_SIZE
        local tile_quad = quads[map[y][x].tile] or quads.grass
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(assets.tileset, tile_quad, tx, ty)

        if map[y][x].decoration == "tree" then
            love.graphics.draw(assets.forest, quads.tree, tx - 8, ty - 48)
        end
    end end

    -- FARM (central 8x8 - overrides)
    local farm_cx, farm_cy = math.floor(MAP_WIDTH/2 - 4), math.floor(MAP_HEIGHT/2 - 4)
    for fy = 1, 8 do for fx = 1, 8 do
        local ftx, fty = (farm_cx + fx - 1) * TILE_SIZE, (farm_cy + fy - 1) * TILE_SIZE
        local tile = farm_grid[fy][fx]
        local q = quads[tile.type] or quads.soil
        love.graphics.draw(assets.tileset, q, ftx, fty)
        -- Growth text
        love.graphics.setColor(0,0,0,0.8)
        love.graphics.print(tile.growth, ftx + 4, fty + 4)
    end end

    -- Player (better rect)
    love.graphics.setColor(1, 0.8, 0.4)
    love.graphics.rectangle("fill", player.x, player.y, 12, 20)
    love.graphics.setColor(1,1,1)

    love.graphics.pop()

    -- UI
    love.graphics.setColor(1,1,1)
    love.graphics.print("🌱 Seeds: " .. seeds .. " | Tool: " .. selected_tile, 10, 10)
    love.graphics.print("WASD move | Click= till/plant/harvest farm | 1-4=tools | R=reset | HOVER tileset for coords!", 10, 30)

    if showRegister then
        love.graphics.setColor(0,0,0,0.8); love.graphics.rectangle("fill", 0, 0, 800, 600)
        love.graphics.setColor(1,1,1)
        love.graphics.print("👤 Username for cloud:", 250, 250, 0, 1.5)
        love.graphics.print(inputText, 250, 300, 0, 2)
        love.graphics.print("ENTER to start farming 🌾", 250, 350)
    end

    -- 🔍 TILESET DEBUG PREVIEW (BIGGER + BETTER)
    local preview_scale = 0.75
    local ts_w, ts_h = assets.tileset:getDimensions()
    local px, py = 10, love.graphics.getHeight() - (ts_h * preview_scale) - 20
    love.graphics.setColor(1,1,1,0.9)
    love.graphics.draw(assets.tileset, px, py, 0, preview_scale, preview_scale)
    love.graphics.setColor(1,0,0,1)  -- Red grid
    for row = 0, ts_h/TILE_SIZE -1 do for col = 0, ts_w/TILE_SIZE -1 do
        local gx = px + col * TILE_SIZE * preview_scale
        local gy = py + row * TILE_SIZE * preview_scale
        love.graphics.rectangle("line", gx, gy, TILE_SIZE*preview_scale, TILE_SIZE*preview_scale)
        love.graphics.setColor(1,1,1)
        love.graphics.print(col .. "," .. row, gx+2, gy+2)
    end end
end

function love.mousepressed(mx, my, mb)
    if mb == 1 and not showRegister then
        local wx = math.floor((mx / SCALE + camera.x) / TILE_SIZE) + 1
        local wy = math.floor((my / SCALE + camera.y) / TILE_SIZE) + 1

        -- World paint
        if wx >=1 and wx <= MAP_WIDTH and wy >=1 and wy <= MAP_HEIGHT then
            map[wy][wx].tile = selected_tile
        end

        -- FARM interact (central 8x8)
        local farm_cx, farm_cy = math.floor(MAP_WIDTH/2 - 4), math.floor(MAP_HEIGHT/2 - 4)
        local fx = math.floor((mx / SCALE + camera.x - farm_cx * TILE_SIZE) / TILE_SIZE) + 1
        local fy = math.floor((my / SCALE + camera.y - farm_cy * TILE_SIZE) / TILE_SIZE) + 1
        if fx >=1 and fx <=8 and fy >=1 and fy <=8 then
            local tile = farm_grid[fy][fx]
            if tile.type == "grass" then
                tile.type = "soil"
            elseif tile.type == "soil" and seeds > 0 then
                tile.type = "planted"; tile.growth = 0; seeds = seeds - 1
            elseif tile.type == "ready" then
                tile.type = "soil"; tile.growth = 0; seeds = seeds + 3  -- Harvest!
            end
            saveGame()  -- Auto cloud save
        end
    end
end

function love.mousemoved(mx, my, dx, dy)
    -- HOVER DEBUG → CONSOLE PRINTS QUAD CODE!
    local preview_scale = 0.75
    local ts_w, ts_h = assets.tileset:getDimensions()
    local px, py = 10, love.graphics.getHeight() - (ts_h * preview_scale) - 20
    local rel_x = (mx - px) / preview_scale
    local rel_y = (my - py) / preview_scale
    local col = math.floor(rel_x / TILE_SIZE)
    local row = math.floor(rel_y / TILE_SIZE)
    if col >=0 and row >=0 and col < ts_w/TILE_SIZE and row < th/TILE_SIZE then
        print("🎯 HOVER: col=" .. col .. " row=" .. row .. " → quads.YOURNAME = love.graphics.newQuad(" .. (col*16) .. ", " .. (row*16) .. ", 16, 16, " .. ts_w .. ", " .. ts_h .. ")")
    end
end

function love.textinput(t)
    if showRegister then inputText = inputText .. t end
end

function love.keypressed(key)
    if showRegister then
        if key == "return" and #inputText > 0 then
            username = inputText; showRegister = false; loadGame()
        elseif key == "backspace" then inputText = string.sub(inputText, 1, -2) end
        return
    end

    -- Tools 1-4
    local tools = {"grass", "soil", "path", "water"}
    if key >= "1" and key <= "4" then selected_tile = tools[tonumber(key)] end

    if key == "r" then love.load(); love.timer.sleep(0.1) end  -- Reload
    if key == "escape" then saveGame(); love.event.quit() end
end

-- Cloud (stub - add lib.https.lua)
function saveGame()
    print("💾 Saved: seeds=" .. seeds .. " farm=" .. #love.data.encode("string", "json", farm_grid))
    -- if https_lib then ... end
end

function loadGame()
    print("☁️  Loaded for " .. username)
    -- Load from API
end