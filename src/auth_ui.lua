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

function auth_ui.draw()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(auth_ui.state == "login" and "Login" or "Register", 0, 100, 800, "center", 0, 2)
    
    local y = 200
    local fields = auth_ui.state == "login" and {"email", "password"} or {"email", "password", "fullName"}
    
    for _, field in ipairs(fields) do
        local label = field:gsub("^%l", string.upper)
        love.graphics.print(label .. ":", 250, y)
        
        -- Draw input box
        love.graphics.rectangle("line", 250, y + 25, 300, 30)
        
        -- Mask password
        local displayVal = auth_ui.fields[field]
        if field == "password" then
            displayVal = string.rep("*", #displayVal)
        end
        
        love.graphics.print(displayVal, 260, y + 32)
        
        -- Cursor
        if auth_ui.activeField == field and not auth_ui.loading then
            if math.floor(love.timer.getTime() * 2) % 2 == 0 then
                local tw = love.graphics.getFont():getWidth(displayVal)
                love.graphics.line(260 + tw, y + 30, 260 + tw, y + 50)
            end
        end
        
        y = y + 80
    end
    
    -- Buttons
    love.graphics.setColor(0.2, 0.6, 0.2)
    love.graphics.rectangle("fill", 250, y, 300, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(auth_ui.loading and "Loading..." or (auth_ui.state == "login" and "LOGIN" or "REGISTER"), 250, y + 10, 300, "center")
    
    -- Switch link
    love.graphics.printf(auth_ui.state == "login" and "No account? Register here" or "Have account? Login here", 0, y + 60, 800, "center")
    
    -- Message
    if auth_ui.message ~= "" then
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.printf(auth_ui.message, 0, y + 100, 800, "center")
    end
end

function auth_ui.keypressed(key)
    if auth_ui.loading then return end

    if key == "tab" then
        local fields = auth_ui.state == "login" and {"email", "password"} or {"email", "password", "fullName"}
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
    auth_ui.fields[auth_ui.activeField] = auth_ui.fields[auth_ui.activeField] .. t
end

function auth_ui.mousepressed(x, y, button)
    if button ~= 1 or auth_ui.loading then return end
    
    -- Check switch link
    if y > 450 and y < 550 then
        auth_ui.state = auth_ui.state == "login" and "register" or "login"
        auth_ui.message = ""
    end
    
    -- Check button
    if x > 250 and x < 550 and y > 400 and y < 440 then
        auth_ui.submit()
    end
end

function auth_ui.submit()
    auth_ui.loading = true
    auth_ui.message = "Contacting server..."
    
    if auth_ui.state == "login" then
        local res, err = api.login(auth_ui.fields.email, auth_ui.fields.password)
        if res and res.success then
            auth_ui.message = "Login successful!"
            -- We can signal main.lua to start game
            gameState = "game"
        else
            auth_ui.message = err or "Login failed"
        end
    else
        local res, err = api.register(auth_ui.fields.email, auth_ui.fields.password, auth_ui.fields.fullName)
        if res and res.success then
            auth_ui.message = "Registered! Please login."
            auth_ui.state = "login"
        else
            auth_ui.message = err or "Registration failed"
        end
    end
    auth_ui.loading = false
end

return auth_ui
