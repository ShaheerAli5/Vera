import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
  MomentModel? _moment;
  bool _isLoading = false;
  bool _isSubmitting = false;

  VideoPlayerController? _videoController;
  bool _isVideoInitializing = false;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  String? _videoErrorMessage;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _moment = widget.initialMoment;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_moment == null) {
        _fetchMoment();
      } else if (_moment!.isVideo || _moment!.contentType?.toUpperCase() == 'VIDEO') {
        final client = ApiClientScope.of(context);
        final mediaUrl = adminMomentMediaUrl(client, _moment?.mediaUrl, widget.momentId);
        final mediaHeaders = adminMediaHeaders(client);
        _initVideoPlayer(mediaUrl, mediaHeaders);
      }
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideoPlayer(String mediaUrl, Map<String, String> headers) async {
    if (_videoController != null || _isVideoInitializing) return;
    setState(() {
      _isVideoInitializing = true;
      _hasVideoError = false;
      _videoErrorMessage = null;
    });

    try {
      VideoPlayerController? controller;
      bool initialized = false;
      VideoPlayerController? netController;

      try {
        netController = VideoPlayerController.networkUrl(
          Uri.parse(mediaUrl),
          httpHeaders: headers,
        );
        await netController.initialize().timeout(const Duration(seconds: 4));
        controller = netController;
        initialized = true;
      } catch (_) {
        netController?.dispose();
        initialized = false;
      }

      if (!initialized) {
        final client = ApiClientScope.of(context);
        final response = await client.getRaw('/admin/moments/${widget.momentId}/media');
        final tempFile = File('${Directory.systemTemp.path}/admin_moment_${widget.momentId}.mp4');
        await tempFile.writeAsBytes(response.bodyBytes, flush: true);
        final fileController = VideoPlayerController.file(tempFile);
        await fileController.initialize();
        controller = fileController;
      }

      if (controller == null) {
        if (!mounted) return;
        setState(() {
          _isVideoInitializing = false;
          _hasVideoError = true;
          _videoErrorMessage = 'Failed to load video';
        });
        return;
      }

      _videoController = controller;
      controller.setLooping(true);
      await controller.play();
      if (!mounted) return;
      setState(() {
        _isVideoInitializing = false;
        _isVideoInitialized = true;
        _isPlaying = true;
      });
      controller.addListener(() {
        if (!mounted) return;
        final playing = controller!.value.isPlaying;
        if (playing != _isPlaying) {
          setState(() => _isPlaying = playing);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVideoInitializing = false;
        _hasVideoError = true;
        _videoErrorMessage = e.toString();
      });
    }
  }

  void _togglePlayPause() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
      setState(() => _isPlaying = false);
    } else {
      _videoController!.play();
      setState(() => _isPlaying = true);
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

      if (moment.isVideo || moment.contentType?.toUpperCase() == 'VIDEO') {
        final mediaUrl = adminMomentMediaUrl(client, moment.mediaUrl, widget.momentId);
        final mediaHeaders = adminMediaHeaders(client);
        _initVideoPlayer(mediaUrl, mediaHeaders);
      }
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final moment = _moment;
    final apiClient = ApiClientScope.of(context);
    final mediaUrl = adminMomentMediaUrl(apiClient, moment?.mediaUrl, widget.momentId);
    final mediaHeaders = adminMediaHeaders(apiClient);
    final isVideo = moment?.isVideo == true || moment?.contentType?.toUpperCase() == 'VIDEO';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Media View Area
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF9044FB)))
          else if (isVideo) ...[
            if (_isVideoInitialized && _videoController != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio > 0
                      ? _videoController!.value.aspectRatio
                      : 9 / 16,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else if (_isVideoInitializing)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF9044FB)),
                    SizedBox(height: 16),
                    Text(
                      'Loading video stream...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              )
            else if (_hasVideoError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Failed to load video stream',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (_videoErrorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _videoErrorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          _videoController?.dispose();
                          _videoController = null;
                          _initVideoPlayer(mediaUrl, mediaHeaders);
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('Retry', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9044FB)),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Center(child: CircularProgressIndicator(color: Color(0xFF9044FB))),

            // Tap gesture detector for Video Play / Pause
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _togglePlayPause,
              child: Center(
                child: AnimatedOpacity(
                  opacity: !_isPlaying ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 64),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Image Display
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.5,
              child: Center(
                child: Image.network(
                  mediaUrl,
                  headers: mediaHeaders,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF9044FB),
                      ),
                    );
                  },
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
                          Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
                          SizedBox(height: 12),
                          Text(
                            'Failed to load media image',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Top Bar
          Positioned(
            top: MediaQuery.paddingOf(context).top,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    isVideo ? 'Video Review' : 'Media Review',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (isVideo && _isVideoInitialized && _videoController != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: _videoController!,
                        builder: (context, value, _) {
                          return Text(
                            '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          );
                        },
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          // Bottom Controls & Actions
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isVideo && _isVideoInitialized && _videoController != null) ...[
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFF9044FB),
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white10,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  const SizedBox(height: 8),
                ],
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _reject,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Reject', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _approve,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
