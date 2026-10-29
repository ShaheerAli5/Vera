import 'dart:ui';
import 'package:flutter/material.dart';

class VeraBottomNavBar extends StatelessWidget {
  const VeraBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.scale,
    this.onCreateMomentTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final double scale;
  final VoidCallback? onCreateMomentTap;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      height: (88 * scale) + bottomPad,
      decoration: BoxDecoration(
        color: const Color(0x59090A17),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(44 * scale),
          bottomRight: Radius.circular(44 * scale),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(44 * scale),
          bottomRight: Radius.circular(44 * scale),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24 * scale,
              16 * scale,
              24 * scale,
              24 * scale + bottomPad,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xD91B152E),
                  Color(0xF2120D22),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(44 * scale),
                bottomRight: Radius.circular(44 * scale),
              ),
              border: Border(
                top: BorderSide(
                  color: Color(0x1FFFFFFF),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavItem(
                      icon: Image.asset(
                        'assets/images/nav_home.png',
                        fit: BoxFit.contain,
                        color: selectedIndex == 0
                            ? const Color(0xFFE291FF)
                            : null,
                        colorBlendMode: selectedIndex == 0
                            ? BlendMode.srcIn
                            : BlendMode.dst,
                      ),
                      onTap: () => onTap(0),
                      scale: scale,
                    ),
                    SizedBox(width: 24 * scale),
                    _NavItem(
                      icon: selectedIndex == 1
                          ? CustomPaint(
                              painter: SearchIconPainter(isSelected: true),
                            )
                          : Image.asset('assets/images/nav_search.png',
                              fit: BoxFit.contain),
                      onTap: () => onTap(1),
                      scale: scale,
                    ),
                    SizedBox(width: 24 * scale),
                    _NavItem(
                      icon: selectedIndex == 2
                          ? CustomPaint(
                              painter: MessageIconPainter(isSelected: true),
                            )
                          : Image.asset('assets/images/nav_messages.png',
                              fit: BoxFit.contain),
                      onTap: () => onTap(2),
                      scale: scale,
                    ),
                    SizedBox(width: 24 * scale),
                    _NavItem(
                      icon: selectedIndex == 3
                          ? Image.asset('assets/images/nav_profile.png',
                              fit: BoxFit.contain)
                          : CustomPaint(
                              painter: ProfileIconPainter(isSelected: false),
                            ),
                      onTap: () => onTap(3),
                      scale: scale,
                    ),
                  ],
                ),

                // Figma create button asset (48x48)
                GestureDetector(
                  onTap: onCreateMomentTap,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 48 * scale,
                    height: 48 * scale,
                    child: Image.asset(
                      'assets/images/nav_create_moment.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.onTap,
    required this.scale,
  });

  final Widget icon;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 24 * scale,
        height: 24 * scale,
        child: icon,
      ),
    );
  }
}

/// Custom Painter for Home Icon with active gradient fill & door slot cut-out
class HomeIconPainter extends CustomPainter {
  final bool isSelected;

  HomeIconPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.12;

    final path = Path();
    path.moveTo(w * 0.5 - r, h * 0.15);
    path.quadraticBezierTo(w * 0.5, h * 0.08, w * 0.5 + r, h * 0.15);
    path.lineTo(w * 0.88 - r, h * 0.40);
    path.quadraticBezierTo(w * 0.92, h * 0.44, w * 0.92, h * 0.52);
    path.lineTo(w * 0.92, h * 0.82);
    path.quadraticBezierTo(w * 0.92, h * 0.92, w * 0.82, h * 0.92);
    path.lineTo(w * 0.18, h * 0.92);
    path.quadraticBezierTo(w * 0.08, h * 0.92, w * 0.08, h * 0.82);
    path.lineTo(w * 0.08, h * 0.52);
    path.quadraticBezierTo(w * 0.08, h * 0.44, w * 0.12, h * 0.40);
    path.close();

    if (isSelected) {
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8E37FF), Color(0xFFC857FF)],
        ).createShader(Offset.zero & size);
      canvas.drawPath(path, fillPaint);

      // Inner white vertical door slot
      final doorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final doorRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.72),
          width: w * 0.10,
          height: h * 0.26,
        ),
        Radius.circular(w * 0.05),
      );
      canvas.drawRRect(doorRRect, doorPaint);
    } else {
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = const Color(0xFFC68CFF)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant HomeIconPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}

/// Custom Painter for Search Icon
class SearchIconPainter extends CustomPainter {
  final bool isSelected;

  SearchIconPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final color = isSelected ? const Color(0xFFD88CFF) : const Color(0xFFC68CFF);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color
      ..strokeCap = StrokeCap.round;

    final center = Offset(w * 0.42, h * 0.42);
    final radius = w * 0.32;
    canvas.drawCircle(center, radius, paint);

    final dx = radius * 0.7071;
    final dy = radius * 0.7071;
    final start = Offset(center.dx + dx, center.dy + dy);
    final end = Offset(w * 0.88, h * 0.88);
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant SearchIconPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}

/// Custom Painter for Message Icon with horizontal lines inside
class MessageIconPainter extends CustomPainter {
  final bool isSelected;

  MessageIconPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokeColor = isSelected ? const Color(0xFFD88CFF) : const Color(0xFFC68CFF);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.84, h * 0.72),
      Radius.circular(w * 0.22),
    );

    final path = Path()..addRRect(rrect);

    final tailPath = Path()
      ..moveTo(w * 0.12, h * 0.72)
      ..lineTo(w * 0.08, h * 0.90)
      ..lineTo(w * 0.28, h * 0.80);

    if (isSelected) {
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8E37FF), Color(0xFFC857FF)],
        ).createShader(Offset.zero & size);
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawPath(tailPath, fillPaint);
    } else {
      canvas.drawPath(path, strokePaint);
      canvas.drawPath(tailPath, strokePaint);
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = isSelected
          ? const Color(0xFF542075)
          : strokeColor.withAlpha(230)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.28, h * 0.34),
      Offset(w * 0.68, h * 0.34),
      linePaint,
    );

    canvas.drawLine(
      Offset(w * 0.28, h * 0.52),
      Offset(w * 0.54, h * 0.52),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant MessageIconPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}

/// Custom Painter for Profile Icon
class ProfileIconPainter extends CustomPainter {
  final bool isSelected;

  ProfileIconPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokeColor = isSelected ? const Color(0xFFD88CFF) : const Color(0xFFC68CFF);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = strokeColor
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(w * 0.5, h * 0.30), w * 0.20, paint);

    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.80),
      width: w * 0.72,
      height: h * 0.44,
    );

    canvas.drawArc(bodyRect, 3.14159, 3.14159, false, paint);
  }

  @override
  bool shouldRepaint(covariant ProfileIconPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}
