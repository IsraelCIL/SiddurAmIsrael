import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:siddur_am_israel_chai/domain/entities/sukkot_korban.dart';

class SukkotKorbanotDatasource {
  SukkotKorbanotDatasource({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  static const String _path =
      'assets/prayers/musaf/sukkot/_sukkot_korbanot_mapping.json';

  final AssetBundle _bundle;
  Future<List<SukkotKorban>>? _cached;

  Future<List<SukkotKorban>> _all() => _cached ??= _load();

  Future<List<SukkotKorban>> _load() async {
    final raw = await _bundle.loadString(_path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final days = (json['days'] as List<dynamic>)
        .map((d) => SukkotKorban.fromJson(d as Map<String, dynamic>))
        .toList();
    if (days.length != 7) {
      throw StateError(
        '_sukkot_korbanot_mapping.json must contain 7 days, got ${days.length}',
      );
    }
    return days;
  }

  Future<SukkotKorban> loadDay(int day) async {
    if (day < 1 || day > 7) {
      throw ArgumentError.value(day, 'day', 'must be 1..7');
    }
    final all = await _all();
    return all[day - 1];
  }
}
