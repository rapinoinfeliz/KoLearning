local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local ButtonDialog = require("ui/widget/buttondialog")
local UIManager = require("ui/uimanager")
local Widget = require("ui/widget/widget")
local logger = require("logger")
local _ = require("al_i18n").t

local AL_API = require("al_api")
local AL_Context = require("al_context")
local AL_Parser = require("al_quiz_parser")
local AL_Prompts = require("al_prompts")
local AL_QuizViewer = require("al_quiz_viewer")
local AL_Settings = require("al_settings")
local AL_HistoryUI = require("al_history_ui")

local AugmentedLearning = Widget:extend{
    name = "augmentedlearning",
    api_key = "your_api_key_here", -- Default to provided Groq key
    model = "groq/llama-3.3-70b-versatile",
}

function AugmentedLearning:init()
    self.ui.menu:registerToMainMenu(self)
    self:onDispatcherRegisterActions()
end

function AugmentedLearning:onDispatcherRegisterActions()
    Dispatcher:registerAction("augmented_learning_menu", {
        category = "none",
        event = "AugmentedLearningMenu",
        title = _("Augmented Learning: Abrir Menu"),
        general = true,
    })
end



function AugmentedLearning:generatePreQuestions(text, custom_meta)
    if not text or text == "" then
        UIManager:show(InfoMessage:new{ text = _("Nenhum texto selecionado/extraído."), timeout = 2 })
        return
    end

    local AL_History = require("al_history")
    local hash = AL_Context.hashText(text)
    local target_id = "preq_" .. hash
    local existing = AL_History.loadProgress(target_id)

    local function executePreqGeneration(final_id)
        logger.info("AL: Enviando texto para IA (Pré-questões): " .. string.sub(text, 1, 100))
        local info = InfoMessage:new{ text = _("Gerando Pré-questões...") }
        UIManager:show(info)
        UIManager:forceRePaint()

        local active_model = AL_Settings.getActiveModel()
        local config = AL_Settings.getQuizConfig()
        local meta = AL_Context.getContextMetadata(self.ui)
        if custom_meta and custom_meta.chapter_title then
            meta.chapter_title = custom_meta.chapter_title
        end
        meta.type = _("Pré-questões")
        meta.timestamp = os.time()

        AL_API.request(active_model.api_key, active_model.model, AL_Prompts.getPreQuestionsSystemPrompt(config), text, 
            function(response_text)
                UIManager:close(info)
                local data, err = AL_Parser.parsePreQuestions(response_text)
                if data then
                    local opts = { 
                        title = _("Pré-questões") .. ": " .. meta.chapter_title,
                        on_save_state = function(state)
                            AL_History.saveProgress(final_id, meta, data, state)
                        end,
                        on_close = function()
                            self:onAugmentedLearningMenu()
                        end
                    }
                    UIManager:show(AL_QuizViewer:new{ quiz_data = data, opts = opts })
                else
                    UIManager:show(InfoMessage:new{ text = _("Erro de parser: ") .. tostring(err), timeout = 3 })
                end
            end,
            function(err)
                UIManager:close(info)
                UIManager:show(InfoMessage:new{ text = _("Erro na API: ") .. tostring(err), timeout = 4 })
            end
        )
    end

    if existing then
        local ConfirmBox = require("ui/widget/confirmbox")
        UIManager:show(ConfirmBox:new{
            text = _("Já existem pré-questões para este trecho.\nO que deseja fazer?"),
            ok_text = _("Substituir"),
            cancel_text = _("Manter Ambos"),
            ok_callback = function()
                executePreqGeneration(target_id)
            end,
            cancel_callback = function()
                executePreqGeneration(target_id .. "_" .. os.time())
            end,
        })
    else
        executePreqGeneration(target_id)
    end
end

