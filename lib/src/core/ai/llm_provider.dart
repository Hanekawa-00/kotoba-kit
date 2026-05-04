abstract class LlmProvider {
  String get providerId;

  Future<String> generate({
    required String prompt,
    String? systemPrompt,
    Map<String, dynamic>? jsonSchema,
  });

  Stream<String> generateStream({
    required String prompt,
    String? systemPrompt,
  });

  Future<bool> testConnection();

  Future<List<String>> listModels();

  Future<void> dispose();
}

class LlmException implements Exception {
  const LlmException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'LlmException: $message';
}
