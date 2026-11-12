import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/create_moment_params.dart';
import '../models/create_moment_result.dart';
import '../models/moment_media_stream.dart';
import '../models/moment_model.dart';
import '../models/resend_invite_result.dart';
import '../models/update_moment_params.dart';

class MomentsRemoteDataSource {
  const MomentsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<CreateMomentResult> createMoment(CreateMomentParams params) async {
    final response = await _apiClient.post(
      '/moments',
      body: params.toJson(),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Create moment response must be a JSON object.');
    }
    return CreateMomentResult.fromJson(response);
  }

  Future<MomentsListResponse> getMoments({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get(
      '/moments',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    return MomentsListResponse.fromJson(response);
  }

  Future<MomentsListResponse> getInboxMoments({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get(
      '/moments/inbox',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    return MomentsListResponse.fromJson(response);
  }

  Future<MomentModel> getMomentById(String momentId) async {
    final response = await _apiClient.get('/moments/$momentId');
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Moment response must be a JSON object.');
    }
    return MomentModel.fromJson(response);
  }

  Future<MomentModel> getMomentContent(String momentId) async {
    final response = await _apiClient.get('/moments/$momentId/content');
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Moment content response must be a JSON object.');
    }
    return MomentModel.fromJson(response);
  }

  Future<MomentModel> updateMoment(
    String momentId,
    UpdateMomentParams params,
  ) async {
    final response = await _apiClient.patch(
      '/moments/$momentId',
      body: params.toJson(),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Update moment response must be a JSON object.');
    }
    return MomentModel.fromJson(response);
  }

  Future<void> deleteMoment({
    required String momentId,
    required int version,
  }) async {
    await _apiClient.delete(
      '/moments/$momentId',
      body: {
        'version': version,
      },
    );
  }

  Future<MomentModel> publishMoment({
    required String momentId,
    required int version,
  }) async {
    final response = await _apiClient.post(
      '/moments/$momentId/publish',
      body: {
        'version': version,
      },
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Publish moment response must be a JSON object.');
    }
    return MomentModel.fromJson(response);
  }

  Future<ResendInviteResult> resendInvite(String momentId) async {
    final response = await _apiClient.post('/moments/$momentId/resend-invite');
    return ResendInviteResult.fromJson(response);
  }

  Future<MomentModel> acceptInvitation(String momentId) async {
    final response = await _apiClient.post('/moments/$momentId/invitations/accept');
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Accept invitation response must be a JSON object.');
    }
    return MomentModel.fromJson(response);
  }

  Future<MomentModel> declineInvitation(String momentId) async {
    final response = await _apiClient.post('/moments/$momentId/invitations/decline');
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Decline invitation response must be a JSON object.');
    }
    return MomentModel.fromJson(response);
  }

  Future<MomentModel> unlockMoment({
    required String momentId,
    double? latitude,
    double? longitude,
  }) async {
    final Map<String, dynamic> body = {};
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final response = await _apiClient.post(
      '/moments/$momentId/unlock',
      body: body,
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Unlock moment response must be a JSON object.');
    }
    return MomentModel.fromJson(response);
  }

  Future<MomentModel> uploadMomentMedia({
    required String momentId,
    required int version,
    required List<int> bytes,
    required String filename,
  }) async {
    final mediaType = _resolveMediaType(filename);
    final file = http.MultipartFile.fromBytes(
      'media',
      bytes,
      filename: filename,
      contentType: mediaType,
    );

    final response = await _apiClient.postMultipart(
      '/moments/$momentId/media',
      files: [file],
      fields: {
        'version': version.toString(),
      },
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException('Upload moment media response must be a JSON object.');
    }
    return MomentModel.fromJson(response);
  }

  Future<MomentMediaStream> getMomentMedia(String momentId) async {
    final response = await _apiClient.getRaw('/moments/$momentId/media');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to stream moment media (HTTP ${response.statusCode}).',
      );
    }
    return MomentMediaStream(
      bytes: response.bodyBytes,
      contentType: response.headers['content-type'],
      contentLength: response.contentLength,
    );
  }

  String getMomentMediaStreamUrl(String momentId) {
    return _apiClient.config.endpoint('/moments/$momentId/media').toString();
  }

  Map<String, String> getMomentMediaHeaders() {
    final token = _apiClient.authToken;
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  MediaType _resolveMediaType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'mp4':
        return MediaType('video', 'mp4');
      case 'mov':
        return MediaType('video', 'quicktime');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
