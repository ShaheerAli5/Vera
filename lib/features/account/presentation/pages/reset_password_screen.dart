import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/account_remote_data_source.dart';
import '../../data/repositories/account_repository_impl.dart';
import 'sign_in_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const int _otpLength = 6;
  final List<TextEditingController> _otpControllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown(60);
  }

  void _startCountdown([int seconds = 60]) {
    setState(() => _resendCountdown = seconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatCountdown(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0 || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final repository = AccountRepositoryImpl(
        AccountRemoteDataSource(ApiClientScope.of(context)),
      );
      final result = await repository.resendOtp(
        email: widget.email.trim(),
        purpose: 'reset-password',
      );

      _startCountdown(60);
      for (var c in _otpControllers) {
        c.clear();
      }
      if (_otpFocusNodes.isNotEmpty) {
        _otpFocusNodes.first.requestFocus();
      }

      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Code resent',
        message: result.message,
        icon: Icons.mark_email_read_rounded,
        accent: VeraTheme.info,
      );
    } on ApiException catch (error) {
      final match = RegExp(r'wait\s+(\d+)\s+seconds', caseSensitive: false)
          .firstMatch(error.message);
      if (match != null) {
        final remaining = int.tryParse(match.group(1) ?? '');
        if (remaining != null && remaining > 0) {
          _startCountdown(remaining);
        }
      } else {
        _startCountdown(60);
      }
      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Could not resend',
        message: error.message,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    } catch (_) {
      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Connection error',
        message: 'Please check your connection and try again.',
        icon: Icons.wifi_off_rounded,
        accent: VeraTheme.warning,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_isSubmitting) return;

    if (_otpControllers.any((c) => c.text.trim().isEmpty)) {
      _showValidation(
        'Code required',
        'Please enter the full 6-digit verification code.',
        Icons.pin_outlined,
      );
      return;
    }

    final otp = _otpControllers.map((c) => c.text.trim()).join();

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.length < 8) {
      _showValidation(
        'Password too short',
        'New password must be at least 8 characters long.',
        Icons.lock_outline_rounded,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _showValidation(
        'Passwords mismatch',
        'Passwords do not match. Please verify and try again.',
        Icons.lock_reset_rounded,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repository = AccountRepositoryImpl(
        AccountRemoteDataSource(ApiClientScope.of(context)),
      );
      final result = await repository.resetPassword(
        email: widget.email.trim(),
        code: otp,
        password: newPassword,
      );

      if (!mounted) return;
      if (result.accessToken != null && result.accessToken!.isNotEmpty) {
        await ApiClientScope.of(context).setAuthToken(result.accessToken);
        if (!mounted) return;
      }
      VeraPopup.show(
        context,
        title: 'Password reset',
        message: result.message.isNotEmpty
            ? result.message
            : 'Your password has been reset successfully. Please sign in.',
        icon: Icons.check_circle_rounded,
        accent: VeraTheme.success,
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      VeraPopup.show(
        context,
        title: _errorTitle(error.statusCode),
        message: error.message,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Unexpected server response',
        message: error.message,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    } catch (_) {
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
        400 => 'Invalid or expired code',
        404 => 'Account not found',
        422 => 'Invalid details',
        429 => 'Please wait a moment',
        _ => 'Reset failed',
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

    final spacing = 8.0 * scale;
    final totalSpacing = spacing * (_otpLength - 1);
    final boxWidth = ((contentWidth - totalSpacing) / _otpLength)
        .clamp(40.0 * scale, 52.0 * scale);
    final boxHeight = (boxWidth * 1.18).clamp(50.0 * scale, 64.0 * scale);

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
                                  'Reset password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26 * scale,
                                    height: 1.15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8 * scale),
                                Text(
                                  'We have sent a 6-digit code to\n${widget.email}',
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
                          SizedBox(height: 32 * scale),
                          SizedBox(
                            width: contentWidth,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(_otpLength, (index) {
                                return SizedBox(
                                  width: boxWidth,
                                  height: boxHeight,
                                  child: TextField(
                                    controller: _otpControllers[index],
                                    focusNode: _otpFocusNodes[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    enabled: !_isSubmitting,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(_otpLength),
                                    ],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20 * scale,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    cursorColor: const Color(0xFFB45BFF),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: const Color(0xFF19192D),
                                      contentPadding: EdgeInsets.zero,
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14 * scale),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14 * scale),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14 * scale),
                                        borderSide: BorderSide(
                                          color: const Color(0xFFA346FF),
                                          width: 1.5 * scale,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value.length > 1) {
                                        final digits = value.replaceAll(
                                            RegExp(r'\D'), '');
                                        if (digits.length > 1) {
                                          for (int i = 0;
                                              i < digits.length &&
                                                  (index + i) < _otpLength;
                                              i++) {
                                            _otpControllers[index + i].text =
                                                digits[i];
                                          }
                                          final nextIndex =
                                              (index + digits.length)
                                                  .clamp(0, _otpLength - 1);
                                          _otpFocusNodes[nextIndex].requestFocus();
                                        } else if (digits.isNotEmpty) {
                                          _otpControllers[index].text =
                                              digits[digits.length - 1];
                                          if (index < _otpLength - 1) {
                                            _otpFocusNodes[index + 1]
                                                .requestFocus();
                                          }
                                        }
                                      } else if (value.isNotEmpty &&
                                          index < _otpLength - 1) {
                                        _otpFocusNodes[index + 1].requestFocus();
                                      } else if (value.isEmpty && index > 0) {
                                        _otpFocusNodes[index - 1].requestFocus();
                                      }
                                      setState(() {});
                                    },
                                  ),
                                );
                              }),
                            ),
                          ),
                          SizedBox(height: 16 * scale),
                          SizedBox(
                            width: contentWidth,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _resendCountdown > 0
                                  ? Text(
                                      'Resend in ${_formatCountdown(_resendCountdown)}',
                                      style: TextStyle(
                                        color: const Color(0xFF6E6E8F),
                                        fontSize: 12 * scale,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed:
                                          _isSubmitting ? null : _resendCode,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Resend code',
                                        style: TextStyle(
                                          color: VeraTheme.purpleBright,
                                          fontSize: 12 * scale,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 20 * scale),
                          SizedBox(
                            width: contentWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _PasswordField(
                                  label: 'New password',
                                  hint: 'At least 8 characters',
                                  controller: _newPasswordController,
                                  obscureText: _obscureNewPassword,
                                  enabled: !_isSubmitting,
                                  scale: scale,
                                  onToggleVisibility: () => setState(() =>
                                      _obscureNewPassword =
                                          !_obscureNewPassword),
                                ),
                                SizedBox(height: 16 * scale),
                                _PasswordField(
                                  label: 'Confirm password',
                                  hint: 'Repeat your new password',
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  enabled: !_isSubmitting,
                                  scale: scale,
                                  onToggleVisibility: () => setState(() =>
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 32 * scale),
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
                                onPressed: _isSubmitting ? null : _resetPassword,
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
                                        'Reset password',
                                        style: TextStyle(
                                          fontSize: 14 * scale,
                                          height: 1,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscureText,
    required this.scale,
    required this.onToggleVisibility,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final double scale;
  final VoidCallback onToggleVisibility;
  final bool enabled;

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
            controller: controller,
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
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFFA6A6C1),
                  size: 18 * scale,
                ),
                onPressed: onToggleVisibility,
              ),
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
