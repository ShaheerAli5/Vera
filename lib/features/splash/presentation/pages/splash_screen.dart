import 'package:flutter/material.dart';

import '../../../account/presentation/pages/create_account_screen.dart';
import '../../../account/presentation/pages/sign_in_screen.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/vera_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = (screen.width / 393).clamp(.82, 1.12);
    final actionsWidth = (screen.width - 48 * scale).clamp(0.0, 345 * scale);
    final compact = screen.height < 740;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/vera_splash_background.jpg', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x3302041A), Colors.transparent, Color(0x55020412)],
                stops: [0, .48, 1],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned(
                      top: constraints.maxHeight * .105,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SizedBox(
                          width: 264.04 * scale,
                          height: 235.01 * scale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 190 * scale,
                                height: 88 * scale,
                                child: const CustomPaint(painter: InfinityPainter()),
                              ),
                              SizedBox(height: 12 * scale),
                              VeraLogo(height: 32 * scale),
                              SizedBox(height: 12 * scale),
                              Text(
                                "There's always\nsomething waiting for you...",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFF8F6FF),
                                  fontSize: 12 * scale,
                                  height: 1.48,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: .1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: compact ? 14 : 20 * scale,
                      child: Center(
                        child: SizedBox(
                          width: actionsWidth,
                          height: 104 * scale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: actionsWidth,
                                height: 48 * scale,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: VeraTheme.buttonGradient,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const CreateAccountScreen(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                                      shape: const StadiumBorder(),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Get started',
                                      style: TextStyle(
                                        fontSize: 12 * scale,
                                        height: 1,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                              SizedBox(
                                width: actionsWidth,
                                height: 48 * scale,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const SignInScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFE5E1F4),
                                    padding: EdgeInsets.fromLTRB(
                                      24 * scale,
                                      12.5 * scale,
                                      24 * scale,
                                      13.5 * scale,
                                    ),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    textStyle: TextStyle(
                                      fontSize: 12 * scale,
                                      height: 1,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: const Text('Sign in'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class InfinityPainter extends CustomPainter {
  const InfinityPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .5, size.height * .52)
      ..cubicTo(size.width * .36, size.height * .36, size.width * .20, -size.height * .04,
          size.width * .08, size.height * .30)
      ..cubicTo(-size.width * .04, size.height * .67, size.width * .17, size.height * 1.08,
          size.width * .37, size.height * .79)
      ..cubicTo(size.width * .49, size.height * .62, size.width * .67, size.height * .02,
          size.width * .84, size.height * .19)
      ..cubicTo(size.width * 1.05, size.height * .40, size.width * .81, size.height * 1.07,
          size.width * .62, size.height * .82)
      ..cubicTo(size.width * .57, size.height * .75, size.width * .53, size.height * .65,
          size.width * .5, size.height * .52);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * .20
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFF9652FF), Color(0xFFE342F3), Color(0xFFA600FF), Color(0xFF6014FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant InfinityPainter oldDelegate) => false;
}
