local logger = require("logger")

local AL_Context = {}

--- Obtém o texto do highlight selecionado
function AL_Context.getHighlightText(highlight)
    if highlight and highlight.text then
        return highlight.text
    end
    return ""
end

--- Auxiliar para extrair texto de XPointers (EPUB)
local function extractVisibleTextEPUB(document, start_page, end_page)
    local total_pages = document.info and document.info.number_of_pages or 0
    if total_pages == 0 then return "" end

    local start_xp = document:getPageXPointer(math.max(1, start_page))
    local end_xp = document:getPageXPointer(math.min(end_page + 1, total_pages))
    
    if start_xp and end_xp then
        return document:getTextFromXPointers(start_xp, end_xp) or ""
    end
    return ""
end

--- Auxiliar para extrair texto de Páginas (PDF)
local function extractVisibleTextPDF(document, start_page, end_page)
    local pages = {}
    for page = start_page, end_page do
        local page_text = document:getPageText(page) or ""
        if type(page_text) == "table" then
            local words = {}
            for _, block in ipairs(page_text) do
                if type(block) == "table" then
                    for i = 1, #block do
                        local span = block[i]
                        if type(span) == "table" and span.word then
                            table.insert(words, span.word)
                        end
                    end
                end
            end
            page_text = table.concat(words, " ")
        end
        table.insert(pages, page_text)
    end
    return table.concat(pages, "\n")
end

--- Extrai texto com base em um range de páginas
function AL_Context.getPageRangeText(ui, start_page, end_page)
    if not ui or not ui.document then return "" end
    local doc = ui.document
    local total_pages = doc.info and doc.info.number_of_pages or 0
    if total_pages == 0 then return "" end

    start_page = math.max(1, start_page)
    end_page = math.min(total_pages, end_page)

    local success, text = pcall(function()
        if not doc.info.has_pages then
            return extractVisibleTextEPUB(doc, start_page, end_page)
        else
            return extractVisibleTextPDF(doc, start_page, end_page)
        end
    end)

    if success then
        return text
    else
        logger.warn("AL_Context: Failed to extract text range:", text)
        return ""
    end
end

--- Extrai desde o início até a página atual (simulando "Capítulo Atual" ou "Até o momento")
function AL_Context.getTextUntilCurrent(ui, max_chars)
    if not ui or not ui.document then return "" end
    max_chars = max_chars or 100000 -- limite seguro de caracteres
    
    local current_page = (ui.view and ui.view.cpage) or (ui.view and ui.view.state and ui.view.state.page) or 1
    local text = AL_Context.getPageRangeText(ui, 1, current_page)
    
    if #text > max_chars then
        text = text:sub(-max_chars)
    end
    
    return text
end

--- Obtém metadados do contexto atual (título do livro, capítulo)
function AL_Context.getContextMetadata(ui)
    local meta = {
        book_title = "Livro Desconhecido",
        chapter_title = "Seção/Capítulo Atual"
    }
    if not ui or not ui.document then return meta end
    if ui.doc_props and ui.doc_props.title then
        meta.book_title = ui.doc_props.title
    elseif ui.document.info and ui.document.info.title then
        meta.book_title = ui.document.info.title
    end
    if ui.doc_props and ui.doc_props.authors then
        meta.book_author = ui.doc_props.authors
    elseif ui.document.info and ui.document.info.authors then
        meta.book_author = ui.document.info.authors
    end
    
    local current_page = (ui.view and ui.view.cpage) or (ui.view and ui.view.state and ui.view.state.page) or 1
    local toc = ui.toc and ui.toc.toc
    if toc and #toc > 0 then
        local best_match = nil
        local start_page = current_page
        local end_page = ui.document.info.number_of_pages or current_page
        
        for i, entry in ipairs(toc) do
            if current_page >= entry.page then
                best_match = entry.text
                start_page = entry.page
                local next_entry = toc[i+1]
                if next_entry then
                    end_page = next_entry.page - 1
                else
                    end_page = ui.document.info.number_of_pages or current_page
                end
            else
                break
            end
        end
        if best_match then 
            meta.chapter_title = best_match 
            meta.page_range = "p." .. start_page .. "-p." .. end_page
        else
            meta.page_range = "p." .. current_page
        end
    else
        meta.page_range = "p." .. current_page
    end
    return meta
end

--- Gera um pseudo-hash baseado no texto
function AL_Context.hashText(text)
    if not text then return "0_empty" end
    local len = #text
    local preview = text:sub(1, 100):gsub("%W", ""):sub(1, 40)
    return tostring(len) .. "_" .. preview
end

return AL_Context
