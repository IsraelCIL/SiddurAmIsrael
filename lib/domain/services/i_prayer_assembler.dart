import 'package:smart_siddur/domain/entities/assembled_segment.dart';
import 'package:smart_siddur/domain/entities/user_context.dart';

abstract class IPrayerAssembler {
  Future<List<AssembledSegment>> assemble({
    required String templateId,
    required UserContext userContext,
  });
}
