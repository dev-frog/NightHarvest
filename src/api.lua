local json = require("lib.json")
local api = {}

-- Updated to your local server
api.baseUrl = "http://localhost:3000" 
api.accessToken = nil
api.refreshToken = nil
api.user = nil

local function request(method, path, data)
    local url = api.baseUrl .. path
    local body = data and json.encode(data) or ""
    
    local headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = tostring(#body)
    }
    if api.accessToken then
        headers["Authorization"] = "Bearer " .. api.accessToken
    end

    -- 1. Try lib.https (for HTTPS)
    local ok_https, https = pcall(require, "lib.https")
    if ok_https and https.request then
        local res_body, code, res_headers, status = https.request(url, {
            method = method,
            headers = headers,
            data = body
        })
        if res_body then
            local success, decoded = pcall(json.decode, res_body)
            if success then return decoded, code end
        end
    end

    -- 2. Try socket.http (Works for http://localhost)
    local ok_socket, http = pcall(require, "socket.http")
    local ltn12 = require("ltn12")
    if ok_socket then
        local response_body = {}
        local res, code, response_headers, status = http.request({
            url = url,
            method = method,
            headers = headers,
            source = ltn12.source.string(body),
            sink = ltn12.sink.table(response_body)
        })
        
        local full_body = table.concat(response_body)
        if full_body and #full_body > 0 then
            local success, decoded = pcall(json.decode, full_body)
            if success then return decoded, code end
        end
        return nil, code or "Error"
    end

    print("⚠️ No HTTP/HTTPS library found (lib.https or socket.http)")
    return nil, "No Network Library"
end

function api.register(email, password, fullName)
    local data = {
        email = email,
        password = password,
        fullName = fullName,
        hasAgreedToTerms = true
    }
    return request("POST", "/api/auth/register", data)
end

function api.login(email, password)
    local data = {
        email = email,
        password = password
    }
    local res, err = request("POST", "/api/auth/login", data)
    if res and res.success and res.data then
        api.accessToken = res.data.accessToken
        api.refreshToken = res.data.refreshToken
        api.user = res.data.user
    end
    return res, err
end

return api
