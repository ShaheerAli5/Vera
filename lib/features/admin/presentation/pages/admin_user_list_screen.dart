import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import 'admin_user_detail_screen.dart';

class AdminUserListScreen extends StatelessWidget {
  const AdminUserListScreen({super.key});

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
            'User Management',
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
                      hintText: 'Search by name or email...',
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
            itemCount: 15,
            itemBuilder: (context, index) {
              final isAdmin = index % 5 == 0;
              final isSuspended = index == 3;

              return _buildUserItem(context, scale, index, isAdmin, isSuspended);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserItem(BuildContext context, double scale, int index, bool isAdmin, bool isSuspended) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminUserDetailScreen(
              userId: 'user_$index',
              username: 'user_$index',
              isAdmin: isAdmin,
              isSuspended: isSuspended,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12 * scale),
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF161626),
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: const Color(0xFF282842)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24 * scale,
              backgroundColor: const Color(0xFF1B152E),
              child: Icon(Icons.person, color: const Color(0xFFC68CFF), size: 24 * scale),
            ),
            SizedBox(width: 16 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Name $index',
                    style: TextStyle(color: Colors.white, fontSize: 16 * scale, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    'user$index@example.com',
                    style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 13 * scale),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                  decoration: BoxDecoration(
                    color: isAdmin ? const Color(0xFF9044FB).withValues(alpha: 0.2) : const Color(0xFF38BDF8).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4 * scale),
                  ),
                  child: Text(
                    isAdmin ? 'Admin' : 'User',
                    style: TextStyle(color: isAdmin ? const Color(0xFFC057FF) : const Color(0xFF38BDF8), fontSize: 10 * scale, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isSuspended) ...[
                  SizedBox(height: 8 * scale),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4 * scale),
                    ),
                    child: Text(
                      'Suspended',
                      style: TextStyle(color: const Color(0xFFE53935), fontSize: 10 * scale, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
