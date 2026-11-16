import 'dart:typed_data';

import '../../domain/entities/registered_user.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_data_source.dart';
import '../models/blocked_user_model.dart';
import '../models/forgot_password_result.dart';
import '../models/login_result.dart';
import '../models/logout_result.dart';
import '../models/profile_settings.dart';
import '../models/resend_otp_result.dart';
import '../models/reset_password_result.dart';
import '../models/user_profile.dart';
import '../models/verify_email_result.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._remoteDataSource);

  final AccountRemoteDataSource _remoteDataSource;

  @override
  Future<RegisteredUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _remoteDataSource.register(
      name: name,
      email: email,
      password: password,
    );
    return result.user;
  }

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
    String? deviceName,
  }) {
    return _remoteDataSource.login(
      email: email,
      password: password,
      deviceName: deviceName,
    );
  }

  @override
  Future<LoginResult> adminLogin({
    required String email,
    required String password,
  }) {
    return _remoteDataSource.adminLogin(
      email: email,
      password: password,
    );
  }

  @override
  Future<VerifyEmailResult> verifyEmail({
    required String email,
    required String code,
  }) {
    return _remoteDataSource.verifyEmail(
      email: email,
      code: code,
    );
  }

  @override
  Future<ForgotPasswordResult> forgotPassword({
    required String email,
  }) {
    return _remoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<ResetPasswordResult> resetPassword({
    required String email,
    required String code,
    required String password,
  }) {
    return _remoteDataSource.resetPassword(
      email: email,
      code: code,
      password: password,
    );
  }

  @override
  Future<ResendOtpResult> resendOtp({
    required String email,
    required String purpose,
  }) {
    return _remoteDataSource.resendOtp(
      email: email,
      purpose: purpose,
    );
  }

  @override
  Future<LogoutResult> logout({
    required String refreshToken,
  }) {
    return _remoteDataSource.logout(refreshToken: refreshToken);
  }

  @override
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
    String? deviceName,
  }) {
    return _remoteDataSource.refreshToken(
      refreshToken: refreshToken,
      deviceName: deviceName,
    );
  }

  @override
  Future<UserProfile> getProfile() {
    return _remoteDataSource.getProfile();
  }

  @override
  Future<Uint8List?> getAvatar() {
    return _remoteDataSource.getAvatar();
  }

  @override
  Future<UserProfile> updateProfile({
    required String name,
  }) {
    return _remoteDataSource.updateProfile(name: name);
  }

  @override
  Future<Uint8List?> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) {
    return _remoteDataSource.uploadAvatar(bytes: bytes, filename: filename);
  }

  @override
  Future<void> deleteAvatar() {
    return _remoteDataSource.deleteAvatar();
  }

  @override
  Future<ProfileSettings> getSettings() {
    return _remoteDataSource.getSettings();
  }

  @override
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
  }) {
    return _remoteDataSource.updateSettings(
      settings: settings,
      language: language,
      timezone: timezone,
      pushInvitations: pushInvitations,
      pushUnlocks: pushUnlocks,
      pushReplies: pushReplies,
      discoverableByEmail: discoverableByEmail,
      analyticsEnabled: analyticsEnabled,
      privacy: privacy,
      allowLocationChecks: allowLocationChecks,
    );
  }

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<BlockedUserListResponse> getBlockedUsers() {
    return _remoteDataSource.getBlockedUsers();
  }

  @override
  Future<void> unblockUser(String userId) {
    return _remoteDataSource.unblockUser(userId);
  }

  @override
  Future<void> deleteAccount() {
    return _remoteDataSource.deleteAccount();
  }
}
