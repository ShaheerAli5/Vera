import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/blocked_user_model.dart';
import '../models/forgot_password_result.dart';
import '../models/login_result.dart';
import '../models/logout_result.dart';
import '../models/profile_settings.dart';
import '../models/registration_result.dart';
import '../models/resend_otp_result.dart';
import '../models/reset_password_result.dart';
import '../models/user_profile.dart';
import '../models/verify_email_result.dart';

class AccountRemoteDataSource {
  const AccountRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<RegistrationResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Registration response must be a JSON object.');
    }
    return RegistrationResult.fromJson(response);
  }

  Future<LoginResult> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
        if (deviceName != null && deviceName.isNotEmpty)
          'deviceName': deviceName,
      },
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Login response must be a JSON object.');
    }
    return LoginResult.fromJson(response);
  }

  Future<LoginResult> adminLogin({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Admin Login response must be a JSON object.');
    }
    return LoginResult.fromJson(response);
  }

  Future<VerifyEmailResult> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _apiClient.post(
      '/auth/verify-email',
      body: {'email': email, 'code': code},
    );
    if (response is! Map<String, dynamic>) {
      if (response == null) {
        return const VerifyEmailResult(message: 'Email verified successfully.');
      }
      throw const FormatException('Verification response must be a JSON object.');
    }
    return VerifyEmailResult.fromJson(response);
  }

  Future<ForgotPasswordResult> forgotPassword({
    required String email,
  }) async {
    final response = await _apiClient.post(
      '/auth/forgot-password',
      body: {'email': email},
    );
    if (response is! Map<String, dynamic>) {
      if (response == null) {
        return const ForgotPasswordResult(
          message: 'If an eligible account exists, a reset code has been sent.',
        );
      }
      throw const FormatException('Forgot password response must be a JSON object.');
    }
    return ForgotPasswordResult.fromJson(response);
  }

  Future<ResetPasswordResult> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/reset-password',
      body: {
        'email': email,
        'code': code,
        'password': password,
      },
    );
    if (response is! Map<String, dynamic>) {
      if (response == null) {
        return const ResetPasswordResult(
          message: 'Password reset successfully.',
        );
      }
      throw const FormatException('Reset password response must be a JSON object.');
    }
    return ResetPasswordResult.fromJson(response);
  }

  Future<ResendOtpResult> resendOtp({
    required String email,
    required String purpose,
  }) async {
    final response = await _apiClient.post(
      '/auth/resend-otp',
      body: {
        'email': email,
        'purpose': purpose,
      },
    );
    if (response is! Map<String, dynamic>) {
      if (response == null) {
        return const ResendOtpResult(
          message: 'A new verification code has been sent.',
        );
      }
      throw const FormatException('Resend OTP response must be a JSON object.');
    }
    return ResendOtpResult.fromJson(response);
  }

  Future<LogoutResult> logout({
    required String refreshToken,
  }) async {
    final response = await _apiClient.post(
      '/auth/logout',
      body: {'refreshToken': refreshToken},
    );
    if (response is! Map<String, dynamic>) {
      if (response == null) {
        return const LogoutResult(message: 'Logged out successfully.');
      }
      throw const FormatException('Logout response must be a JSON object.');
    }
    return LogoutResult.fromJson(response);
  }

  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
    String? deviceName,
  }) async {
    final response = await _apiClient.post(
      '/auth/refresh',
      body: {
        'refreshToken': refreshToken,
        if (deviceName != null && deviceName.isNotEmpty)
          'deviceName': deviceName,
      },
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Refresh response must be a JSON object.');
    }
    return response;
  }

  Future<UserProfile> getProfile() async {
    final response = await _apiClient.get('/profile');
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Profile response must be a JSON object.');
    }
    return UserProfile.fromJson(response);
  }

  Future<UserProfile> updateProfile({
    required String name,
  }) async {
    final response = await _apiClient.patch(
      '/profile',
      body: {'name': name},
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Profile response must be a JSON object.');
    }
    return UserProfile.fromJson(response);
  }

  Future<ProfileSettings> getSettings() async {
    final response = await _apiClient.get('/profile/settings');
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Settings response must be a JSON object.');
    }
    return ProfileSettings.fromJson(response);
  }

  Future<ProfileSettings> updateSettings({
    ProfileSettings? settings,
    String? language,
    String? timezone,
    bool? pushInvitations,
    bool? pushUnlocks,
    bool? pushReplies,
    bool? discoverableByEmail,
    bool? analyticsEnabled,
    String? privacy,
    bool? allowLocationChecks,
  }) async {
    final finalLanguage = language ?? settings?.language;
    final finalTimezone = timezone ?? settings?.timezone;
    final finalPushInvitations = pushInvitations ?? settings?.pushInvitations;
    final finalPushUnlocks = pushUnlocks ?? settings?.pushUnlocks;
    final finalPushReplies = pushReplies ?? settings?.pushReplies;
    final finalDiscoverableByEmail =
        discoverableByEmail ?? settings?.discoverableByEmail;
    final finalAnalyticsEnabled =
        analyticsEnabled ?? settings?.analyticsEnabled;
    final finalPrivacy = privacy ?? settings?.privacy;
    final finalAllowLocationChecks =
        allowLocationChecks ?? settings?.allowLocationChecks;

    final payload = <String, dynamic>{
      if (finalLanguage != null) 'language': finalLanguage,
      if (finalTimezone != null) 'timezone': finalTimezone,
      if (finalPushInvitations != null) 'pushInvitations': finalPushInvitations,
      if (finalPushUnlocks != null) 'pushUnlocks': finalPushUnlocks,
      if (finalPushReplies != null) 'pushReplies': finalPushReplies,
      if (finalDiscoverableByEmail != null) 'discoverableByEmail': finalDiscoverableByEmail,
      if (finalAnalyticsEnabled != null) 'analyticsEnabled': finalAnalyticsEnabled,
      if (finalPrivacy != null) 'privacy': finalPrivacy,
      if (finalAllowLocationChecks != null) 'allowLocationChecks': finalAllowLocationChecks,
    };
    final response = await _apiClient.patch(
      '/profile/settings',
      body: payload,
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException(
        'Settings update response must be a JSON object.',
      );
    }
    return ProfileSettings.fromJson(response);
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.post(
      '/profile/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    if (response is Map<String, dynamic>) {
      final msg = response['message']?.toString();
      if (msg != null && msg.trim().isNotEmpty) return msg.trim();
    }
    return 'Password changed successfully.';
  }

  Future<void> deleteAccount() async {
    await _apiClient.delete('/profile/account');
  }

  Future<Uint8List?> getAvatar() async {
    final response = await _apiClient.getRaw('/profile/avatar');
    if (response.statusCode == 404 || response.statusCode == 204) {
      return null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    if (response.bodyBytes.isEmpty) {
      return null;
    }

    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('application/json')) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final url = (decoded['avatarUrl'] ??
                  decoded['url'] ??
                  decoded['avatar'] ??
                  (decoded['data'] is Map ? decoded['data']['avatarUrl'] : null))
              ?.toString();
          if (url != null && url.isNotEmpty) {
            final fetched = await http.get(Uri.parse(url));
            if (fetched.statusCode == 200) {
              return fetched.bodyBytes;
            }
          }
        }
      } catch (_) {}
    }

    return response.bodyBytes;
  }

  Future<Uint8List?> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async {
    final mediaType = _resolveMediaType(filename);
    try {
      final file = http.MultipartFile.fromBytes(
        'avatar',
        bytes,
        filename: filename,
        contentType: mediaType,
      );
      final response = await _apiClient.postMultipart(
        '/profile/avatar',
        files: [file],
      );
      return await _processAvatarResponse(response, bytes);
    } on ApiException catch (e) {
      if (e.statusCode == 400 || e.statusCode == 422) {
        final file = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: mediaType,
        );
        final response = await _apiClient.postMultipart(
          '/profile/avatar',
          files: [file],
        );
        return await _processAvatarResponse(response, bytes);
      }
      rethrow;
    }
  }

  Future<Uint8List?> _processAvatarResponse(
    Object? response,
    List<int> bytes,
  ) async {
    if (response is Uint8List && response.isNotEmpty) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      final avatarUrl = (response['avatarUrl'] ??
              response['url'] ??
              response['avatar'] ??
              (response['data'] is Map ? response['data']['avatarUrl'] : null))
          ?.toString();
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        try {
          final fetched = await http.get(Uri.parse(avatarUrl));
          if (fetched.statusCode == 200) {
            return fetched.bodyBytes;
          }
        } catch (_) {}
      }
    }

    return Uint8List.fromList(bytes);
  }

  Future<void> deleteAvatar() async {
    await _apiClient.delete('/profile/avatar');
  }

  Future<BlockedUserListResponse> getBlockedUsers() async {
    try {
      final response = await _apiClient.get('/users/blocked');
      return BlockedUserListResponse.fromJson(response);
    } catch (_) {
      try {
        final response = await _apiClient.get('/account/blocked');
        return BlockedUserListResponse.fromJson(response);
      } catch (_) {
        return const BlockedUserListResponse(items: []);
      }
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _apiClient.delete('/users/blocked/$userId');
    } catch (_) {
      try {
        await _apiClient.post('/users/unblock', body: {'userId': userId});
      } catch (_) {}
    }
  }

  static MediaType _resolveMediaType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