function AugmentedLearning:onAugmentedLearningQuiz(text, custom_meta)
    if not text or text == "" then
        UIManager:show(InfoMessage:new{ text = _("Operação cancelada ou sem texto."), timeout = 2 })
        return
    end

    local AL_History = require("al_history")
    local hash = AL_Context.hashText(text)
    local target_id = "quiz_" .. hash
    local existing = AL_History.loadProgress(target_id)

    local function executeQuizGeneration(final_id)
        logger.info("AL: Enviando texto para IA (Quiz): " .. string.sub(text, 1, 100))
        local info = InfoMessage:new{ text = _("Gerando Quiz da Seção...") }
        UIManager:show(info)
        UIManager:forceRePaint()

        local active_model = AL_Settings.getActiveModel()
        local config = AL_Settings.getQuizConfig()
        local meta = AL_Context.getContextMetadata(self.ui)
        if custom_meta and custom_meta.chapter_title then
            meta.chapter_title = custom_meta.chapter_title
        end
        meta.type = _("Quiz")
        meta.timestamp = os.time()

        AL_API.request(active_model.api_key, active_model.model, AL_Prompts.getQuizSystemPrompt(config), text, 
            function(response_text)
                UIManager:close(info)
                local data, err = AL_Parser.parseQuiz(response_text)
                if data then
                    local opts = { 
                        title = _("Quiz") .. ": " .. meta.chapter_title,
                        on_save_state = function(state)
                            AL_History.saveProgress(final_id, meta, data, state)
                        end,
                        on_close = function()
                            self:onAugmentedLearningMenu()
                        end
                    }
                    UIManager:show(AL_QuizViewer:new{ quiz_data = data, opts = opts })
                else
                    UIManager:show(InfoMessage:new{ text = _("Erro de parser: ") .. tostring(err), timeout = 3 })
                end
            end,
            function(err)
                UIManager:close(info)
                UIManager:show(InfoMessage:new{ text = _("Erro na API: ") .. tostring(err), timeout = 4 })
            end
        )
    end

    if existing then
        local ConfirmBox = require("ui/widget/confirmbox")
        UIManager:show(ConfirmBox:new{
            text = _("Já existe um quiz para este trecho.\nO que deseja fazer?"),
            ok_text = _("Substituir"),
            cancel_text = _("Manter Ambos"),
            ok_callback = function()
                executeQuizGeneration(target_id)
            end,
            cancel_callback = function()
                executeQuizGeneration(target_id .. "_" .. os.time())
            end,
        })
    else
        executeQuizGeneration(target_id)
    end
end

function AugmentedLearning:onAugmentedLearningMenu()
    local AL_ContextUI = require("al_context_ui")
    local active_model = AL_Settings.getActiveModel()
    local dialog
    dialog = ButtonDialog:new{
        title = "Augmented Learning",
        title_align = "center",
        buttons = {
            {
                {
                    text = "Quiz",
                    callback = function()
                        UIManager:close(dialog)
                        AL_ContextUI.showExtractorDialog(self.ui, function(text, custom_meta)
                            if text then 
                                self:onAugmentedLearningQuiz(text, custom_meta)
                            else
                                self:onAugmentedLearningMenu()
                            end
                        end)
                    end,
                },
            },
            {
                {
                    text = "Pré-Questões",
                    callback = function()
                        UIManager:close(dialog)
                        AL_ContextUI.showExtractorDialog(self.ui, function(text, custom_meta)
                            if text then 
                                self:generatePreQuestions(text, custom_meta)
                            else
                                self:onAugmentedLearningMenu()
                            end
                        end)
                    end
                }
            },
            {
                {
                    text = _("Modelo: ") .. (active_model.display or "Desconhecido"),
                    callback = function()
                        UIManager:close(dialog)
                        AL_Settings.showModelSelector(function()
                            -- Reabre o menu principal após alterar o modelo
                            self:onAugmentedLearningMenu()
                        end)
                    end,
                },
            },
            {
                {
                    text = _("Arquivo"),
                    callback = function()
                        UIManager:close(dialog)
                        AL_HistoryUI.show(self.ui, function()
                            self:onAugmentedLearningMenu()
                        end)
                    end,
                },
                {
                    text = _("Configurações"),
                    callback = function()
                        UIManager:close(dialog)
                        AL_Settings.showQuizConfig(function()
                            self:onAugmentedLearningMenu()
                        end)
                    end,
                },
            },
        },
        title = "Augmented Learning",
        title_align = "center",
    }
    UIManager:show(dialog)
end

return AugmentedLearning
