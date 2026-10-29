import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/moment.dart';

class LockedMomentScreen extends StatelessWidget {
  const LockedMomentScreen({super.key, required this.moment});

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 393).clamp(.82, 1.12);

    return Scaffold(
      backgroundColor: const Color(0xFF080914),
      body: SafeArea(
        bottom: false,
        child: Builder(
          builder: (context) {
            final bottomPad = MediaQuery.paddingOf(context).bottom;
            return Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: 56 * scale,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).maybePop(),
                                icon: Icon(Icons.arrow_back_rounded,
                                    color: Colors.white, size: 22 * scale),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints.tightFor(
                                  width: 40 * scale,
                                  height: 40 * scale,
                                ),
                              ),
                            ),
                            Text(
                              'Locked moment',
                              style: TextStyle(
                                color: const Color(0xFFF7F5FF),
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                            24 * scale, 20 * scale, 24 * scale, (104 * scale) + bottomPad),
                        child: Column(
                          children: [
                            _LockedPreview(moment: moment, scale: scale),
                            SizedBox(height: 16 * scale),
                            _FromBadge(moment: moment, scale: scale),
                            SizedBox(height: 16 * scale),
                            _UnlockBanner(moment: moment, scale: scale),
                            SizedBox(height: 16 * scale),
                            _LockedContentPlaceholder(scale: scale),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: (88 * scale) + bottomPad,
                    padding: EdgeInsets.fromLTRB(
                        24 * scale, 16 * scale, 24 * scale, 24 * scale + bottomPad),
                    decoration: BoxDecoration(
                      color: const Color(0xD9090A17),
                      border: Border(
                        top: BorderSide(
                            color: const Color(0x334B3B70), width: 1 * scale),
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(44 * scale),
                      ),
                    ),
                    child: SizedBox(
                      height: 48 * scale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: VeraTheme.buttonGradient,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x665A26B8),
                              blurRadius: 20,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('This moment is still locked.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            "Check if it's ready",
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LockedPreview extends StatelessWidget {
  const _LockedPreview({required this.moment, required this.scale});

  final Moment moment;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20 * scale),
      child: SizedBox(
        width: double.infinity,
        height: 430 * scale,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Image.network(
                moment.backgroundImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF124552), Color(0xFF51352F)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0x22000000)),
            ),
            Center(
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 64 * scale,
                    height: 64 * scale,
                    color: const Color(0x66090A17),
                    child: Icon(Icons.lock_outline_rounded,
                        color: Colors.white, size: 26 * scale),
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

class _FromBadge extends StatelessWidget {
  const _FromBadge({required this.moment, required this.scale});

  final Moment moment;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52 * scale,
      padding: EdgeInsets.symmetric(horizontal: 12 * scale),
      decoration: BoxDecoration(
        color: const Color(0x33090A17),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x443F4356), width: 1 * scale),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.network(
              moment.userAvatarUrl,
              width: 36 * scale,
              height: 36 * scale,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF6B42FF),
                width: 36 * scale,
                height: 36 * scale,
                child: Icon(Icons.person, color: Colors.white, size: 18 * scale),
              ),
            ),
          ),
          SizedBox(width: 10 * scale),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From ${moment.userName}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w500,
                  )),
              SizedBox(height: 2 * scale),
              Text(moment.timeAgo,
                  style: TextStyle(
                    color: const Color(0xFFF7F5FF),
                    fontSize: 11 * scale,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnlockBanner extends StatelessWidget {
  const _UnlockBanner({required this.moment, required this.scale});

  final Moment moment;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20 * scale),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          height: 56 * scale,
          padding: EdgeInsets.symmetric(horizontal: 16 * scale),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xCC9451FF), Color(0x8058C3F4)],
            ),
            borderRadius: BorderRadius.circular(20 * scale),
            border: Border.all(color: const Color(0x55FFFFFF), width: 2 * scale),
          ),
          child: Row(
            children: [
              Icon(
                moment.unlockType == MomentUnlockType.location
                    ? Icons.location_on_rounded
                    : Icons.access_time_filled_rounded,
                color: Colors.white,
                size: 20 * scale,
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Text(
                  moment.unlockCondition,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedContentPlaceholder extends StatelessWidget {
  const _LockedContentPlaceholder({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 112 * scale,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0x14090A17),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: const Color(0x333F4356), width: scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonLine(width: .88, scale: scale),
          SizedBox(height: 10 * scale),
          _SkeletonLine(width: .62, scale: scale),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.scale});

  final double width;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: width,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFF20212D),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
