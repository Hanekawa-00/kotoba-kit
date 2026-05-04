import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai/llm_config.dart';
import 'app_settings.dart';
import 'settings_repository.dart';

final settingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return SettingsRepository(SharedPreferencesAsync());
});

final appSettingsControllerProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

class AppSettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() {
    return ref.watch(settingsRepositoryProvider).load();
  }

  Future<void> setThemeMode(ThemeMode themeMode) {
    return _update((settings) => settings.copyWith(themeMode: themeMode));
  }

  Future<void> setColorPreset(AppColorPreset colorPreset) {
    return _update((settings) => settings.copyWith(colorPreset: colorPreset));
  }

  Future<void> setPureBlackDarkMode(bool enabled) {
    return _update((settings) => settings.copyWith(pureBlackDarkMode: enabled));
  }

  Future<void> setCompactDensity(bool enabled) {
    return _update((settings) => settings.copyWith(compactDensity: enabled));
  }

  Future<void> addLlmConfig(LlmConfig config) {
    return _update((settings) {
      final configs = [...settings.llmConfigs, config];
      return settings.copyWith(
        llmConfigs: configs,
        activeLlmConfigId: config.id,
      );
    });
  }

  Future<void> updateLlmConfig(LlmConfig config) {
    return _update((settings) {
      final configs = settings.llmConfigs.map((c) {
        return c.id == config.id ? config : c;
      }).toList();
      return settings.copyWith(llmConfigs: configs);
    });
  }

  Future<void> removeLlmConfig(String id) {
    return _update((settings) {
      final configs = settings.llmConfigs.where((c) => c.id != id).toList();
      final activeId = settings.activeLlmConfigId == id
          ? (configs.isNotEmpty ? configs.first.id : null)
          : settings.activeLlmConfigId;
      return settings.copyWith(
        llmConfigs: configs,
        activeLlmConfigId: activeId,
      );
    });
  }

  Future<void> setActiveLlmConfig(String? id) {
    return _update((settings) => settings.copyWith(activeLlmConfigId: id));
  }

  Future<void> reset() {
    return _update((settings) => AppSettings.defaults());
  }

  Future<void> _update(AppSettings Function(AppSettings) update) async {
    final repository = ref.read(settingsRepositoryProvider);
    final previous = state.asData?.value ?? AppSettings.defaults();
    final next = update(previous);

    state = AsyncData(next);

    try {
      await repository.save(next);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
