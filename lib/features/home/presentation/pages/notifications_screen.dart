import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/moments_remote_data_source.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/moments_repository_impl.dart';
import 'locked_moment_screen.dart';
import 'unlocked_moment_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedTab = 0; // 0: All, 1: Unread, 2: Read
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNotifications();
    });
  }

  Future<void> _openNotificationItem(NotificationModel n, int index) async {
    if (!n.isRead) {
      if (mounted) {
        setState(() {
          _notifications[index] = n.copyWith(isRead: true);
        });
      }
      try {
        final client = ApiClientScope.of(context);
        final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
        await repo.markNotificationAsRead(n.id);
        if (mounted) {
          PushNotificationService.instance.refreshUnreadCount(client);
        }
      } catch (_) {}
    }

    final momentId = n.data['momentId']?.toString() ??
        (n.type == 'MOMENT_INVITATION' || n.type == 'PRIVATE_MOMENT' || n.type == 'ADMIN_APPROVAL' || n.type == 'ADMIN_REJECTION' ? n.id : null);

    if (momentId != null && momentId.isNotEmpty && !momentId.startsWith('fallback-')) {
      try {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: VeraTheme.purple),
          ),
        );

        final client = ApiClientScope.of(context);
        final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
        final momentModel = await repo.getMomentById(momentId);
        final moment = momentModel.toEntity();

        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();

        if (!mounted) return;
        if (moment.isReadyToOpen || moment.status == 'OPENED' || moment.unlockedAt != null) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => UnlockedMomentScreen(moment: moment),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LockedMomentScreen(moment: moment),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          VeraPopup.show(
            context,
            title: n.title,
            message: n.body,
            icon: Icons.notifications_rounded,
            accent: VeraTheme.purple,
          );
        }
      }
    } else {
      if (mounted) {
        VeraPopup.show(
          context,
          title: n.title,
          message: n.body,
          icon: Icons.notifications_rounded,
          accent: VeraTheme.purple,
        );
      }
    }
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
      final response = await repo.getNotifications();

      if (!mounted) return;
      setState(() {
        _notifications = response.items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = VeraResponsive.scale(MediaQuery.sizeOf(context).width);

    final filteredNotifications = _notifications.where((n) {
      if (_selectedTab == 1) return !n.isRead;
      if (_selectedTab == 2) return n.isRead;
      return true;
    }).toList();

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
                      icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20 * scale),
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
                    IconButton(
                      onPressed: () async {
                        final client = ApiClientScope.of(context);
                        final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
                        await repo.markAllNotificationsAsRead();
                        setState(() {
                          _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
                        });
                        if (!mounted) return;
                        PushNotificationService.instance.refreshUnreadCount(client);
                      },
                      tooltip: 'Mark all as read',
                      icon: Icon(Icons.done_all_rounded, color: const Color(0xFFC68CFF), size: 20 * scale),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tightFor(
                        width: 40 * scale,
                        height: 40 * scale,
                      ),
                    ),
                    IconButton(
                      onPressed: _fetchNotifications,
                      icon: Icon(Icons.refresh_rounded, color: const Color(0xFFC68CFF), size: 20 * scale),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tightFor(
                        width: 40 * scale,
                        height: 40 * scale,
                      ),
                    ),
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
            const Divider(height: 1, thickness: 1, color: Color(0x223F4356)),

            // Content List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchNotifications,
                color: const Color(0xFF9044FB),
                backgroundColor: const Color(0xFF161626),
                child: _buildBody(filteredNotifications, scale),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<NotificationModel> notifications, double scale) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9044FB)),
      );
    }

    if (_errorMessage != null && notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.amber, size: 48 * scale),
              SizedBox(height: 16 * scale),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: const Color(0xFFA6A6C1), fontSize: 14 * scale),
              ),
              SizedBox(height: 16 * scale),
              ElevatedButton.icon(
                onPressed: _fetchNotifications,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9044FB)),
              ),
            ],
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined, color: const Color(0xFF6E6E8F), size: 48 * scale),
            SizedBox(height: 16 * scale),
            Text(
              'No notifications',
              style: TextStyle(
                color: const Color(0xFFA6A6C1),
                fontSize: 16 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 48 * scale),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final n = notifications[index];
        final timeStr = n.createdAt != null
            ? n.createdAt!.toLocal().toString().split('.').first
            : 'Recently';

        return GestureDetector(
          onTap: () => _openNotificationItem(n, index),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: EdgeInsets.only(bottom: 12 * scale),
            padding: EdgeInsets.all(12 * scale),
            decoration: BoxDecoration(
              color: n.isRead ? const Color(0xFF121326) : const Color(0xFF1E1736),
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(
                color: n.isRead ? const Color(0x333F4356) : const Color(0xFF9044FB).withAlpha(120),
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
                Container(
                  width: 48 * scale,
                  height: 48 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B152E),
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12 * scale),
                    child: n.imageUrl != null && n.imageUrl!.isNotEmpty
                        ? Image.network(
                            n.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.notifications, color: Colors.white, size: 20),
                          )
                        : const Icon(Icons.notifications, color: Colors.white, size: 20),
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!n.isRead) ...[
                            SizedBox(width: 8 * scale),
                            Container(
                              width: 8 * scale,
                              height: 8 * scale,
                              decoration: const BoxDecoration(
                                color: Color(0xFF38BDF8),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 8 * scale),
                      Text(
                        n.body,
                        style: TextStyle(
                          color: const Color(0xFFA6A6C1),
                          fontSize: 12 * scale,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      Text(
                        timeStr,
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
          ),
        );
      },
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
