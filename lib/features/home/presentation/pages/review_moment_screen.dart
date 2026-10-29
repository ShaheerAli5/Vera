import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/moment.dart';
import 'home_screen.dart';
import 'moment_ready_screen.dart';

class ReviewMomentScreen extends StatelessWidget {
  const ReviewMomentScreen({
    super.key,
    this.title = 'A memory to keep',
    this.audience = 'Public',
    this.audienceSubtitle = 'Discoverable by other users',
    this.condition = 'October 25, 2026 · 9:00 AM',
    this.conditionSubtitle = 'Date & time (UTC+05:00)',
    this.isPrivate = false,
    this.recipientName,
  });

  final String title;
  final String audience;
  final String audienceSubtitle;
  final String condition;
  final String conditionSubtitle;
  final bool isPrivate;
  final String? recipientName;

  void _showUploadingModal(BuildContext context, double scale) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      isDismissible: false,
      isScrollControlled: true,
      builder: (modalContext) {
        return _UploadingModalContent(
          scale: scale,
          onComplete: () {
            Navigator.of(modalContext).pop();
            final isTimeLocked = conditionSubtitle.startsWith('Date & time');
            final createdMoment = Moment(
              id: 'sent_${DateTime.now().microsecondsSinceEpoch}',
              userName: 'You',
              userAvatarUrl:
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
              timeAgo: 'Just now',
              backgroundImageUrl:
                  'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?q=80&w=800',
              unlockCondition: isTimeLocked ? 'Opens $condition' : condition,
              unlockType: isTimeLocked
                  ? MomentUnlockType.time
                  : MomentUnlockType.location,
              sentBadgeTitle: isPrivate
                  ? 'To ${recipientName ?? 'John Travolta'}'
                  : 'To Everyone (public)',
              sentBadgeSubtitle: isPrivate
                  ? '2h ago'
                  : 'Pending Moderator review',
              isPublicSentMoment: !isPrivate,
            );
            HomeScreen.sentMoments.insert(0, createdMoment);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => MomentReadyScreen(
                  title: title,
                  recipient: isPrivate ? 'Anna' : 'Everyone (Public)',
                  unlockTime: condition,
                  isPublic: !isPrivate,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = (screen.width / 390).clamp(.82, 1.12);

    return Scaffold(
      backgroundColor: VeraTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (div.nav: 390 x 56)
            SizedBox(
              height: 56 * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                child: Row(
                  children: [
                    // Back Button Frame
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 48 * scale,
                        height: 48 * scale,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24 * scale),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18 * scale,
                          ),
                        ),
                      ),
                    ),

                    // Nav Item Frame
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 16 * scale),
                        child: SizedBox(
                          height: 24 * scale,
                          child: Center(
                            child: Text(
                              'Choose your condition',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFF7F5FF),
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w600,
                                height: 24 / 16,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Step Meta
                    SizedBox(
                      width: 64 * scale,
                      height: 22 * scale,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '3 of 3',
                          style: TextStyle(
                            color: VeraTheme.textSecondary,
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3-Step Progress Bar (All 3 Active)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 6 * scale),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3 * scale,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9044FB), Color(0xFF38BDF8)],
                        ),
                        borderRadius: BorderRadius.circular(2 * scale),
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Container(
                      height: 3 * scale,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9044FB), Color(0xFF38BDF8)],
                        ),
                        borderRadius: BorderRadius.circular(2 * scale),
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Container(
                      height: 3 * scale,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9044FB), Color(0xFF38BDF8)],
                        ),
                        borderRadius: BorderRadius.circular(2 * scale),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Review Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 16 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading Text (345 x 32)
                    SizedBox(
                      width: 345 * scale,
                      height: 32 * scale,
                      child: Text(
                        'Review your moment',
                        style: TextStyle(
                          color: const Color(0xFFF7F5FF),
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.w500,
                          height: 32 / 24,
                          letterSpacing: 0,
                        ),
                      ),
                    ),

                    SizedBox(height: 16 * scale),

                    // Card 1: Content Summary Card
                    Container(
                      width: 345 * scale,
                      height: 120 * scale,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail Preview Box
                          Container(
                            width: 96 * scale,
                            height: 96 * scale,
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
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 6 * scale,
                                  right: 6 * scale,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6 * scale,
                                      vertical: 2 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x99000000),
                                      borderRadius:
                                          BorderRadius.circular(10 * scale),
                                    ),
                                    child: Text(
                                      '0:12',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10 * scale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: 12 * scale),

                          // Content Information Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Content',
                                      style: TextStyle(
                                        color: const Color(0xFFA6A6C1),
                                        fontSize: 12 * scale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(
                                      Icons.mode_edit_outline_rounded,
                                      color: const Color(0xFFA6A6C1),
                                      size: 16 * scale,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2 * scale),
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2 * scale),
                                Text(
                                  'Video · 12 seconds',
                                  style: TextStyle(
                                    color: const Color(0xFFA6A6C1),
                                    fontSize: 12 * scale,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Add a message (optional)',
                                        style: TextStyle(
                                          color: const Color(0xFFA6A6C1),
                                          fontSize: 11.5 * scale,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: const Color(0xFFA6A6C1),
                                      size: 18 * scale,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12 * scale),

                    // Card 2: Audience Summary Card
                    Container(
                      width: 345 * scale,
                      height: 88 * scale,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.language_rounded,
                            color: Colors.white,
                            size: 20 * scale,
                          ),
                          SizedBox(width: 12 * scale),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Audience',
                                      style: TextStyle(
                                        color: const Color(0xFFA6A6C1),
                                        fontSize: 12 * scale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(
                                      Icons.mode_edit_outline_rounded,
                                      color: const Color(0xFFA6A6C1),
                                      size: 16 * scale,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2 * scale),
                                Text(
                                  audience,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2 * scale),
                                Text(
                                  audienceSubtitle,
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

                    SizedBox(height: 12 * scale),

                    // Card 3: Unlock Condition Summary Card
                    Container(
                      width: 345 * scale,
                      height: 88 * scale,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.white,
                            size: 20 * scale,
                          ),
                          SizedBox(width: 12 * scale),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Unlock condition',
                                      style: TextStyle(
                                        color: const Color(0xFFA6A6C1),
                                        fontSize: 12 * scale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(
                                      Icons.mode_edit_outline_rounded,
                                      color: const Color(0xFFA6A6C1),
                                      size: 16 * scale,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2 * scale),
                                Text(
                                  condition,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2 * scale),
                                Text(
                                  conditionSubtitle,
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
                  ],
                ),
              ),
            ),

            // Bottom Navigation Action Container
            Container(
              height: 88 * scale,
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
              child: SizedBox(
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
                    onPressed: () => _showUploadingModal(context, scale),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'Create moment',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadingModalContent extends StatefulWidget {
  const _UploadingModalContent({
    required this.scale,
    required this.onComplete,
  });

  final double scale;
  final VoidCallback onComplete;

  @override
  State<_UploadingModalContent> createState() => _UploadingModalContentState();
}

class _UploadingModalContentState extends State<_UploadingModalContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward().then((_) {
        if (mounted) {
          widget.onComplete();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24 * scale),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF16172E),
                  Color(0xFF0C0D1A),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24 * scale),
              ),
              border: Border.all(
                color: const Color(0xFF373657),
                width: 1,
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              24 * scale,
              20 * scale,
              24 * scale,
              24 * scale + MediaQuery.paddingOf(context).bottom,
            ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Uploading your moment...',
                    style: TextStyle(
                      color: const Color(0xFFF7F5FF),
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _controller.stop();
                      Navigator.of(context).pop();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32 * scale,
                      height: 32 * scale,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(18),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16 * scale,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24 * scale),

              // Animated Progress Bar
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: double.infinity,
                    height: 6 * scale,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1F36),
                      borderRadius: BorderRadius.circular(3 * scale),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _controller.value,
                        child: Container(
                          height: 6 * scale,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF9044FB),
                                Color(0xFFC057FF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3 * scale),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
