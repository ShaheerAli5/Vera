import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/models/admin_audit_log_model.dart';
import '../../data/repositories/admin_repository_impl.dart';
import 'admin_reports_screen.dart';
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
  int _approvedMoments = 0;
  int _rejectedMoments = 0;
  List<AdminAuditLogModel> _recentActivities = [];
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
      if (statsMap['pendingMoments'] != null && statsMap['pendingMoments'] != pending) {
        logAdminModeration('pending_totals_disagree', {
          'queueTotal': pending, 'statsTotal': statsMap['pendingMoments'],
        });
      }
      setState(() {
        _pendingMomentsCount = counts.pendingReview;
        _totalUsers = statsMap['totalUsers'] ?? _totalUsers;
        _activeUsers = statsMap['activeUsers'] ?? _activeUsers;
        _suspendedUsers = statsMap['suspendedUsers'] ?? _suspendedUsers;
        _approvedMoments = counts.approved;
        _rejectedMoments = counts.rejected;
        _recentActivities = logsRes.items;
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
      color: const Color(0xFF9044FB),
      backgroundColor: const Color(0xFF161626),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16 * scale, 16 * scale, 16 * scale, 100 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    color: const Color(0xFFF7F5FF),
                    fontSize: 24 * scale,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.3,
                  ),
                )),
                IconButton(
                  tooltip: 'Refresh dashboard',
                  onPressed: _isLoading ? null : refreshAdmin,
                  icon: const Icon(Icons.refresh, color: Color(0xFFC68CFF)),
                ),
                if (_isLoading)
                  SizedBox(
                    width: 18 * scale,
                    height: 18 * scale,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9044FB)),
                  ),
              ],
            ),
            SizedBox(height: 24 * scale),
            _buildStatCardsRow(scale, 'Total Users', '$_totalUsers', 'Active Users', '$_activeUsers', const Color(0xFF9044FB), const Color(0xFFC057FF)),
            SizedBox(height: 16 * scale),
            _buildStatCardsRow(scale, 'Suspended', '$_suspendedUsers', 'Pending Moments', '$_pendingMomentsCount', const Color(0xFFE291FF), const Color(0xFF9044FB)),
            SizedBox(height: 16 * scale),
            _buildStatCardsRow(scale, 'Approved Moments', '$_approvedMoments', 'Rejected Moments', '$_rejectedMoments', const Color(0xFFC057FF), const Color(0xFF8A8EB3)),
            SizedBox(height: 20 * scale),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminReportsScreen(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale,
                  vertical: 14 * scale,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A1B4E), Color(0xFF1E1538)],
                  ),
                  borderRadius: BorderRadius.circular(16 * scale),
                  border: Border.all(
                    color: const Color(0xFF9044FB).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10 * scale),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9044FB).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12 * scale),
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        color: const Color(0xFFC857FF),
                        size: 24 * scale,
                      ),
                    ),
                    SizedBox(width: 14 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User & Moment Reports',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2 * scale),
                          Text(
                            'Review reported users, spam, and policy violations',
                            style: TextStyle(
                              color: const Color(0xFFB3AFD0),
                              fontSize: 12 * scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: const Color(0xFF8A8EB3),
                      size: 16 * scale,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32 * scale),
            Text(
              'Recent Activities',
              style: TextStyle(
                color: const Color(0xFFF7F5FF),
                fontSize: 20 * scale,
                fontWeight: FontWeight.w600,
                letterSpacing: -.2,
              ),
            ),
            SizedBox(height: 16 * scale),
            _buildActivityList(scale),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardsRow(double scale, String title1, String val1, String title2, String val2, Color c1, Color c2) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(scale, title1, val1, c1)),
        SizedBox(width: 16 * scale),
        Expanded(child: _buildStatCard(scale, title2, val2, c2)),
      ],
    );
  }

  Widget _buildStatCard(double scale, String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF161626),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: const Color(0xFF282842)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8 * scale,
                height: 8 * scale,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 13 * scale, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 28 * scale, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(double scale) {
    if (_recentActivities.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF161626),
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: const Color(0xFF282842)),
        ),
        child: Text(
          'No recent activity recorded.',
          style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 14 * scale),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentActivities.length,
      separatorBuilder: (context, index) => SizedBox(height: 12 * scale),
      itemBuilder: (context, index) {
        final activity = _recentActivities[index];
        final timeStr = activity.createdAt != null
            ? activity.createdAt!.toLocal().toString().split('.').first
            : 'Recently';

        return Container(
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            color: const Color(0xFF161626),
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(color: const Color(0xFF282842)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20 * scale,
                backgroundColor: const Color(0xFF1B152E),
                child: Icon(Icons.person, color: const Color(0xFFC68CFF), size: 20 * scale),
              ),
              SizedBox(width: 16 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.actorName,
                      style: TextStyle(color: Colors.white, fontSize: 14 * scale, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      activity.action,
                      style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 12 * scale),
                    ),
                  ],
                ),
              ),
              Text(
                timeStr,
                style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 11 * scale),
              ),
            ],
          ),
        );
      },
    );
  }
}
