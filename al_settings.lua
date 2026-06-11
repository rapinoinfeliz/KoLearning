local ButtonDialog = require("ui/widget/buttondialog")
local UIManager = require("ui/uimanager")

local AL_Settings = {}
local _ = require("al_i18n").t

local plugin_dir = require("libs/libkoreader-lfs").currentdir() .. "/plugins/augmentedlearning.koplugin"
local creds_file = plugin_dir .. "/al_credentials.lua"

local DEFAULT_MODELS = {
    { display = "Groq Llama 3 70B", api_key = "your_api_key_here" },
    { display = "OpenRouter owl-alpha", api_key = "your_api_key_here" },
}

function AL_Settings.loadModels()
    local saved_data = nil
    local f = io.open(creds_file, "r")
    if f then
        local content = f:read("*all")
        f:close()
        if content and content ~= "" then
            local chunk = loadstring(content)
            if chunk then saved_data = chunk() end
        end
    end
    
    local saved_models = saved_data and saved_data.models
    local active_idx = saved_data and saved_data.active_idx
    
    if type(saved_models) ~= "table" or #saved_models == 0 then
        saved_models = DEFAULT_MODELS
    end
    
    if type(active_idx) ~= "number" or active_idx < 1 or active_idx > #saved_models then
        active_idx = 1
    end
    
    return saved_models, active_idx
end

function AL_Settings.saveActiveIndex(models, active_idx)
    local saved_data = nil
    local f = io.open(creds_file, "r")
    if f then
        local content = f:read("*all")
        f:close()
        if content and content ~= "" then
            local chunk = loadstring(content)
            if chunk then saved_data = chunk() end
        end
    end
    saved_data = saved_data or {}
    saved_data.models = models
    saved_data.active_idx = active_idx

    f = io.open(creds_file, "w")
    if f then
        f:write("return {\n")
        f:write("  active_idx = " .. tostring(saved_data.active_idx) .. ",\n")
        f:write("  models = {\n")
        for _, m in ipairs(saved_data.models) do
            f:write(string.format('    { display = %q, api_key = %q, model = %q },\n', m.display or "", m.api_key or "", m.model or ""))
        end
        f:write("  },\n")
        if saved_data.quiz_config then
            local qc = saved_data.quiz_config
            f:write("  quiz_config = {\n")
            f:write(string.format('    quiz_type = %q,\n', qc.quiz_type or ""))
            f:write(string.format('    quiz_amount = %d,\n', qc.quiz_amount or 5))
            f:write(string.format('    quiz_difficulty = %q,\n', qc.quiz_difficulty or ""))
            f:write("  }\n")
        end
        f:write("}\n")
        f:close()
    end
end

function AL_Settings.getActiveModel()
    local models, idx = AL_Settings.loadModels()
    return models[idx]
end

function AL_Settings.showModelSelector(on_change)
    local models, active_idx = AL_Settings.loadModels()
    local buttons = {}
    local dialog
    
    for i, m in ipairs(models) do
        local prefix = (i == active_idx) and "[✓] " or "    "
        table.insert(buttons, {
            {
                text = prefix .. m.display,
                callback = function()
                    AL_Settings.saveActiveIndex(models, i)
                    UIManager:close(dialog)
                    if on_change then on_change() end
                end
            }
        })
    end
    
    table.insert(buttons, {
        {
            text = _("Voltar"),
            callback = function()
                UIManager:close(dialog)
                if on_change then on_change() end
            end
        }
    })

    dialog = ButtonDialog:new{
        title = _("Modelos / API"),
        title_align = "center",
        buttons = buttons,
    }
    UIManager:show(dialog)
end

local DEFAULT_QUIZ_CONFIG = {
    quiz_type = "Múltipla Escolha",
    quiz_amount = 5,
    quiz_difficulty = "Média",
}

function AL_Settings.getQuizConfig()
    local saved_data = nil
    local f = io.open(creds_file, "r")
    if f then
        local content = f:read("*all")
        f:close()
        if content and content ~= "" then
            local chunk = loadstring(content)
            if chunk then saved_data = chunk() end
        end
    end
    
    local config = saved_data and saved_data.quiz_config or {}
    
    config.quiz_amount = config.quiz_amount or 5
    
    -- Migrate from string to table if necessary, or set defaults
    if type(config.quiz_types) ~= "table" then
        config.quiz_types = { ["Múltipla Escolha"] = true, ["Verdadeiro/Falso"] = false, ["Discursiva"] = false }
        if type(config.quiz_type) == "string" then
            if config.quiz_type == "Misto" then
                config.quiz_types["Discursiva"] = true
            elseif config.quiz_types[config.quiz_type] ~= nil then
                for k, _ in pairs(config.quiz_types) do config.quiz_types[k] = false end
                config.quiz_types[config.quiz_type] = true
            end
        end
    end
    
    if type(config.quiz_difficulties) ~= "table" then
        config.quiz_difficulties = { ["Fácil"] = false, ["Média"] = true, ["Difícil"] = false }
        if type(config.quiz_difficulty) == "string" and config.quiz_difficulties[config.quiz_difficulty] ~= nil then
            for k, _ in pairs(config.quiz_difficulties) do config.quiz_difficulties[k] = false end
            config.quiz_difficulties[config.quiz_difficulty] = true
        end
    end
    
    return config
