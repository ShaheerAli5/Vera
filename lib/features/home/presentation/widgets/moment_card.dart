import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/utils/server_time_manager.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../domain/entities/moment.dart';
import '../pages/edit_moment_screen.dart';

class MomentCard extends StatelessWidget {
  const MomentCard({
    super.key,
    required this.moment,
    required this.scale,
    this.showDiscoverActions = false,
    this.onTap,
    this.onMomentUpdated,
  });

  final Moment moment;
  final double scale;
  final bool showDiscoverActions;
  final VoidCallback? onTap;
  final ValueChanged<Moment>? onMomentUpdated;

  @override
  Widget build(BuildContext context) {
    const cardHeight = 194.0;
    const cardRadius = 20.0;
    final bool isUnlocked = moment.isReadyToOpen ||
        moment.unlockedAt != null ||
        (moment.unlockAt != null &&
            !ServerTimeManager.instance.now.isBefore(moment.unlockAt!));
    final client = ApiClientScope.of(context);
    final token = client.authToken;
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
      height: cardHeight * scale,
      margin: EdgeInsets.only(bottom: 16 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius * scale),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius * scale),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image / Video Cover with Blur
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: isUnlocked ? 0 : 7,
                sigmaY: isUnlocked ? 0 : 7,
              ),
              child: (moment.isVideo || moment.contentType?.toUpperCase() == 'VIDEO')
                  ? _VideoThumbnailCover(
                      videoUrl: moment.backgroundImageUrl.isNotEmpty
                          ? moment.backgroundImageUrl
                          : (moment.id.isNotEmpty
                              ? 'https://vera.aptechmedia.com/api/v1/moments/${moment.id}/media'
                              : ''),
                      headers: headers,
                    )
                  : (moment.backgroundImageUrl.isNotEmpty
                      ? Image.network(
                          moment.backgroundImageUrl,
                          headers: headers,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1E2B45),
                                  Color(0xFF0F172A),
                                  Color(0xFF2C1338),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1E2B45),
                                Color(0xFF0F172A),
                                Color(0xFF2C1338),
                              ],
                            ),
                          ),
                        )),
            ),

            // Dark gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x44000000),
                    Color(0x11000000),
                    Color(0x55000000),
                  ],
                ),
              ),
            ),

            // Top Floating User Badge (Frame 1618874368)
            Positioned(
              top: 14 * scale,
              left: 12 * scale,
              child: _buildAuthorBadge(scale),
            ),
            // Both feeds show the lock at the upper-right; Discover adds menu.
            if (showDiscoverActions)
              Positioned(
                top: 12 * scale,
                right: 12 * scale,
                child: SizedBox(
                  height: 52 * scale,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTopLock(scale),
                      SizedBox(width: 4 * scale),
                      _buildMoreButton(context, scale),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                top: 12 * scale,
                right: 12 * scale,
                child: _buildTopLock(scale),
              ),

            // Bottom Banner (Unlock Condition)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20 * scale),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    height: 48.5 * scale,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * scale,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xCCDD4EFC),
                          Color(0x8031367D),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20 * scale),
                      border: Border.all(
                        color: const Color(0x55FFFFFF),
                        width: 2 * scale,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          moment.unlockType == MomentUnlockType.location
                              ? Icons.location_on_rounded
                              : Icons.access_time_filled_rounded,
                          color: Colors.white,
                          size: 20 * scale,
                        ),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: Text(
                            isUnlocked
                                ? 'Ready to open'
                                : moment.unlockCondition,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (moment.unlockType == MomentUnlockType.time ||
                            moment.sentBadgeTitle != null) ...[
                          SizedBox(width: 8 * scale),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18 * scale,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAuthorBadge(double scale) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999 * scale),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 52 * scale,
          padding: EdgeInsets.fromLTRB(
            12 * scale, 6 * scale, 12 * scale, 6 * scale,
          ),
          decoration: BoxDecoration(
            color: const Color(0x38FFFFFF),
            borderRadius: BorderRadius.circular(999 * scale),
            border: Border.all(color: const Color(0x40FFFFFF), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (moment.isPublicSentMoment)
                SizedBox(
                  width: 28 * scale,
                  height: 28 * scale,
                  child: Icon(Icons.groups_2_outlined,
                      color: Colors.white, size: 24 * scale),
                )
              else
                Container(
                  width: 40 * scale,
                  height: 40 * scale,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: moment.userAvatarUrl.isNotEmpty
                        ? Image.network(
                            moment.userAvatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFF6B42FF),
                              child: Icon(Icons.person, size: 20 * scale,
                                  color: Colors.white),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF6B42FF),
                            child: Icon(Icons.person, size: 20 * scale,
                                color: Colors.white),
                          ),
                  ),
                ),
              SizedBox(width: 10 * scale),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(moment.sentBadgeTitle ?? moment.userName, style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  )),
                  SizedBox(height: 2 * scale),
                  Text(moment.sentBadgeSubtitle ?? moment.timeAgo, style: TextStyle(
                    color: const Color(0xFFE2E2F0),
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w400,
                    height: 1.1,
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTopLock(double scale) {
    final bool isUnlocked = moment.isReadyToOpen ||
        moment.unlockedAt != null ||
        (moment.unlockAt != null &&
            !ServerTimeManager.instance.now.isBefore(moment.unlockAt!));
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 52 * scale,
          height: 52 * scale,
          decoration: BoxDecoration(
            color: const Color(0x8C090A17),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x30FFFFFF)),
          ),
          child: Icon(
            isUnlocked
                ? Icons.lock_open_rounded
                : Icons.lock_outline_rounded,
            color: isUnlocked
                ? const Color(0xFF7DF0B0)
                : Colors.white,
            size: 22 * scale,
          ),
        ),
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context, double scale) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 52 * scale,
          height: 52 * scale,
          decoration: BoxDecoration(
            color: const Color(0x8C090A17),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x30FFFFFF)),
          ),
          child: IconButton(
            onPressed: () => _showMomentActions(context),
            icon: Icon(
              Icons.more_horiz_rounded,
              color: Colors.white,
              size: 22 * scale,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  void _showMomentActions(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final responsiveScale = (screenWidth / 393).clamp(.82, 1.12);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3090A17),
      builder: (sheetContext) {
        final bottomPad = MediaQuery.paddingOf(sheetContext).bottom;
        return Container(
            padding: EdgeInsets.fromLTRB(
              24 * responsiveScale,
              12 * responsiveScale,
              24 * responsiveScale,
              (40 * responsiveScale) + bottomPad,
            ),
            decoration: BoxDecoration(
              color: const Color(0x59090A17),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24 * responsiveScale),
                bottom: Radius.circular(24 * responsiveScale),
              ),
              border: Border.all(
                color: const Color(0x454B3B70),
                width: 1 * responsiveScale,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x77000000),
                  blurRadius: 30,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 36 * responsiveScale,
                    child: Row(
                      children: [
                      ClipOval(
                        child: Image.network(
                          moment.userAvatarUrl,
                          width: 36 * responsiveScale,
                          height: 36 * responsiveScale,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 36 * responsiveScale,
                            height: 36 * responsiveScale,
                            color: const Color(0xFF6B42FF),
                            child: Icon(Icons.person,
                                color: Colors.white,
                                size: 18 * responsiveScale),
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * responsiveScale),
                      Expanded(
                        child: Text(
                          'Moment from ${moment.userName}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16 * responsiveScale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36 * responsiveScale,
                        height: 36 * responsiveScale,
                        child: IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: Icon(Icons.close_rounded,
                              color: Colors.white, size: 18 * responsiveScale),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0x4410101D),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24 * responsiveScale),
                  _MomentActionButton(
                    label: 'Edit moment',
                    scale: responsiveScale,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      final updated = await Navigator.of(context).push<Moment>(
                        MaterialPageRoute<Moment>(
                          builder: (_) => EditMomentScreen(moment: moment),
                        ),
                      );
                      if (updated != null && onMomentUpdated != null) {
                        onMomentUpdated!(updated);
                      }
                    },
                  ),
                  SizedBox(height: 16 * responsiveScale),
                  _MomentActionButton(
                    label: 'Report moment',
                    scale: responsiveScale,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Future<void>.delayed(const Duration(milliseconds: 250), () {
                        if (context.mounted) _showReportReasons(context);
                      });
                    },
                  ),
                  SizedBox(height: 16 * responsiveScale),
                  _MomentActionButton(
                    label: 'Block ${moment.userName}',
                    scale: responsiveScale,
                    isDestructive: true,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Future<void>.delayed(const Duration(milliseconds: 250), () {
                        if (context.mounted) {
                          _showBlockConfirmation(context);
                        }
                      });
                    },
                  ),
                ],
            ),
        );
      },
    );
  }

  void _showBlockConfirmation(BuildContext context) {
    final responsiveScale =
        (MediaQuery.sizeOf(context).width / 393).clamp(.82, 1.12);
    final firstName = moment.userName.split(' ').first;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3090A17),
      builder: (sheetContext) {
        final bottomPad = MediaQuery.paddingOf(sheetContext).bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(
            24 * responsiveScale,
            12 * responsiveScale,
            24 * responsiveScale,
            (40 * responsiveScale) + bottomPad,
          ),
          decoration: BoxDecoration(
            color: const Color(0x59090A17),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24 * responsiveScale),
              bottom: Radius.circular(24 * responsiveScale),
            ),
            border: Border.all(
              color: const Color(0x454B3B70),
              width: 1 * responsiveScale,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x77000000),
                blurRadius: 30,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 36 * responsiveScale,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Block $firstName?',
                        style: TextStyle(
                          color: const Color(0xFFF7F5FF),
                          fontSize: 24 * responsiveScale,
                          fontWeight: FontWeight.w600,
                          height: 32 / 24,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 36 * responsiveScale,
                      height: 36 * responsiveScale,
                      child: IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18 * responsiveScale,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0x4410101D),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4 * responsiveScale),
              SizedBox(
                width: 286 * responsiveScale,
                height: 66 * responsiveScale,
                child: Text(
                  "You won't receive new invitations or notifications from "
                  '${moment.userName}. You can unblock them in Privacy settings.',
                  style: TextStyle(
                    color: const Color(0xFFA2A5C2),
                    fontSize: 14 * responsiveScale,
                    fontWeight: FontWeight.w400,
                    height: 22 / 14,
                  ),
                ),
              ),
              SizedBox(height: 24 * responsiveScale),
              _MomentActionButton(
                label: 'Block ${moment.userName}',
                scale: responsiveScale,
                isDestructive: true,
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportReasons(BuildContext context) {
    final responsiveScale =
        (MediaQuery.sizeOf(context).width / 393).clamp(.82, 1.12);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3090A17),
      builder: (sheetContext) {
        final bottomPad = MediaQuery.paddingOf(sheetContext).bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(
            24 * responsiveScale,
            12 * responsiveScale,
            24 * responsiveScale,
            (40 * responsiveScale) + bottomPad,
          ),
          decoration: BoxDecoration(
            color: const Color(0x59090A17),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24 * responsiveScale),
              bottom: Radius.circular(24 * responsiveScale),
            ),
            border: Border.all(
              color: const Color(0x454B3B70),
              width: 1 * responsiveScale,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x77000000),
                blurRadius: 30,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 36 * responsiveScale,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Why are you reporting this?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 * responsiveScale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 36 * responsiveScale,
                      height: 36 * responsiveScale,
                      child: IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18 * responsiveScale,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0x4410101D),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24 * responsiveScale),
              for (final reason in const [
                'Spam',
                'Inappropriate content',
                'Harassment',
                'Something else',
              ]) ...[
                _MomentActionButton(
                  label: reason,
                  scale: responsiveScale,
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
                if (reason != 'Something else')
                  SizedBox(height: 16 * responsiveScale),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MomentActionButton extends StatelessWidget {
  const _MomentActionButton({
    required this.label,
    required this.scale,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final double scale;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 48 * scale),
      child: SizedBox(
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: EdgeInsets.symmetric(
                  vertical: 12 * scale, horizontal: 16 * scale),
              decoration: BoxDecoration(
                gradient: isDestructive
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0x20FF6B8B),
                          Color(0x12F7F5FF),
                          Color(0x201E1A34),
                        ],
                      )
                    : const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0x26F7F5FF),
                          Color(0x12131724),
                          Color(0x20F7F5FF),
                        ],
                      ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0x44FFFFFF),
                  width: .8,
                ),
              ),
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor:
                      isDestructive ? const Color(0xFFFF6B8B) : Colors.white,
                  shape: const StadiumBorder(),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoThumbnailCover extends StatefulWidget {
  const _VideoThumbnailCover({
    required this.videoUrl,
    required this.headers,
  });

  final String videoUrl;
  final Map<String, String> headers;

  @override
  State<_VideoThumbnailCover> createState() => _VideoThumbnailCoverState();
}

class _VideoThumbnailCoverState extends State<_VideoThumbnailCover> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    if (widget.videoUrl.isEmpty) return;
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: widget.headers,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.setVolume(0);
      controller.setLooping(true);
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (_) {
      // Fallback
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized && _controller != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width > 0 ? _controller!.value.size.width : 100,
              height: _controller!.value.size.height > 0 ? _controller!.value.size.height : 100,
              child: VideoPlayer(_controller!),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF6D28D9),
            Color(0xFF312E81),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
