import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/utils/server_time_manager.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../home/data/models/moment_model.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/models/admin_report_model.dart';
import '../../data/repositories/admin_repository_impl.dart';
import 'admin_review_moment_screen.dart';
import 'admin_reports_screen.dart';
import '../utils/admin_live_refresh.dart';
import '../../../../core/realtime/admin_moderation_update.dart';
import '../../../../core/realtime/admin_moderation_diagnostics.dart';
import '../../../../core/network/api_exception.dart';

class AdminModerationQueueScreen extends StatefulWidget {
  const AdminModerationQueueScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<AdminModerationQueueScreen> createState() => _AdminModerationQueueScreenState();
}

class _AdminModerationQueueScreenState extends State<AdminModerationQueueScreen> with WidgetsBindingObserver, AdminLiveRefresh<AdminModerationQueueScreen> {
  @override
  bool get adminRefreshActive => widget.isActive;
  int? _pendingTotal;
  int _reportsTotal = 14;

  @override
  bool onAdminModeration(AdminModerationUpdate update) {
    setState(() {
      _pendingTotal = liveModerationCounts?.pendingReview ?? _pendingTotal;
      if (update.removesFromQueue) {
        _moments.removeWhere((moment) => moment.id == update.momentId);
      }
    });
    return update.isTransition;
  }

  List<MomentModel> _moments = [];
  List<AdminReportModel> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedTab = 'Moments'; // Moments, Reports
  String _selectedMomentFilter = 'All'; // All, Locked, Unlocked, Reported
  String _selectedReportFilter = 'Open'; // Open, In review, Resolved

  @override
  void initState() {
    super.initState();
    ServerTimeManager.instance.ticker.addListener(_onTick);
  }

  @override
  void dispose() {
    ServerTimeManager.instance.ticker.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Future<void> loadAdminData({required bool showLoading}) async {
    if (!mounted) return;
    setState(() {
      if (showLoading) _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      final beforeRevision = client.momentRealtime.moderationRevision;

      final response = await repo.getPendingMoments();
      final reportsRes = await repo.getReports(page: 1, limit: 50);

      if (!mounted) return;
      final filtered = response.moments.where((moment) {
        final latest = moderationState(moment.id);
        return latest == null || !latest.removesFromQueue ||
            (latest.transition != 'DELETED' && latest.version != null && moment.version > latest.version!);
      }).toList();
      final removed = response.moments.length - filtered.length;
      final pending = response.total >= removed ? response.total - removed : 0;
      final total = client.momentRealtime.reconcilePendingTotal(pending, beforeRevision);

      setState(() {
        _moments = filtered;
        _pendingTotal = total;
        _reports = reportsRes.items;
        _reportsTotal = reportsRes.total > 0 ? reportsRes.total : 14;
        _isLoading = false;
      });
    } catch (e) {
      logAdminModeration('queue_fetch_failed', {
        'errorType': e.runtimeType.toString(),
        if (e is ApiException) 'httpStatus': e.statusCode,
      });
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
        _isLoading = false;
      });
    }
  }

  List<MomentModel> get _filteredMoments {
    return _moments.where((moment) {
      final isLocked = moment.visibility?.toUpperCase() == 'PRIVATE' || moment.unlockAt != null;
      if (_selectedMomentFilter == 'Locked') return isLocked;
      if (_selectedMomentFilter == 'Unlocked') return !isLocked;
      if (_selectedMomentFilter == 'Reported') return false;
      return true; // 'All'
    }).toList();
  }

  List<AdminReportModel> get _filteredReports {
    return _reports.where((report) {
      final status = report.status.toUpperCase();
      if (_selectedReportFilter == 'Open') return status == 'PENDING';
      if (_selectedReportFilter == 'Resolved') return status == 'RESOLVED';
      if (_selectedReportFilter == 'In review') return status == 'IN_REVIEW' || status == 'PENDING';
      return true;
    }).toList();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);
    final displayMoments = _filteredMoments;
    final displayReports = _filteredReports;

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moderation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28 * scale,
                    height: 36 / 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  'Review moments and reports',
                  style: TextStyle(
                    color: const Color(0xFF8A8EB3),
                    fontSize: 12 * scale,
                    height: 18 / 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20 * scale),

