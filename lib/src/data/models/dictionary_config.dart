import 'package:flutter/foundation.dart';

@immutable
class DictionaryConfig {
  const DictionaryConfig({
    required this.id,
    required this.name,
    required this.mdxPath,
    required this.importedAt,
    required this.enabled,
    this.mddPaths = const [],
    this.entryCount,
  });

  factory DictionaryConfig.fromJson(Map<String, Object?> json) {
    final rawMddPaths = json['mddPaths'];
    final mddPaths = rawMddPaths is List
        ? rawMddPaths
              .whereType<String>()
              .where((path) => path.isNotEmpty)
              .toList(growable: false)
        : [
            if (json['mddPath'] case final String path when path.isNotEmpty)
              path,
          ];

    return DictionaryConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      mdxPath: json['mdxPath'] as String,
      mddPaths: mddPaths,
      importedAt: DateTime.parse(json['importedAt'] as String),
      enabled: json['enabled'] as bool? ?? true,
      entryCount: json['entryCount'] as int?,
    );
  }

  final String id;
  final String name;
  final String mdxPath;
  final List<String> mddPaths;
  final DateTime importedAt;
  final bool enabled;
  final int? entryCount;

  String? get mddPath => mddPaths.isEmpty ? null : mddPaths.first;

  DictionaryConfig copyWith({
    String? id,
    String? name,
    String? mdxPath,
    List<String>? mddPaths,
    DateTime? importedAt,
    bool? enabled,
    int? entryCount,
  }) {
    return DictionaryConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      mdxPath: mdxPath ?? this.mdxPath,
      mddPaths: mddPaths ?? this.mddPaths,
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
      'mddPaths': mddPaths,
      'importedAt': importedAt.toIso8601String(),
      'enabled': enabled,
      'entryCount': entryCount,
    };
  }
}
