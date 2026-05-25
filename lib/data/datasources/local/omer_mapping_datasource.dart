import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../domain/entities/omer_day.dart';

class OmerMappingDatasource {
  OmerMappingDatasource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String _path = 'assets/prayers/maariv/sefirat_haomer/_omer_mapping.json';

  final AssetBundle _bundle;
  Future<List<OmerDay>>? _cached;

  Future<List<OmerDay>> _all() {
    return _cached ??= _load();
  }

  Future<List<OmerDay>> _load() async {
    final raw = await _bundle.loadString(_path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final days = (json['days'] as List<dynamic>)
        .map((d) => OmerDay.fromJson(d as Map<String, dynamic>))
        .toList();
    if (days.length != 49) {
      throw StateError('_omer_mapping.json must contain 49 days, got ${days.length}');
    }
    return days;
  }

  Future<OmerDay> loadDay(int day) async {
    if (day < 1 || day > 49) {
      throw ArgumentError.value(day, 'day', 'must be 1..49');
    }
    final all = await _all();
    return all[day - 1];
  }
}
