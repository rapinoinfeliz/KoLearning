local http = require("socket.http")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("json")
local logger = require("logger")
local socket = require("socket")

local AL_API = {}

--- Faz uma requisição assíncrona ou síncrona (com timeout) para a API (OpenAI/Groq compatible)
--- @param api_key string
--- @param model string
--- @param system_prompt string
--- @param user_prompt string
--- @param on_success function
--- @param on_error function
function AL_API.request(api_key, model, system_prompt, user_prompt, on_success, on_error)
    if not api_key or api_key == "" then
        if on_error then on_error("API key is missing.") end
        return
    end

    local endpoint = "https://api.groq.com/openai/v1/chat/completions"
    if api_key:match("^sk%-or%-") then
        endpoint = "https://openrouter.ai/api/v1/chat/completions"
    elseif api_key:match("^sk%-") then
        endpoint = "https://api.openai.com/v1/chat/completions"
    end

    local payload = {
        model = model,
        messages = {
            { role = "system", content = system_prompt },
            { role = "user", content = user_prompt }
        },
        temperature = 0.3
    }
    
    local body = json.encode(payload)
    local response_body = {}

    local req = {
        url = endpoint,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. api_key,
            ["Content-Length"] = tostring(#body)
        },
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(response_body),
    }

    logger.dbg("AL_API: Sending request to " .. endpoint)
    
    -- Utilizando luasec HTTPS
    local res, code, headers, status = https.request(req)

    if code == 200 then
        local res_str = table.concat(response_body)
        local ok, data = pcall(json.decode, res_str)
        if ok and data and data.choices and data.choices[1] and data.choices[1].message then
            local text = data.choices[1].message.content
            if on_success then on_success(text) end
        else
            if on_error then on_error("Failed to parse JSON response: " .. tostring(res_str)) end
        end
    else
        local err_msg = "HTTP Error " .. tostring(code) .. ": " .. tostring(status)
        local res_str = table.concat(response_body)
        if res_str and res_str ~= "" then
            err_msg = err_msg .. "\n" .. res_str
        end
        if on_error then on_error(err_msg) end
    end
end

return AL_API
