local lfs = require("libs/libkoreader-lfs")
local DataStorage = require("datastorage")
local json = require("json")

local AL_History = {}

function AL_History.getHistoryDir()
    local dir = DataStorage:getDataDir() .. "/augmentedlearning_history"
    lfs.mkdir(dir)
    return dir
end

-- metadata: { title="book title", chapter="chap", timestamp=time(), ... }
-- quiz_data: the JSON output from AI
-- state: { answers={}, correct={}, revealed={}, current_index=1, phase="taking" }
function AL_History.saveProgress(id, metadata, quiz_data, state)
    local dir = AL_History.getHistoryDir()
    local filename = id:gsub("[/\\:*?\"<>|]", "_") .. ".json"
    local filepath = dir .. "/" .. filename

    local data = {
        id = id,
        metadata = metadata,
        quiz_data = quiz_data,
        state = state
    }

    local file = io.open(filepath, "w")
    if file then
        file:write(json.encode(data))
        file:close()
        return true
    end
    return false
end

function AL_History.loadProgress(id)
    local dir = AL_History.getHistoryDir()
    local filename = id:gsub("[/\\:*?\"<>|]", "_") .. ".json"
    local filepath = dir .. "/" .. filename

    local file = io.open(filepath, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local ok, data = pcall(json.decode, content)
        if ok then return data end
    end
    return nil
end

function AL_History.deleteProgress(id)
    local dir = AL_History.getHistoryDir()
    local filename = id:gsub("[/\\:*?\"<>|]", "_") .. ".json"
    local filepath = dir .. "/" .. filename
    os.remove(filepath)
end

function AL_History.listHistory()
    local dir = AL_History.getHistoryDir()
    local list = {}
    
    for file in lfs.dir(dir) do
        if file:match("%.json$") then
            local filepath = dir .. "/" .. file
            local f = io.open(filepath, "r")
            if f then
                local content = f:read("*all")
                f:close()
                local ok, data = pcall(json.decode, content)
                if ok and data and data.id then
                    table.insert(list, data)
                end
            end
        end
    end
    
    -- Sort by newest first
    table.sort(list, function(a, b)
        local ta = (a.metadata and a.metadata.timestamp) or 0
        local tb = (b.metadata and b.metadata.timestamp) or 0
        return ta > tb
    end)
    
    return list
end

return AL_History
