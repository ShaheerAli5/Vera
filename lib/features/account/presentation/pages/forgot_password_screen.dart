import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/account_remote_data_source.dart';
import '../../data/repositories/account_repository_impl.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (_isSubmitting) return;

    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showValidation(
        'Valid email required',
        'Please enter a valid email address.',
        Icons.email_outlined,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repository = AccountRepositoryImpl(
        AccountRemoteDataSource(ApiClientScope.of(context)),
      );
      final result = await repository.forgotPassword(email: email);

      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Reset code sent',
        message: result.message,
        icon: Icons.mark_email_read_rounded,
        accent: VeraTheme.info,
      );

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResetPasswordScreen(email: email),
        ),
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
        400 => 'Invalid details',
        404 => 'Account not found',
        429 => 'Please wait a moment',
        _ => 'Request failed',
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
                                  'Forgot password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26 * scale,
                                    height: 1.15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8 * scale),
                                Text(
                                  "Enter your email address and we'll send you a 6-digit code to reset your password.",
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
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
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: !_isSubmitting,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14 * scale,
                                    ),
                                    cursorColor: const Color(0xFFB45BFF),
                                    decoration: InputDecoration(
                                      hintText: 'name@example.com',
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
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12 * scale),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12 * scale),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12 * scale),
                                        borderSide: BorderSide(
                                          color: const Color(0xFFA346FF),
                                          width: 1 * scale,
                                        ),
                                      ),
                                    ),
                                  ),
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
                                onPressed: _isSubmitting ? null : _sendResetCode,
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
                                        'Send reset code',
                                        style: TextStyle(
                                          fontSize: 14 * scale,
                                          height: 1,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20 * scale),
                          SizedBox(
                            width: contentWidth,
                            height: 30 * scale,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).maybePop(),
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
                              child: const Text('Remember password? Sign in'),
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
