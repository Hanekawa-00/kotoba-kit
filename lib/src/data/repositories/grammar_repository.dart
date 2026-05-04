import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../features/practice/models/practice_types.dart';

class GrammarRepository {
  List<GrammarPoint>? _cache;

  Future<List<GrammarPoint>> loadAll() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString(
      'assets/grammar/jlpt_grammar_full.json',
    );
    final list = json.decode(jsonStr) as List<dynamic>;
    _cache = list
        .map((e) => GrammarPoint.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return _cache!;
  }

  List<GrammarPoint> filterByLevel(
    List<GrammarPoint> points,
    Difficulty level,
  ) {
    return points.where((p) => p.level == level).toList(growable: false);
  }

  GrammarPoint? randomByLevel(List<GrammarPoint> points, Difficulty level) {
    final filtered = filterByLevel(points, level);
    if (filtered.isEmpty) return null;
    return filtered[Random().nextInt(filtered.length)];
  }
}
