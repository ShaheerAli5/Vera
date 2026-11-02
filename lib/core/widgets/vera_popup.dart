import 'package:flutter/material.dart';

/// Displays Vera's compact, branded feedback popup above the current screen.
abstract final class VeraPopup {
  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_rounded,
    String? title,
    Color accent = const Color(0xFF83F3D1),
  }) {
    final scale = MediaQuery.sizeOf(context).width / 393;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.fromLTRB(
            16 * scale,
            0,
            16 * scale,
            16 * scale + MediaQuery.paddingOf(context).bottom,
          ),
          content: Container(
            padding: EdgeInsets.all(14 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFF17182D),
              borderRadius: BorderRadius.circular(18 * scale),
              border: Border.all(color: accent.withValues(alpha: .38)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .12),
                  blurRadius: 24 * scale,
                  offset: Offset(0, 8 * scale),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: .28),
                  blurRadius: 18 * scale,
                  offset: Offset(0, 6 * scale),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38 * scale,
                  height: 38 * scale,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  child: Icon(icon, color: accent, size: 21 * scale),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: title == null
                      ? Text(
                          message,
                          style: TextStyle(
                            color: const Color(0xFFF7F5FF),
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: const Color(0xFFF7F5FF),
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 3 * scale),
                            Text(
                              message,
                              style: TextStyle(
                                color: const Color(0xFFB8B7D0),
                                fontSize: 12 * scale,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
