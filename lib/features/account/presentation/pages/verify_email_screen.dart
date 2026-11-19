import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../home/presentation/pages/home_screen.dart';
import '../../data/datasources/account_remote_data_source.dart';
import '../../data/repositories/account_repository_impl.dart';
import 'sign_in_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const int _otpLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  int _resendCountdown = 60;
  Timer? _timer;
  bool _isSubmitting = false;

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
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _isComplete =>
      _controllers.every((c) => c.text.trim().isNotEmpty);

  Future<void> _resendCode() async {
    if (_resendCountdown > 0 || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final repository = AccountRepositoryImpl(
        AccountRemoteDataSource(ApiClientScope.of(context)),
      );
      final result = await repository.resendOtp(
        email: widget.email.trim(),
        purpose: 'verify-email',
      );

      _startCountdown(60);
      for (var c in _controllers) {
        c.clear();
      }
      if (_focusNodes.isNotEmpty) {
        _focusNodes.first.requestFocus();
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

  Future<void> _verify() async {
    if (_isSubmitting || !_isComplete) return;

    final otp = _controllers.map((c) => c.text.trim()).join();
    if (otp.length != _otpLength) return;

    setState(() => _isSubmitting = true);
    try {
      final repository = AccountRepositoryImpl(
        AccountRemoteDataSource(ApiClientScope.of(context)),
      );
      final result = await repository.verifyEmail(
        email: widget.email.trim(),
        code: otp,
      );
      if (!mounted) return;
      if (result.token != null && result.token!.isNotEmpty) {
        final apiClient = ApiClientScope.of(context);
        await apiClient.setTokens(
          authToken: result.token,
          refreshToken: result.refreshToken,
          userRole: UserRole.user.value,
        );
        await PushNotificationService.instance.initialize(apiClient);
        if (!mounted) return;
        VeraPopup.show(
          context,
          title: 'Email verified',
          message: result.message.isNotEmpty
              ? result.message
              : 'Your account has been successfully created and verified.',
          icon: Icons.check_circle_rounded,
          accent: VeraTheme.success,
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        VeraPopup.show(
          context,
          title: 'Email verified',
          message: result.message.isNotEmpty
              ? result.message
              : 'Your email has been verified. Please sign in to continue.',
          icon: Icons.check_circle_rounded,
          accent: VeraTheme.success,
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => SignInScreen(initialEmail: widget.email.trim()),
          ),
          (route) => false,
        );
      }
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
        400 => 'Invalid code',
        404 => 'Account not found',
        409 => 'Already verified',
        422 => 'Invalid code',
        429 => 'Please wait a moment',
        _ => 'Verification failed',
      };

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
                                icon: Icon(Icons.arrow_back,
                                    size: 20 * scale, color: Colors.white),
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
                                  'Verify your email',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26 * scale,
                                    height: 1.15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10 * scale),
                                Text(
                                  'We have sent a 6-digit verification code to\n${widget.email}',
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
                          SizedBox(height: 36 * scale),
                          SizedBox(
                            width: contentWidth,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(_otpLength, (index) {
                                return SizedBox(
                                  width: boxWidth,
                                  height: boxHeight,
                                  child: TextField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
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
                                            _controllers[index + i].text =
                                                digits[i];
                                          }
                                          final nextIndex =
                                              (index + digits.length)
                                                  .clamp(0, _otpLength - 1);
                                          _focusNodes[nextIndex].requestFocus();
                                        } else if (digits.isNotEmpty) {
                                          _controllers[index].text =
                                              digits[digits.length - 1];
                                          if (index < _otpLength - 1) {
                                            _focusNodes[index + 1]
                                                .requestFocus();
                                          }
                                        }
                                      } else if (value.isNotEmpty &&
                                          index < _otpLength - 1) {
                                        _focusNodes[index + 1].requestFocus();
                                      } else if (value.isEmpty && index > 0) {
                                        _focusNodes[index - 1].requestFocus();
                                      }
                                      setState(() {});
                                      if (_isComplete) {
                                        _verify();
                                      }
                                    },
                                  ),
                                );
                              }),
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
                                onPressed: (_isComplete && !_isSubmitting)
                                    ? _verify
                                    : null,
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
                                        'Verify email',
                                        style: TextStyle(
                                          fontSize: 14 * scale,
                                          height: 1,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24 * scale),
                          SizedBox(
                            width: contentWidth,
                            child: Center(
                              child: _resendCountdown > 0
                                  ? Text(
                                      'Resend code in ${_formatCountdown(_resendCountdown)}',
                                      style: TextStyle(
                                        color: const Color(0xFF6E6E8F),
                                        fontSize: 13 * scale,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed:
                                          _isSubmitting ? null : _resendCode,
                                      child: Text(
                                        'Resend code',
                                        style: TextStyle(
                                          color: VeraTheme.purpleBright,
                                          fontSize: 13 * scale,
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
