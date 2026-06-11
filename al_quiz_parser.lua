local json = require("json")
local logger = require("logger")

local AL_Parser = {}

local function shuffleMultipleChoice(q)
    if q.type ~= "multiple_choice" or type(q.options) ~= "table" then return end
    
    local correct_text = q.options[q.correct]
    if not correct_text then return end
    
    local vals = {}
    for _, v in pairs(q.options) do
        table.insert(vals, v)
    end
    
    -- Fisher-Yates shuffle
    for i = #vals, 2, -1 do
        local j = math.random(1, i)
        vals[i], vals[j] = vals[j], vals[i]
    end
    
    local letters = {"A", "B", "C", "D", "E", "F", "G", "H"}
    local new_options = {}
    local new_correct = "A"
    
    for i, v in ipairs(vals) do
        local letter = letters[i]
        if not letter then break end
        new_options[letter] = v
        if v == correct_text then
            new_correct = letter
        end
    end
    
    q.options = new_options
    q.correct = new_correct
end

--- Tenta extrair JSON de code blocks (```json ... ```) se necessário
local function extractJSON(text)
    local s, e = text:find("```json%s*\n(.*)\n```")
    if s then return text:sub(s+7, e-3) end
    s, e = text:find("```%s*\n(.*)\n```")
    if s then return text:sub(s+3, e-3) end
    
    -- Extrair do primeiro { até o último }
    local first = text:find("{")
    local last = nil
    for i = #text, 1, -1 do
        if text:byte(i) == 125 then last = i; break end
    end
    if first and last and last > first then
        return text:sub(first, last)
    end
    
    -- Extrair do primeiro [ até o último ] (para array de pre-questões)
    first = text:find("%[")
    last = nil
    for i = #text, 1, -1 do
        if text:byte(i) == 93 then last = i; break end
    end
    if first and last and last > first then
        return text:sub(first, last)
    end
    
    return text
end

--- Faz o parse do Quiz pós-leitura
function AL_Parser.parseQuiz(text)
    local raw = extractJSON(text)
    local ok, data = pcall(json.decode, raw)
    if ok and data and type(data.questions) == "table" then
        for _, q in ipairs(data.questions) do
            shuffleMultipleChoice(q)
        end
        return data, nil
    end
    return nil, "Failed to parse quiz JSON: " .. tostring(data)
end

function AL_Parser.parsePreQuestions(text)
    local raw = extractJSON(text)
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == "table" and #data > 0 then
        local quiz_data = { questions = {} }
        for _, item in ipairs(data) do
            if type(item) == "table" and item.question then
                table.insert(quiz_data.questions, {
                    type = "essay",
                    question = item.question,
                    key_points = type(item.key_points) == "table" and item.key_points or {"Apenas reflita sobre esta pergunta durante a leitura do texto."},
                })
            elseif type(item) == "string" then
                table.insert(quiz_data.questions, {
                    type = "essay",
                    question = item,
                    key_points = {"Apenas reflita sobre esta pergunta durante a leitura do texto."},
                })
            end
        end
        return quiz_data, nil
    end
    return nil, "Failed to parse pre-questions JSON array."
end

return AL_Parser
