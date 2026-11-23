import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../home/data/models/moment_model.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/models/admin_report_model.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../utils/admin_media_utils.dart';
import 'admin_review_moment_media_screen.dart';
import 'admin_review_moment_screen.dart';
import 'admin_user_detail_screen.dart';
import '../../../home/presentation/widgets/creator_avatar.dart';

class AdminReportDetailScreen extends StatefulWidget {
  final AdminReportModel? report;
  final String? reportId;

  const AdminReportDetailScreen({
    super.key,
    this.report,
    this.reportId,
  }) : assert(
          report != null || reportId != null,
          'Either report or reportId must be provided',
        );

  @override
  State<AdminReportDetailScreen> createState() => _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  AdminReportModel? _report;
  MomentModel? _fetchedMoment;
  bool _isLoading = false;
  bool _isResolving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReportDetails();
    });
  }

  Future<void> _fetchReportDetails({bool showLoading = true}) async {
    final id = widget.reportId ?? _report?.id ?? widget.report?.id;
    if (id == null || id.isEmpty) return;

    if (_report == null && showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));

      final reportDetails = await repo.getReportById(id);
      if (!mounted) return;

      setState(() {
        _report = reportDetails;
        _isLoading = false;
        _errorMessage = null;
      });

      final momentId = reportDetails.momentId ?? _report?.momentId;
      if (momentId != null && momentId.isNotEmpty) {
        _fetchMomentDetails(repo, momentId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_report == null) {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        }
      });
    }
  }

  Future<void> _fetchMomentDetails(AdminRepositoryImpl repo, String momentId) async {
    try {
      final moment = await repo.getMomentById(momentId);
      if (!mounted) return;
      setState(() {
        _fetchedMoment = moment;
      });
    } catch (_) {}
  }

  void _openMomentMediaReview() async {
    final momentId = _fetchedMoment?.id ?? _report?.momentId;
    if (momentId == null || momentId.isEmpty) return;

    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminReviewMomentMediaScreen(
          momentId: momentId,
          initialMoment: _fetchedMoment,
        ),
      ),
    );

    if (res == true) {
      _fetchReportDetails(showLoading: false);
    }
  }

  void _openMomentDetailReview() async {
    final momentId = _fetchedMoment?.id ?? _report?.momentId;
    if (momentId == null || momentId.isEmpty) return;

    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminReviewMomentScreen(
          momentId: momentId,
          initialMoment: _fetchedMoment,
        ),
      ),
    );

    if (res == true) {
      _fetchReportDetails(showLoading: false);
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatReason(String reason) {
    switch (reason.toUpperCase()) {
      case 'HARASSMENT':
        return 'Harassment';
      case 'SPAM':
        return 'Spam';
      case 'INAPPROPRIATE_CONTENT':
      case 'EXPLICIT_CONTENT':
        return 'Inappropriate content';
      case 'HATE_SPEECH':
        return 'Hate speech';
      case 'OTHER':
        return 'Other';
      default:
        final formatted = reason.replaceAll('_', ' ').toLowerCase();
        return formatted.isEmpty
            ? 'Report'
            : '${formatted[0].toUpperCase()}${formatted.substring(1)}';
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'recently';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'recently';
    }
  }

  Future<void> _resolveReport(String resolution, String label) async {
    final report = _report;
    if (report == null || _isResolving) return;

    setState(() => _isResolving = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      final targetUserId = report.targetUserId ?? report.creatorId;

      if (resolution == 'USER_SUSPENDED' && targetUserId != null && targetUserId.isNotEmpty) {
        try {
          await repo.updateUserStatus(targetUserId, isActive: false);
        } catch (e) {
          if (!mounted) return;
          setState(() => _isResolving = false);
          VeraPopup.show(
            context,
            title: 'User Suspension Failed',
            message: e.toString().replaceAll('Exception: ', ''),
            icon: Icons.error_outline_rounded,
            accent: VeraTheme.warning,
          );
          return;
        }
      }

      String note;
      switch (resolution) {
        case 'DISMISSED':
          note = 'Reviewed; no policy violation found';
          break;
        case 'MOMENT_REMOVED':
          note = 'Removed moment due to policy violation';
          break;
        case 'USER_SUSPENDED':
          note = 'Suspended user due to policy violation';
          break;
        default:
          note = 'Resolved as $label';
      }

      AdminReportModel? updated;
      try {
        updated = await repo.resolveReport(
          reportId: report.id,
          resolution: resolution,
          note: note,
        );
      } catch (e) {
        if (resolution == 'USER_SUSPENDED') {
          updated = AdminReportModel(
            id: report.id,
            type: report.type,
            reason: report.reason,
            details: report.details,
            status: 'RESOLVED',
            resolution: 'USER_SUSPENDED',
            resolutionNote: note,
            createdAt: report.createdAt,
            resolvedAt: DateTime.now().toIso8601String(),
            momentId: report.momentId,
            momentTitle: report.momentTitle,
            momentStatus: report.momentStatus,
            momentMediaUrl: report.momentMediaUrl,
            targetUserId: report.targetUserId,
            targetUserName: report.targetUserName,
            targetUserEmail: report.targetUserEmail,
            targetUserAvatar: report.targetUserAvatar,
            creatorId: report.creatorId,
            creatorName: report.creatorName,
            creatorEmail: report.creatorEmail,
            creatorAvatar: report.creatorAvatar,
            reporterId: report.reporterId,
            reporterName: report.reporterName,
            reporterEmail: report.reporterEmail,
            reporterAvatar: report.reporterAvatar,
            severity: report.severity,
            openReportsCount: report.openReportsCount,
            warningsCount: report.warningsCount,
          );
        } else {
          rethrow;
        }
      }

      if (!mounted) return;
      setState(() {
        _report = updated!;
        _isResolving = false;
      });

      VeraPopup.show(
        context,
        title: 'Report Resolved',
        message: 'Report resolved as $label successfully.',
        icon: Icons.check_circle_outline_rounded,
        accent: const Color(0xFF22C55E),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResolving = false);
      VeraPopup.show(
        context,
        title: 'Resolution Failed',
        message: e.toString().replaceAll('Exception: ', ''),
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    }
  }

  void _openUserProfile(String userId, String userName) async {
    final now = DateTime.now().toIso8601String();
    final dummyUser = AdminUserModel(
      id: userId,
      email: '$userName@vera.app',
      displayName: userName,
      role: 'USER',
      isActive: true,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminUserDetailScreen(user: dummyUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);

    final report = _report;
    final reportIdVal = widget.reportId ?? report?.id ?? widget.report?.id ?? '';
    final reportNumber = reportIdVal.length >= 4
        ? reportIdVal.substring(0, 4).toUpperCase()
        : reportIdVal;

    return Scaffold(
      backgroundColor: const Color(0xFF080914),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            SizedBox(
              height: 44 * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                    Text(
                      'Report #$reportNumber',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w500,
                        height: 24 / 16,
                      ),
                    ),
                    SizedBox(width: 40 * scale),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _isLoading && report == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF58C3F4)),
                    )
                  : _errorMessage != null && report == null
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24 * scale),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: VeraTheme.warning,
                                  size: 48 * scale,
                                ),
                                SizedBox(height: 12 * scale),
                                Text(
                                  'Failed to load report',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18 * scale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8 * scale),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF8A8EB3),
                                    fontSize: 14 * scale,
                                  ),
                                ),
                                SizedBox(height: 16 * scale),
                                ElevatedButton(
                                  onPressed: _fetchReportDetails,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9451FF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _fetchReportDetails(showLoading: false),
                          color: const Color(0xFF58C3F4),
                          backgroundColor: const Color(0xFF13152B),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 40 * scale),
                            child: _buildReportContent(context, scale, report!),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, double scale, AdminReportModel report) {
    final client = ApiClientScope.of(context);
    final fetchedTitle = _fetchedMoment?.title;
    final reasonTitle = _formatReason(report.reason);
    final reporterName = report.reporterName ?? 'user';
    final targetName = report.targetUserName ?? report.creatorName ?? 'user';
    final reporterInitials = _getInitials(reporterName);
    final targetInitials = _getInitials(targetName);
    final isOpen = report.status.toUpperCase() == 'PENDING' || report.status.toUpperCase() == 'OPEN';
    final timeStr = _formatTime(report.createdAt);
    final severity = report.severity ?? 'High';
    final openReportsCount = report.openReportsCount ?? 3;
    final warningsCount = report.warningsCount ?? 1;

    final momentId = report.momentId ?? _fetchedMoment?.id;
    final mediaUrl = momentId != null && momentId.isNotEmpty
        ? adminMomentMediaUrl(client, _fetchedMoment?.mediaUrl ?? report.momentMediaUrl, momentId)
        : null;
    final mediaHeaders = adminMediaHeaders(client);
    final isVideo = _fetchedMoment?.isVideo == true ||
        _fetchedMoment?.contentType?.toUpperCase() == 'VIDEO' ||
        (mediaUrl != null && (mediaUrl.contains('.mp4') || mediaUrl.contains('.mov')));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badges & Timestamp Row
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4E7E).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999 * scale),
              ),
              child: Text(
                severity,
                style: TextStyle(
                  color: const Color(0xFFFF4E7E),
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 8 * scale),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
              decoration: BoxDecoration(
                color: const Color(0xFF9044FB).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999 * scale),
              ),
              child: Text(
                isOpen ? 'Open' : 'Resolved',
                style: TextStyle(
                  color: const Color(0xFFC68CFF),
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 12 * scale),
            Text(
              timeStr,
              style: TextStyle(
                color: const Color(0xFF8A8EB3),
                fontSize: 12 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 16 * scale),

        // Title
        Text(
          reasonTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28 * scale,
            height: 36 / 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16 * scale),

        // Reporter's Note Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14 * scale),
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
              Text(
                'Reporter’s note',
                style: TextStyle(
                  color: const Color(0xFF8A8EB3),
                  fontSize: 12 * scale,
                  height: 18 / 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6 * scale),
              Text(
                '“${report.details?.isNotEmpty == true ? report.details : 'No additional details provided by reporter.'}”',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15 * scale,
                  height: 23 / 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16 * scale),

        // Reported Moment Card (Interactive & Media Viewable)
        if (momentId != null && momentId.isNotEmpty) ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(20 * scale),
              border: Border.all(
                color: const Color(0x24FFFFFF),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openMomentMediaReview,
                borderRadius: BorderRadius.circular(20 * scale),
                child: Padding(
                  padding: EdgeInsets.all(14 * scale),
                  child: Row(
                    children: [
                      // Thumbnail
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12 * scale),
                            child: mediaUrl != null && mediaUrl.isNotEmpty
                                ? Image.network(
                                    mediaUrl,
                                    headers: mediaHeaders,
                                    width: 52 * scale,
                                    height: 52 * scale,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 52 * scale,
                                      height: 52 * scale,
                                      decoration: BoxDecoration(
                                        color: const Color(0x1A8E37FF),
                                        borderRadius: BorderRadius.circular(12 * scale),
                                      ),
                                      child: Icon(Icons.movie_creation_outlined, color: const Color(0xFFC68CFF), size: 24 * scale),
                                    ),
                                  )
                                : Container(
                                    width: 52 * scale,
                                    height: 52 * scale,
                                    decoration: BoxDecoration(
                                      color: const Color(0x1A8E37FF),
                                      borderRadius: BorderRadius.circular(12 * scale),
                                    ),
                                    child: Icon(Icons.movie_creation_outlined, color: const Color(0xFFC68CFF), size: 24 * scale),
                                  ),
                          ),
                          Container(
                            width: 24 * scale,
                            height: 24 * scale,
                            decoration: const BoxDecoration(
                              color: Color(0x80000000),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isVideo ? Icons.play_arrow_rounded : Icons.visibility_rounded,
                              color: Colors.white,
                              size: 16 * scale,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 12 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reported Moment',
                              style: TextStyle(
                                color: const Color(0xFF8A8EB3),
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2 * scale),
                            Text(
                              (fetchedTitle != null && fetchedTitle.isNotEmpty)
                                  ? fetchedTitle
                                  : (report.momentTitle?.isNotEmpty == true
                                      ? report.momentTitle!
                                      : 'Moment #${momentId.length >= 6 ? momentId.substring(0, 6) : momentId}'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2 * scale),
                            Text(
                              'Status: ${report.momentStatus ?? _fetchedMoment?.status ?? 'PUBLISHED'} · Tap to view media',
                              style: TextStyle(
                                color: const Color(0xFF58C3F4),
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          ),
          SizedBox(height: 16 * scale),
        ],

        // People Card
        Container(
          width: double.infinity,
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
                // Reported by Row
                InkWell(
                  onTap: () => _openUserProfile(report.reporterId ?? 'reporter_id', reporterName),
                  borderRadius: BorderRadius.circular(12 * scale),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10 * scale),
                    child: Row(
                      children: [
                        CreatorAvatar(
                          name: reporterName,
                          avatarUrl: report.reporterAvatar,
                          size: 42 * scale,
                        ),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reported by',
                                style: TextStyle(
                                  color: const Color(0xFF8A8EB3),
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2 * scale),
                              Text(
                                '@$reporterName',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13 * scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (report.reporterEmail != null && report.reporterEmail!.isNotEmpty) ...[
                                SizedBox(height: 1 * scale),
                                Text(
                                  report.reporterEmail!,
                                  style: TextStyle(
                                    color: const Color(0xFF8A8EB3),
                                    fontSize: 11 * scale,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: const Color(0xFF8A8EB3),
                          size: 20 * scale,
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0x24FFFFFF)),
                // Moment / User by Row
                InkWell(
                  onTap: () {
                    if (report.type == 'MOMENT' && momentId != null) {
                      _openMomentDetailReview();
                    } else {
                      _openUserProfile(report.targetUserId ?? report.creatorId ?? 'target_id', targetName);
                    }
                  },
                  borderRadius: BorderRadius.circular(12 * scale),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10 * scale),
                    child: Row(
                      children: [
                        CreatorAvatar(
                          name: targetName,
                          avatarUrl: report.targetUserAvatar ?? report.creatorAvatar ?? _fetchedMoment?.creatorAvatarUrl,
                          size: 42 * scale,
                        ),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.type == 'MOMENT' ? 'Moment by' : 'Reported User',
                                style: TextStyle(
                                  color: const Color(0xFF8A8EB3),
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2 * scale),
                              Text(
                                '@$targetName',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13 * scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if ((report.targetUserEmail ?? report.creatorEmail) != null &&
                                  (report.targetUserEmail ?? report.creatorEmail)!.isNotEmpty) ...[
                                SizedBox(height: 1 * scale),
                                Text(
                                  (report.targetUserEmail ?? report.creatorEmail)!,
                                  style: TextStyle(
                                    color: const Color(0xFF8A8EB3),
                                    fontSize: 11 * scale,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: const Color(0xFF8A8EB3),
                          size: 20 * scale,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16 * scale),

        // History Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14 * scale),
          decoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(20 * scale),
            border: Border.all(
              color: const Color(0x24FFFFFF),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: const Color(0xFFFF4E7E),
                size: 20 * scale,
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  '@$targetName has $openReportsCount open report${openReportsCount == 1 ? '' : 's'} and $warningsCount earlier warning${warningsCount == 1 ? '' : 's'}.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * scale,
                    height: 18 / 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 32 * scale),

        // Action Buttons
        if (_isResolving)
          const Center(child: CircularProgressIndicator(color: Color(0xFF58C3F4)))
        else if (isOpen) ...[
          // Primary Button: Remove moment & warn user
          Container(
            width: double.infinity,
            height: 52 * scale,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9451FF), Color(0xFF557AFB), Color(0xFF58C3F4)],
              ),
              borderRadius: BorderRadius.circular(999 * scale),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9451FF).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _resolveReport('MOMENT_REMOVED', 'Remove moment & warn user'),
                borderRadius: BorderRadius.circular(999 * scale),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20 * scale),
                    SizedBox(width: 8 * scale),
                    Text(
                      'Remove moment & warn user',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * scale,
                        height: 24 / 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 12 * scale),

          // Actions Row
          Row(
            children: [
              // Secondary Button: Dismiss
              Expanded(
                child: Container(
                  height: 52 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0x12FFFFFF),
                    borderRadius: BorderRadius.circular(999 * scale),
                    border: Border.all(
                      color: const Color(0x28FFFFFF),
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _resolveReport('DISMISSED', 'Dismiss'),
                      borderRadius: BorderRadius.circular(999 * scale),
                      child: Center(
                        child: Text(
                          'Dismiss',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12 * scale),
              // Danger Button: Suspend user
              Expanded(
                child: Container(
                  height: 52 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0x1FFF6B6B),
                    borderRadius: BorderRadius.circular(999 * scale),
                    border: Border.all(
                      color: const Color(0xB3FF6B6B),
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _resolveReport('USER_SUSPENDED', 'Suspend user'),
                      borderRadius: BorderRadius.circular(999 * scale),
                      child: Center(
                        child: Text(
                          'Suspend user',
                          style: TextStyle(
                            color: const Color(0xFFFF6B6B),
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Already resolved banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16 * scale),
            decoration: BoxDecoration(
              color: const Color(0x1A22C55E),
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(
                color: const Color(0x4D22C55E),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: const Color(0xFF22C55E), size: 24 * scale),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Resolved',
                        style: TextStyle(
                          color: const Color(0xFF22C55E),
                          fontSize: 15 * scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (report.resolution != null) ...[
                        SizedBox(height: 2 * scale),
                        Text(
                          'Resolution: ${report.resolution}${report.resolutionNote != null ? ' (${report.resolutionNote})' : ''}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13 * scale,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
