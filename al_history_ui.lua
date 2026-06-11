local ButtonDialog = require("ui/widget/buttondialog")
local UIManager = require("ui/uimanager")
local ConfirmBox = require("ui/widget/confirmbox")
local InfoMessage = require("ui/widget/infomessage")
local AL_History = require("al_history")
local AL_QuizViewer = require("al_quiz_viewer")

local AL_HistoryUI = {}
local _ = require("al_i18n").t

function AL_HistoryUI.show(ui, on_close)
    local history_list = AL_History.listHistory()
    local books = {}
    local book_list = {}
    
    for idx, item in ipairs(history_list) do
        local meta = item.metadata or {}
        local book_title = meta.book_title and meta.book_title ~= _("Desconhecido") and meta.book_title or _("Outros/Sem Título")
        if not books[book_title] then
            books[book_title] = {}
            table.insert(book_list, book_title)
        end
        table.insert(books[book_title], item)
    end
    
    local buttons = {}
    local dialog
    
    if #book_list == 0 then
        table.insert(buttons, { { text = _("Nenhum histórico encontrado."), enabled = false } })
    else
        for idx, book_title in ipairs(book_list) do
            local count = #books[book_title]
            table.insert(buttons, {
                {
                    text = book_title .. " (" .. count .. _(" itens)"),
                    callback = function()
                        UIManager:close(dialog)
                        AL_HistoryUI.showBookItems(ui, book_title, books[book_title], on_close)
                    end,
                    hold_callback = function()
                        UIManager:close(dialog)
                        UIManager:show(ConfirmBox:new{
                            text = _("Deseja excluir TODOS os ") .. count .. _(" itens de '") .. book_title .. _("'?"),
                            ok_callback = function()
                                for idx, item in ipairs(books[book_title]) do
                                    AL_History.deleteProgress(item.id)
                                end
                                UIManager:show(InfoMessage:new{ text = count .. _(" itens excluídos"), timeout = 2 })
                                AL_HistoryUI.show(ui, on_close)
                            end,
                            cancel_callback = function()
                                AL_HistoryUI.show(ui, on_close)
                            end
                        })
                    end
                }
            })
        end
    end
    
    table.insert(buttons, {
        {
            text = _("Voltar"),
            font_bold = true,
            callback = function()
                UIManager:close(dialog)
                if on_close then on_close() end
            end
        }
    })
    
    dialog = ButtonDialog:new{
        title = _("Arquivo (Livros)"),
        title_align = "center",
        buttons = buttons,
    }
    UIManager:show(dialog)
end

function AL_HistoryUI.showBookItems(ui, book_title, items, on_close)
    local buttons = {}
    local dialog
    
    for idx, item in ipairs(items) do
        local meta = item.metadata or {}
        local date_str = meta.timestamp and os.date("%d/%m %H:%M", meta.timestamp) or _("Desconhecido")
        local type_str = meta.type or _("Quiz")
        local display_text = type_str
        
        if meta.chapter_title and meta.chapter_title ~= _("Seção/Capítulo Atual") then
            display_text = display_text .. " - " .. meta.chapter_title
        elseif meta.chapter then
            display_text = display_text .. " - " .. meta.chapter
        elseif meta.page_range then
            display_text = display_text .. " - " .. meta.page_range:gsub("[()]", "")
        end
        
        local state_str = ""
        if item.state then
            local answered = 0
            for k, v in pairs(item.state.revealed or {}) do
                if v then answered = answered + 1 end
            end
            local total = #(item.quiz_data.questions or {})
            if item.state.phase == "complete" then
                state_str = _(" (Concluído)")
            else
                state_str = " (" .. answered .. "/" .. total .. ")"
            end
        end
        
        table.insert(buttons, {
            {
                text = date_str .. " - " .. display_text .. state_str,
                callback = function()
                    UIManager:close(dialog)
                    AL_HistoryUI.openQuiz(ui, item, function() AL_HistoryUI.showBookItems(ui, book_title, items, on_close) end)
                end,
                hold_callback = function()
                    UIManager:close(dialog)
                    UIManager:show(ConfirmBox:new{
                        text = _("Deseja excluir este item do histórico?"),
                        ok_callback = function()
                            AL_History.deleteProgress(item.id)
                            UIManager:show(InfoMessage:new{ text = _("Item excluído"), timeout = 2 })
                            AL_HistoryUI.show(ui, on_close)
                        end,
                        cancel_callback = function()
                            AL_HistoryUI.showBookItems(ui, book_title, items, on_close)
                        end
                    })
                end
            }
        })
    end
    
    table.insert(buttons, {
        {
            text = _("Voltar"),
            font_bold = true,
            callback = function()
                UIManager:close(dialog)
                AL_HistoryUI.show(ui, on_close)
            end
        }
    })
    
    dialog = ButtonDialog:new{
        title = _("Arquivo: ") .. book_title,
        title_align = "center",
        buttons = buttons,
    }
    UIManager:show(dialog)
end

function AL_HistoryUI.openQuiz(ui, item, on_close)
    local meta = item.metadata or {}
    local v_title = meta.type or _("Quiz")
    if meta.chapter_title and meta.chapter_title ~= _("Seção/Capítulo Atual") then
        v_title = v_title .. " - " .. meta.chapter_title
    end
    
    local viewer = AL_QuizViewer:new{
        quiz_data = item.quiz_data,
        opts = {
            title = v_title,
            chapter = meta.chapter_title or meta.chapter,
            on_save_state = function(state)
                AL_History.saveProgress(item.id, item.metadata, item.quiz_data, state)
            end,
            on_close = function()
                -- When viewer closes, reopen the history menu
                AL_HistoryUI.show(ui, on_close)
            end
        },
        answers = item.state and item.state.answers,
        revealed = item.state and item.state.revealed,
        correct = item.state and item.state.correct,
        current_index = item.state and item.state.current_index,
        phase = item.state and item.state.phase,
    }
    UIManager:show(viewer)
end

return AL_HistoryUI
