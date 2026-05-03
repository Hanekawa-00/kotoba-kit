import 'package:flutter/foundation.dart';

@immutable
class DictionaryConfig {
  const DictionaryConfig({
    required this.id,
    required this.name,
    required this.mdxPath,
    required this.importedAt,
    required this.enabled,
    this.mddPath,
    this.entryCount,
  });

  factory DictionaryConfig.fromJson(Map<String, Object?> json) {
    return DictionaryConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      mdxPath: json['mdxPath'] as String,
      mddPath: json['mddPath'] as String?,
      importedAt: DateTime.parse(json['importedAt'] as String),
      enabled: json['enabled'] as bool? ?? true,
      entryCount: json['entryCount'] as int?,
    );
  }

  final String id;
  final String name;
  final String mdxPath;
  final String? mddPath;
  final DateTime importedAt;
  final bool enabled;
  final int? entryCount;

  DictionaryConfig copyWith({
    String? id,
    String? name,
    String? mdxPath,
    String? mddPath,
    DateTime? importedAt,
    bool? enabled,
    int? entryCount,
  }) {
    return DictionaryConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      mdxPath: mdxPath ?? this.mdxPath,
      mddPath: mddPath ?? this.mddPath,
      importedAt: importedAt ?? this.importedAt,
      enabled: enabled ?? this.enabled,
      entryCount: entryCount ?? this.entryCount,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'mdxPath': mdxPath,
      'mddPath': mddPath,
      'importedAt': importedAt.toIso8601String(),
      'enabled': enabled,
      'entryCount': entryCount,
    };
  }
}
