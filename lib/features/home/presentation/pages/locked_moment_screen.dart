import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/server_time_manager.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/moments_remote_data_source.dart';
import '../../data/repositories/moments_repository_impl.dart';
import '../../domain/entities/moment.dart';
import 'edit_moment_screen.dart';
import 'unlocked_moment_screen.dart';

class LockedMomentScreen extends StatefulWidget {
  const LockedMomentScreen({super.key, required this.moment});

  final Moment moment;

  @override
  State<LockedMomentScreen> createState() => _LockedMomentScreenState();
}

class _LockedMomentScreenState extends State<LockedMomentScreen> {
  late Moment _currentMoment;
  bool _isChecking = false;
  int _ticksCount = 0;

  @override
  void initState() {
    super.initState();
    _currentMoment = widget.moment;
    ServerTimeManager.instance.ticker.addListener(_onTick);
    ServerTimeManager.instance.addResumedListener(_onResumed);
  }

  @override
  void dispose() {
    ServerTimeManager.instance.ticker.removeListener(_onTick);
    ServerTimeManager.instance.removeResumedListener(_onResumed);
    super.dispose();
  }

  void _onResumed() {
    if (!mounted) return;
    _checkIfReadySilent();
  }

  void _onTick() {
    if (!mounted) return;
    _ticksCount++;
    final now = ServerTimeManager.instance.now;

    if (_currentMoment.unlockAt != null && _currentMoment.status == 'PUBLISHED') {
      final isTimeReached = !now.isBefore(_currentMoment.unlockAt!);
      if (isTimeReached && !_isChecking && !_currentMoment.isReadyToOpen) {
        _checkIfReadySilent();
        return;
      }
    }

    if (_currentMoment.status == 'PENDING_REVIEW' && _ticksCount % 5 == 0 && !_isChecking) {
      _checkIfReadySilent();
      return;
    }

    setState(() {});
  }

