import 'package:flutter/material.dart';

/// Official brand logo widget for VERA using the exact PNG asset from Figma.
class VeraLogo extends StatelessWidget {
  const VeraLogo({
    super.key,
    this.height,
    this.width,
    this.fontSize,
    this.color,
  });

  final double? height;
  final double? width;
  final double? fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? fontSize ?? 28.0;
    final effectiveWidth = width ?? (effectiveHeight * 5.08);

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: Image.asset(
        'assets/images/vera_logo.png',
        fit: BoxFit.contain,
        color: color,
      ),
    );
  }
}
