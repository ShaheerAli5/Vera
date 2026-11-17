import 'package:flutter/material.dart';

import '../../../../main.dart' show ApiClientScope;
import '../../../home/data/models/moment_model.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../utils/admin_media_utils.dart';

class AdminReviewMomentMediaScreen extends StatefulWidget {
  final String momentId;
  final MomentModel? initialMoment;

  const AdminReviewMomentMediaScreen({
    super.key,
    required this.momentId,
    this.initialMoment,
  });

  @override
  State<AdminReviewMomentMediaScreen> createState() => _AdminReviewMomentMediaScreenState();
}

class _AdminReviewMomentMediaScreenState extends State<AdminReviewMomentMediaScreen> {
  bool _isPlaying = true;
  MomentModel? _moment;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _moment = widget.initialMoment;
    if (_moment == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchMoment();
      });
    }
  }

  Future<void> _fetchMoment() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approve() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      final moment = _moment;
      await repo.approveMoment(
        widget.momentId,
        version: moment?.version ?? 1,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moment approved successfully.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve moment: ${e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')}')),
      );
    }
  }

  Future<void> _reject() async {
    if (_isSubmitting) return;

    String? reason = 'Inappropriate content';
    final customReasonController = TextEditingController();
    final reasons = ['Inappropriate content', 'Spam', 'Copyright violation', 'Other'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161626),
            title: const Text('Reject Moment', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select a reason for rejection:', style: TextStyle(color: Color(0xFFA2A5C2))),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  dropdownColor: const Color(0xFF161626),
                  style: const TextStyle(color: Colors.white),
                  items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setDlgState(() => reason = val),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFFA2A5C2))),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
                child: const Text('Reject', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );

    if (confirm != true || !mounted) return;
    final client = ApiClientScope.of(context);
    final finalReason = (reason == 'Other' && customReasonController.text.trim().isNotEmpty)
        ? customReasonController.text.trim()
        : (reason ?? 'Inappropriate content');

    setState(() => _isSubmitting = true);

    try {
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      final moment = _moment;
      await repo.rejectMoment(
        widget.momentId,
        reason: finalReason,
        version: moment?.version ?? 1,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Moment rejected: $finalReason')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject moment: ${e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final moment = _moment;
    final apiClient = ApiClientScope.of(context);
    final mediaUrl = adminMomentMediaUrl(apiClient, moment?.mediaUrl, widget.momentId);
    final mediaHeaders = adminMediaHeaders(apiClient);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF9044FB)))
          else
            Image.network(
              mediaUrl,
              headers: mediaHeaders,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2C1338),
                      Color(0xFF1E2B45),
                      Color(0xFF0F172A),
                    ],
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 64),
                      SizedBox(height: 12),
                      Text(
                        'Moment Media Review',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Play/Pause Overlay
          GestureDetector(
            onTap: () {
              setState(() {
                _isPlaying = !_isPlaying;
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: !_isPlaying
                    ? const Icon(Icons.play_arrow, color: Colors.white70, size: 80)
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          // Top Bar
          Positioned(
            top: MediaQuery.paddingOf(context).top,
            left: 0,
            right: 0,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('Media Review', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),

          // Bottom Actions
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: _isSubmitting
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _reject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Reject', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _approve,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
