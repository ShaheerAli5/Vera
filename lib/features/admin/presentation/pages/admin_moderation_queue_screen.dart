import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import 'admin_review_moment_screen.dart';

class AdminModerationQueueScreen extends StatelessWidget {
  const AdminModerationQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16 * scale, 16 * scale, 16 * scale, 8 * scale),
          child: Text(
            'Moderation Queue (45)',
            style: TextStyle(
              color: const Color(0xFFF7F5FF),
              fontSize: 24 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: -.3,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16 * scale),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48 * scale,
                  child: TextField(
                    style: TextStyle(color: Colors.white, fontSize: 14 * scale),
                    cursorColor: const Color(0xFF9044FB),
                    decoration: InputDecoration(
                      hintText: 'Search moments...',
                      hintStyle: TextStyle(color: const Color(0xFF535370), fontSize: 14 * scale),
                      filled: true,
                      fillColor: const Color(0xFF161626),
                      prefixIcon: Icon(Icons.search, color: const Color(0xFF535370), size: 20 * scale),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12 * scale),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12 * scale),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12 * scale),
                        borderSide: BorderSide(
                          color: const Color(0xFF9044FB),
                          width: 1 * scale,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 14 * scale),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12 * scale),
              Container(
                height: 48 * scale,
                width: 48 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFF161626),
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.filter_list, color: const Color(0xFFC68CFF), size: 24 * scale),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 100 * scale),
            itemCount: 10,
            itemBuilder: (context, index) {
              return _buildQueueItem(context, scale, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItem(BuildContext context, double scale, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminReviewMomentScreen(momentId: 'moment_$index'),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16 * scale),
        padding: EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF161626),
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: const Color(0xFF282842)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80 * scale,
              height: 120 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFF1B152E),
                borderRadius: BorderRadius.circular(12 * scale),
                image: const DecorationImage(
                  image: NetworkImage('https://picsum.photos/200/300'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Icon(Icons.play_circle_outline, color: Colors.white.withValues(alpha: 0.8), size: 32 * scale),
              ),
            ),
            SizedBox(width: 16 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '@user_$index',
                        style: TextStyle(color: Colors.white, fontSize: 16 * scale, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9044FB).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4 * scale),
                        ),
                        child: Text(
                          'Pending',
                          style: TextStyle(color: const Color(0xFFC057FF), fontSize: 10 * scale, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * scale),
                  Text(
                    'This is a dummy caption for moment #$index. It contains some text that might need moderation.',
                    style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 13 * scale, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16 * scale),
                  Text(
                    'Uploaded: Oct 24, 2023 14:${10 + index}',
                    style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 11 * scale),
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
