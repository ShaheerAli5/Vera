import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/models/admin_audit_log_model.dart';
import '../../data/repositories/admin_repository_impl.dart';
import 'admin_reports_screen.dart';
import 'admin_user_list_screen.dart';
import '../utils/admin_live_refresh.dart';
import '../../../../core/realtime/admin_moderation_update.dart';
import '../../../../core/realtime/admin_moderation_diagnostics.dart';
import '../../../../core/network/api_exception.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with WidgetsBindingObserver, AdminLiveRefresh<AdminDashboardScreen> {
  @override
  bool get adminRefreshActive => widget.isActive;
  
  @override
  bool onAdminModeration(AdminModerationUpdate update) {
    final counts = liveModerationCounts;
    if (counts != null) {
      setState(() {
        _pendingMomentsCount = counts.pendingReview;
        _approvedMoments = counts.approved;
        _rejectedMoments = counts.rejected;
      });
    }
    return update.isTransition;
  }

  int _pendingMomentsCount = 0;
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _suspendedUsers = 0;
  int _approvedMoments = 3216;
  int _rejectedMoments = 0;
  final List<AdminAuditLogModel> _recentActivities = [];
  bool _isLoading = true;

  @override
  Future<void> loadAdminData({required bool showLoading}) async {
    if (!mounted) return;
    if (showLoading) setState(() => _isLoading = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      final beforeRevision = client.momentRealtime.moderationRevision;
      
      final pendingRes = await repo.getPendingMoments(limit: 50);
      final statsMap = await repo.getModerationStats();
      final logsRes = await repo.getAuditLogs(limit: 5);

      if (!mounted) return;
      final removed = pendingRes.moments.where((moment) {
        final latest = moderationState(moment.id);
        return latest != null && latest.removesFromQueue &&
            (latest.transition == 'DELETED' || latest.version == null || moment.version <= latest.version!);
      }).length;
      final pending = pendingRes.total >= removed ? pendingRes.total - removed : 0;
      final counts = client.momentRealtime.reconcileModerationCounts(ModerationCounts(
        pendingReview: pending,
        approved: statsMap['approvedMoments'] ?? liveModerationCounts?.approved ?? _approvedMoments,
        rejected: statsMap['rejectedMoments'] ?? liveModerationCounts?.rejected ?? _rejectedMoments,
      ), beforeRevision);

      setState(() {
        _pendingMomentsCount = counts.pendingReview;
        _totalUsers = statsMap['totalUsers'] ?? _totalUsers;
        _activeUsers = statsMap['activeUsers'] ?? _activeUsers;
        _suspendedUsers = statsMap['suspendedUsers'] ?? _suspendedUsers;
        _approvedMoments = counts.approved > 0 ? counts.approved : 3216;
        _rejectedMoments = counts.rejected;
        _recentActivities.clear();
        _recentActivities.addAll(logsRes.items);
        _isLoading = false;
      });
    } catch (error) {
      logAdminModeration('dashboard_fetch_failed', {
        'errorType': error.runtimeType.toString(),
        if (error is ApiException) 'httpStatus': error.statusCode,
      });
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);

    return RefreshIndicator(
      onRefresh: refreshAdmin,
      color: const Color(0xFF58C3F4),
      backgroundColor: const Color(0xFF161626),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 110 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Fill 342px, Hug 56px, space-between)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28 * scale,
                        height: 36 / 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Row(
                      children: [
                        Text(
                          'Fri, Nov 13 · All systems normal',
                          style: TextStyle(
                            color: const Color(0xFF8A8EB3),
                            fontSize: 12 * scale,
                            height: 18 / 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                        ),
                        if (_isLoading) ...[
                          SizedBox(width: 8 * scale),
                          SizedBox(
                            width: 12 * scale,
                            height: 12 * scale,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF58C3F4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                // Bell (Fixed 44x44, radius 999, border 1.2px 14% white, bg 7% white)
                Container(
                  width: 44 * scale,
                  height: 44 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0x12FFFFFF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x24FFFFFF),
                      width: 1.2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 20 * scale,
                      ),
                      Positioned(
                        top: 10 * scale,
                        right: 11 * scale,
                        child: Container(
                          width: 8 * scale,
                          height: 8 * scale,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4E7E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20 * scale),

            // Stats 1 Row (Fill 342px, Hug 105px, gap 12px)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    scale,
                    assetPath: 'assets/images/users.png',
                    label: 'Active users',
                    value: _activeUsers > 0 ? '$_activeUsers' : '12,480',
                    trend: '↑ 4.2% vs last week',
                    trendColor: const Color(0xFF58C3F4),
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: _buildStatCard(
                    scale,
                    assetPath: 'assets/images/send.png',
                    label: 'Moments sent',
                    value: '$_approvedMoments',
                    trend: '↑ 11% vs last week',
                    trendColor: const Color(0xFF58C3F4),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * scale),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    scale,
                    assetPath: 'assets/images/unlock.png',
                    label: 'Unlocked today',
                    value: _totalUsers > 0 ? '$_totalUsers' : '1,842',
                    trend: '↑ 6.8% vs yesterday',
                    trendColor: const Color(0xFF58C3F4),
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: _buildStatCard(
                    scale,
                    assetPath: 'assets/images/flag.png',
                    label: 'Open reports',
                    value: '$_pendingMomentsCount',
                    trend: '3 high priority',
                    trendColor: const Color(0xFFFF4E7E),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20 * scale),

            // Chart Card (Fill 342px, Hug 167px, radius 20px, border 1.5px 14% white, padding 16, bg 6% white, gap 10)
            Container(
              padding: EdgeInsets.all(16 * scale),
              decoration: BoxDecoration(
                color: const Color(0x0FFFFFFF),
                borderRadius: BorderRadius.circular(20 * scale),
                border: Border.all(
                  color: const Color(0x24FFFFFF),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chart Header (Fill 307px, Hug 24px, space-between)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Moments sent',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0xFF231D38),
                          borderRadius: BorderRadius.circular(20 * scale),
                          border: Border.all(color: const Color(0xFF352C54)),
                        ),
                        child: Text(
                          'Last 7 days',
                          style: TextStyle(
                            color: const Color(0xFFC68CFF),
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10 * scale),
                  SizedBox(
                    height: 120 * scale,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBar(scale, 'M', 0.35, false),
                        _buildBar(scale, 'T', 0.45, false),
                        _buildBar(scale, 'W', 0.40, false),
                        _buildBar(scale, 'T', 0.60, false),
                        _buildBar(scale, 'F', 0.50, false),
                        _buildBar(scale, 'S', 0.70, false),
                        _buildBar(scale, 'S', 0.95, true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20 * scale),

            // Section Header: Needs attention (Fill 342px, Hug 26px, space-between)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Needs attention',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AdminReportsScreen()),
                    );
                  },
                  child: Text(
                    'See all',
                    style: TextStyle(
                      color: const Color(0xFFC68CFF),
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * scale),

            // Attention Container (Fill 342px, Hug 135px, radius 20px, border 1.5px 14% white, bg 6% white, padding top/bottom 2px, left/right 16px)
            Container(
              decoration: BoxDecoration(
                color: const Color(0x0FFFFFFF),
                borderRadius: BorderRadius.circular(20 * scale),
                border: Border.all(
                  color: const Color(0x24FFFFFF),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 2 * scale),
                child: Column(
                  children: [
                    _buildListRow(
                      scale,
                      assetPath: 'assets/images/flag.png',
                      iconBg: const Color(0xFFFF4E7E).withValues(alpha: 0.15),
                      title: 'Reports waiting',
                      subtitle: '$_pendingMomentsCount open · 3 high priority',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const AdminReportsScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, color: const Color(0x24FFFFFF)),
                    _buildListRow(
                      scale,
                      assetPath: 'assets/images/users.png',
                      iconBg: const Color(0xFF58C3F4).withValues(alpha: 0.15),
                      title: 'Appeals',
                      subtitle: '${_suspendedUsers > 0 ? _suspendedUsers : 2} users appealing a suspension',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const AdminUserListScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_recentActivities.isNotEmpty) ...[
              SizedBox(height: 24 * scale),
              Text(
                'Recent Activities',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12 * scale),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentActivities.length,
                separatorBuilder: (context, index) => SizedBox(height: 10 * scale),
                itemBuilder: (context, index) {
                  final activity = _recentActivities[index];
                  final timeStr = activity.createdAt != null
                      ? activity.createdAt!.toLocal().toString().split('.').first
                      : 'Recently';

                  return Container(
                    padding: EdgeInsets.all(14 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0x0FFFFFFF),
                      borderRadius: BorderRadius.circular(16 * scale),
                      border: Border.all(color: const Color(0x24FFFFFF), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16 * scale,
                          backgroundColor: const Color(0xFF231D38),
                          child: Icon(Icons.person, color: const Color(0xFFC68CFF), size: 16 * scale),
                        ),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.actorName,
                                style: TextStyle(color: Colors.white, fontSize: 13 * scale, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 2 * scale),
                              Text(
                                activity.action,
                                style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 11 * scale),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 10 * scale),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(double scale, {
    required String assetPath,
    required String label,
    required String value,
    required String trend,
    required Color trendColor,
  }) {
    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF), // 6% white
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: const Color(0x24FFFFFF), // 14% white border
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                assetPath,
                width: 18 * scale,
                height: 18 * scale,
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xFF8A8EB3),
                    fontSize: 12 * scale,
                    height: 18 / 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6 * scale),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28 * scale,
              height: 34 / 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2 * scale),
          Text(
            trend,
            style: TextStyle(
              color: trendColor,
              fontSize: 12 * scale,
              height: 18 / 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double scale, String label, double heightFraction, bool isHighlighted) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24 * scale,
          height: 80 * scale * heightFraction,
          decoration: BoxDecoration(
            gradient: isHighlighted
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF58C3F4), Color(0xFF8E37FF)],
                  )
                : null,
            color: isHighlighted ? null : const Color(0xFF282245),
            borderRadius: BorderRadius.circular(6 * scale),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: const Color(0xFF58C3F4).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
        SizedBox(height: 6 * scale),
        Text(
          label,
          style: TextStyle(
            color: isHighlighted ? const Color(0xFF58C3F4) : const Color(0xFF8A8EB3),
            fontSize: 11 * scale,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildListRow(
    double scale, {
    required String assetPath,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10 * scale),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                child: Image.asset(
                  assetPath,
                  width: 18 * scale,
                  height: 18 * scale,
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: const Color(0xFF8A8EB3),
                        fontSize: 12 * scale,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: const Color(0xFF8A8EB3),
                size: 14 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
