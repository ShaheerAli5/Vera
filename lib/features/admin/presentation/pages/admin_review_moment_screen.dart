import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import 'admin_review_moment_media_screen.dart';

class AdminReviewMomentScreen extends StatelessWidget {
  final String momentId;

  const AdminReviewMomentScreen({super.key, required this.momentId});

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161626),
        title: const Text('Approve Moment', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to approve this moment?', style: TextStyle(color: Color(0xFFA2A5C2))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFFA2A5C2)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to queue
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Moment Approved.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9044FB)),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    String? reason = 'Inappropriate content';
    final reasons = ['Inappropriate content', 'Spam', 'Copyright violation', 'Other'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161626),
            title: const Text('Reject Moment', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select a reason for rejection:', style: TextStyle(color: Color(0xFFA2A5C2))),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: reason,
                  dropdownColor: const Color(0xFF161626),
                  style: const TextStyle(color: Colors.white),
                  items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() => reason = val),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF080914),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFFA2A5C2)))),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Go back to queue
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Moment Rejected: $reason')));
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
                child: const Text('Reject', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);

    return Scaffold(
      backgroundColor: VeraTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            SizedBox(
              height: 56 * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                child: Row(
                  children: [
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
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 16 * scale),
                        child: SizedBox(
                          height: 24 * scale,
                          child: Text(
                            'Review Moment',
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
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AdminReviewMomentMediaScreen(momentId: momentId)),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 400 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B152E),
                          borderRadius: BorderRadius.circular(24 * scale),
                          image: const DecorationImage(
                            image: NetworkImage('https://picsum.photos/400/600'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(16 * scale),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.play_arrow, color: Colors.white, size: 48 * scale),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24 * scale),
                    Text('Creator', style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 13 * scale)),
                    SizedBox(height: 8 * scale),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF1B152E),
                          child: const Icon(Icons.person, color: Color(0xFFC68CFF))
                        ),
                        SizedBox(width: 12 * scale),
                        Text('@awesome_user', style: TextStyle(color: Colors.white, fontSize: 16 * scale, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 24 * scale),
                    Text('Caption', style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 13 * scale)),
                    SizedBox(height: 8 * scale),
                    Text(
                      'This is the full caption of the moment that is being reviewed. It can be quite long and contain hashtags like #awesome #review.',
                      style: TextStyle(color: Colors.white, fontSize: 15 * scale, height: 1.4),
                    ),
                    SizedBox(height: 48 * scale),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48 * scale,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF161626),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0xFF373657)),
                              ),
                              child: TextButton(
                                onPressed: () => _showRejectDialog(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                ),
                                child: Text('Reject', style: TextStyle(color: Colors.white, fontSize: 14 * scale, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16 * scale),
                        Expanded(
                          child: SizedBox(
                            height: 48 * scale,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF9044FB), Color(0xFFC057FF)],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x889044FB),
                                    blurRadius: 28,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: () => _showApproveDialog(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                ),
                                child: Text('Approve', style: TextStyle(color: Colors.white, fontSize: 14 * scale, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
