import 'package:flutter/widgets.dart';

/// Shared layout measurements based on Flutter's logical-pixel constraints.
abstract final class VeraResponsive {
  static const double tabletBreakpoint = 600;
  static const double contentMaxWidth = 680;
  static const double formMaxWidth = 480;

  static double scale(double availableWidth, {double designWidth = 393}) {
    return (availableWidth / designWidth).clamp(.82, 1.12).toDouble();
  }

  static double contentWidth(
    double availableWidth, {
    double maxWidth = contentMaxWidth,
    double horizontalPadding = 24,
  }) {
    return (availableWidth - horizontalPadding * 2)
        .clamp(0.0, maxWidth)
        .toDouble();
  }

  static bool isTablet(double availableWidth) =>
      availableWidth >= tabletBreakpoint;
}

/// Centers content at a readable width while preserving the full-width phone layout.
class VeraContent extends StatelessWidget {
  const VeraContent({
    super.key,
    required this.child,
    this.maxWidth = VeraResponsive.contentMaxWidth,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
