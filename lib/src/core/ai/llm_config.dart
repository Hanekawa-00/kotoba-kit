import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum LlmProviderType {
  openai('OpenAI'),
  anthropic('Anthropic'),
  gemini('Gemini'),
  ollama('Ollama');

  const LlmProviderType(this.label);

  final String label;

  String get defaultModel {
    return switch (this) {
      LlmProviderType.openai => 'gpt-4o',
      LlmProviderType.anthropic => 'claude-sonnet-4-20250514',
      LlmProviderType.gemini => 'gemini-2.5-flash',
      LlmProviderType.ollama => 'qwen3:14b',
    };
  }

  String get defaultBaseUrl {
    return switch (this) {
      LlmProviderType.openai => 'https://api.openai.com/v1',
      LlmProviderType.anthropic => 'https://api.anthropic.com',
      LlmProviderType.ollama => 'http://localhost:11434/v1',
      _ => '',
    };
  }
}

@immutable
class LlmConfig {
  const LlmConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.apiKey,
    required this.model,
    this.baseUrl = '',
  });

  factory LlmConfig.create({
    required String name,
    required LlmProviderType provider,
    required String apiKey,
    required String model,
    String baseUrl = '',
  }) {
    return LlmConfig(
      id: const Uuid().v4(),
      name: name,
      provider: provider,
      apiKey: apiKey,
      model: model,
      baseUrl: baseUrl,
    );
  }

  factory LlmConfig.fromJson(Map<String, dynamic> json) {
    return LlmConfig(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      provider: LlmProviderType.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => LlmProviderType.gemini,
      ),
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final LlmProviderType provider;
  final String apiKey;
  final String model;
  final String baseUrl;

  bool get isConfigured =>
      apiKey.isNotEmpty || provider == LlmProviderType.ollama;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider.name,
        'apiKey': apiKey,
        'model': model,
        'baseUrl': baseUrl,
      };

  LlmConfig copyWith({
    String? name,
    LlmProviderType? provider,
    String? apiKey,
    String? model,
    String? baseUrl,
  }) {
    return LlmConfig(
      id: id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}
