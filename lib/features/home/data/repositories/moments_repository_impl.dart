import '../../domain/repositories/moments_repository.dart';
import '../datasources/moments_remote_data_source.dart';
import '../models/create_moment_params.dart';
import '../models/create_moment_result.dart';
import '../models/moment_media_stream.dart';
import '../models/moment_model.dart';
import '../models/resend_invite_result.dart';
import '../models/update_moment_params.dart';

class MomentsRepositoryImpl implements MomentsRepository {
  const MomentsRepositoryImpl(this._remoteDataSource);

  final MomentsRemoteDataSource _remoteDataSource;

  @override
  Future<CreateMomentResult> createMoment(CreateMomentParams params) {
    return _remoteDataSource.createMoment(params);
  }

  @override
  Future<MomentsListResponse> getMoments({int page = 1, int limit = 20}) {
    return _remoteDataSource.getMoments(page: page, limit: limit);
  }

  @override
  Future<MomentsListResponse> getInboxMoments({int page = 1, int limit = 20}) {
    return _remoteDataSource.getInboxMoments(page: page, limit: limit);
  }

  @override
  Future<MomentModel> getMomentById(String momentId) {
    return _remoteDataSource.getMomentById(momentId);
  }

  @override
  Future<MomentModel> updateMoment(
    String momentId,
    UpdateMomentParams params,
  ) {
    return _remoteDataSource.updateMoment(momentId, params);
  }

  @override
  Future<void> deleteMoment({
    required String momentId,
    required int version,
  }) {
    return _remoteDataSource.deleteMoment(
      momentId: momentId,
      version: version,
    );
  }

  @override
  Future<MomentModel> publishMoment({
    required String momentId,
    required int version,
  }) {
    return _remoteDataSource.publishMoment(
      momentId: momentId,
      version: version,
    );
  }

  @override
  Future<ResendInviteResult> resendInvite(String momentId) {
    return _remoteDataSource.resendInvite(momentId);
  }

  @override
  Future<MomentModel> acceptInvitation(String momentId) {
    return _remoteDataSource.acceptInvitation(momentId);
  }

  @override
  Future<MomentModel> declineInvitation(String momentId) {
    return _remoteDataSource.declineInvitation(momentId);
  }

  @override
  Future<MomentModel> unlockMoment({
    required String momentId,
    double? latitude,
    double? longitude,
  }) {
    return _remoteDataSource.unlockMoment(
      momentId: momentId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<MomentModel> uploadMomentMedia({
    required String momentId,
    required int version,
    required List<int> bytes,
    required String filename,
  }) {
    return _remoteDataSource.uploadMomentMedia(
      momentId: momentId,
      version: version,
      bytes: bytes,
      filename: filename,
    );
  }

  @override
  Future<MomentMediaStream> getMomentMedia(String momentId) {
    return _remoteDataSource.getMomentMedia(momentId);
  }

  @override
  Future<MomentModel> getMomentContent(String momentId) {
    return _remoteDataSource.getMomentContent(momentId);
  }

  @override
  String getMomentMediaStreamUrl(String momentId) {
    return _remoteDataSource.getMomentMediaStreamUrl(momentId);
  }

  @override
  Map<String, String> getMomentMediaHeaders() {
    return _remoteDataSource.getMomentMediaHeaders();
  }
}
