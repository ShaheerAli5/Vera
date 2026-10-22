import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/theme.dart';
import 'home_screen.dart';

class MomentReadyScreen extends StatelessWidget {
  const MomentReadyScreen({
    super.key,
    this.title = 'Midnight at the tower',
    this.recipient = 'Everyone (Public)',
    this.unlockTime = "Opens when you're at Tokyo Tower",
    this.isPublic = true,
    this.shareUrl = 'https://vera.app/m/90401549',
  });

  final String title;
  final String recipient;
  final String unlockTime;
  final bool isPublic;
  final String shareUrl;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = (screen.width / 390).clamp(.82, 1.12);

    final subtitleText = isPublic
        ? 'Your public moment was sent for review. It appears in Discover once approved.'
        : 'Recipients must sign in and accept the invitation before they can see anything.';

    return Scaffold(
      backgroundColor: VeraTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Body Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24 * scale, 40 * scale, 24 * scale, 16 * scale),
                child: Column(
                  children: [
                    // Top Glowing Checkmark Circle
                    Container(
                      width: 80 * scale,
                      height: 80 * scale,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF231742),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x669044FB),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 36 * scale,
                        ),
                      ),
                    ),

                    SizedBox(height: 28 * scale),

                    // Title: Your moment is ready!
                    Text(
                      'Your moment is ready!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF7F5FF),
                        fontSize: 22 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10 * scale),

                    // Subtitle
                    Text(
                      subtitleText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFA6A6C1),
                        fontSize: 13 * scale,
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: 28 * scale),

                    // Moment Summary Card
                    Container(
                      width: 345 * scale,
                      padding: EdgeInsets.all(12 * scale),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17182D),
                        borderRadius: BorderRadius.circular(16 * scale),
                        border: Border.all(
                          color: const Color(0x1AFFFFFF),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Media Thumbnail Box
                          Container(
                            width: 64 * scale,
                            height: 64 * scale,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12 * scale),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFC026D3),
                                  Color(0xFF1E1B4B),
                                  Color(0xFF0284C7),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(width: 14 * scale),

                          // Details Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3 * scale),
                                Text(
                                  'For: $recipient',
                                  style: TextStyle(
                                    color: const Color(0xFFA6A6C1),
                                    fontSize: 12 * scale,
                                  ),
                                ),
                                SizedBox(height: 2 * scale),
                                Text(
                                  unlockTime,
                                  style: TextStyle(
                                    color: const Color(0xFFA6A6C1),
                                    fontSize: 12 * scale,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!isPublic) ...[
                      SizedBox(height: 20 * scale),

                      // Share URL Bar & Copy Button Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48 * scale,
                              padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141527),
                                borderRadius: BorderRadius.circular(12 * scale),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                shareUrl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF8A8EB3),
                                  fontSize: 13.5 * scale,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * scale),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: shareUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Link copied to clipboard!')),
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 68 * scale,
                              height: 48 * scale,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D1E36),
                                borderRadius: BorderRadius.circular(12 * scale),
                              ),
                              child: Center(
                                child: Text(
                                  'Copy',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5 * scale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Action Buttons Area
            Container(
              decoration: const BoxDecoration(
                color: Color(0x59090A17),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(44),
                  bottomRight: Radius.circular(44),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24 * scale,
                16 * scale,
                24 * scale,
                24 * scale,
              ),
              child: isPublic
                  ? SizedBox(
                      width: 345 * scale,
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
                                builder: (_) => const HomeScreen(initialTabIndex: 2),
                              ),
                              (route) => false,
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            'View in Your moments',
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Primary Button: Share Link
                        SizedBox(
                          width: 345 * scale,
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
                                Clipboard.setData(ClipboardData(text: shareUrl));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Link copied to clipboard!')),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                'Share link',
                                style: TextStyle(
                                  fontSize: 14 * scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 12 * scale),

                        // Secondary Button: View in Your moments
                        SizedBox(
                          width: 345 * scale,
                          height: 48 * scale,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF17182D),
                              side: const BorderSide(
                                color: Color(0x22FFFFFF),
                                width: 1,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              'View in Your moments',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
