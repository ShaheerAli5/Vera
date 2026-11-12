import 'dart:typed_data';

import '../../data/models/forgot_password_result.dart';
import '../../data/models/login_result.dart';
import '../../data/models/logout_result.dart';
import '../../data/models/profile_settings.dart';
import '../../data/models/resend_otp_result.dart';
import '../../data/models/reset_password_result.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/verify_email_result.dart';
import '../entities/registered_user.dart';

abstract interface class AccountRepository {
  Future<RegisteredUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<LoginResult> login({
    required String email,
    required String password,
    String? deviceName,
  });

  Future<VerifyEmailResult> verifyEmail({
    required String email,
    required String code,
  });

  Future<ForgotPasswordResult> forgotPassword({
    required String email,
  });

  Future<ResetPasswordResult> resetPassword({
    required String email,
    required String code,
    required String password,
  });

  Future<ResendOtpResult> resendOtp({
    required String email,
    required String purpose,
  });

  Future<LogoutResult> logout({
    required String refreshToken,
  });

  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
    String? deviceName,
  });

  Future<UserProfile> getProfile();

  Future<Uint8List?> getAvatar();

  Future<UserProfile> updateProfile({
    required String name,
  });

  Future<Uint8List?> uploadAvatar({
    required List<int> bytes,
    required String filename,
  });

  Future<void> deleteAvatar();

  Future<ProfileSettings> getSettings();

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
  });

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> deleteAccount();
}
