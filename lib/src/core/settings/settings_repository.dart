import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await Future.wait<void>([
      _preferences.setString(_themeModeKey, settings.themeMode.name),
      _preferences.setString(_colorPresetKey, settings.colorPreset.name),
      _preferences.setBool(_pureBlackDarkModeKey, settings.pureBlackDarkMode),
      _preferences.setBool(_compactDensityKey, settings.compactDensity),
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
