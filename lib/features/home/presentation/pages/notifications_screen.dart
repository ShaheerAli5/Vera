import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedTab = 0; // 0: All, 1: Unread, 2: Read

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Your moment is now unclockd',
      'body': 'Your Tokyo Tower moment is ready to reveal. Discover what was capture',
      'time': '2 min ago',
      'section': 'TODAY',
      'isRead': false,
      'image': 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?q=80&w=200',
    },
    {
      'title': 'Your moment is now unclockd',
      'body': 'Your Tokyo Tower moment is ready to reveal. Discover what was capture',
      'time': '1 hour ago',
      'section': 'TODAY',
      'isRead': false,
      'image': 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?q=80&w=200',
    },
    {
      'title': 'Your moment is now unclockd',
      'body': 'Your Tokyo Tower moment is ready to reveal. Discover what was capture',
      'time': '3 hours ago',
      'section': 'TODAY',
      'isRead': true,
      'image': 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?q=80&w=200',
    },
    {
      'title': 'Your moment is now unclockd',
      'body': 'Your Tokyo Tower moment is ready to reveal. Discover what was capture',
      'time': 'Yesterday',
      'section': 'YESTERDAY',
      'isRead': true,
      'image': 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?q=80&w=200',
    },
    {
      'title': 'Your moment is now unclockd',
      'body': 'Your Tokyo Tower moment is ready to reveal. Discover what was capture',
      'time': '2 min ago',
      'section': 'YESTERDAY',
      'isRead': true,
      'image': 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?q=80&w=200',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 393).clamp(.82, 1.12);

    List<Map<String, dynamic>> filteredNotifications = _notifications.where((n) {
      if (_selectedTab == 1) return !(n['isRead'] as bool);
      if (_selectedTab == 2) return n['isRead'] as bool;
      return true;
    }).toList();

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var n in filteredNotifications) {
      String section = n['section'] as String;
      grouped.putIfAbsent(section, () => []).add(n);
    }

    return Scaffold(
      backgroundColor: VeraTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            SizedBox(
              height: 56 * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20 * scale),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tightFor(
                        width: 40 * scale,
                        height: 40 * scale,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            color: const Color(0xFFF7F5FF),
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 40 * scale),
                  ],
                ),
              ),
            ),

            // Tabs
            Row(
              children: [
                _buildTab('All', 0, scale),
                _buildTab('Unread', 1, scale),
                _buildTab('Read', 2, scale),
              ],
            ),
            Divider(height: 1, thickness: 1, color: const Color(0x223F4356)),

            // Content List
            Expanded(
              child: grouped.isEmpty
                  ? Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(
                          color: const Color(0xFFA6A6C1),
                          fontSize: 14 * scale,
                        ),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                          24 * scale, 16 * scale, 24 * scale, 48 * scale),
                      children: grouped.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                color: const Color(0xFFA6A6C1),
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 12 * scale),
                            ...entry.value.map((n) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 12 * scale),
                                padding: EdgeInsets.all(12 * scale),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF121326),
                                  borderRadius: BorderRadius.circular(16 * scale),
                                  border: Border.all(
                                    color: const Color(0x333F4356),
                                    width: scale,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 16,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12 * scale),
                                      child: Image.network(
                                        n['image']!,
                                        width: 48 * scale,
                                        height: 48 * scale,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, error, stackTrace) => Container(
                                          width: 48 * scale,
                                          height: 48 * scale,
                                          color: const Color(0xFF6B42FF),
                                          child: const Icon(Icons.notifications,
                                              color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12 * scale),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n['title']!,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14 * scale,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 8 * scale),
                                          Text(
                                            n['body']!,
                                            style: TextStyle(
                                              color: const Color(0xFFA6A6C1),
                                              fontSize: 12 * scale,
                                              height: 1.2,
                                            ),
                                          ),
                                          SizedBox(height: 8 * scale),
                                          Text(
                                            n['time']!,
                                            style: TextStyle(
                                              color: const Color(0xFF6E6E8F),
                                              fontSize: 11 * scale,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            SizedBox(height: 16 * scale),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index, double scale) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 44 * scale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFA6A6C1),
                  fontSize: 14 * scale,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  height: 2 * scale,
                  decoration: BoxDecoration(
                    gradient: VeraTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
