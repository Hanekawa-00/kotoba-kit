import 'package:flutter/material.dart';

enum AppColorPreset {
  ocean('Ocean', Color(0xFF1565C0)),
  forest('Forest', Color(0xFF4A672D)),
  coral('Coral', Color(0xFFC2415D)),
  violet('Violet', Color(0xFF6D4CDE)),
  graphite('Graphite', Color(0xFF54616F));

  const AppColorPreset(this.label, this.seedColor);

  final String label;
  final Color seedColor;
}

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.colorPreset,
    required this.pureBlackDarkMode,
    required this.compactDensity,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      themeMode: ThemeMode.system,
      colorPreset: AppColorPreset.ocean,
      pureBlackDarkMode: false,
      compactDensity: false,
    );
  }

  final ThemeMode themeMode;
  final AppColorPreset colorPreset;
  final bool pureBlackDarkMode;
  final bool compactDensity;

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppColorPreset? colorPreset,
    bool? pureBlackDarkMode,
    bool? compactDensity,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      colorPreset: colorPreset ?? this.colorPreset,
      pureBlackDarkMode: pureBlackDarkMode ?? this.pureBlackDarkMode,
      compactDensity: compactDensity ?? this.compactDensity,
    );
  }
}
