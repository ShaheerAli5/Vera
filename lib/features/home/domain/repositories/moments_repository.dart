import '../../data/models/chat_message_model.dart';
import '../../data/models/create_moment_params.dart';
import '../../data/models/create_moment_result.dart';
import '../../data/models/moment_media_stream.dart';
import '../../data/models/moment_model.dart';
import '../../data/models/moment_thread_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/recipient_user_model.dart';
import '../../data/models/resend_invite_result.dart';
import '../../data/models/update_moment_params.dart';

abstract class MomentsRepository {
  Future<CreateMomentResult> createMoment(CreateMomentParams params);
  Future<MomentsListResponse> getHomeFeed({
    required String tab,
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
  });
  Future<MomentsListResponse> getDiscoverMoments({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? contentType,
    String? unlockType,
  });
  Future<MomentsListResponse> getMoments({int page = 1, int limit = 20});
  Future<MomentsListResponse> getInboxMoments({int page = 1, int limit = 20});
  Future<NotificationsListResponse> getNotifications({
    int page = 1,
    int limit = 20,
  });
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
  Future<MomentModel> deleteMomentMedia({
    required String momentId,
    required int version,
  });
  Future<MomentMediaStream> getMomentMedia(String momentId);
  Future<MomentModel> getMomentContent(String momentId);
  Future<MomentThreadModel> createOrGetMomentThread({
    required String momentId,
    String? recipientUserId,
  });
  Future<ChatThreadsResponse> getChatThreads({
    required String box,
    int limit = 20,
    String? cursor,
  });
  Future<ThreadMessagesResponse> getThreadMessages({
    required String chatThreadId,
    int limit = 50,
    String? cursor,
  });
  Future<ChatMessageModel> sendThreadMessage({
    required String chatThreadId,
    required String text,
    String? clientMessageId,
  });
  Future<void> markThreadAsRead({
    required String chatThreadId,
    required String messageId,
  });
  String getMomentMediaStreamUrl(String momentId);
  Map<String, String> getMomentMediaHeaders();
  Future<List<RecipientUserModel>> searchUsers(String query);
  Future<void> markNotificationAsRead(String notificationId);
  Future<void> markAllNotificationsAsRead();
}