end

function AL_Settings.saveQuizConfig(config)
    local saved_data = nil
    local f = io.open(creds_file, "r")
    if f then
        local content = f:read("*all")
        f:close()
        if content and content ~= "" then
            local chunk = loadstring(content)
            if chunk then saved_data = chunk() end
        end
    end
    saved_data = saved_data or {}
    saved_data.quiz_config = config
    saved_data.models = saved_data.models or DEFAULT_MODELS
    saved_data.active_idx = saved_data.active_idx or 1

    f = io.open(creds_file, "w")
    if f then
        f:write("return {\n")
        f:write("  active_idx = " .. tostring(saved_data.active_idx) .. ",\n")
        f:write("  models = {\n")
        for _, m in ipairs(saved_data.models) do
            f:write(string.format('    { display = %q, api_key = %q, model = %q },\n', m.display or "", m.api_key or "", m.model or ""))
        end
        f:write("  },\n")
        f:write("  quiz_config = {\n")
        f:write(string.format('    quiz_amount = %d,\n', config.quiz_amount or 5))
        f:write("    quiz_types = {\n")
        for k, v in pairs(config.quiz_types or {}) do
            f:write(string.format('      [%q] = %s,\n', k, tostring(v)))
        end
        f:write("    },\n")
        f:write("    quiz_difficulties = {\n")
        for k, v in pairs(config.quiz_difficulties or {}) do
            f:write(string.format('      [%q] = %s,\n', k, tostring(v)))
        end
        f:write("    },\n")
        f:write("  }\n")
        f:write("}\n")
        f:close()
    end
end

function AL_Settings.showQuizConfig(on_change)
    local config = AL_Settings.getQuizConfig()
    
    local types_order = {"Múltipla Escolha", "Verdadeiro/Falso", "Discursiva"}
    local diffs_order = {"Fácil", "Média", "Difícil"}
    
    local dialog
    local function refreshDialog()
        local type_buttons = {}
        for _, t in ipairs(types_order) do
            table.insert(type_buttons, {
                text = (config.quiz_types[t] and "✓ " or "") .. _(t),
                callback = function()
                    config.quiz_types[t] = not config.quiz_types[t]
                    local any = false
                    for _, v in pairs(config.quiz_types) do if v then any = true break end end
                    if not any then config.quiz_types[t] = true end
                    UIManager:close(dialog)
                    refreshDialog()
                end
            })
        end

        local diff_buttons = {}
        for _, d in ipairs(diffs_order) do
            table.insert(diff_buttons, {
                text = (config.quiz_difficulties[d] and "✓ " or "") .. _(d),
                callback = function()
                    config.quiz_difficulties[d] = not config.quiz_difficulties[d]
                    local any = false
                    for _, v in pairs(config.quiz_difficulties) do if v then any = true break end end
                    if not any then config.quiz_difficulties[d] = true end
                    UIManager:close(dialog)
                    refreshDialog()
                end
            })
        end

        local buttons = {
            {
                {
                    text = "-",
                    callback = function()
                        if config.quiz_amount > 1 then config.quiz_amount = config.quiz_amount - 1 end
                        UIManager:close(dialog)
                        refreshDialog()
                    end
                },
                { text = _("Quantidade") .. ": " .. config.quiz_amount, callback = function() end },
                {
                    text = "+",
                    callback = function()
                        if config.quiz_amount < 30 then config.quiz_amount = config.quiz_amount + 1 end
                        UIManager:close(dialog)
                        refreshDialog()
                    end
                }
            },
            type_buttons,
            diff_buttons,
            {
                {
                    text = _("Voltar"),
                    font_bold = true,
                    callback = function()
                        AL_Settings.saveQuizConfig(config)
                        UIManager:close(dialog)
                        if on_change then on_change() end
                    end
                }
            }
        }
        dialog = ButtonDialog:new{
            title = _("Configurações"),
            title_align = "center",
            buttons = buttons,
        }
        UIManager:show(dialog)
    end
    
    refreshDialog()
end

return AL_Settings
