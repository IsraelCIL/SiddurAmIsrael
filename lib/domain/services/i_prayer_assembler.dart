import 'package:siddur_am_israel_chai/domain/entities/assembled_segment.dart';
import 'package:siddur_am_israel_chai/domain/entities/user_context.dart';

abstract class IPrayerAssembler {
  Future<List<AssembledSegment>> assemble({
    required String templateId,
    required UserContext userContext,
  });
}
