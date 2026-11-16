import 'package:flutter/material.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../account/data/datasources/account_remote_data_source.dart';
import '../../../account/data/repositories/account_repository_impl.dart';
import 'admin_main_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  String _email = '';
  String _password = '';
  bool _obscurePassword = true;
  bool _rememberDevice = true;
  bool _isSubmitting = false;

  Future<void> _signIn() async {
    if (_isSubmitting) return;

    if (_email.trim().isEmpty || _password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClientScope.of(context);
      final repository = AccountRepositoryImpl(
        AccountRemoteDataSource(apiClient),
      );
      final result = await repository.adminLogin(
        email: _email.trim(),
        password: _password,
      );

      // Set initial auth tokens to allow backend profile request
      await apiClient.setTokens(
        authToken: result.accessToken,
        refreshToken: result.refreshToken,
      );

      // Fetch user's complete profile directly from backend API
      final profile = await repository.getProfile();
      final parsedRole = UserRole.parse(profile.role ?? result.user.role);

      if (parsedRole == UserRole.user) {
        await apiClient.clearTokens();
        throw const ApiException(
          statusCode: 403,
          message:
              'Access denied. This account is not authorized for Admin Login.',
        );
      }

      if (parsedRole != UserRole.owner) {
        await apiClient.clearTokens();
        throw const ApiException(
          statusCode: 403,
          message: 'Access denied. Unknown or invalid user role.',
        );
      }

      await apiClient.setTokens(
        authToken: result.accessToken,
        refreshToken: result.refreshToken,
        userRole: UserRole.owner.value,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AdminMainScreen()),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Access Denied',
        message: error.message,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    } catch (e) {
      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Could not connect',
        message:
            e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), ''),
        icon: Icons.wifi_off_rounded,
        accent: VeraTheme.warning,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0919),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 32 * scale),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24 * scale,
                    16 * scale,
                    24 * scale,
                    32 * scale,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 342 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand Header: VERA (34px, light, 14% letter spacing) + ADMIN badge
                          SizedBox(
                            height: 40 * scale,
                            child: Row(
                              children: [
                                if (Navigator.of(context).canPop()) ...[
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).maybePop(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      Icons.arrow_back,
                                      size: 22 * scale,
                                      color: const Color(0xFFF7F5FF),
                                    ),
                                  ),
                                  SizedBox(width: 12 * scale),
                                ],
                                Text(
                                  'VERA',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: const Color(0xFFF7F5FF),
                                    fontSize: 34 * scale,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 34 * 0.14 * scale,
                                    height: 40 / 34,
                                  ),
                                ),
                                SizedBox(width: 10 * scale),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10 * scale,
                                    vertical: 4 * scale,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x299451FF),
                                    borderRadius:
                                        BorderRadius.circular(999 * scale),
                                  ),
                                  child: Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: const Color(0xFF9451FF),
                                      fontSize: 10 * scale,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40 * scale),

                          // Title: Admin sign in (28px, SemiBold, #F7F5FF)
                          Text(
                            'Admin sign in',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: const Color(0xFFF7F5FF),
                              fontSize: 28 * scale,
                              fontWeight: FontWeight.w600,
                              height: 36 / 28,
                              letterSpacing: 0,
                            ),
                          ),
                          SizedBox(height: 8 * scale),

                          // Subtitle: Manage Vera... (14px, Regular, #A2A5C2)
                          Text(
                            'Manage Vera, review reported moments and keep the community safe.',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: const Color(0xFFA2A5C2),
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w400,
                              height: 22 / 14,
                              letterSpacing: 0,
                            ),
                          ),
                          SizedBox(height: 24 * scale),

                          // Work email Field Frame
                          _InputField(
                            label: 'Work email',
                            hint: 'admin@vera.app',
                            onChanged: (value) =>
                                setState(() => _email = value),
                            scale: scale,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isSubmitting,
                            suffixIcon: Icon(
                              Icons.mail_outline_rounded,
                              color: const Color(0xFFA2A5C2),
                              size: 20 * scale,
                            ),
                          ),
                          SizedBox(height: 16 * scale),

                          // Password Field Frame
                          _InputField(
                            label: 'Password',
                            hint: '•••••••••',
                            onChanged: (value) =>
                                setState(() => _password = value),
                            scale: scale,
                            obscureText: _obscurePassword,
                            enabled: !_isSubmitting,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFFA2A5C2),
                                size: 20 * scale,
                              ),
                            ),
                          ),
                          SizedBox(height: 16 * scale),

                          // Options Row (Space-between: Remember device + Forgot password?)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(
                                  () => _rememberDevice = !_rememberDevice,
                                ),
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      width: 18 * scale,
                                      height: 18 * scale,
                                      decoration: BoxDecoration(
                                        color: _rememberDevice
                                            ? const Color(0xFF9451FF)
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(5 * scale),
                                        border: Border.all(
                                          color: _rememberDevice
                                              ? const Color(0xFF9451FF)
                                              : const Color(0x33FFFFFF),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: _rememberDevice
                                          ? Icon(
                                              Icons.check_rounded,
                                              size: 13 * scale,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 8 * scale),
                                    Text(
                                      'Remember this device',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: const Color(0xFFA2A5C2),
                                        fontSize: 13 * scale,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Contact system administrator to reset password.',
                                      ),
                                    ),
                                  );
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: const Color(0xFFC9A8FF),
                                    fontSize: 13 * scale,
                                    fontWeight: FontWeight.w500,
                                    height: 18 / 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24 * scale),

                          // Primary Button (342 Fill x 52 Fixed, Radius 999px, Gradient: #9451FF, #557AFB, #58C3F4)
                          SizedBox(
                            width: double.infinity,
                            height: 52 * scale,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF9451FF),
                                    Color(0xFF557AFB),
                                    Color(0xFF58C3F4),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius:
                                    BorderRadius.circular(999 * scale),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x669451FF),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: _isSubmitting ? null : _signIn,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24 * scale,
                                  ),
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
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Sign in',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: const Color(0xFFF7F5FF),
                                          fontSize: 16 * scale,
                                          fontWeight: FontWeight.w500,
                                          height: 24 / 16,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16 * scale),

                          // Footer Note (12px, Medium, #A2A5C2, Center)
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Admin access is logged and needs two-step verification.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: const Color(0xFFA2A5C2),
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w500,
                                height: 18 / 12,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label (14px, Regular, #F7F5FF, height 22px)
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: const Color(0xFFF7F5FF),
            fontSize: 14 * scale,
            fontWeight: FontWeight.w400,
            height: 22 / 14,
          ),
        ),
        SizedBox(height: 8 * scale),
        // Input Box (Height 52px, Radius 18px, Fill 3% white, Border 1.2px 20% white)
        SizedBox(
          height: 52 * scale,
          child: TextField(
            onChanged: onChanged,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: enabled,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: const Color(0xFFF7F5FF),
              fontSize: 15 * scale,
              fontWeight: FontWeight.w400,
              height: 22 / 15,
            ),
            cursorColor: const Color(0xFFC9A8FF),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Outfit',
                color: const Color(0xFFA2A5C2),
                fontSize: 15 * scale,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: const Color(0x08FFFFFF), // 3% opacity #FFFFFF
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 14 * scale,
              ),
              suffixIcon: suffixIcon != null
                  ? Padding(
                      padding: EdgeInsets.only(right: 16 * scale),
                      child: suffixIcon,
                    )
                  : null,
              suffixIconConstraints: BoxConstraints(
                minWidth: 20 * scale,
                minHeight: 20 * scale,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18 * scale),
                borderSide: const BorderSide(
                  color: Color(0x33FFFFFF), // 20% opacity #FFFFFF
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18 * scale),
                borderSide: const BorderSide(
                  color: Color(0x33FFFFFF), // 20% opacity #FFFFFF
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18 * scale),
                borderSide: const BorderSide(
                  color: Color(0xFFC9A8FF),
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


