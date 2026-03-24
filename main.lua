-- main.lua
-- Isometric Forest - Dark Gray Theme

local TILE_W = 64
local TILE_H = 32
local MAP_SIZE = 12

-- Center map
local OFFSET_X = 450
local OFFSET_Y = 100

local assets = {}
local quads = {}
local map = {}
local objects = {}

-- Mesh for the isometric floor
local grassMesh = nil

function love.load()
    love.window.setTitle("Night Harvest - Dark Forest")
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Load Assets
    assets.tileset = love.graphics.newImage("assets/images/tileset_16px.png")
    assets.forest = love.graphics.newImage("assets/images/tileset_forest_32px.png")
    
    local tw, th = assets.tileset:getDimensions()
    
    -- Grass at 32, 96
    local u1, v1 = 32/tw, 96/th
    local u2, v2 = (32+16)/tw, (96+16)/th
    quads.tree = love.graphics.newQuad(0, 0, 32, 64, assets.forest:getDimensions())

    -- Create Isometric Floor Mesh
    grassMesh = love.graphics.newMesh({
        {-TILE_W/2, 0, u1, v1}, 
        {0, -TILE_H/2, u2, v1}, 
        {TILE_W/2, 0, u2, v2},  
        {0, TILE_H/2, u1, v2}   
    }, "fan")
    grassMesh:setTexture(assets.tileset)

    -- Map setup with random variation
    for i = 1, MAP_SIZE do
        map[i] = {}
        for j = 1, MAP_SIZE do
            -- Store a random shade for each tile
            map[i][j] = {
                shade = 0.15 + (math.random() * 0.1)
            }
        end
    end

    -- Objects placement
    local function addObj(i, j, type)
        table.insert(objects, {i = i, j = j, type = type})
    end

    addObj(2, 2, "tree")
    addObj(2, 8, "tree")
    addObj(5, 10, "tree")
    addObj(9, 3, "tree")
    addObj(11, 7, "tree")
    addObj(3, 11, "tree")
    addObj(6, 6, "tree")

    table.sort(objects, function(a, b) return (a.i + a.j) < (b.i + b.j) end)
end

function love.draw()
    -- Full Dark Gray Background
    love.graphics.clear(0.05, 0.05, 0.05)
    
    -- Draw Floor
    for i = 1, MAP_SIZE do
        for j = 1, MAP_SIZE do
            local sx = OFFSET_X + (j - i) * (TILE_W / 2)
            local sy = OFFSET_Y + (i + j) * (TILE_H / 2)
            
            -- Apply different gray shades to each tile
            local s = map[i][j].shade
            love.graphics.setColor(s, s, s)
            love.graphics.draw(grassMesh, sx, sy)
        end
    end

    -- Draw Objects (Darkened/Silhouetted)
    for _, obj in ipairs(objects) do
        local sx = OFFSET_X + (obj.j - obj.i) * (TILE_W / 2)
        local sy = OFFSET_Y + (obj.i + obj.j) * (TILE_H / 2)
        
        if obj.type == "tree" then
            -- Draw trees very dark to match the gray theme
            love.graphics.setColor(0.1, 0.1, 0.12)
            love.graphics.draw(assets.forest, quads.tree, sx, sy, 0, 2, 2, 16, 60)
        end
    end

    -- UI
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.print("The Gray Woods", 20, 20)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
end
