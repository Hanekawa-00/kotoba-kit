import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'llm_provider.dart';

class AnthropicProvider implements LlmProvider {
  AnthropicProvider({
    required String apiKey,
    required String model,
    String baseUrl = 'https://api.anthropic.com',
    Dio? dio,
  }) : _apiKey = apiKey,
       _model = model,
       _baseUrl = baseUrl,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 30),
               receiveTimeout: const Duration(seconds: 120),
               contentType: Headers.jsonContentType,
             ),
           );

  final String _apiKey;
  final String _model;
  final String _baseUrl;
  final Dio _dio;

  @override
  String get providerId => 'anthropic';

  @override
  Future<String> generate({
    required String prompt,
    String? systemPrompt,
    Map<String, dynamic>? jsonSchema,
  }) async {
    final body = _buildBody(
      prompt,
      systemPrompt: systemPrompt,
      jsonSchema: jsonSchema,
    );
    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/v1/messages',
      data: body,
      options: Options(headers: _headers()),
    );
    final content = response.data?['content'];
    if (content is List && content.isNotEmpty) {
      final text = content[0]?['text'] as String?;
      if (text != null) return text.trim();
    }
    throw const LlmException('Anthropic returned empty response');
  }

  @override
  Stream<String> generateStream({
    required String prompt,
    String? systemPrompt,
  }) async* {
    final body = _buildBody(prompt, systemPrompt: systemPrompt, stream: true);
    final response = await _dio.post<ResponseBody>(
      '$_baseUrl/v1/messages',
      data: body,
      options: Options(headers: _headers(), responseType: ResponseType.stream),
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
        final type = json['type'] as String?;
        if (type == 'content_block_delta') {
          final text = json['delta']?['text'] as String?;
          if (text != null && text.isNotEmpty) {
            yield text;
          }
        } else if (type == 'message_stop') {
          break;
        }
      } catch (_) {}
    }
  }

  Map<String, dynamic> _buildBody(
    String prompt, {
    String? systemPrompt,
    bool stream = false,
    Map<String, dynamic>? jsonSchema,
  }) {
    final body = <String, dynamic>{
      'model': _model,
      'max_tokens': 4096,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    };

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['system'] = systemPrompt;
    }

    if (stream) {
      body['stream'] = true;
    }

    return body;
  }

  Map<String, String> _headers() {
    return {'x-api-key': _apiKey, 'anthropic-version': '2023-06-01'};
  }

  @override
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/v1/models',
        options: Options(headers: _headers()),
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
        '$_baseUrl/v1/models',
        options: Options(headers: _headers()),
      );
      final data = response.data?['data'] as List?;
      if (data == null) return [];
      return data
          .map((m) => (m as Map<String, dynamic>)['id'] as String?)
          .where((id) => id != null)
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
