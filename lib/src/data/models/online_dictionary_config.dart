import 'package:flutter/foundation.dart';

@immutable
class OnlineDictionaryConfig {
  const OnlineDictionaryConfig({
    required this.id,
    required this.name,
    required this.enabled,
    this.baseUrl,
  });

  factory OnlineDictionaryConfig.fromJson(Map<String, Object?> json) {
    return OnlineDictionaryConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      enabled: json['enabled'] as bool? ?? true,
      baseUrl: json['baseUrl'] as String?,
    );
  }

  final String id;
  final String name;
  final bool enabled;
  final String? baseUrl;

  OnlineDictionaryConfig copyWith({
    String? id,
    String? name,
    bool? enabled,
    String? baseUrl,
  }) {
    return OnlineDictionaryConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (baseUrl != null) 'baseUrl': baseUrl,
      'id': id,
      'name': name,
      'enabled': enabled,
    };
  }
}
