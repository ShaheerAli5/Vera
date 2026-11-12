import '../../data/models/create_moment_params.dart';
import '../../data/models/create_moment_result.dart';
import '../../data/models/moment_media_stream.dart';
import '../../data/models/moment_model.dart';
import '../../data/models/resend_invite_result.dart';
import '../../data/models/update_moment_params.dart';

abstract class MomentsRepository {
  Future<CreateMomentResult> createMoment(CreateMomentParams params);
  Future<MomentsListResponse> getMoments({int page = 1, int limit = 20});
  Future<MomentsListResponse> getInboxMoments({int page = 1, int limit = 20});
  Future<MomentModel> getMomentById(String momentId);
  Future<MomentModel> updateMoment(String momentId, UpdateMomentParams params);
  Future<void> deleteMoment({
    required String momentId,
    required int version,
  });
  Future<MomentModel> publishMoment({
    required String momentId,
    required int version,
  });
  Future<ResendInviteResult> resendInvite(String momentId);
  Future<MomentModel> acceptInvitation(String momentId);
  Future<MomentModel> declineInvitation(String momentId);
  Future<MomentModel> unlockMoment({
    required String momentId,
    double? latitude,
    double? longitude,
  });
  Future<MomentModel> uploadMomentMedia({
    required String momentId,
    required int version,
    required List<int> bytes,
    required String filename,
  });
  Future<MomentMediaStream> getMomentMedia(String momentId);
  Future<MomentModel> getMomentContent(String momentId);
  String getMomentMediaStreamUrl(String momentId);
  Map<String, String> getMomentMediaHeaders();
}
