import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/realtime/moment_realtime_route.dart';
import '../../../../core/realtime/moment_realtime_service.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/server_time_manager.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../home/data/models/moment_model.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/repositories/admin_repository_impl.dart';

class AdminReviewMomentScreen extends StatefulWidget {
  final String momentId;
  final MomentModel? initialMoment;

  const AdminReviewMomentScreen({
    super.key,
    required this.momentId,
    this.initialMoment,
  });

  @override
  State<AdminReviewMomentScreen> createState() => _AdminReviewMomentScreenState();
}

class _AdminReviewMomentScreenState extends State<AdminReviewMomentScreen> with MomentRealtimeRoute<AdminReviewMomentScreen> {
  MomentModel? _moment;
  @override
  String get realtimeMomentId => widget.momentId;

  @override
  void onMomentRealtime(MomentRealtimeUpdate update) {
    setState(() {
      final moment = _moment;
      if (moment != null) {
        _moment = MomentModel.fromJson(update.applyToJson(moment.raw));
      }
    });
  }

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isRevealed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _moment = widget.initialMoment;
    ServerTimeManager.instance.ticker.addListener(_onTick);
    if (_moment == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchMomentDetails();
      });
    }
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

  Future<void> _fetchMomentDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      final moment = await repo.getMomentById(widget.momentId);
      if (!mounted) return;
      setState(() {
        _moment = moment;
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

  Future<void> _approveMoment() async {
    final moment = _moment;
    if (moment == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      await repo.approveMoment(moment.id, version: moment.version);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moment kept / approved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to keep moment: ${e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectMoment(String reason) async {
    final moment = _moment;
    if (moment == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      await repo.rejectMoment(
        moment.id,
        reason: reason,
        version: moment.version,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moment removed: $reason'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove moment: ${e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    if (realtimeDeleted) return deletedMomentView();
    final latest = ApiClientScope.of(context).momentRealtime.latest(widget.momentId);
    if (latest != null && _moment != null) {
      _moment = MomentModel.fromJson(latest.applyToJson(_moment!.raw));
    }
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
                padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      'Moment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      width: 40 * scale,
                      height: 40 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0x12FFFFFF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x24FFFFFF), width: 1.2),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.more_horiz_rounded,
                          color: Colors.white,
                          size: 18 * scale,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _buildContent(scale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(double scale) {
    if (_isLoading && _moment == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF58C3F4)),
      );
    }

    if (_errorMessage != null && _moment == null) {
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
                style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 14 * scale),
              ),
              SizedBox(height: 16 * scale),
              ElevatedButton.icon(
                onPressed: _fetchMomentDetails,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF58C3F4)),
              ),
            ],
          ),
        ),
      );
    }

    final moment = _moment;
    if (moment == null) {
      return const Center(
        child: Text('Moment not found', style: TextStyle(color: Colors.white)),
      );
    }

    final creatorName = moment.creatorName ?? 'Unknown User';
    final initials = _getInitials(creatorName);
    final isLocked = moment.visibility?.toUpperCase() == 'PRIVATE' || moment.unlockAt != null;
    final timeStr = moment.timeAgo ?? 'Recently';

    final bannerText = moment.locationName != null
        ? 'Location · ${moment.locationName}'
        : (moment.unlockAt != null
            ? 'Opens at ${moment.unlockAt!.toLocal().toString().split('.').first}'
            : 'Public / Instant');

    final createdDateStr = moment.createdAt != null
        ? moment.createdAt!.toLocal().toString().split('.').first
        : 'Recently';

    final sentToCount = '${moment.recipientUserIds.length} people';
    final unlockRuleStr = moment.locationName != null
        ? 'Location · ${moment.locationName}'
        : (moment.unlockRuleType ?? 'Standard');

    final reportCount = moment.raw['reportCount']?.toString() ?? '3';
    final reasonsRaw = moment.raw['reasons'] as List<dynamic>?;
    final reasons = reasonsRaw?.map((e) => e.toString()).toList() ?? ['Harassment', 'Spam'];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24 * scale, 12 * scale, 24 * scale, 40 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Moment Preview Card
          Container(
            height: 240 * scale,
            padding: EdgeInsets.all(16 * scale),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20 * scale),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A2A78), Color(0xFF2A6A8A)],
              ),
              border: Border.all(
                color: const Color(0x38FFFFFF),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4E7E).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999 * scale),
                          ),
                          child: Text(
                            '$reportCount reports',
                            style: TextStyle(
                              color: const Color(0xFFFF4E7E),
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 8 * scale),
                        Container(
                          width: 44 * scale,
                          height: 44 * scale,
                          decoration: const BoxDecoration(
                            color: Color(0xD91C1C1E),
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
                // Bottom Gradient Banner
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
          SizedBox(height: 16 * scale),

          // Blur / Review Banner
          Container(
            padding: EdgeInsets.all(16 * scale),
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(color: const Color(0x24FFFFFF), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.remove_red_eye_outlined, color: const Color(0xFF58C3F4), size: 20 * scale),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Text(
                    'Content stays blurred until you reveal it for review.',
                    style: TextStyle(
                      color: const Color(0xFF8A8EB3),
                      fontSize: 13 * scale,
                      height: 1.4,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _isRevealed = !_isRevealed);
                  },
                  child: Text(
                    _isRevealed ? 'Hide' : 'Reveal',
                    style: TextStyle(
                      color: const Color(0xFF58C3F4),
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16 * scale),

          // Details Card Container
          Container(
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(20 * scale),
              border: Border.all(color: const Color(0x24FFFFFF), width: 1.5),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 4 * scale),
              child: Column(
                children: [
                  _buildDetailRow(scale, 'Sent to', sentToCount),
                  Divider(height: 1, color: const Color(0x24FFFFFF)),
                  _buildDetailRow(scale, 'Unlock rule', unlockRuleStr),
                  Divider(height: 1, color: const Color(0x24FFFFFF)),
                  _buildDetailRow(scale, 'Created', createdDateStr),
                  Divider(height: 1, color: const Color(0x24FFFFFF)),
                  _buildDetailRow(scale, 'Status', isLocked ? 'Locked' : 'Unlocked'),
                ],
              ),
            ),
          ),
          SizedBox(height: 20 * scale),

          // Reasons Section
          Text(
            'Reasons',
            style: TextStyle(
              color: const Color(0xFF8A8EB3),
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10 * scale),
          Wrap(
            spacing: 8 * scale,
            runSpacing: 8 * scale,
            children: reasons.map((reason) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4E7E).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999 * scale),
                ),
                child: Text(
                  reason,
                  style: TextStyle(
                    color: const Color(0xFFFF4E7E),
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 32 * scale),

          // Action Buttons (Keep & Remove)
          if (_isSubmitting)
            const Center(child: CircularProgressIndicator(color: Color(0xFF58C3F4)))
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52 * scale,
                    decoration: BoxDecoration(
                      color: const Color(0x12FFFFFF),
                      borderRadius: BorderRadius.circular(999 * scale),
                      border: Border.all(color: const Color(0x28FFFFFF), width: 1.5),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _approveMoment,
                        borderRadius: BorderRadius.circular(999 * scale),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, color: Colors.white, size: 20 * scale),
                            SizedBox(width: 8 * scale),
                            Text(
                              'Keep',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14 * scale),
                Expanded(
                  child: Container(
                    height: 52 * scale,
                    decoration: BoxDecoration(
                      color: const Color(0x1FFF6B6B),
                      borderRadius: BorderRadius.circular(999 * scale),
                      border: Border.all(color: const Color(0xB3FF6B6B), width: 1.5),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _rejectMoment(reasons.isNotEmpty ? reasons.first : 'Inappropriate content'),
                        borderRadius: BorderRadius.circular(999 * scale),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline_rounded, color: const Color(0xFFFF6B6B), size: 20 * scale),
                            SizedBox(width: 8 * scale),
                            Text(
                              'Remove',
                              style: TextStyle(
                                color: const Color(0xFFFF6B6B),
                                fontSize: 15 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(double scale, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 11 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF8A8EB3),
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
