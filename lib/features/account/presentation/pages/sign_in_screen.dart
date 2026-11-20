import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/auth/auth_diagnostics.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../admin/presentation/pages/admin_main_screen.dart';
import '../../../home/presentation/pages/home_screen.dart';
import '../../data/datasources/account_remote_data_source.dart';
import '../../data/repositories/account_repository_impl.dart';
import 'create_account_screen.dart';
import 'forgot_password_screen.dart';
import 'verify_email_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String _email = '';
  String _password = '';
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  Future<void> _signIn() async {
    if (_isSubmitting) return;

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.trim())) {
      _showValidation(
        'Valid email required',
        'Please enter a valid email address.',
        Icons.email_outlined,
      );
      return;
    }

    if (_password.isEmpty) {
      _showValidation(
        'Password required',
        'Please enter your password.',
        Icons.lock_outline_rounded,
      );
      return;
    }

    var stage = 'login_request';
    final timer = Stopwatch()..start();
    logAuthFlow('login_started', {'stage': stage});
    setState(() => _isSubmitting = true);
    try {
      final apiClient = ApiClientScope.of(context);
      final repository = AccountRepositoryImpl(
        AccountRemoteDataSource(apiClient),
      );
      final result = await repository.login(
        email: _email.trim(),
        password: _password,
        deviceName: defaultTargetPlatform.name,
      );

      logAuthFlow('login_response', {
        'responseRole': diagnosticRole(result.user.role),
        'hasAccessToken': result.accessToken.isNotEmpty,
        'hasRefreshToken': result.refreshToken.isNotEmpty,
        'hasUser': result.user.id.isNotEmpty,
        'elapsedMs': timer.elapsedMilliseconds,
      });
      if (result.accessToken.trim().isEmpty) {
        throw const FormatException('Login response is missing an access token.');
      }

      stage = 'save_tokens';
      await apiClient.setTokens(
        authToken: result.accessToken,
        refreshToken: result.refreshToken,
      );

      var parsedRole = UserRole.parse(result.user.role);
      if (parsedRole == null && (result.user.role?.trim().isEmpty ?? true)) {
        stage = 'profile_role';
        logAuthFlow('login_profile_role_requested', {'stage': stage});
        final profile = await repository.getProfile();
        parsedRole = UserRole.parse(profile.role);
      }
      if (parsedRole == null) {
        logAuthFlow('login_role_denied', {'decision': 'deny_invalid_role'});
        await apiClient.clearTokens();
        throw const ApiException(
          statusCode: 403,
          message: 'Access denied. Unknown or invalid user role.',
        );
      }

      stage = 'save_role';
      await apiClient.setTokens(userRole: parsedRole.value);
      logAuthFlow('login_session_saved', {
        'savedRole': diagnosticRole(apiClient.userRole),
        'hasAccessToken': apiClient.authToken?.isNotEmpty == true,
        'hasRefreshToken': apiClient.refreshToken?.isNotEmpty == true,
      });
      PushNotificationService.instance.initialize(apiClient).catchError((_) {});

      if (!mounted) return;

      VeraPopup.show(
        context,
        title: 'Welcome back',
        message: 'Signed in successfully.',
        icon: Icons.check_circle_rounded,
        accent: VeraTheme.success,
      );

      stage = 'navigate_dashboard';
      logAuthFlow('login_navigation', {
        'destination': parsedRole.isOwner ? 'admin' : 'home',
        'savedRole': parsedRole.value, 'elapsedMs': timer.elapsedMilliseconds,
      });
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => parsedRole!.isOwner
            ? const AdminMainScreen() : const HomeScreen()),
        (route) => false,
      );
    } on ApiException catch (error) {
      logAuthFlow('login_failed', {
        'stage': stage, 'httpStatus': error.statusCode, 'errorType': 'api',
        'elapsedMs': timer.elapsedMilliseconds,
      });
      if (!mounted) return;
      if (error.message.toLowerCase().contains('not verified') ||
          error.message.toLowerCase().contains('unverified')) {
        VeraPopup.show(
          context,
          title: 'Email not verified',
          message: 'Please enter your verification code to complete sign in.',
          icon: Icons.mark_email_unread_rounded,
          accent: VeraTheme.warning,
        );
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VerifyEmailScreen(email: _email.trim()),
          ),
        );
        return;
      }
      VeraPopup.show(
        context,
        title: _errorTitle(error.statusCode),
        message: error.message,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    } on FormatException catch (error) {
      logAuthFlow('login_failed', {
        'stage': stage, 'errorType': 'response_format',
        'elapsedMs': timer.elapsedMilliseconds,
      });
      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Unexpected server response',
        message: error.message,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    } catch (error) {
      logAuthFlow('login_failed', {
        'stage': stage, 'errorType': error.runtimeType.toString(),
        'elapsedMs': timer.elapsedMilliseconds,
      });
      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Could not connect',
        message: 'Please check your connection and try again.',
        icon: Icons.wifi_off_rounded,
        accent: VeraTheme.warning,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _errorTitle(int statusCode) => switch (statusCode) {
        400 => 'Invalid details',
        401 => 'Invalid email or password',
        403 => 'Access denied',
        404 => 'Account not found',
        429 => 'Please wait a moment',
        _ => 'Sign in failed',
      };

  void _showValidation(String title, String message, IconData icon) {
    VeraPopup.show(
      context,
      title: title,
      message: message,
      icon: icon,
      accent: VeraTheme.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);
    final contentWidth = VeraResponsive.contentWidth(
      screen.width,
      maxWidth: VeraResponsive.formMaxWidth,
      horizontalPadding: 24 * scale,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF080914),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 32 * scale),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      24 * scale, 8 * scale, 24 * scale, 32 * scale),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: VeraResponsive.formMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 32 * scale,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).maybePop(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  Icons.arrow_back,
                                  size: 20 * scale,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 28 * scale),
                          SizedBox(
                            width: contentWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26 * scale,
                                    height: 1.15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8 * scale),
                                Text(
                                  "Sign in to see what's waiting for you.",
                                  style: TextStyle(
                                    color: const Color(0xFFA6A6C1),
                                    fontSize: 14 * scale,
                                    height: 1.4,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 28 * scale),
                          SizedBox(
                            width: contentWidth,
                            child: Row(
                              children: [
                                Expanded(child: _SocialButton.apple(scale: scale)),
                                SizedBox(width: 12 * scale),
                                Expanded(child: _SocialButton.google(scale: scale)),
                              ],
                            ),
                          ),
                          SizedBox(height: 20 * scale),
                          SizedBox(
                            width: contentWidth,
                            child: Text(
                              'or continue with email',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFA6A6C1),
                                fontSize: 12 * scale,
                                height: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: 24 * scale),
                          SizedBox(
                            width: contentWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InputField(
                                  label: 'Email',
                                  hint: 'name@example.com',
                                  onChanged: (value) =>
                                      setState(() => _email = value),
                                  scale: scale,
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: !_isSubmitting,
                                ),
                                SizedBox(height: 16 * scale),
                                _InputField(
                                  label: 'Password',
                                  hint: 'Enter your password',
                                  onChanged: (value) =>
                                      setState(() => _password = value),
                                  scale: scale,
                                  obscureText: _obscurePassword,
                                  enabled: !_isSubmitting,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFFA6A6C1),
                                      size: 18 * scale,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                SizedBox(height: 10 * scale),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isSubmitting
                                        ? null
                                        : () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    ForgotPasswordScreen(
                                                  initialEmail: _email.trim(),
                                                ),
                                              ),
                                            );
                                          },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: const Color(0xFFA6A6C1),
                                    ),
                                    child: Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        fontSize: 12 * scale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24 * scale),
                          SizedBox(
                            width: contentWidth,
                            height: 48 * scale,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: VeraTheme.buttonGradient,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: const [
                                  BoxShadow(
                                    color: VeraTheme.glowPurple,
                                    blurRadius: 22,
                                    spreadRadius: 1,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: _isSubmitting ? null : _signIn,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24 * scale),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: _isSubmitting
                                    ? SizedBox(
                                        width: 20 * scale,
                                        height: 20 * scale,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Sign in',
                                        style: TextStyle(
                                          fontSize: 14 * scale,
                                          height: 1,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16 * scale),
                          SizedBox(
                            width: contentWidth,
                            height: 30 * scale,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const CreateAccountScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFA6A6C1),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                textStyle: TextStyle(
                                  fontSize: 13 * scale,
                                  height: 1,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              child: const Text('New here? Create account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.hint,
    required this.onChanged,
    required this.scale,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.suffixIcon,
  });

  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final double scale;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFFA6A6C1),
            fontSize: 12 * scale,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        SizedBox(height: 8 * scale),
        SizedBox(
          height: 48 * scale,
          child: TextField(
            onChanged: onChanged,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: enabled,
            style: TextStyle(color: Colors.white, fontSize: 14 * scale),
            cursorColor: const Color(0xFFB45BFF),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: const Color(0xFF535370),
                fontSize: 14 * scale,
              ),
              filled: true,
              fillColor: const Color(0xFF161626),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 14 * scale,
              ),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * scale),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * scale),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * scale),
                borderSide: BorderSide(
                  color: const Color(0xFFA346FF),
                  width: 1 * scale,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.scale, required this.child});

  final double scale;
  final Widget child;

  factory _SocialButton.apple({required double scale}) {
    return _SocialButton(
      scale: scale,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/apple_logo.png',
            width: 18 * scale,
            height: 20 * scale,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 8 * scale),
          Text(
            'Apple',
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  factory _SocialButton.google({required double scale}) {
    return _SocialButton(
      scale: scale,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/google_logo.png',
            width: 18 * scale,
            height: 18 * scale,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 8 * scale),
          Text(
            'Google',
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48 * scale,
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => const HomeScreen(),
            ),
            (route) => false,
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF161626),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14 * scale),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8 * scale),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: child,
      ),
    );
  }
}
