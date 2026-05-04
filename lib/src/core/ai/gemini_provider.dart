import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'llm_provider.dart';

class GeminiProvider implements LlmProvider {
  GeminiProvider({
    required String apiKey,
    required String model,
    String baseUrl = 'https://generativelanguage.googleapis.com',
    Dio? dio,
  })  : _apiKey = apiKey,
        _model = model,
        _baseUrl = baseUrl,
        _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
          contentType: Headers.jsonContentType,
        ));

  final String _apiKey;
  final String _model;
  final String _baseUrl;
  final Dio _dio;

  @override
  String get providerId => 'gemini';

  @override
  Future<String> generate({
    required String prompt,
    String? systemPrompt,
    Map<String, dynamic>? jsonSchema,
  }) async {
    final body = _buildBody(prompt, systemPrompt: systemPrompt, jsonSchema: jsonSchema);
    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/v1beta/models/$_model:generateContent?key=$_apiKey',
      data: body,
    );
    final content = _extractText(response.data);
    if (content == null) {
      throw const LlmException('Gemini returned empty response');
    }
    return content.trim();
  }

  @override
  Stream<String> generateStream({
    required String prompt,
    String? systemPrompt,
  }) async* {
    final body = _buildBody(prompt, systemPrompt: systemPrompt);
    final response = await _dio.post<ResponseBody>(
      '$_baseUrl/v1beta/models/$_model:streamGenerateContent?alt=sse&key=$_apiKey',
      data: body,
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stream) {
      if (!line.startsWith('data: ')) continue;
      final data = line.substring(6).trim();
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final text = _extractText(json);
        if (text != null && text.isNotEmpty) {
          yield text;
        }
      } catch (_) {}
    }
  }

  String? _extractText(Map<String, dynamic>? data) {
    final candidates = data?['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;
    final parts = candidates[0]?['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;
    return parts[0]?['text'] as String?;
  }

  Map<String, dynamic> _buildBody(
    String prompt, {
    String? systemPrompt,
    Map<String, dynamic>? jsonSchema,
  }) {
    final contents = <Map<String, dynamic>>[
      {
        'parts': [
          {'text': prompt},
        ],
      },
    ];

    final body = <String, dynamic>{'contents': contents};

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [
          {'text': systemPrompt},
        ],
      };
    }

    if (jsonSchema != null) {
      body['generationConfig'] = {
        'response_mime_type': 'application/json',
        'response_schema': jsonSchema,
      };
    }

    return body;
  }

  @override
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/v1beta/models?key=$_apiKey&pageSize=1',
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
        '$_baseUrl/v1beta/models?key=$_apiKey',
      );
      final models = response.data?['models'] as List?;
      if (models == null) return [];
      return models
          .map((m) {
            final name = (m as Map<String, dynamic>)['name'] as String? ?? '';
            return name.replaceFirst('models/', '');
          })
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
