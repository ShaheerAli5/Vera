import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../home/data/models/notification_model.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/repositories/admin_repository_impl.dart';
import 'admin_moderation_queue_screen.dart';
import 'admin_report_detail_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_review_moment_screen.dart';
import 'admin_user_detail_screen.dart';
import 'admin_user_list_screen.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'All'; // All, Moments, Reports, Users

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAdminNotifications();
    });
  }

  Future<void> _fetchAdminNotifications({bool showLoading = true}) async {
    if (showLoading && _notifications.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));

      final response = await repo.getAdminNotifications();
      final items = List<NotificationModel>.from(response.items);

      // Synthesize actionable notifications from live backend data if items list is sparse
      final pendingMoments = await repo.getPendingMoments();
      final pendingReports = await repo.getReports(status: 'PENDING');

      for (final moment in pendingMoments.moments) {
        final existing = items.any((n) => n.data['momentId'] == moment.id || n.id == 'moment_${moment.id}');
        if (!existing) {
          items.add(NotificationModel(
            id: 'moment_${moment.id}',
            title: 'Moment Approval Required',
            body: '"${moment.title}" by @${moment.creatorName ?? 'User'} is waiting for admin review.',
            isRead: false,
            type: 'MOMENT_APPROVAL_REQUIRED',
            data: {'momentId': moment.id, 'category': 'MOMENT'},
            createdAt: moment.createdAt,
          ));
        }
      }

      for (final report in pendingReports.items) {
        final existing = items.any((n) => n.data['reportId'] == report.id || n.id == 'report_${report.id}');
        if (!existing) {
          final isUser = report.type == 'USER';
          final target = report.targetUserName ?? report.creatorName ?? 'User';
          items.add(NotificationModel(
            id: 'report_${report.id}',
            title: isUser ? 'User Reported' : 'Moment Reported',
            body: isUser
                ? '@$target was reported for ${report.reason.replaceAll('_', ' ')}.'
                : 'Moment reported by @${report.reporterName ?? 'User'} for ${report.reason.replaceAll('_', ' ')}.',
            isRead: false,
            type: isUser ? 'USER_REPORTED' : 'MOMENT_REPORTED',
            data: {
              'reportId': report.id,
              'momentId': report.momentId,
              'targetUserId': report.targetUserId,
              'category': isUser ? 'USER' : 'REPORT',
            },
            createdAt: report.createdAt != null ? DateTime.tryParse(report.createdAt!) : null,
          ));
        }
      }

      // Sort by newest first
      items.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      if (!mounted) return;
      setState(() {
        _notifications = items;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_notifications.isEmpty) {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        }
      });
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(isRead: true);
      }
    });

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      await repo.markAdminNotificationAsRead(notification.id);
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      await repo.markAllAdminNotificationsAsRead();
      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Notifications Updated',
        message: 'All admin notifications marked as read.',
        icon: Icons.check_circle_outline_rounded,
        accent: const Color(0xFF22C55E),
      );
    } catch (_) {}
  }

  void _onNotificationTap(NotificationModel notification) async {
    _markAsRead(notification);

    final type = (notification.type ?? '').toUpperCase();
    final data = notification.data;

    final momentId = data['momentId']?.toString();
    final reportId = data['reportId']?.toString();
    final targetUserId = data['targetUserId']?.toString() ?? data['userId']?.toString();

    if (type.contains('MOMENT') && momentId != null && momentId.isNotEmpty) {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AdminReviewMomentScreen(momentId: momentId),
        ),
      );
      _fetchAdminNotifications(showLoading: false);
    } else if (type.contains('REPORT') && reportId != null && reportId.isNotEmpty) {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AdminReportDetailScreen(reportId: reportId),
        ),
      );
      _fetchAdminNotifications(showLoading: false);
    } else if (type.contains('USER') && targetUserId != null && targetUserId.isNotEmpty) {
      final dummyUser = AdminUserModel(
        id: targetUserId,
        email: 'user@vera.app',
        displayName: 'User',
        role: 'USER',
        isActive: true,
        version: 1,
        createdAt: '',
        updatedAt: '',
      );
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => AdminUserDetailScreen(user: dummyUser),
        ),
      );
      _fetchAdminNotifications(showLoading: false);
    } else if (type.contains('MOMENT')) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => const AdminModerationQueueScreen(),
        ),
      );
    } else if (type.contains('REPORT')) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => const AdminReportsScreen(),
        ),
      );
    } else if (type.contains('USER')) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => const AdminUserListScreen(),
        ),
      );
    }
  }

  List<NotificationModel> get _filteredNotifications {
    if (_selectedFilter == 'Moments') {
      return _notifications.where((n) {
        final t = (n.type ?? '').toUpperCase();
        return t.contains('MOMENT') || n.data['category'] == 'MOMENT';
      }).toList();
    }
    if (_selectedFilter == 'Reports') {
      return _notifications.where((n) {
        final t = (n.type ?? '').toUpperCase();
        return t.contains('REPORT') || n.data['category'] == 'REPORT';
      }).toList();
    }
    if (_selectedFilter == 'Users') {
      return _notifications.where((n) {
        final t = (n.type ?? '').toUpperCase();
        return t.contains('USER') || n.data['category'] == 'USER';
      }).toList();
    }
    return _notifications;
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'Recently';
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);
    final displayItems = _filteredNotifications;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFF080914),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            SizedBox(
              height: 56 * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 40 * scale,
                        height: 40 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0x12FFFFFF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x24FFFFFF), width: 1.2),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 18 * scale,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            SizedBox(width: 8 * scale),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 2 * scale),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4E7E),
                                borderRadius: BorderRadius.circular(999 * scale),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: _markAllAsRead,
                        child: Text(
                          'Mark all read',
                          style: TextStyle(
                            color: const Color(0xFF58C3F4),
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Filter Chips Row
            SizedBox(
              height: 44 * scale,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                children: [
                  _buildFilterChip('All', scale),
                  SizedBox(width: 8 * scale),
                  _buildFilterChip('Moments', scale),
                  SizedBox(width: 8 * scale),
                  _buildFilterChip('Reports', scale),
                  SizedBox(width: 8 * scale),
                  _buildFilterChip('Users', scale),
                ],
              ),
            ),
            SizedBox(height: 12 * scale),

            // Content Body
            Expanded(
              child: _isLoading && _notifications.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF58C3F4)),
                    )
                  : _errorMessage != null && _notifications.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24 * scale),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline_rounded, color: VeraTheme.warning, size: 48 * scale),
                                SizedBox(height: 12 * scale),
                                Text(
                                  'Failed to load notifications',
                                  style: TextStyle(color: Colors.white, fontSize: 16 * scale, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 6 * scale),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 13 * scale),
                                ),
                                SizedBox(height: 16 * scale),
                                ElevatedButton(
                                  onPressed: _fetchAdminNotifications,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9451FF),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                  ),
                                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _fetchAdminNotifications(showLoading: false),
                          color: const Color(0xFF58C3F4),
                          backgroundColor: const Color(0xFF13152B),
                          child: displayItems.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(height: 100 * scale),
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.notifications_off_outlined, color: const Color(0x44FFFFFF), size: 48 * scale),
                                          SizedBox(height: 12 * scale),
                                          Text(
                                            'No notifications found',
                                            style: TextStyle(color: Colors.white70, fontSize: 15 * scale, fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(height: 4 * scale),
                                          Text(
                                            'No admin alerts in this category.',
                                            style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 12 * scale),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.fromLTRB(24 * scale, 8 * scale, 24 * scale, 40 * scale),
                                  itemCount: displayItems.length,
                                  separatorBuilder: (_, __) => SizedBox(height: 10 * scale),
                                  itemBuilder: (context, index) {
                                    return _buildNotificationCard(context, scale, displayItems[index]);
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, double scale) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = label);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E2452) : const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(999 * scale),
          border: Border.all(
            color: isSelected ? const Color(0xFF8E37FF) : const Color(0x24FFFFFF),
            width: isSelected ? 1.5 : 1.2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF8A8EB3),
              fontSize: 12 * scale,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, double scale, NotificationModel notification) {
    final type = (notification.type ?? '').toUpperCase();
    final isUnread = !notification.isRead;

    IconData iconData = Icons.notifications_active_outlined;
    Color iconColor = const Color(0xFF58C3F4);
    Color iconBg = const Color(0x1A58C3F4);

    if (type.contains('MOMENT')) {
      iconData = Icons.movie_creation_outlined;
      iconColor = const Color(0xFF9451FF);
      iconBg = const Color(0x1A9451FF);
    } else if (type.contains('REPORT')) {
      iconData = Icons.shield_outlined;
      iconColor = const Color(0xFFFF4E7E);
      iconBg = const Color(0x1AFF4E7E);
    } else if (type.contains('USER')) {
      iconData = Icons.person_outline_rounded;
      iconColor = const Color(0xFF00FF85);
      iconBg = const Color(0x1A00FF85);
    }

    return Container(
      decoration: BoxDecoration(
        color: isUnread ? const Color(0x12FFFFFF) : const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: isUnread ? const Color(0x38FFFFFF) : const Color(0x1AFFFFFF),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNotificationTap(notification),
          borderRadius: BorderRadius.circular(16 * scale),
          child: Padding(
            padding: EdgeInsets.all(14 * scale),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  width: 40 * scale,
                  height: 40 * scale,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 20 * scale),
                ),
                SizedBox(width: 12 * scale),

                // Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14 * scale,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread) ...[
                            SizedBox(width: 6 * scale),
                            Container(
                              width: 8 * scale,
                              height: 8 * scale,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF4E7E),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: const Color(0xFF8A8EB3),
                          fontSize: 12 * scale,
                          height: 18 / 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6 * scale),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          color: const Color(0xFF535370),
                          fontSize: 11 * scale,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8 * scale),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF8A8EB3),
                  size: 20 * scale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
