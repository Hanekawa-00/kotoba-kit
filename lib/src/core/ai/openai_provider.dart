import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'llm_provider.dart';

class OpenAiProvider implements LlmProvider {
  OpenAiProvider({
    required String apiKey,
    required String model,
    String baseUrl = 'https://api.openai.com/v1',
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
  String get providerId => 'openai';

  @override
  Future<String> generate({
    required String prompt,
    String? systemPrompt,
    Map<String, dynamic>? jsonSchema,
  }) async {
    final body = _buildBody(prompt, systemPrompt: systemPrompt, stream: false, jsonSchema: jsonSchema);
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/chat/completions',
        data: body,
        options: Options(headers: _headers()),
      );
      final content = response.data?['choices']?[0]?['message']?['content'] as String?;
      if (content == null) {
        throw LlmException('OpenAI returned empty response: ${response.data}');
      }
      return content.trim();
    } on DioException catch (e) {
      final detail = e.response?.data?.toString() ?? e.message ?? '';
      throw LlmException('OpenAI API error (${e.response?.statusCode}): $detail');
    }
  }

  @override
  Stream<String> generateStream({
    required String prompt,
    String? systemPrompt,
  }) async* {
    final body = _buildBody(prompt, systemPrompt: systemPrompt, stream: true);
    try {
      final response = await _dio.post<ResponseBody>(
        '$_baseUrl/chat/completions',
        data: body,
        options: Options(
          headers: _headers(),
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data == '[DONE]') break;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final delta = json['choices']?[0]?['delta']?['content'] as String?;
          if (delta != null && delta.isNotEmpty) {
            yield delta;
          }
        } catch (_) {}
      }
    } on DioException catch (e) {
      final detail = e.response?.data?.toString() ?? e.message ?? '';
      throw LlmException('OpenAI streaming error (${e.response?.statusCode}): $detail');
    }
  }

  Map<String, dynamic> _buildBody(
    String prompt, {
    String? systemPrompt,
    required bool stream,
    Map<String, dynamic>? jsonSchema,
  }) {
    final messages = <Map<String, dynamic>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    return <String, dynamic>{
      'model': _model,
      'messages': messages,
      'stream': stream,
    };
  }

  Map<String, String> _headers() {
    return {'Authorization': 'Bearer $_apiKey'};
  }

  @override
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/models',
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
        '$_baseUrl/models',
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
