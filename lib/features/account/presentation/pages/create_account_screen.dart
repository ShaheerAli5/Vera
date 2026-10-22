import 'package:flutter/material.dart';

import 'sign_in_screen.dart';
import '../../../home/presentation/pages/home_screen.dart';
import '../../../../shared/widgets/vera_logo.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  String _name = '';
  String _email = '';
  bool _acceptedTerms = false;

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
                            icon: Icon(Icons.arrow_back, size: 20 * scale, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 25 * scale),
                      SizedBox(
                        width: contentWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to',
                              style: TextStyle(
                                color: const Color(0xFFF4F2FF),
                                fontSize: 21 * scale,
                                height: 1.15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6 * scale),
                            VeraLogo(height: 22 * scale),
                            SizedBox(height: 12 * scale),
                            Text(
                              'Create an account and send your first\nmoment.',
                              style: TextStyle(
                                color: const Color(0xFFA6A6C1),
                                fontSize: 14 * scale,
                                height: 1.7,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20 * scale),
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
                      SizedBox(height: 16 * scale),
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
                      SizedBox(height: 20 * scale),
                      SizedBox(
                        width: contentWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InputField(
                              label: 'Name',
                              hint: 'Your name',
                              onChanged: (value) => setState(() => _name = value),
                              scale: scale,
                              textCapitalization: TextCapitalization.words,
                            ),
                            SizedBox(height: 16 * scale),
                            _InputField(
                              label: 'Email',
                              hint: 'name@example.com',
                              onChanged: (value) => setState(() => _email = value),
                              scale: scale,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: 16 * scale),
                            SizedBox(
                              height: 28 * scale,
                              child: InkWell(
                                onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                                borderRadius: BorderRadius.circular(8 * scale),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24 * scale,
                                      height: 24 * scale,
                                      decoration: BoxDecoration(
                                        color: _acceptedTerms
                                            ? const Color(0xFFA346FF)
                                            : const Color(0xFF19192D),
                                        borderRadius: BorderRadius.circular(7 * scale),
                                        boxShadow: _acceptedTerms
                                            ? const [
                                                BoxShadow(
                                                  color: Color(0x554F1C89),
                                                  blurRadius: 10,
                                                  offset: Offset(0, 3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: _acceptedTerms
                                          ? Icon(Icons.check, size: 17 * scale, color: Colors.white)
                                          : null,
                                    ),
                                    SizedBox(width: 10 * scale),
                                    Expanded(
                                      child: Text(
                                        'I accept the Terms of Use and Privacy Policy.',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: const Color(0xFFA6A6C1),
                                          fontSize: 12 * scale,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
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
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9044FB), Color(0xFFC057FF), Color(0xFF9044FB)],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x664F1C89),
                                blurRadius: 22,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: _canSubmit
                                ? () {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const HomeScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                : null,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Create account',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                height: 1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ),
                      ),
                      SizedBox(height: 8 * scale),
                      SizedBox(
                        width: contentWidth,
                        height: 30 * scale,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const SignInScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFA6A6C1),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: TextStyle(
                              fontSize: 12 * scale,
                              height: 1,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: const Text('Already have an account? Sign in'),
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

  bool get _canSubmit =>
      _name.trim().isNotEmpty &&
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.trim()) &&
      _acceptedTerms;
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.hint,
    required this.onChanged,
    required this.scale,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final double scale;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

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
            height: 1.2,
          ),
        ),
        SizedBox(height: 8 * scale),
        SizedBox(
          height: 48 * scale,
          child: TextField(
            onChanged: onChanged,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: TextStyle(color: Colors.white, fontSize: 14 * scale),
            cursorColor: const Color(0xFFB45BFF),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: const Color(0xFF9292B1), fontSize: 14 * scale),
              filled: true,
              fillColor: const Color(0xFF19192D),
              contentPadding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 14 * scale),
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
                borderSide: BorderSide(color: const Color(0xFFA346FF), width: 1 * scale),
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
          Text('Apple', style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w500)),
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
          Text('Google', style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w500)),
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
          backgroundColor: const Color(0xFF191923),
          shape: const StadiumBorder(),
          padding: EdgeInsets.symmetric(horizontal: 8 * scale),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: child,
      ),
    );
  }
}
