import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/server_time_manager.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/moments_remote_data_source.dart';
import '../../data/repositories/moments_repository_impl.dart';
import '../../domain/entities/moment.dart';
import 'edit_moment_screen.dart';
import 'unlocked_moment_screen.dart';
import '../utils/moment_permission_utils.dart';
import '../../../account/data/datasources/account_remote_data_source.dart';
import '../../../account/data/repositories/account_repository_impl.dart';

class _LocationProof {
  const _LocationProof({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.capturedAt,
    required this.isMocked,
  });

  final double latitude;
  final double longitude;
  final double accuracyM;
  final DateTime capturedAt;
  final bool isMocked;
}

class LockedMomentScreen extends StatefulWidget {
  const LockedMomentScreen({super.key, required this.moment});

  final Moment moment;

  @override
  State<LockedMomentScreen> createState() => _LockedMomentScreenState();
}

class _LockedMomentScreenState extends State<LockedMomentScreen> {
  late Moment _currentMoment;
  bool _isChecking = false;
  bool _isRefreshingStatus = false;
  DateTime? _nextStatusRefreshAt;
  DateTime? _retryAfter;
  int _ticksCount = 0;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _currentMoment = widget.moment;
    ServerTimeManager.instance.ticker.addListener(_onTick);
    ServerTimeManager.instance.addResumedListener(_onResumed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPermissions();
    });
  }

  Future<void> _loadPermissions() async {
    final result = await MomentPermissionUtils.resolve(context: context, moment: _currentMoment);
    if (!mounted) return;
    setState(() {
      _isOwner = result['isOwner'] == true;
    });
  }

  void _showSafetyMenu(BuildContext context, double scale) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3090A17),
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 32 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF17182D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
          border: Border.all(color: const Color(0xFF373657)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36 * scale,
              height: 4 * scale,
              margin: EdgeInsets.only(bottom: 20 * scale),
              decoration: BoxDecoration(
                color: const Color(0xFF454B70),
                borderRadius: BorderRadius.circular(2 * scale),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.white),
              title: const Text('Report moment', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showReportSheet(context, scale);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Color(0xFFFF4D4F)),
              title: Text('Block ${_currentMoment.userName}',
                  style: const TextStyle(color: Color(0xFFFF4D4F))),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showBlockConfirmation(context, scale);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockConfirmation(BuildContext context, double scale) {
    final client = ApiClientScope.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF17182D),
        title: Text('Block ${_currentMoment.userName}?',
            style: const TextStyle(color: Colors.white)),
        content: Text(
          "You won't receive new invitations or notifications from ${_currentMoment.userName}. You can unblock them in Privacy settings.",
          style: const TextStyle(color: Color(0xFFA2A5C2)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFA2A5C2))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F)),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final targetId = _currentMoment.creatorId;
              if (targetId == null || targetId.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot block this user.')),
                );
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              try {
                final repo = AccountRepositoryImpl(AccountRemoteDataSource(client));
                await repo.blockUser(targetId);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('${_currentMoment.userName} has been blocked.')),
                );
                nav.pop(_currentMoment.copyWith(
                  id: '__DELETED__:${_currentMoment.id}',
                ));
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to block user: $e')),
                );
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReportSheet(BuildContext context, double scale) {
    final client = ApiClientScope.of(context);
    final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3090A17),
      builder: (sheetCtx) => Container(
        padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 32 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF17182D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
          border: Border.all(color: const Color(0xFF373657)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why are you reporting this?',
                style: TextStyle(color: Colors.white, fontSize: 18 * scale, fontWeight: FontWeight.bold)),
            SizedBox(height: 16 * scale),
            for (final entry in const [
              MapEntry('Spam', 'SPAM'),
              MapEntry('Inappropriate content', 'INAPPROPRIATE_CONTENT'),
              MapEntry('Harassment', 'HARASSMENT'),
              MapEntry('Something else', 'OTHER'),
            ])
              ListTile(
                title: Text(entry.key, style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  final messenger = ScaffoldMessenger.of(context);
                  String? details;
                  if (entry.value == 'OTHER') {
                    details = await _promptReportDetails(context, scale);
                    if (!mounted) return;
                    if (details == null || details.trim().isEmpty) return;
                  }
                  try {
                    await repo.reportMoment(
                      momentId: _currentMoment.id,
                      reason: entry.value,
                      details: details,
                    );
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Report submitted. Thank you for keeping Vera safe.')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to submit report: $e')),
                    );
                  }
                },
              ),
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
        title: const Text('Report details', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Please describe the issue...',
            hintStyle: TextStyle(color: Color(0xFFA2A5C2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFA2A5C2))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9044FB)),
            onPressed: () => Navigator.of(dialogCtx).pop(controller.text.trim()),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

    if (_currentMoment.unlockType == MomentUnlockType.time &&
        _currentMoment.unlockAt != null &&
        _currentMoment.status == 'PUBLISHED') {
      final isTimeReached = !now.isBefore(_currentMoment.unlockAt!);
      if (isTimeReached && !_isChecking && !_currentMoment.isReadyToOpen) {
        _checkIfReadySilent();
        return;
      }
    }

    if (_currentMoment.status == 'PENDING_REVIEW' && _ticksCount % 15 == 0 && !_isChecking) {
      _checkIfReadySilent();
      return;
    }

    setState(() {});
  }

  Future<void> _checkIfReadySilent() async {
    final now = DateTime.now();
    if (!mounted || _isChecking || _isRefreshingStatus ||
        _currentMoment.id.isEmpty ||
        ModalRoute.of(context)?.isCurrent != true ||
        (_retryAfter != null && now.isBefore(_retryAfter!)) ||
        (_nextStatusRefreshAt != null && now.isBefore(_nextStatusRefreshAt!))) {
      return;
    }
    _isRefreshingStatus = true;
    _nextStatusRefreshAt = now.add(const Duration(seconds: 15));
    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
      // Refreshing status must never attempt an unlock without user location proof.
      final model = await repo.getMomentById(_currentMoment.id);
      final updated = model.toEntity();
      if (!mounted) return;
      setState(() => _currentMoment = updated);
      if (updated.isReadyToOpen && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => UnlockedMomentScreen(moment: updated),
          ),
        );
      }
    } on ApiException catch (error) {
      if (error.statusCode == 429) {
        _retryAfter = DateTime.now().add(const Duration(minutes: 1));
      }
    } catch (_) {
      // Keep the current screen and allow a later refresh after transient errors.
    } finally {
      _isRefreshingStatus = false;
    }
  }

  Future<_LocationProof> _captureLocationProof() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Enable Location Services to unlock this Moment.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it in device settings.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission is required to unlock this Moment.');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    if (position.accuracy > 100) {
      throw Exception(
        'Location accuracy is ${position.accuracy.round()}m. '
        'Move near a window or outdoors and try again.',
      );
    }
    return _LocationProof(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyM: position.accuracy,
      capturedAt: position.timestamp,
      isMocked: position.isMocked,
    );
  }

  Future<void> _checkIfReady() async {
    if (_isChecking || _isRefreshingStatus) return;
    if (_retryAfter != null && DateTime.now().isBefore(_retryAfter!)) {
      VeraPopup.show(
        context,
        title: 'Please wait',
        message: 'Too many requests. Please wait a minute before trying again.',
        icon: Icons.hourglass_empty_rounded,
        accent: VeraTheme.warning,
      );
      return;
    }
    setState(() => _isChecking = true);

    _LocationProof? locationProof;
    if (_currentMoment.unlockType == MomentUnlockType.location) {
      try {
        locationProof = await _captureLocationProof();
      } catch (error) {
        if (!mounted) return;
        setState(() => _isChecking = false);
        VeraPopup.show(
          context,
          title: 'Location unavailable',
          message: error.toString().replaceFirst('Exception: ', ''),
          icon: Icons.location_off_outlined,
          accent: VeraTheme.warning,
        );
        return;
      }
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF161626),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: VeraTheme.purple),
              const SizedBox(height: 24),
              const Text(
                'Please wait, your moment is being checked...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

      Moment? readyMoment;
      bool isNotReady = false;
      String? notReadyReason;
      bool isLocationMismatch = false;

      try {
        final unlockedModel = await repo.unlockMoment(
          momentId: _currentMoment.id,
          latitude: locationProof?.latitude,
          longitude: locationProof?.longitude,
          accuracyM: locationProof?.accuracyM,
          capturedAt: locationProof?.capturedAt,
          isMocked: locationProof?.isMocked,
        );
        final base = unlockedModel.toEntity();
        readyMoment = base.copyWith(
          isReadyToOpen: true,
          userName: (base.userName.isNotEmpty && base.userName != 'You')
              ? base.userName
              : _currentMoment.userName,
          userAvatarUrl: base.userAvatarUrl.isNotEmpty
              ? base.userAvatarUrl
              : _currentMoment.userAvatarUrl,
          timeAgo: base.timeAgo.isNotEmpty ? base.timeAgo : _currentMoment.timeAgo,
          message: base.message ?? _currentMoment.message,
          title: (base.title != null && base.title!.isNotEmpty && base.title != 'Untitled Moment')
              ? base.title
              : _currentMoment.title,
          teaser: base.teaser ?? _currentMoment.teaser,
          backgroundImageUrl: (base.backgroundImageUrl.isNotEmpty && !base.backgroundImageUrl.contains('api/v1/moments'))
              ? base.backgroundImageUrl
              : _currentMoment.backgroundImageUrl,
          hasMedia: base.hasMedia || _currentMoment.hasMedia,
          isVideo: base.isVideo || _currentMoment.isVideo,
        );
      } catch (unlockErr) {
        if (unlockErr is ApiException) {
          if (unlockErr.statusCode == 429) {
            _retryAfter = DateTime.now().add(const Duration(minutes: 1));
          }
          if (unlockErr.statusCode == 0 ||
              unlockErr.statusCode == 401 ||
              unlockErr.statusCode == 404 ||
              unlockErr.statusCode == 429 ||
              (unlockErr.statusCode == 400 &&
                  unlockErr.message.contains('must be a number')) ||
              unlockErr.statusCode >= 500) {
            rethrow;
          }
        } else {
          rethrow;
        }
        final errMsg = unlockErr.message;

        final lowerMsg = errMsg.toLowerCase();
        if (lowerMsg.contains('location') ||
            lowerMsg.contains('distance') ||
            lowerMsg.contains('radius') ||
            lowerMsg.contains('far') ||
            lowerMsg.contains('not at')) {
          isLocationMismatch = true;
        }

        final model = await repo.getMomentById(_currentMoment.id);
        final updated = model.toEntity();
        if (updated.isReadyToOpen || updated.status == 'OPENED' || updated.unlockedAt != null) {
          readyMoment = updated;
        } else {
          isNotReady = true;
          notReadyReason = errMsg.isNotEmpty && !errMsg.startsWith('Exception')
              ? errMsg
              : updated.unlockCondition;
        }
      }

      if (!mounted) return;
      try {
        Navigator.of(context, rootNavigator: true).pop(); // close waiting dialog
      } catch (_) {}

      if (readyMoment != null) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF161626),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.check_circle_rounded, color: Color(0xFF7DF0B0), size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Your moment is ready! Unlocking now...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        try {
          Navigator.of(context, rootNavigator: true).pop(); // close success dialog
        } catch (_) {}

        setState(() {
          _currentMoment = readyMoment!;
          _isChecking = false;
        });

        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => UnlockedMomentScreen(moment: readyMoment!),
          ),
        );
      } else if (isLocationMismatch) {
        setState(() => _isChecking = false);
        _showLocationMismatchDialog(notReadyReason);
      } else if (isNotReady) {
        setState(() => _isChecking = false);
        VeraPopup.show(
          context,
          title: 'Not ready yet',
          message: notReadyReason != null && notReadyReason.isNotEmpty
              ? notReadyReason
              : 'Your moment is not ready yet. Please wait.',
          icon: Icons.hourglass_empty_rounded,
          accent: const Color(0xFF8CB8FF),
        );
      } else {
        setState(() => _isChecking = false);
      }
    } catch (e) {
      if (e is ApiException && e.statusCode == 429) {
        _retryAfter = DateTime.now().add(const Duration(minutes: 1));
      }
      if (!mounted) return;
      try {
        Navigator.of(context, rootNavigator: true).pop(); // ensure waiting dialog is closed
      } catch (_) {}
      setState(() => _isChecking = false);

      String errorMsg = '';
      if (e is ApiException) {
        errorMsg = e.message;
      } else {
        errorMsg = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
      }

      VeraPopup.show(
        context,
        title: 'Check failed',
        message: errorMsg.isNotEmpty && !errorMsg.startsWith('Exception')
            ? errorMsg
            : 'Could not refresh moment status from server. Please check your connection and try again.',
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    }
  }

  void _showLocationMismatchDialog(String? reason) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161626),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: VeraTheme.warning, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Location Mismatch',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: const Text(
          'You are not at the moment location.',
          style: TextStyle(color: Color(0xFFD4D4E8), fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8A8EB3))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _checkIfReady();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VeraTheme.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
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
                            _isOwner
                                ? Align(
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
                                            _loadPermissions();
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
                                  )
                                : Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      onPressed: () => _showSafetyMenu(context, scale),
                                      icon: Icon(
                                        Icons.more_horiz_rounded,
                                        color: Colors.white,
                                        size: 22 * scale,
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


