local ButtonDialog = require("ui/widget/buttondialog")
local UIManager = require("ui/uimanager")
local AL_Context = require("al_context")
local InfoMessage = require("ui/widget/infomessage")

local AL_ContextUI = {}
local _ = require("al_i18n").t

--- Mostra o seletor de capítulos (TOC)
local function showTocPicker(ui, callback)
    local toc = ui.toc and ui.toc.toc
    if not toc or #toc == 0 then
        UIManager:show(InfoMessage:new{ text = _("O livro não possui sumário."), timeout = 2 })
        return
    end

    local total_pages = ui.document.info.number_of_pages or 1
    local buttons = {}
    
    for i, entry in ipairs(toc) do
        local start_page = entry.page
        local end_page = total_pages
        -- Procura o fim do capítulo atual (o próximo capítulo na mesma hierarquia)
        for j = i + 1, #toc do
            if (toc[j].depth or 1) <= (entry.depth or 1) and toc[j].page then
                end_page = toc[j].page - 1
                break
            end
        end
        if end_page < start_page then end_page = start_page end
        
        local indent = string.rep("  ", (entry.depth or 1) - 1)
        table.insert(buttons, {
            {
                text = indent .. (entry.title or entry.text or (_("Página ") .. start_page)),
                callback = function()
                    if AL_ContextUI._toc_dialog then
                        UIManager:close(AL_ContextUI._toc_dialog)
                    end
                    local text = AL_Context.getPageRangeText(ui, start_page, end_page)
                    local chapter_name = entry.title or entry.text or _("Capítulo")
                    local final_title = string.format("%s (p.%d-p.%d)", chapter_name, start_page, end_page)
                    callback(text, { chapter_title = final_title })
                end
            }
        })
    end
    
    -- Botão voltar no final
    table.insert(buttons, {
        {
            text = "Voltar",
            font_bold = true,
            callback = function()
                if AL_ContextUI._toc_dialog then
                    UIManager:close(AL_ContextUI._toc_dialog)
                end
                callback(nil)
            end
        }
    })
    
    AL_ContextUI._toc_dialog = ButtonDialog:new{
        title = _("Selecionar Capítulo"),
        title_align = "center",
        buttons = buttons,
    }
    UIManager:show(AL_ContextUI._toc_dialog)
end

AL_ContextUI.page_delta = AL_ContextUI.page_delta or 5

function AL_ContextUI.showExtractorDialog(ui, callback)
    local dialog
    local current_page = (ui.view and ui.view.cpage) or (ui.view and ui.view.state and ui.view.state.page) or 1

    local function refreshExtractor()
        local buttons = {
            {
                {
                    text = _("Capítulo Atual"),
                    callback = function()
                        UIManager:close(dialog)
                        local toc = ui.toc and ui.toc.toc
                        local start_page = current_page
                        local total_pages = ui.document.info.number_of_pages or 1
                        local end_page = total_pages
                        local chapter_title = _("Capítulo Atual")
                        if toc and #toc > 0 then
                            for i, entry in ipairs(toc) do
                                local next_entry = toc[i+1]
                                local cp = entry.page
                                local np = next_entry and next_entry.page or (total_pages + 1)
                                if current_page >= cp and current_page < np then
                                    start_page = cp
                                    end_page = np - 1
                                    chapter_title = entry.title or entry.text or chapter_title
                                    break
                                end
                            end
                        end
                        if end_page < start_page then end_page = start_page end
                        local final_title = string.format("%s (p.%d-p.%d)", chapter_title, start_page, end_page)
                        callback(AL_Context.getPageRangeText(ui, start_page, end_page), { chapter_title = final_title })
                    end
                },
                {
                    text = _("Selecionar Capítulo"),
                    callback = function()
                        UIManager:close(dialog)
                        showTocPicker(ui, callback)
                    end
                }
            },
            {
                {
                    text = "-" .. AL_ContextUI.page_delta,
                    callback = function()
                        UIManager:close(dialog)
                        local start_page = math.max(1, current_page - AL_ContextUI.page_delta)
                        local title = string.format("p.%d-p.%d", start_page, current_page)
                        callback(AL_Context.getPageRangeText(ui, start_page, current_page), { chapter_title = title })
                    end,
                    hold_callback = function()
                        UIManager:close(dialog)
                        local d
                        local function showDeltaPicker()
                            if d then UIManager:close(d) end
                            d = require("ui/widget/buttondialog"):new{
                                title = "Quantidade de Páginas: " .. AL_ContextUI.page_delta,
                                buttons = {
                                    {
                                        {
                                            text = "-1",
                                            callback = function()
                                                if AL_ContextUI.page_delta > 1 then
                                                    AL_ContextUI.page_delta = AL_ContextUI.page_delta - 1
                                                end
                                                showDeltaPicker()
                                            end
                                        },
                                        {
                                            text = "+1",
                                            callback = function()
                                                AL_ContextUI.page_delta = AL_ContextUI.page_delta + 1
                                                showDeltaPicker()
                                            end
                                        }
                                    },
                                    {
                                        {
                                            text = "OK",
                                            font_bold = true,
                                            is_enter_default = true,
                                            callback = function()
                                                if d then UIManager:close(d) end
                                                refreshExtractor()
                                            end
                                        }
                                    }
                                }
                            }
                            UIManager:show(d)
                        end
                        showDeltaPicker()
                    end
                },
                {
                    text = _("Página Atual"),
                    callback = function()
                        UIManager:close(dialog)
                        callback(AL_Context.getPageRangeText(ui, current_page, current_page), { chapter_title = "p." .. current_page })
                    end
                },
                {
                    text = "+" .. AL_ContextUI.page_delta,
                    callback = function()
                        UIManager:close(dialog)
                        local total_pages = ui.document.info.number_of_pages or 1
                        local end_page = math.min(total_pages, current_page + AL_ContextUI.page_delta)
                        local title = string.format("p.%d-p.%d", current_page, end_page)
                        callback(AL_Context.getPageRangeText(ui, current_page, end_page), { chapter_title = title })
                    end,
                    hold_callback = function()
                        UIManager:close(dialog)
                        local d
                        local function showDeltaPicker()
                            if d then UIManager:close(d) end
                            d = require("ui/widget/buttondialog"):new{
                                title = "Quantidade de Páginas: " .. AL_ContextUI.page_delta,
                                buttons = {
                                    {
                                        {
                                            text = "-1",
                                            callback = function()
                                                if AL_ContextUI.page_delta > 1 then
                                                    AL_ContextUI.page_delta = AL_ContextUI.page_delta - 1
                                                end
                                                showDeltaPicker()
                                            end
                                        },
                                        {
                                            text = "+1",
                                            callback = function()
                                                AL_ContextUI.page_delta = AL_ContextUI.page_delta + 1
                                                showDeltaPicker()
                                            end
                                        }
                                    },
                                    {
                                        {
                                            text = "OK",
                                            font_bold = true,
                                            is_enter_default = true,
                                            callback = function()
                                                if d then UIManager:close(d) end
                                                refreshExtractor()
                                            end
                                        }
                                    }
                                }
                            }
                            UIManager:show(d)
                        end
                        showDeltaPicker()
                    end
                }
            },
            {
                {
                    text = "Voltar",
                    id = "close",
                    callback = function()
                        UIManager:close(dialog)
                        callback(nil)
                    end
                }
            }
        }

        dialog = ButtonDialog:new{
            title = _("Extrair Texto"),
            title_align = "center",
            buttons = buttons,
        }
        UIManager:show(dialog)
    end

    refreshExtractor()
end

return AL_ContextUI
