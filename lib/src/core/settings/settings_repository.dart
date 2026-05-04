import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai/llm_config.dart';
import 'app_settings.dart';

abstract class AppSettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

class SettingsRepository implements AppSettingsRepository {
  SettingsRepository(this._preferences);

  final SharedPreferencesAsync _preferences;

  static const _themeModeKey = 'settings.themeMode';
  static const _colorPresetKey = 'settings.colorPreset';
  static const _pureBlackDarkModeKey = 'settings.pureBlackDarkMode';
  static const _compactDensityKey = 'settings.compactDensity';
  static const _llmConfigsKey = 'settings.llmConfigs';
  static const _activeLlmConfigIdKey = 'settings.activeLlmConfigId';

  @override
  Future<AppSettings> load() async {
    final defaults = AppSettings.defaults();

    return AppSettings(
      themeMode: _themeModeFromName(
        await _preferences.getString(_themeModeKey),
        defaults.themeMode,
      ),
      colorPreset: _colorPresetFromName(
        await _preferences.getString(_colorPresetKey),
        defaults.colorPreset,
      ),
      pureBlackDarkMode:
          await _preferences.getBool(_pureBlackDarkModeKey) ??
          defaults.pureBlackDarkMode,
      compactDensity:
          await _preferences.getBool(_compactDensityKey) ??
          defaults.compactDensity,
      llmConfigs: await _loadLlmConfigs(),
      activeLlmConfigId: await _preferences.getString(_activeLlmConfigIdKey),
    );
  }

  Future<List<LlmConfig>> _loadLlmConfigs() async {
    final jsonStr = await _preferences.getString(_llmConfigsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = json.decode(jsonStr) as List<dynamic>;
      return list
          .map((e) => LlmConfig.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    final configsJson = json.encode(
      settings.llmConfigs.map((c) => c.toJson()).toList(),
    );
    await Future.wait<void>([
      _preferences.setString(_themeModeKey, settings.themeMode.name),
      _preferences.setString(_colorPresetKey, settings.colorPreset.name),
      _preferences.setBool(_pureBlackDarkModeKey, settings.pureBlackDarkMode),
      _preferences.setBool(_compactDensityKey, settings.compactDensity),
      _preferences.setString(_llmConfigsKey, configsJson),
      if (settings.activeLlmConfigId != null)
        _preferences.setString(_activeLlmConfigIdKey, settings.activeLlmConfigId!)
      else
        _preferences.remove(_activeLlmConfigIdKey),
    ]);
  }

  ThemeMode _themeModeFromName(String? name, ThemeMode fallback) {
    for (final mode in ThemeMode.values) {
      if (mode.name == name) {
        return mode;
      }
    }
    return fallback;
  }

  AppColorPreset _colorPresetFromName(String? name, AppColorPreset fallback) {
    for (final preset in AppColorPreset.values) {
      if (preset.name == name) {
        return preset;
      }
    }
    return fallback;
  }
}