  Future<void> _checkIfReadySilent() async {
    if (_isChecking || _currentMoment.id.isEmpty) return;
    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

      try {
        final unlockedModel = await repo.unlockMoment(
          momentId: _currentMoment.id,
        );
        final unlockedEntity = unlockedModel.toEntity().copyWith(isReadyToOpen: true);
        if (!mounted) return;
        setState(() {
          _currentMoment = unlockedEntity;
        });

        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => UnlockedMomentScreen(moment: unlockedEntity),
          ),
        );
        return;
      } catch (_) {
        final model = await repo.getMomentById(_currentMoment.id);
        final updated = model.toEntity();

        if (!mounted) return;
        setState(() {
          _currentMoment = updated;
        });

        if (updated.isReadyToOpen) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => UnlockedMomentScreen(moment: updated),
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _checkIfReady() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

      // Attempt to unlock on the server
      try {
        final unlockedModel = await repo.unlockMoment(
          momentId: _currentMoment.id,
        );
        final unlockedEntity = unlockedModel.toEntity().copyWith(isReadyToOpen: true);
        if (!mounted) return;
        setState(() {
          _currentMoment = unlockedEntity;
          _isChecking = false;
        });

        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => UnlockedMomentScreen(moment: unlockedEntity),
          ),
        );
        return;
      } catch (unlockErr) {
        // If unlock API returned an error, fetch latest moment status to update details
        final model = await repo.getMomentById(_currentMoment.id);
        final updated = model.toEntity();

        if (!mounted) return;
        setState(() {
          _currentMoment = updated;
          _isChecking = false;
        });

        if (updated.status == 'PENDING_REVIEW') {
          VeraPopup.show(
            context,
            title: 'Pending Admin Approval',
            message:
                'This moment has been submitted to admin and is awaiting approval. Once approved, it will be published.',
            icon: Icons.hourglass_top_rounded,
            accent: const Color(0xFFFFB74D),
          );
        } else if (updated.isReadyToOpen) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => UnlockedMomentScreen(moment: updated),
            ),
          );
        } else {
          final errorMsg = unlockErr
              .toString()
              .replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
          VeraPopup.show(
            context,
            title: 'Still locked',
            message: errorMsg.isNotEmpty && !errorMsg.contains('HTTP')
                ? errorMsg
                : 'This moment isn’t ready to open yet.\n${updated.unlockCondition}',
            icon: Icons.lock_outline_rounded,
            accent: const Color(0xFF8CB8FF),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      VeraPopup.show(
        context,
        title: 'Check failed',
        message: 'Could not refresh moment status from server.',
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    }
  }

  bool _isResendingInvite = false;
  bool _isAcceptingInvite = false;
  bool _isDecliningInvite = false;

  Future<void> _acceptInvitation() async {
    if (_isAcceptingInvite || _isDecliningInvite || _currentMoment.id.isEmpty) return;
    setState(() => _isAcceptingInvite = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
      final model = await repo.acceptInvitation(_currentMoment.id);
      final updated = model.toEntity();

      if (!mounted) return;
      setState(() {
        _currentMoment = updated.copyWith(invitationStatus: 'ACCEPTED');
        _isAcceptingInvite = false;
      });

      VeraPopup.show(
        context,
        title: 'Invitation Accepted',
        message: 'You have accepted the invitation for this moment.',
        icon: Icons.check_circle_outline_rounded,
        accent: const Color(0xFF7DF0B0),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAcceptingInvite = false);

      final errorMsg =
          e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
      VeraPopup.show(
        context,
        title: 'Accept Failed',
        message: errorMsg,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    }
  }

  Future<void> _declineInvitation() async {
    if (_isAcceptingInvite || _isDecliningInvite || _currentMoment.id.isEmpty) return;
    setState(() => _isDecliningInvite = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
      final model = await repo.declineInvitation(_currentMoment.id);
      final updated = model.toEntity();

      if (!mounted) return;
      setState(() {
        _currentMoment = updated.copyWith(invitationStatus: 'DECLINED');
        _isDecliningInvite = false;
      });

      VeraPopup.show(
        context,
        title: 'Invitation Declined',
        message: 'You have declined this moment invitation.',
        icon: Icons.cancel_outlined,
        accent: const Color(0xFF8A8EB3),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDecliningInvite = false);

      final errorMsg =
          e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
      VeraPopup.show(
        context,
        title: 'Decline Failed',
        message: errorMsg,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    }
  }

  Future<void> _resendInvite() async {
    if (_isResendingInvite || _currentMoment.id.isEmpty) return;
    setState(() => _isResendingInvite = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
      final result = await repo.resendInvite(_currentMoment.id);

      if (!mounted) return;
      setState(() => _isResendingInvite = false);

      final msg = result.message ??
          'Invites sent: ${result.sent}, Attempted: ${result.attempted}, Failed: ${result.failed}';
      VeraPopup.show(
        context,
        title: 'Invites Resent',
        message: msg,
        icon: Icons.mark_email_read_rounded,
        accent: const Color(0xFF7DF0B0),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResendingInvite = false);

      final errorMsg = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
      VeraPopup.show(
        context,
        title: 'Resend Failed',
        message: errorMsg,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = VeraResponsive.scale(MediaQuery.sizeOf(context).width);
    final moment = _currentMoment;

    return Scaffold(
      backgroundColor: const Color(0xFF080914),
      body: SafeArea(
        bottom: false,
        child: Builder(
          builder: (context) {
            final bottomPad = MediaQuery.paddingOf(context).bottom;
            return Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: 56 * scale,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).maybePop(_currentMoment),
                                icon: Icon(Icons.arrow_back_rounded,
                                    color: Colors.white, size: 22 * scale),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints.tightFor(
                                  width: 40 * scale,
                                  height: 40 * scale,
                                ),
                              ),
                            ),
                            Text(
                              'Locked moment',
                              style: TextStyle(
                                color: const Color(0xFFF7F5FF),
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  final result = await nav.push<Moment>(
                                    MaterialPageRoute<Moment>(
                                      builder: (_) => EditMomentScreen(moment: _currentMoment),
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (result != null) {
                                    if (result.id.startsWith('__DELETED__:')) {
                                      nav.pop(result);
                                    } else {
                                      setState(() {
                                        _currentMoment = result;
                                      });
                                    }
                                  }
                                },
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 20 * scale,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints.tightFor(
                                  width: 40 * scale,
                                  height: 40 * scale,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                            24 * scale, 20 * scale, 24 * scale, (104 * scale) + bottomPad),
                        child: Column(
                          children: [
                            _LockedPreview(moment: moment, scale: scale),
                            SizedBox(height: 16 * scale),
                            _FromBadge(moment: moment, scale: scale),
                            if (moment.status == 'PENDING_REVIEW') ...[
                              SizedBox(height: 16 * scale),
                              _PendingReviewBanner(scale: scale),
                            ],
                            SizedBox(height: 16 * scale),
                            _UnlockBanner(moment: moment, scale: scale),
                            if (!moment.isPublicSentMoment &&
                                moment.id.isNotEmpty &&
                                moment.invitationStatus == 'PENDING') ...[
                              SizedBox(height: 16 * scale),
                              _PendingInvitationCard(
                                isAccepting: _isAcceptingInvite,
                                isDeclining: _isDecliningInvite,
                                onAccept: _acceptInvitation,
                                onDecline: _declineInvitation,
                                scale: scale,
                              ),
                            ],
                            if (!moment.isPublicSentMoment &&
                                moment.id.isNotEmpty &&
                                moment.invitationStatus == 'DECLINED') ...[
                              SizedBox(height: 16 * scale),
                              _DeclinedInvitationBanner(scale: scale),
                            ],
                            if (!moment.isPublicSentMoment &&
                                moment.id.isNotEmpty &&
                                moment.status == 'PUBLISHED') ...[
                              SizedBox(height: 16 * scale),
                              _ResendInviteCard(
                                isSending: _isResendingInvite,
                                onResend: _resendInvite,
                                scale: scale,
                              ),
                            ],
                            SizedBox(height: 16 * scale),
                            _LockedContentPlaceholder(scale: scale),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: (88 * scale) + bottomPad,
                    padding: EdgeInsets.fromLTRB(
                        24 * scale, 16 * scale, 24 * scale, 24 * scale + bottomPad),
                    decoration: BoxDecoration(
                      color: const Color(0xD9090A17),
                      border: Border(
                        top: BorderSide(
                            color: const Color(0x334B3B70), width: 1 * scale),
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(44 * scale),
                      ),
                    ),
                    child: SizedBox(
                      height: 48 * scale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: VeraTheme.buttonGradient,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x665A26B8),
                              blurRadius: 20,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: _isChecking ? null : _checkIfReady,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: EdgeInsets.zero,
                          ),
                          child: _isChecking
                              ? SizedBox(
                                  width: 20 * scale,
                                  height: 20 * scale,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _currentMoment.isReadyToOpen
                                      ? "Unlock moment"
                                      : "Check if it's ready",
                                  style: TextStyle(
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LockedPreview extends StatelessWidget {
  const _LockedPreview({required this.moment, required this.scale});

  final Moment moment;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20 * scale),
      child: SizedBox(
        width: double.infinity,
        height: 430 * scale,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: moment.backgroundImageUrl.isNotEmpty
                  ? Image.network(
                      moment.backgroundImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF124552), Color(0xFF51352F)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    )
                  : const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF124552), Color(0xFF51352F)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0x22000000)),
            ),
            Center(
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 64 * scale,
                    height: 64 * scale,
                    color: const Color(0x66090A17),
                    child: Icon(Icons.lock_outline_rounded,
                        color: Colors.white, size: 26 * scale),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FromBadge extends StatelessWidget {
  const _FromBadge({required this.moment, required this.scale});

  final Moment moment;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52 * scale,
      padding: EdgeInsets.symmetric(horizontal: 12 * scale),
      decoration: BoxDecoration(
        color: const Color(0x33090A17),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x443F4356), width: 1 * scale),
      ),
      child: Row(
        children: [
          ClipOval(
            child: moment.userAvatarUrl.isNotEmpty
                ? Image.network(
                    moment.userAvatarUrl,
                    width: 36 * scale,
                    height: 36 * scale,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF6B42FF),
                      width: 36 * scale,
                      height: 36 * scale,
                      child: Icon(Icons.person, color: Colors.white, size: 18 * scale),
                    ),
                  )
                : Container(
                    color: const Color(0xFF6B42FF),
                    width: 36 * scale,
                    height: 36 * scale,
                    child: Icon(Icons.person, color: Colors.white, size: 18 * scale),
                  ),
          ),
          SizedBox(width: 10 * scale),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From ${moment.userName}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w500,
                  )),
              SizedBox(height: 2 * scale),
              Text(moment.timeAgo,
                  style: TextStyle(
                    color: const Color(0xFFF7F5FF),
                    fontSize: 11 * scale,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnlockBanner extends StatelessWidget {
  const _UnlockBanner({required this.moment, required this.scale});

  final Moment moment;
  final double scale;

  String _buildBannerText() {
    if (moment.unlockAt != null) {
      final now = ServerTimeManager.instance.now;
      if (!now.isBefore(moment.unlockAt!)) {
        return '${moment.unlockCondition} · Ready to unlock';
      }
      final diff = moment.unlockAt!.difference(now);
      if (diff.inDays > 0) {
        return '${moment.unlockCondition} (in ${diff.inDays}d ${diff.inHours % 24}h)';
      } else if (diff.inHours > 0) {
        final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
        return '${moment.unlockCondition} (in ${diff.inHours}:$m:$s)';
      } else {
        final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
        return '${moment.unlockCondition} (in $m:$s)';
      }
    }
    return moment.unlockCondition;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20 * scale),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          height: 56 * scale,
          padding: EdgeInsets.symmetric(horizontal: 16 * scale),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xCC9451FF), Color(0x8058C3F4)],
            ),
            borderRadius: BorderRadius.circular(20 * scale),
            border: Border.all(color: const Color(0x55FFFFFF), width: 2 * scale),
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
                  _buildBannerText(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedContentPlaceholder extends StatelessWidget {
  const _LockedContentPlaceholder({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 112 * scale,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0x14090A17),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: const Color(0x333F4356), width: scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonLine(width: .88, scale: scale),
          SizedBox(height: 10 * scale),
          _SkeletonLine(width: .62, scale: scale),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.scale});

  final double width;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: width,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFF20212D),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _PendingReviewBanner extends StatelessWidget {
  const _PendingReviewBanner({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 14 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0x29FF9800),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: const Color(0x66FF9800),
          width: 1 * scale,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36 * scale,
            height: 36 * scale,
            decoration: const BoxDecoration(
              color: Color(0x4DFF9800),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_top_rounded,
              color: const Color(0xFFFFB74D),
              size: 18 * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Admin Approval',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  'Submitted for review. Once an admin approves it, this moment will be published.',
                  style: TextStyle(
                    color: const Color(0xFFD4D4E8),
                    fontSize: 11 * scale,
                    height: 1.3,
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

class _ResendInviteCard extends StatelessWidget {
  const _ResendInviteCard({
    required this.isSending,
    required this.onResend,
    required this.scale,
  });

  final bool isSending;
  final VoidCallback onResend;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0x3317182D),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: const Color(0x334B3B70), width: 1 * scale),
      ),
      child: Row(
        children: [
          Container(
            width: 40 * scale,
            height: 40 * scale,
            decoration: BoxDecoration(
              color: VeraTheme.purpleBright.withAlpha(35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.send_rounded,
              color: VeraTheme.purpleBright,
              size: 20 * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recipient Invites',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  'Re-send invitation email to recipients',
                  style: TextStyle(
                    color: const Color(0xFF8A8EB3),
                    fontSize: 11 * scale,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * scale),
          OutlinedButton(
            onPressed: isSending ? null : onResend,
            style: OutlinedButton.styleFrom(
              foregroundColor: VeraTheme.purpleBright,
              side: BorderSide(
                color: VeraTheme.purpleBright.withAlpha(120),
                width: 1 * scale,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10 * scale),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 8 * scale,
              ),
              minimumSize: Size(0, 34 * scale),
            ),
            child: isSending
                ? SizedBox(
                    width: 14 * scale,
                    height: 14 * scale,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Resend',
                    style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PendingInvitationCard extends StatelessWidget {
  const _PendingInvitationCard({
    required this.isAccepting,
    required this.isDeclining,
    required this.onAccept,
    required this.onDecline,
    required this.scale,
  });

  final bool isAccepting;
  final bool isDeclining;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final isBusy = isAccepting || isDeclining;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0x3317182D),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: const Color(0x334B3B70), width: 1 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40 * scale,
                height: 40 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFF7DF0B0).withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_rounded,
                  color: const Color(0xFF7DF0B0),
                  size: 20 * scale,
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Invitation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      'Would you like to accept or decline this invitation?',
                      style: TextStyle(
                        color: const Color(0xFF8A8EB3),
                        fontSize: 11 * scale,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * scale),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF87171),
                    side: BorderSide(
                      color: const Color(0xFFF87171).withAlpha(120),
                      width: 1 * scale,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10 * scale),
                    minimumSize: Size(0, 36 * scale),
                  ),
                  child: isDeclining
                      ? SizedBox(
                          width: 14 * scale,
                          height: 14 * scale,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF87171),
                          ),
                        )
                      : Text(
                          'Decline',
                          style: TextStyle(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: ElevatedButton(
                  onPressed: isBusy ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7DF0B0),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10 * scale),
                    minimumSize: Size(0, 36 * scale),
                  ),
                  child: isAccepting
                      ? SizedBox(
                          width: 14 * scale,
                          height: 14 * scale,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w700,
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

class _DeclinedInvitationBanner extends StatelessWidget {
  const _DeclinedInvitationBanner({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 14 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0x29EF4444),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: const Color(0x66EF4444),
          width: 1 * scale,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36 * scale,
            height: 36 * scale,
            decoration: const BoxDecoration(
              color: Color(0x4DEF4444),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cancel_outlined,
              color: const Color(0xFFF87171),
              size: 18 * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invitation Declined',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  'You declined this invitation and cannot unlock or view its content.',
                  style: TextStyle(
                    color: const Color(0xFFD4D4E8),
                    fontSize: 11 * scale,
                    height: 1.3,
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


