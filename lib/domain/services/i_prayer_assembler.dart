import '../entities/assembled_segment.dart';
import '../entities/user_context.dart';

abstract class IPrayerAssembler {
  Future<List<AssembledSegment>> assemble({
    required String templateId,
    required UserContext userContext,
  });
}