            // Tabs Segmented Control (Fill 342px, Hug 28px)
            Row(
              children: [
                _buildTab('Moments', scale),
                SizedBox(width: 32 * scale),
                _buildTab('Reports · $_reportsTotal', scale),
              ],
            ),
            SizedBox(height: 16 * scale),

            // Filter Chips Row based on active tab
            if (_selectedTab == 'Moments')
              Row(
                children: [
                  _buildMomentFilterChip('All', scale),
                  SizedBox(width: 8 * scale),
                  _buildMomentFilterChip('Locked', scale),
                  SizedBox(width: 8 * scale),
                  _buildMomentFilterChip('Unlocked', scale),
                  SizedBox(width: 8 * scale),
                  _buildMomentFilterChip('Reported', scale),
                ],
              )
            else
              Row(
                children: [
                  _buildReportFilterChip('Open', scale),
                  SizedBox(width: 8 * scale),
                  _buildReportFilterChip('In review', scale),
                  SizedBox(width: 8 * scale),
                  _buildReportFilterChip('Resolved', scale),
                ],
              ),
            SizedBox(height: 20 * scale),

            // Body List
            _isLoading
                ? Padding(
                    padding: EdgeInsets.all(60 * scale),
                    child: Center(
                      child: CircularProgressIndicator(color: const Color(0xFF58C3F4)),
                    ),
                  )
                : _errorMessage != null
                    ? Padding(
                        padding: EdgeInsets.all(32 * scale),
                        child: Center(
                          child: Text(
                            'Error: $_errorMessage',
                            style: TextStyle(color: Colors.red, fontSize: 14 * scale),
                          ),
                        ),
                      )
                    : _selectedTab == 'Moments'
                        ? (displayMoments.isEmpty
                            ? Padding(
                                padding: EdgeInsets.symmetric(vertical: 60 * scale),
                                child: Center(
                                  child: Text(
                                    'No pending moments found.',
                                    style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 14 * scale),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayMoments.length,
                                separatorBuilder: (context, index) => SizedBox(height: 16 * scale),
                                itemBuilder: (context, index) {
                                  final moment = displayMoments[index];
                                  return _buildModerationCard(context, scale, moment);
                                },
                              ))
                        : (displayReports.isEmpty
                            ? Padding(
                                padding: EdgeInsets.symmetric(vertical: 60 * scale),
                                child: Center(
                                  child: Text(
                                    'No reports found.',
                                    style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 14 * scale),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayReports.length,
                                separatorBuilder: (context, index) => SizedBox(height: 16 * scale),
                                itemBuilder: (context, index) {
                                  final report = displayReports[index];
                                  return _buildReportCard(context, scale, report);
                                },
                              )),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, double scale) {
    final isSelected = _selectedTab == (label.startsWith('Reports') ? 'Reports' : 'Moments');
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = label.startsWith('Reports') ? 'Reports' : 'Moments');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF8A8EB3),
              fontSize: 16 * scale,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          SizedBox(height: 6 * scale),
          Container(
            height: 2 * scale,
            width: label.startsWith('Reports') ? 80 * scale : 70 * scale,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF8E37FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentFilterChip(String label, double scale) {
    final isSelected = _selectedMomentFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMomentFilter = label);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 8 * scale),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E2452) : const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(999 * scale),
          border: Border.all(
            color: isSelected ? const Color(0xFF8E37FF) : const Color(0x24FFFFFF),
            width: isSelected ? 1.5 : 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF8A8EB3),
            fontSize: 12 * scale,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildReportFilterChip(String label, double scale) {
    final isSelected = _selectedReportFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedReportFilter = label);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 8 * scale),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E2452) : const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(999 * scale),
          border: Border.all(
            color: isSelected ? const Color(0xFF8E37FF) : const Color(0x24FFFFFF),
            width: isSelected ? 1.5 : 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF8A8EB3),
            fontSize: 12 * scale,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, double scale, AdminReportModel report) {
    final reasonTitle = report.reason.replaceAll('_', ' ');
    final creatorName = report.creatorName ?? report.targetUserName ?? 'user';
    final reporterName = report.reporterName ?? 'user';
    final subtitle = report.type == 'MOMENT'
        ? 'Moment by @$creatorName · reported by @$reporterName'
        : 'Profile @$creatorName · reported by @$reporterName';

    Color priorityColor = const Color(0xFF58C3F4); // Medium
    String priorityText = 'Medium';
    if (report.reason.toUpperCase().contains('HARASSMENT') || report.reason.toUpperCase().contains('ABUSE')) {
      priorityColor = const Color(0xFFFF4E7E);
      priorityText = 'High';
    } else if (report.reason.toUpperCase().contains('SPAM')) {
      priorityColor = const Color(0xFF8A8EB3);
      priorityText = 'Low';
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AdminReportsScreen(),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16 * scale),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999 * scale),
                  ),
                  child: Text(
                    priorityText,
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 11 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '12 min ago',
                      style: TextStyle(
                        color: const Color(0xFF8A8EB3),
                        fontSize: 12 * scale,
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: const Color(0xFF8A8EB3),
                      size: 14 * scale,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12 * scale),
            Text(
              reasonTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4 * scale),
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
    );
  }

  Widget _buildModerationCard(BuildContext context, double scale, MomentModel moment) {
    final creatorName = moment.creatorName ?? 'John Travolta';
    final initials = _getInitials(creatorName);
    final isLocked = moment.visibility?.toUpperCase() == 'PRIVATE' || moment.unlockAt != null;
    final timeStr = moment.createdAt != null ? '2h ago' : 'Yesterday';
    final bannerText = moment.unlockAt != null
        ? 'Opens at ${moment.unlockAt!.toLocal().toString().split('.').first}'
        : 'Opens when you’re at Tokyo Tower';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => AdminReviewMomentScreen(
              momentId: moment.id,
              initialMoment: moment,
            ),
          ),
        );
        if (result == true) {
          refreshAdmin();
        }
      },
      child: Container(
        height: 150 * scale,
        padding: EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20 * scale),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A2A78), Color(0xFF2A6A8A)],
          ),
          border: Border.all(
            color: const Color(0x38FFFFFF), // 22% white border
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row (Fill 315px, Hug 46px, space-between)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User Pill (Hug 143px, Hug 46px, radius 999px, border 1px 14% white, padding 6 top/bottom, 14 right, 6 left, gap 8)
                Container(
                  padding: EdgeInsets.fromLTRB(6 * scale, 6 * scale, 14 * scale, 6 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0x12FFFFFF),
                    borderRadius: BorderRadius.circular(999 * scale),
                    border: Border.all(color: const Color(0x24FFFFFF), width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32 * scale,
                        height: 32 * scale,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF58C3F4), Color(0xFF8E37FF)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13 * scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            creatorName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 1 * scale),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: const Color(0xFF8A8EB3),
                              fontSize: 11 * scale,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right Section (Hug 117px, Hug 44px, gap 8px)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Reports Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4E7E).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999 * scale),
                      ),
                      child: Text(
                        '3 reports',
                        style: TextStyle(
                          color: const Color(0xFFFF4E7E),
                          fontSize: 11 * scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    // Lock Button (Fixed 44x44, radius 999, bg #1C1C1E at 85%)
                    Container(
                      width: 44 * scale,
                      height: 44 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0xD91C1C1E), // 85% #1C1C1E
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/images/lock.svg',
                          width: 20 * scale,
                          height: 20 * scale,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Rule Strip / Bottom Banner (Fill 315px, Fixed 40px, radius 18px, padding 14 left/right, gap 8px)
            Container(
              width: double.infinity,
              height: 40 * scale,
              padding: EdgeInsets.symmetric(horizontal: 14 * scale),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xD99451FF), Color(0x8058C3F4)],
                ),
                borderRadius: BorderRadius.circular(18 * scale),
              ),
              child: Row(
                children: [
                  Icon(
                    isLocked ? Icons.location_on_outlined : Icons.access_time_rounded,
                    color: Colors.white,
                    size: 18 * scale,
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      bannerText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13 * scale,
                        height: 18 / 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
