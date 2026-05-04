import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_providers.dart';
import 'llm_config.dart';
import 'llm_factory.dart';
import 'llm_provider.dart';

final llmConfigProvider = Provider<LlmConfig?>((ref) {
  final settings = ref.watch(appSettingsControllerProvider).asData?.value;
  return settings?.activeLlmConfig;
});

final llmProviderProvider = Provider<LlmProvider?>((ref) {
  final config = ref.watch(llmConfigProvider);
  if (config == null || !config.isConfigured) return null;

  try {
    return LlmFactory.create(config);
  } catch (_) {
    return null;
  }
});
