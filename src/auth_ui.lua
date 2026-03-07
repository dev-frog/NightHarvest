local api = require("src.api")
local auth_ui = {}

auth_ui.state = "login" -- "login" or "register"
auth_ui.fields = {
    email = "",
    password = "",
    fullName = ""
}
auth_ui.activeField = "email"
auth_ui.message = ""
auth_ui.loading = false

-- UI Layout helper
local function getLayout()
    local sw, sh = love.graphics.getDimensions()
    return {
        width = 400,
        height = 40,
        x = (sw - 400) / 2,
        centerY = sh / 2
    }
end

function auth_ui.draw()
    local layout = getLayout()
    local sw, sh = love.graphics.getDimensions()

    -- Dark overlay
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, sw, sh)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(auth_ui.state == "login" and "LOGIN" or "CREATE ACCOUNT", 0, layout.centerY - 220, sw, "center", 0, 2)
    
    local fields = auth_ui.state == "login" and {"email", "password"} or {"email", "password", "fullName"}
    local startY = layout.centerY - 120
    
    for i, field in ipairs(fields) do
        local y = startY + (i-1) * 90
        local label = field:gsub("^%l", string.upper):gsub("Name", " Name")
        
        -- Label
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(label, layout.x, y - 25)
        
        -- Input Box
        local isSelected = auth_ui.activeField == field
        if isSelected then
            love.graphics.setColor(0.3, 0.8, 0.3) -- Green highlight
        else
            love.graphics.setColor(0.4, 0.4, 0.4)
        end
        love.graphics.rectangle("line", layout.x, y, layout.width, layout.height, 4, 4)
        
        -- Text Content
        love.graphics.setColor(1, 1, 1)
        local displayVal = auth_ui.fields[field]
        if field == "password" then displayVal = string.rep("*", #displayVal) end
        love.graphics.print(displayVal, layout.x + 10, y + 10)
        
        -- Animated Cursor
        if isSelected and not auth_ui.loading then
            if math.floor(love.timer.getTime() * 3) % 2 == 0 then
                local tw = love.graphics.getFont():getWidth(displayVal)
                love.graphics.rectangle("fill", layout.x + 12 + tw, y + 8, 2, 24)
            end
        end
    end
    
    -- Submit Button
    local btnY = startY + #fields * 90 + 20
    local mx, my = love.mouse.getPosition()
    local isHoverBtn = mx > layout.x and mx < layout.x + layout.width and my > btnY and my < btnY + layout.height
    
    if auth_ui.loading then
        love.graphics.setColor(0.3, 0.3, 0.3)
    elseif isHoverBtn then
        love.graphics.setColor(0.3, 0.9, 0.3)
    else
        love.graphics.setColor(0.2, 0.7, 0.2)
    end
    love.graphics.rectangle("fill", layout.x, btnY, layout.width, layout.height, 6, 6)
    
    love.graphics.setColor(1, 1, 1)
    local btnText = auth_ui.loading and "PLEASE WAIT..." or (auth_ui.state == "login" and "LOGIN" or "REGISTER")
    love.graphics.printf(btnText, 0, btnY + 12, sw, "center")
    
    -- Switch Link
    local linkY = btnY + 70
    local isHoverLink = my > linkY - 10 and my < linkY + 30
    love.graphics.setColor(isHoverLink and {1,1,1} or {0.6, 0.6, 0.6})
    love.graphics.printf(auth_ui.state == "login" and "Need an account? Register" or "Already have an account? Login", 0, linkY, sw, "center")
    
    -- Error/Status Message
    if auth_ui.message ~= "" then
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.printf(auth_ui.message, 0, linkY + 50, sw, "center")
    end
end

function auth_ui.keypressed(key)
    if auth_ui.loading then return end

    local fields = auth_ui.state == "login" and {"email", "password"} or {"email", "password", "fullName"}
    
    if key == "tab" then
        for i, field in ipairs(fields) do
            if field == auth_ui.activeField then
                auth_ui.activeField = fields[(i % #fields) + 1]
                break
            end
        end
    elseif key == "return" then
        auth_ui.submit()
    elseif key == "backspace" then
        auth_ui.fields[auth_ui.activeField] = auth_ui.fields[auth_ui.activeField]:sub(1, -2)
    end
end

function auth_ui.textinput(t)
    if auth_ui.loading then return end
    -- Limit text length
    if #auth_ui.fields[auth_ui.activeField] < 32 then
        auth_ui.fields[auth_ui.activeField] = auth_ui.fields[auth_ui.activeField] .. t
    end
end

function auth_ui.mousepressed(mx, my, button)
    if button ~= 1 or auth_ui.loading then return end
    
    local layout = getLayout()
    local fields = auth_ui.state == "login" and {"email", "password"} or {"email", "password", "fullName"}
    local startY = layout.centerY - 120
    
    -- Field Selection
    for i, field in ipairs(fields) do
        local y = startY + (i-1) * 90
        if mx > layout.x and mx < layout.x + layout.width and my > y and my < y + layout.height then
            auth_ui.activeField = field
            return
        end
    end

    -- Submit Button
    local btnY = startY + #fields * 90 + 20
    if mx > layout.x and mx < layout.x + layout.width and my > btnY and my < btnY + layout.height then
        auth_ui.submit()
        return
    end
    
    -- Switch Link
    local linkY = btnY + 70
    if my > linkY - 10 and my < linkY + 30 then
        auth_ui.state = auth_ui.state == "login" and "register" or "login"
        auth_ui.message = ""
        auth_ui.activeField = "email"
    end
end

function auth_ui.submit()
    if auth_ui.fields.email == "" or auth_ui.fields.password == "" then
        auth_ui.message = "Please fill in all fields"
        return
    end

    auth_ui.loading = true
    auth_ui.message = "Connecting..."
    
    if auth_ui.state == "login" then
        local res, err = api.login(auth_ui.fields.email, auth_ui.fields.password)
        if res and res.success then
            gameState = "game"
        else
            auth_ui.message = err or "Login failed"
        end
    else
        local res, err = api.register(auth_ui.fields.email, auth_ui.fields.password, auth_ui.fields.fullName)
        if res and res.success then
            auth_ui.message = "Account created! Please login."
            auth_ui.state = "login"
            auth_ui.fields.password = "" -- Clear password for safety
        else
            auth_ui.message = err or "Registration failed"
        end
    end
    auth_ui.loading = false
end

return auth_ui
