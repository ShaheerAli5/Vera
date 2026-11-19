import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/utils/server_time_manager.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../account/data/datasources/account_remote_data_source.dart';
import '../../../account/data/repositories/account_repository_impl.dart';
import '../../data/datasources/moments_remote_data_source.dart';
import '../../data/repositories/moments_repository_impl.dart';
import '../../domain/entities/moment.dart';
import '../pages/edit_moment_screen.dart';
import '../utils/moment_permission_utils.dart';

class MomentCard extends StatefulWidget {
  const MomentCard({
    super.key,
    required this.moment,
    required this.scale,
    this.showDiscoverActions = false,
    this.onTap,
    this.onMomentUpdated,
    this.onMomentBlocked,
  });

  final Moment moment;
  final double scale;
  final bool showDiscoverActions;
  final VoidCallback? onTap;
  final ValueChanged<Moment>? onMomentUpdated;
  final ValueChanged<Moment>? onMomentBlocked;

  @override
  State<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<MomentCard> {
  bool _isOwner = false;
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _displayName = widget.moment.userName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPermissions();
    });
  }

  Future<void> _loadPermissions() async {
    final result = await MomentPermissionUtils.resolve(context: context, moment: widget.moment);
    if (!mounted) return;
    setState(() {
      _isOwner = result['isOwner'] == true;
      _displayName = result['displayName']?.toString() ?? widget.moment.userName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final moment = widget.moment;
    final scale = widget.scale;
    final showDiscoverActions = widget.showDiscoverActions;
    final onTap = widget.onTap;

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
            // Background Image with Blur
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: isUnlocked ? 0 : 7,
                sigmaY: isUnlocked ? 0 : 7,
              ),
              child: moment.backgroundImageUrl.isNotEmpty
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
                    ),
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

  Widget _buildAuthorBadge(double inputScale) {
    final moment = widget.moment;
    final scale = widget.scale;
    final displayName = _displayName;
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
                  Text(moment.sentBadgeTitle ?? displayName, style: TextStyle(
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
  Widget _buildTopLock(double inputScale) {
    final moment = widget.moment;
    final scale = widget.scale;
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
        return Container(
            padding: EdgeInsets.fromLTRB(
              24 * responsiveScale,
              12 * responsiveScale,
              24 * responsiveScale,
              40 * responsiveScale,
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
                          widget.moment.userAvatarUrl,
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
                          'Moment from $_displayName',
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
                  if (_isOwner) ...[
                    _MomentActionButton(
                      label: 'Edit moment',
                      scale: responsiveScale,
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        final updated = await Navigator.of(context).push<Moment>(
                          MaterialPageRoute<Moment>(
                            builder: (_) => EditMomentScreen(moment: widget.moment),
                          ),
                        );
                        if (updated != null && widget.onMomentUpdated != null) {
                          widget.onMomentUpdated!(updated);
                        }
                      },
                    ),
                    SizedBox(height: 16 * responsiveScale),
                  ],
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
                  if (!_isOwner) ...[
                    SizedBox(height: 16 * responsiveScale),
                    _MomentActionButton(
                      label: 'Report $_displayName',
                      scale: responsiveScale,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Future<void>.delayed(const Duration(milliseconds: 250), () {
                          if (context.mounted) _showReportUserReasons(context);
                        });
                      },
                    ),
                    SizedBox(height: 16 * responsiveScale),
                    _MomentActionButton(
                      label: 'Block $_displayName',
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
                ],
            ),
        );
      },
    );
  }

  void _showBlockConfirmation(BuildContext context) {
    final displayName = _displayName;
    final responsiveScale =
        (MediaQuery.sizeOf(context).width / 393).clamp(.82, 1.12);
    final firstName = displayName.split(' ').first;
    final client = ApiClientScope.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3090A17),
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(
          24 * responsiveScale,
          12 * responsiveScale,
          24 * responsiveScale,
          40 * responsiveScale,
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
                '$displayName. You can unblock them in Privacy settings.',
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
              label: 'Block $displayName',
              scale: responsiveScale,
              isDestructive: true,
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final targetUserId = widget.moment.creatorId;
                if (targetUserId == null || targetUserId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot block this user.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                try {
                  final accountRepo = AccountRepositoryImpl(AccountRemoteDataSource(client));
                  await accountRepo.blockUser(targetUserId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$displayName has been blocked.'),
                        backgroundColor: const Color(0xFF6B42FF),
                      ),
                    );
                    widget.onMomentBlocked?.call(widget.moment);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to block user: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportReasons(BuildContext context) {
    final responsiveScale =
        (MediaQuery.sizeOf(context).width / 393).clamp(.82, 1.12);
    final client = ApiClientScope.of(context);
    final momentsRepo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3090A17),
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(
          24 * responsiveScale,
          12 * responsiveScale,
          24 * responsiveScale,
          40 * responsiveScale,
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
            for (final entry in const [
              MapEntry('Spam', 'SPAM'),
              MapEntry('Inappropriate content', 'INAPPROPRIATE_CONTENT'),
              MapEntry('Harassment', 'HARASSMENT'),
              MapEntry('Something else', 'OTHER'),
            ]) ...[
              _MomentActionButton(
                label: entry.key,
                scale: responsiveScale,
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  String? details;
                  if (entry.value == 'OTHER') {
                    if (context.mounted) {
                      details = await _promptReportDetails(context, responsiveScale);
                      if (details == null || details.trim().isEmpty) {
                        return;
                      }
                    }
                  }
                  try {
                    await momentsRepo.reportMoment(
                      momentId: moment.id,
                      reason: entry.value,
                      details: details,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report submitted. Thank you for keeping Vera safe.'),
                          backgroundColor: Color(0xFF6B42FF),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Report submission failed: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
              ),
              if (entry.key != 'Something else')
                SizedBox(height: 16 * responsiveScale),
            ],
          ],
        ),
      ),
    );
  }

  void _showReportUserReasons(BuildContext context) {
    final responsiveScale =
        (MediaQuery.sizeOf(context).width / 393).clamp(.82, 1.12);
    final client = ApiClientScope.of(context);
    final accountRepo = AccountRepositoryImpl(AccountRemoteDataSource(client));
    final targetUserId = widget.moment.creatorId;

    if (targetUserId == null || targetUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot identify user to report.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3090A17),
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(
          24 * responsiveScale,
          12 * responsiveScale,
          24 * responsiveScale,
          40 * responsiveScale,
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
                      'Report $_displayName',
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
            for (final entry in const [
              MapEntry('Harassment or bullying', 'HARASSMENT'),
              MapEntry('Spam or scam', 'SPAM'),
              MapEntry('Hate speech', 'HATE_SPEECH'),
              MapEntry('Explicit or inappropriate content', 'EXPLICIT_CONTENT'),
              MapEntry('Something else', 'OTHER'),
            ]) ...[
              _MomentActionButton(
                label: entry.key,
                scale: responsiveScale,
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  String? details;
                  if (entry.value == 'OTHER') {
                    if (context.mounted) {
                      details = await _promptReportDetails(context, responsiveScale);
                      if (details == null || details.trim().isEmpty) {
                        return;
                      }
                    }
                  }
                  try {
                    await accountRepo.reportUser(
                      userId: targetUserId,
                      reason: entry.value,
                      details: details,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Report against $_displayName submitted. Thank you.'),
                          backgroundColor: const Color(0xFF6B42FF),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Report submission failed: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
              ),
              if (entry.key != 'Something else')
                SizedBox(height: 16 * responsiveScale),
            ],
          ],
        ),
      ),
    );
  }

  Future<String?> _promptReportDetails(BuildContext context, double scale) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF17182D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20 * scale)),
        title: Text(
          'Report details',
          style: TextStyle(color: Colors.white, fontSize: 18 * scale),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: Colors.white, fontSize: 14 * scale),
          decoration: InputDecoration(
            hintText: 'Please describe the issue...',
            hintStyle: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 14 * scale),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: const BorderSide(color: Color(0xFF373657)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: const BorderSide(color: Color(0xFF9044FB)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancel', style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 14 * scale)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9044FB)),
            onPressed: () => Navigator.of(dialogCtx).pop(controller.text.trim()),
            child: Text('Submit', style: TextStyle(color: Colors.white, fontSize: 14 * scale)),
          ),
        ],
      ),
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
