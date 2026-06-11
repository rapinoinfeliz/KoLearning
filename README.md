# KoLearning (Augmented Learning)

KoLearning is an advanced augmented learning plugin for KOReader that leverages large language models (LLMs) to enhance your reading experience. By intelligently extracting text directly from your books, it automatically generates custom quizzes, pre-questions, and study notes based on what you are currently reading.

It implements pedagogical techniques like **Active Learning**, **Curiosity-Driven Learning**, and the **Prediction Effect**, helping you retain more knowledge and stay actively engaged with the text.

## Features

- **Pre-Questions Generation**: Generates thought-provoking pre-reading questions to activate your curiosity before you start a new chapter. It includes "Recommended Reflections" (Key Points) to guide your understanding as you read.
- **Custom Quizzes**: Turn any chapter or page into a Multiple Choice, True/False, or Short Answer quiz. The plugin tests your comprehension and provides detailed model answers and feedback.
- **Context-Aware Extraction**: Seamlessly select the current page, the current chapter, or any specific amount of pages directly from the table of contents to use as the context for your learning tools.
- **Flexible AI Integration**: Works out of the box with many major LLM providers via OpenRouter, Groq, or any OpenAI-compatible API.
- **History & Archive**: Automatically saves your generated quizzes and pre-questions in a dedicated archive organized by book. You can review them anytime and easily track your completion status.
- **Multi-language Interface**: Fully translated into English, Spanish, and Portuguese, dynamically adapting to your KOReader interface language.

---

## Installation

1. Download or clone this repository.
2. Rename the folder to `augmentedlearning.koplugin` if it isn't already.
3. Copy the folder to the `plugins/` directory of your KOReader installation:
   - On E-ink devices (Kobo, Kindle, PocketBook): Connect to your computer via USB and copy to `koreader/plugins/`.
   - On Android: Copy to `koreader/plugins/` using a file manager.
4. Restart KOReader. You will now see "Augmented Learning" in your reader menu.

---

## Configuration: Adding Different APIs and LLMs

The plugin allows you to define multiple LLM providers and seamlessly switch between them in the Settings menu.

### Setting up via the Interface

1. Open the **Augmented Learning** menu while reading a book.
2. Go to **Configurações** (Settings) > **Modelos / API** (Models / API).
3. Here you can select the active model.

*(Note: In the current version, to add completely new API keys and models easily, you can edit the `al_settings.lua` file directly or check for `al_credentials.lua` in the plugin folder).*

### Manually Adding API Providers (Advanced)

If you want to use a specific model from OpenAI, Anthropic, OpenRouter, or Groq, you can configure it directly in the plugin files. 

1. Open `al_settings.lua` inside the plugin folder.
2. Find the `DEFAULT_MODELS` table at the top of the file:

```lua
local DEFAULT_MODELS = {
    { 
        display = "Groq Llama 3", 
        api_key = "your_groq_api_key_here", 
        model = "llama-3.3-70b-versatile" 
    },
    { 
        display = "OpenRouter GPT-4o", 
        api_key = "your_openrouter_api_key_here", 
        model = "openai/gpt-4o" 
    },
    {
        display = "Local LM Studio",
        api_key = "not_needed",
        model = "local-model",
        -- If you need to override the base URL for local servers (e.g. LM Studio, Ollama)
        -- base_url = "http://192.168.1.100:1234/v1/chat/completions"
    }
}
```

3. Replace `"your_api_key_here"` with your actual API key from your provider.
4. Set the `model` string to match the exact model ID expected by your provider (e.g., `gpt-4o-mini`, `claude-3-5-sonnet`, `llama-3.1-8b-instant`).
5. **Important:** The plugin uses an OpenAI-compatible API format. If you use a local server like Ollama or LM Studio, you may need to adjust the `base_url` directly in the API request handler (`al_api.lua`), or provide a proxy if your endpoint structure differs slightly.

### Using Local LLMs (Ollama / LM Studio)

You can run your own LLMs completely offline and free using tools like Ollama or LM Studio on your computer, provided your e-reader is on the same local Wi-Fi network.

1. Ensure your local server is exposing its API to the local network (e.g., `http://192.168.x.x:1234/v1`).
2. Add an entry in the models list with your local IP and model name.
3. If necessary, adjust the `al_api.lua` HTTP request URL from `https://api.groq.com/openai/v1/chat/completions` (or openrouter) to your local endpoint.

---

## Usage

1. **Open a Book**: Open any EPUB, PDF, or document in KOReader.
2. **Access the Menu**: Open the top reader menu and navigate to the **Augmented Learning** tab.
3. **Generate Pre-Questions**: Before reading a chapter, select "Pré-Questões" (Pre-Questions). Choose "Current Chapter", and the AI will analyze the text to create thought-provoking questions and key points to guide your reading.
4. **Generate Quiz**: After finishing a chapter, select "Quiz". The AI will generate a test based on the text you just read to solidify your memory retention.
5. **Customize**: Go to "Configurações" (Settings) to choose the number of questions, difficulty level (Easy, Medium, Hard), and types of questions (Multiple Choice, True/False, Short Answer).
6. **Archive**: Access "Arquivo" (History/Archive) to view all previously generated quizzes and pre-questions for any book.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
