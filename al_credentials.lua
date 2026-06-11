return {
  active_idx = 2,
  models = {
    { display = "Groq Llama 3 70B", api_key = "COLOQUE_SUA_CHAVE_AQUI", model = "llama-3.3-70b-versatile" },
    { display = "OpenRouter owl-alpha", api_key = "COLOQUE_SUA_CHAVE_AQUI", model = "openrouter/owl-alpha" },
  },
  quiz_config = {
    quiz_amount = 5,
    interface_language = "pt",
    answer_language = "Português",
    quiz_types = {
      ["Discursiva"] = true,
      ["Múltipla Escolha"] = true,
      ["Verdadeiro/Falso"] = true,
    },
    quiz_difficulties = {
      ["Média"] = false,
      ["Difícil"] = true,
      ["Fácil"] = false,
    },
  }
}
