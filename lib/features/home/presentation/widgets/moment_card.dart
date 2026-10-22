import 'dart:ui';
import 'package:flutter/material.dart';

import '../../domain/entities/moment.dart';

class MomentCard extends StatelessWidget {
  const MomentCard({
    super.key,
    required this.moment,
    required this.scale,
  });

  final Moment moment;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 310 * scale,
      margin: EdgeInsets.only(bottom: 16 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24 * scale),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24 * scale),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with Blur
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Image.network(
                moment.backgroundImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E2B45),
                        Color(0xFF0F172A),
                        Color(0xFF2C1338),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Dark gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x44000000),
                    Color(0x11000000),
                    Color(0x55000000),
                  ],
                ),
              ),
            ),

            // Top Floating User Badge (Frame 1618874368)
            Positioned(
              top: 14 * scale,
              left: 0,
              right: 0,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999 * scale),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      height: 52 * scale,
                      padding: EdgeInsets.fromLTRB(
                        12 * scale,
                        6 * scale,
                        12 * scale,
                        6 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x38FFFFFF),
                        borderRadius: BorderRadius.circular(999 * scale),
                        border: Border.all(
                          color: const Color(0x40FFFFFF),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 40 * scale,
                            height: 40 * scale,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.network(
                                moment.userAvatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFF6B42FF),
                                  child: Icon(
                                    Icons.person,
                                    size: 20 * scale,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * scale),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                moment.userName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13 * scale,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                ),
                              ),
                              SizedBox(height: 2 * scale),
                              Text(
                                moment.timeAgo,
                                style: TextStyle(
                                  color: const Color(0xFFE2E2F0),
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.w400,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Center Lock Badge OR Ready to Open Badge
            Center(
              child: moment.isReadyToOpen
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24 * scale),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16 * scale,
                            vertical: 8 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x3322C55E),
                            borderRadius: BorderRadius.circular(24 * scale),
                            border: Border.all(
                              color: const Color(0x664ADE80),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_open_rounded,
                                color: const Color(0xFF4ADE80),
                                size: 18 * scale,
                              ),
                              SizedBox(width: 6 * scale),
                              Text(
                                'Ready to open',
                                style: TextStyle(
                                  color: const Color(0xFF4ADE80),
                                  fontSize: 12.5 * scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(30 * scale),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 52 * scale,
                          height: 52 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0x4D000000),
                            border: Border.all(
                              color: const Color(0x4DFFFFFF),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 22 * scale,
                          ),
                        ),
                      ),
                    ),
            ),

            // Bottom Banner (Unlock Condition)
            Positioned(
              left: 10 * scale,
              right: 10 * scale,
              bottom: 10 * scale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18 * scale),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 * scale,
                      vertical: 10 * scale,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xDFC057FF),
                          Color(0xBF8032C8),
                          Color(0xDF4A1980),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18 * scale),
                      border: Border.all(
                        color: const Color(0x33FFFFFF),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        // White Circular Icon Badge
                        Container(
                          width: 36 * scale,
                          height: 36 * scale,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            moment.unlockType == MomentUnlockType.location
                                ? Icons.location_on_rounded
                                : Icons.access_time_filled_rounded,
                            color: const Color(0xFF9044FB),
                            size: 20 * scale,
                          ),
                        ),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: Text(
                            moment.unlockCondition,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5 * scale,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                        SizedBox(width: 8 * scale),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18 * scale,
                        ),
                      ],
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
