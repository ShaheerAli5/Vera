import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../home/presentation/pages/home_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const int _otpLength = 4;
  final List<TextEditingController> _controllers = List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  int _resendCountdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() => _resendCountdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
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

  bool get _isComplete => _controllers.every((c) => c.text.trim().isNotEmpty);

  void _verify() {
    if (!_isComplete) return;
    VeraPopup.show(
      context,
      title: 'Email verified',
      message: 'Your account has been successfully created and verified.',
      icon: Icons.check_circle_rounded,
      accent: VeraTheme.success,
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (route) => false,
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
                  padding: EdgeInsets.fromLTRB(24 * scale, 8 * scale, 24 * scale, 32 * scale),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: VeraResponsive.formMaxWidth),
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
                                icon: Icon(Icons.arrow_back, size: 20 * scale, color: Colors.white),
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
                                  'We have sent a 4-digit verification code to\n${widget.email}',
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
                                  width: 64 * scale,
                                  height: 64 * scale,
                                  child: TextField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    maxLength: 1,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22 * scale,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    cursorColor: const Color(0xFFB45BFF),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: const Color(0xFF19192D),
                                      contentPadding: EdgeInsets.zero,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16 * scale),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16 * scale),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16 * scale),
                                        borderSide: BorderSide(
                                          color: const Color(0xFFA346FF),
                                          width: 1.5 * scale,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value.isNotEmpty && index < _otpLength - 1) {
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
                                onPressed: _isComplete ? _verify : null,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
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
                                      'Resend code in 0:${_resendCountdown.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: const Color(0xFF6E6E8F),
                                        fontSize: 13 * scale,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: () {
                                        _startCountdown();
                                        VeraPopup.show(
                                          context,
                                          title: 'Code resent',
                                          message: 'A new verification code has been sent to your email.',
                                          icon: Icons.mark_email_read_rounded,
                                          accent: VeraTheme.info,
                                        );
                                      },
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
