import 'package:smart_siddur/domain/entities/assembled_segment.dart';
import 'package:smart_siddur/domain/entities/sukkot_korban.dart';

/// Fills the `{{daily_korban}}` placeholder in
/// `amidah_musaf_intermediate_chm_sukkot` (per-nusach) with the day's korban
/// pasuk from Numbers 29. The placeholder is identical across nusachim
/// because the korban text is a Torah quote (textually identical).
///
/// Used after [PrayerAssembler] builds the segment, called from the
/// assembler when [UserContext.sukkotDay] is set.
class SukkotKorbanotPostProcessor {
  const SukkotKorbanotPostProcessor();

  AssembledSegment process(
    AssembledSegment seg,
    SukkotKorban day, {
    required bool isInIsrael,
  }) {
    if (!seg.id.startsWith('amidah_musaf_intermediate_chm_sukkot')) return seg;
    final korban = day.textFor(isInIsrael: isInIsrael);
    return seg.copyWith(
      resolvedText: seg.resolvedText.replaceAll('{{daily_korban}}', korban),
    );
  }
}
