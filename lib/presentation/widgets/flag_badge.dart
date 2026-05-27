import 'package:flutter/material.dart';

import 'package:smart_siddur/domain/entities/day_flags.dart';

class FlagBadge extends StatelessWidget {
  const FlagBadge({super.key, required this.flag});

  final String flag;

  static const _badges = <String, _BadgeData>{
    DayFlag.roshChodesh: _BadgeData('ראש חודש', Color(0xFF1565C0)),
    DayFlag.asaretYemeiTeshuva: _BadgeData('עשי״ת', Color(0xFF7B1FA2)),
    DayFlag.chanukah: _BadgeData('חנוכה', Color(0xFF0288D1)),
    DayFlag.purim: _BadgeData('פורים', Color(0xFFC62828)),
    DayFlag.shushanPurim: _BadgeData('שושן פורים', Color(0xFFAD1457)),
    DayFlag.fastDay: _BadgeData('תענית', Color(0xFF4E342E)),
    DayFlag.erevYomKippur: _BadgeData('ערב יוה״כ', Color(0xFF37474F)),
    DayFlag.yomKippur: _BadgeData('יוה״כ', Color(0xFF263238)),
    DayFlag.cholHamoedPesach: _BadgeData('חוה״מ פסח', Color(0xFF2E7D32)),
    DayFlag.cholHamoedSukkot: _BadgeData('חוה״מ סוכות', Color(0xFF558B2F)),
    DayFlag.hoshanahRaba: _BadgeData('הו״ר', Color(0xFF33691E)),
  };

  static bool isDisplayWorthy(String flag) => _badges.containsKey(flag);

  @override
  Widget build(BuildContext context) {
    final data = _badges[flag];
    if (data == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        data.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

class _BadgeData {
  const _BadgeData(this.label, this.color);
  final String label;
  final Color color;
}
