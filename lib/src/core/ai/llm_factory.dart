import 'anthropic_provider.dart';
import 'gemini_provider.dart';
import 'llm_config.dart';
import 'llm_provider.dart';
import 'ollama_provider.dart';
import 'openai_provider.dart';

class LlmFactory {
  LlmFactory._();

  static LlmProvider create(LlmConfig config) {
    return switch (config.provider) {
      LlmProviderType.openai => OpenAiProvider(
        apiKey: config.apiKey,
        model: config.model,
        baseUrl: config.baseUrl.isNotEmpty
            ? config.baseUrl
            : LlmProviderType.openai.defaultBaseUrl,
      ),
      LlmProviderType.anthropic => AnthropicProvider(
        apiKey: config.apiKey,
        model: config.model,
        baseUrl: config.baseUrl.isNotEmpty
            ? config.baseUrl
            : LlmProviderType.anthropic.defaultBaseUrl,
      ),
      LlmProviderType.gemini => GeminiProvider(
        apiKey: config.apiKey,
        model: config.model,
        baseUrl: config.baseUrl.isNotEmpty
            ? config.baseUrl
            : 'https://generativelanguage.googleapis.com',
      ),
      LlmProviderType.ollama => OllamaProvider(
        model: config.model,
        baseUrl: config.baseUrl.isNotEmpty
            ? config.baseUrl
            : LlmProviderType.ollama.defaultBaseUrl,
      ),
    };
  }
}
