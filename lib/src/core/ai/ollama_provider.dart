import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'llm_provider.dart';

class OllamaProvider implements LlmProvider {
  OllamaProvider({
    required String model,
    String baseUrl = 'http://localhost:11434',
    Dio? dio,
  })  : _model = model,
        _baseUrl = baseUrl,
        _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
          contentType: Headers.jsonContentType,
        ));

  final String _model;
  final String _baseUrl;
  final Dio _dio;

  @override
  String get providerId => 'ollama';

  @override
  Future<String> generate({
    required String prompt,
    String? systemPrompt,
    Map<String, dynamic>? jsonSchema,
  }) async {
    final body = _buildBody(prompt, systemPrompt: systemPrompt, jsonSchema: jsonSchema);
    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/api/chat',
      data: body,
    );

    final content = response.data?['message']?['content'] as String?;
    if (content == null) {
      throw const LlmException('Ollama returned empty response');
    }
    return content.trim();
  }

  @override
  Stream<String> generateStream({
    required String prompt,
    String? systemPrompt,
  }) async* {
    final body = _buildBody(prompt, systemPrompt: systemPrompt, stream: true);
    final response = await _dio.post<ResponseBody>(
      '$_baseUrl/api/chat',
      data: body,
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stream) {
      if (line.isEmpty) continue;
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        final content = json['message']?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          yield content;
        }
        if (json['done'] == true) break;
      } catch (_) {}
    }
  }

  Map<String, dynamic> _buildBody(
    String prompt, {
    String? systemPrompt,
    bool stream = false,
    Map<String, dynamic>? jsonSchema,
  }) {
    final messages = <Map<String, dynamic>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    final body = <String, dynamic>{
      'model': _model,
      'messages': messages,
      'stream': stream,
    };

    if (jsonSchema != null) {
      body['format'] = 'json';
    }

    return body;
  }

  @override
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/tags',
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<String>> listModels() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/tags',
      );
      final models = response.data?['models'] as List?;
      if (models == null) return [];
      return models
          .map((m) => (m as Map<String, dynamic>)['name'] as String?)
          .where((n) => n != null)
          .cast<String>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> dispose() async {
    _dio.close();
  }
}
