import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/server_time_manager.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../home/data/models/moment_model.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/repositories/admin_repository_impl.dart';
import 'admin_review_moment_media_screen.dart';
import '../utils/admin_media_utils.dart';

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

class _AdminReviewMomentScreenState extends State<AdminReviewMomentScreen> {
  MomentModel? _moment;
  bool _isLoading = false;
  bool _isSubmitting = false;
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
          content: Text('Moment approved successfully.'),
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
          content: Text('Failed to approve moment: ${e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')}'),
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
          content: Text('Moment rejected: $reason'),
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
          content: Text('Failed to reject moment: ${e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161626),
        title: const Text('Approve Moment', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to approve this moment and publish it?', style: TextStyle(color: Color(0xFFA2A5C2))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFFA2A5C2)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _approveMoment();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9044FB)),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    String? reason = 'Inappropriate content';
    final customReasonController = TextEditingController();
    final reasons = ['Inappropriate content', 'Spam', 'Copyright violation', 'Other'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161626),
            title: const Text('Reject Moment', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select a reason for rejection:', style: TextStyle(color: Color(0xFFA2A5C2))),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: reason,
                    dropdownColor: const Color(0xFF161626),
                    style: const TextStyle(color: Colors.white),
                    items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setState(() => reason = val),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF080914),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (reason == 'Other') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: customReasonController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter specific reason...',
                        hintStyle: const TextStyle(color: Color(0xFF535370)),
                        filled: true,
                        fillColor: const Color(0xFF080914),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFFA2A5C2)))),
              ElevatedButton(
                onPressed: () {
                  final finalReason = (reason == 'Other' && customReasonController.text.trim().isNotEmpty)
                      ? customReasonController.text.trim()
                      : (reason ?? 'Inappropriate content');
                  Navigator.pop(ctx);
                  _rejectMoment(finalReason);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
                child: const Text('Reject', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 48 * scale,
                        height: 48 * scale,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24 * scale),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18 * scale,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 16 * scale),
                        child: SizedBox(
                          height: 24 * scale,
                          child: Text(
                            'Review Moment',
                            style: TextStyle(
                              color: const Color(0xFFF7F5FF),
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w600,
                              height: 24 / 16,
                              letterSpacing: 0,
                            ),
                          ),
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
        child: CircularProgressIndicator(color: Color(0xFF9044FB)),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9044FB)),
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
    final caption = (moment.message != null && moment.message!.isNotEmpty)
        ? moment.message!
        : ((moment.teaser != null && moment.teaser!.isNotEmpty)
            ? moment.teaser!
            : moment.title);

    final apiClient = ApiClientScope.of(context);
    final mediaUrl = adminMomentMediaUrl(apiClient, moment.mediaUrl, moment.id);
    final mediaHeaders = adminMediaHeaders(apiClient);

    return SingleChildScrollView(
      padding: EdgeInsets.all(24 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              final res = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AdminReviewMomentMediaScreen(
                    momentId: moment.id,
                    initialMoment: moment,
                  ),
                ),
              );
              if (res == true && mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: Container(
              width: double.infinity,
              height: 380 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFF1B152E),
                borderRadius: BorderRadius.circular(24 * scale),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24 * scale),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      mediaUrl,
                      headers: mediaHeaders,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.image_not_supported, color: Colors.white54, size: 48 * scale),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(16 * scale),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.play_arrow, color: Colors.white, size: 48 * scale),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 24 * scale),
          Text('Creator', style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 13 * scale)),
          SizedBox(height: 8 * scale),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF1B152E),
                backgroundImage: moment.creatorAvatarUrl != null && moment.creatorAvatarUrl!.isNotEmpty
                    ? NetworkImage(moment.creatorAvatarUrl!)
                    : null,
                child: (moment.creatorAvatarUrl == null || moment.creatorAvatarUrl!.isEmpty)
                    ? const Icon(Icons.person, color: Color(0xFFC68CFF))
                    : null,
              ),
              SizedBox(width: 12 * scale),
              Text(
                '@$creatorName',
                style: TextStyle(color: Colors.white, fontSize: 16 * scale, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 24 * scale),
          Text('Title / Caption', style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 13 * scale)),
          SizedBox(height: 8 * scale),
          Text(
            caption,
            style: TextStyle(color: Colors.white, fontSize: 15 * scale, height: 1.4),
          ),
          if (moment.unlockRuleType != null) ...[
            SizedBox(height: 20 * scale),
            Text('Unlock Rule', style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 13 * scale)),
            SizedBox(height: 6 * scale),
            Text(
              'Type: ${moment.unlockRuleType}'
              '${moment.unlockAt != null ? ' (Unlock at: ${moment.unlockAt!.toLocal().toString().split('.').first})' : ''}'
              '${moment.locationName != null ? ' (Location: ${moment.locationName})' : ''}',
              style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 14 * scale),
            ),
          ],
          SizedBox(height: 48 * scale),
          if (_isSubmitting)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF9044FB)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48 * scale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF161626),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF373657)),
                      ),
                      child: TextButton(
                        onPressed: () => _showRejectDialog(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: Text('Reject', style: TextStyle(color: Colors.white, fontSize: 14 * scale, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16 * scale),
                Expanded(
                  child: SizedBox(
                    height: 48 * scale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9044FB), Color(0xFFC057FF)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x889044FB),
                            blurRadius: 28,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () => _showApproveDialog(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: Text('Approve', style: TextStyle(color: Colors.white, fontSize: 14 * scale, fontWeight: FontWeight.w600)),
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
}
