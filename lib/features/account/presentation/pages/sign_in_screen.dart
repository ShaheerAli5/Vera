import 'package:flutter/material.dart';

import 'create_account_screen.dart';
import '../../../../core/theme/theme.dart';
import '../../../home/presentation/pages/home_screen.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = (screen.width / 390).clamp(.82, 1.12);
    final contentWidth = (screen.width - 48 * scale).clamp(0.0, 342 * scale);

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
                                child: Builder(
                                  builder: (context) {
                                    return TextField(
                                      keyboardType: TextInputType.emailAddress,
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
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 28 * scale),
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
                                shape: const StadiumBorder(),
                                padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
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
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              );
            },
          ),
        ),
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
