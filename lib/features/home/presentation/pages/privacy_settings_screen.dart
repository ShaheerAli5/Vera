import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../account/data/datasources/account_remote_data_source.dart';
import '../../../account/data/models/blocked_user_model.dart';
import '../../../account/data/models/profile_settings.dart';
import '../../../account/data/models/user_profile.dart';
import '../../../account/data/repositories/account_repository_impl.dart';
import '../../../account/presentation/pages/sign_in_screen.dart';
import '../widgets/creator_avatar.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  String _privacyOption = 'Everyone'; // 'Everyone', 'Contacts', 'Nobody'
  bool _allowLocationChecks = true;
  bool _pushInvitations = true;
  bool _pushUnlocks = true;
  bool _pushReplies = true;
  bool _discoverableByEmail = true;
  bool _analyticsEnabled = false;
  String _language = 'en';
  String _timezone = 'UTC';
  bool _isLoading = false;

  List<BlockedUserModel> _blockedUsers = [];

  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final client = ApiClientScope.of(context);
    if (client.authToken == null || client.authToken!.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final repo = AccountRepositoryImpl(AccountRemoteDataSource(client));
      final results = await Future.wait([
        repo.getProfile().then<dynamic>((v) => v).catchError((_) => null),
        repo.getSettings().then<dynamic>((v) => v).catchError((_) => null),
        repo.getBlockedUsers().then<dynamic>((v) => v).catchError((_) => null),
      ]);

      if (!mounted) return;
      final profile = results[0] is UserProfile ? results[0] as UserProfile : null;
      final settings = results[1] is ProfileSettings ? results[1] as ProfileSettings : null;
      final blocked = results[2] is BlockedUserListResponse ? (results[2] as BlockedUserListResponse).items : <BlockedUserModel>[];

      setState(() {
        if (profile != null) _profile = profile;
        _blockedUsers = blocked;
        if (settings != null) {
          _privacyOption = settings.privacy;
          _allowLocationChecks = settings.allowLocationChecks;
          _pushInvitations = settings.pushInvitations;
          _pushUnlocks = settings.pushUnlocks;
          _pushReplies = settings.pushReplies;
          _discoverableByEmail = settings.discoverableByEmail;
          _analyticsEnabled = settings.analyticsEnabled;
          _language = settings.language;
          _timezone = settings.timezone;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting({
    String? language,
    String? timezone,
    bool? pushInvitations,
    bool? pushUnlocks,
    bool? pushReplies,
    bool? discoverableByEmail,
    bool? analyticsEnabled,
    String? privacy,
    bool? allowLocationChecks,
  }) async {
    final client = ApiClientScope.of(context);
    try {
      final repo = AccountRepositoryImpl(AccountRemoteDataSource(client));
      final updated = await repo.updateSettings(
        language: language,
        timezone: timezone,
        pushInvitations: pushInvitations,
        pushUnlocks: pushUnlocks,
        pushReplies: pushReplies,
        discoverableByEmail: discoverableByEmail,
        analyticsEnabled: analyticsEnabled,
        privacy: privacy,
        allowLocationChecks: allowLocationChecks,
      );
      if (mounted) {
        setState(() {
          _language = updated.language;
          _timezone = updated.timezone;
          _pushInvitations = updated.pushInvitations;
          _pushUnlocks = updated.pushUnlocks;
          _pushReplies = updated.pushReplies;
          _discoverableByEmail = updated.discoverableByEmail;
          _analyticsEnabled = updated.analyticsEnabled;
          _privacyOption = updated.privacy;
          _allowLocationChecks = updated.allowLocationChecks;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Settings Error',
        message: e.message,
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.error,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scale = VeraResponsive.scale(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: VeraTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            SizedBox(
              height: 56 * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20 * scale),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tightFor(
                        width: 40 * scale,
                        height: 40 * scale,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Privacy & Settings',
                              style: TextStyle(
                                color: const Color(0xFFF7F5FF),
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_isLoading) ...[
                              SizedBox(width: 8 * scale),
                              SizedBox(
                                width: 14 * scale,
                                height: 14 * scale,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFB45BFF),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '1.0.0',
                      style: TextStyle(
                        color: const Color(0xFFA6A6C1),
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    24 * scale, 16 * scale, 24 * scale, 48 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Privacy', scale),
                    SizedBox(height: 12 * scale),
                    Column(
                      children: [
                        _privacyTile(
                          title: 'Everyone',
                          icon: Icons.language_rounded,
                          selected: _privacyOption == 'Everyone',
                          onTap: () {
                            setState(() => _privacyOption = 'Everyone');
                            _updateSetting(privacy: 'Everyone');
                          },
                          scale: scale,
                        ),
                        SizedBox(height: 16 * scale),
                        _privacyTile(
                          title: 'Contacts',
                          icon: Icons.contacts_outlined,
                          selected: _privacyOption == 'Contacts',
                          onTap: () {
                            setState(() => _privacyOption = 'Contacts');
                            _updateSetting(privacy: 'Contacts');
                          },
                          scale: scale,
                        ),
                        SizedBox(height: 16 * scale),
                        _privacyTile(
                          title: 'Nobody',
                          icon: Icons.person_off_outlined,
                          selected: _privacyOption == 'Nobody',
                          onTap: () {
                            setState(() => _privacyOption = 'Nobody');
                            _updateSetting(privacy: 'Nobody');
                          },
                          scale: scale,
                        ),
                      ],
                    ),
                    _sectionHeader('Location', scale),
                    SizedBox(height: 12 * scale),
                    Container(
                      padding: EdgeInsets.all(16 * scale),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121326),
                        borderRadius: BorderRadius.circular(16 * scale),
                        border: Border.all(
                          color: const Color(0x333F4356),
                          width: scale,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Allow location checks',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16 * scale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4 * scale),
                                Text(
                                  'Used once, only when you check a location lock. No background tracking, and raw coordinates are deleted after the check.',
                                  style: TextStyle(
                                    color: const Color(0xFFA6A6C1),
                                    fontSize: 12 * scale,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          GestureDetector(
                            onTap: () {
                              final newVal = !_allowLocationChecks;
                              setState(() => _allowLocationChecks = newVal);
                              _updateSetting(allowLocationChecks: newVal);
                            },
                            child: _allowLocationChecks
                                ? Image.asset(
                                    'assets/images/toggle-on-circle.png',
                                    width: 44 * scale,
                                    height: 24 * scale,
                                    fit: BoxFit.contain,
                                  )
                                : Transform.scale(
                                    scaleX: -1,
                                    child: Image.asset(
                                      'assets/images/toggle-on-circle.png',
                                      width: 44 * scale,
                                      height: 24 * scale,
                                      fit: BoxFit.contain,
                                      color: const Color(0xFF2D2E42),
                                      colorBlendMode: BlendMode.srcIn,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24 * scale),

                    _sectionHeader('Notifications', scale),
                    SizedBox(height: 12 * scale),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121326),
                        borderRadius: BorderRadius.circular(16 * scale),
                        border: Border.all(
                          color: const Color(0x333F4356),
                          width: scale,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _notificationToggle(
                            title: 'Push notifications',
                            iconAsset: 'assets/images/user-tag.png',
                            value: _pushInvitations || _pushUnlocks || _pushReplies,
                            onChanged: (val) {
                              setState(() {
                                _pushInvitations = val;
                                _pushUnlocks = val;
                                _pushReplies = val;
                              });
                              _updateSetting(
                                pushInvitations: val,
                                pushUnlocks: val,
                                pushReplies: val,
                              );
                            },
                            scale: scale,
                          ),
                          _divider(scale),
                          _notificationToggle(
                            title: 'Invitations',
                            iconAsset: 'assets/images/sms-notification.png',
                            value: _pushInvitations,
                            onChanged: (val) {
                              setState(() => _pushInvitations = val);
                              _updateSetting(pushInvitations: val);
                            },
                            scale: scale,
                          ),
                          _divider(scale),
                          _notificationToggle(
                            title: 'Unlocks',
                            iconAsset: 'assets/images/unlock.png',
                            value: _pushUnlocks,
                            onChanged: (val) {
                              setState(() => _pushUnlocks = val);
                              _updateSetting(pushUnlocks: val);
                            },
                            scale: scale,
                          ),
                          _divider(scale),
                          _notificationToggle(
                            title: 'Replies',
                            iconAsset: 'assets/images/send-2.png',
                            value: _pushReplies,
                            onChanged: (val) {
                              setState(() => _pushReplies = val);
                              _updateSetting(pushReplies: val);
                            },
                            scale: scale,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24 * scale),

                    _sectionHeader('Blocked users', scale),
                    SizedBox(height: 12 * scale),
                    if (_blockedUsers.isEmpty)
                      Text(
                        'No blocked users',
                        style: TextStyle(
                          color: const Color(0xFFA6A6C1),
                          fontSize: 13 * scale,
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.all(16 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121326),
                          borderRadius: BorderRadius.circular(16 * scale),
                          border: Border.all(
                            color: const Color(0x333F4356),
                            width: scale,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < _blockedUsers.length; i++) ...[
                              if (i > 0) SizedBox(height: 16 * scale),
                              Row(
                                children: [
                                  CreatorAvatar(
                                    name: _blockedUsers[i].displayName,
                                    avatarUrl: _blockedUsers[i].avatarUrl,
                                    size: 36 * scale,
                                  ),
                                  SizedBox(width: 12 * scale),
                                  Expanded(
                                    child: Text(
                                      _blockedUsers[i].displayName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16 * scale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 30 * scale,
                                    child: TextButton(
                                      onPressed: () async {
                                        final user = _blockedUsers[i];
                                        final client = ApiClientScope.of(context);
                                        final repo = AccountRepositoryImpl(AccountRemoteDataSource(client));
                                        await repo.unblockUser(user.id);
                                        if (mounted) {
                                          setState(() {
                                            _blockedUsers.removeAt(i);
                                          });
                                          VeraPopup.show(
                                            context,
                                            title: 'User unblocked',
                                            message: '${user.displayName} can contact you again.',
                                            icon: Icons.person_add_alt_1_rounded,
                                          );
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: const Color(0x1AF7F5FF),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16 * scale, vertical: 4 * scale),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                      ),
                                      child: Text(
                                        'Unblock',
                                        style: TextStyle(
                                          fontSize: 12 * scale,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    SizedBox(height: 24 * scale),

                    _sectionHeader('Account', scale),
                    SizedBox(height: 12 * scale),
                    if (_profile != null) ...[
                      Container(
                        padding: EdgeInsets.all(16 * scale),
                        margin: EdgeInsets.only(bottom: 16 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121326),
                          borderRadius: BorderRadius.circular(16 * scale),
                          border: Border.all(
                            color: const Color(0x333F4356),
                            width: scale,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipOval(
                                  child: _profile!.avatarUrl != null &&
                                          _profile!.avatarUrl!.trim().isNotEmpty
                                      ? Image.network(
                                          _profile!.avatarUrl!,
                                          width: 44 * scale,
                                          height: 44 * scale,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, error, stackTrace) =>
                                              Container(
                                            width: 44 * scale,
                                            height: 44 * scale,
                                            color: const Color(0xFF2E2244),
                                            alignment: Alignment.center,
                                            child: Icon(Icons.person,
                                                color: Colors.white70,
                                                size: 24 * scale),
                                          ),
                                        )
                                      : Container(
                                          width: 44 * scale,
                                          height: 44 * scale,
                                          color: const Color(0xFF2E2244),
                                          alignment: Alignment.center,
                                          child: Text(
                                            _profile!.displayName.isNotEmpty
                                                ? _profile!.displayName[0]
                                                    .toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              color: const Color(0xFFE4DAFF),
                                              fontSize: 20 * scale,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                ),
                                SizedBox(width: 12 * scale),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _profile!.displayName,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16 * scale,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 2 * scale),
                                      Text(
                                        _profile!.email,
                                        style: TextStyle(
                                          color: const Color(0xFFA6A6C1),
                                          fontSize: 13 * scale,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_profile!.isEmailVerified)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8 * scale,
                                      vertical: 3 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x2210B981),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: const Color(0xFF10B981),
                                        width: 0.8 * scale,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: const Color(0xFF10B981),
                                          size: 12 * scale,
                                        ),
                                        SizedBox(width: 4 * scale),
                                        Text(
                                          'Verified',
                                          style: TextStyle(
                                            color: const Color(0xFF10B981),
                                            fontSize: 11 * scale,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (_profile!.linkedProviders.isNotEmpty) ...[
                              SizedBox(height: 12 * scale),
                              Text(
                                'Linked Providers',
                                style: TextStyle(
                                  color: const Color(0xFFA6A6C1),
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 6 * scale),
                              Wrap(
                                spacing: 6 * scale,
                                runSpacing: 4 * scale,
                                children: _profile!.linkedProviders.map((p) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8 * scale,
                                      vertical: 2 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x229044FB),
                                      borderRadius:
                                          BorderRadius.circular(8 * scale),
                                      border: Border.all(
                                        color: const Color(0x449044FB),
                                        width: 0.8 * scale,
                                      ),
                                    ),
                                    child: Text(
                                      p[0].toUpperCase() + p.substring(1),
                                      style: TextStyle(
                                        color: const Color(0xFFE2DCF7),
                                        fontSize: 11 * scale,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    Column(
                      children: [
                        _actionTile(
                          title: 'Export my data',
                          iconAsset: 'assets/images/export.svg',
                          fallbackIcon: Icons.upload_rounded,
                          onTap: () {
                            VeraPopup.show(
                              context,
                              title: 'Preparing your export',
                              message: 'We’re gathering your account data.',
                              icon: Icons.file_download_outlined,
                              accent: const Color(0xFF9E8BFF),
                            );
                          },
                          scale: scale,
                        ),
                        SizedBox(height: 16 * scale),
                        _actionTile(
                          title: 'Change password',
                          iconAsset: 'assets/images/unlock.png',
                          fallbackIcon: Icons.lock_outline_rounded,
                          onTap: () => _showChangePasswordBottomSheet(context, scale),
                          scale: scale,
                        ),
                        SizedBox(height: 16 * scale),
                        _actionTile(
                          title: 'Sign out',
                          iconAsset: 'assets/images/logout.svg',
                          fallbackIcon: Icons.logout_rounded,
                          onTap: () => _showSignOutBottomSheet(context, scale),
                          scale: scale,
                        ),
                        SizedBox(height: 16 * scale),
                        _actionTile(
                          title: 'Delete account',
                          iconAsset: 'assets/images/profile-delete.svg',
                          fallbackIcon: Icons.person_remove_rounded,
                          isDestructive: true,
                          onTap: () => _showDeleteAccountBottomSheet(context, scale),
                          scale: scale,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountBottomSheet(BuildContext context, double scale) {
    bool isDeleting = false;
    String? localError;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(modalContext).bottom,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF121326),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24 * scale),
                    topRight: Radius.circular(24 * scale),
                  ),
                  border: Border.all(
                    color: const Color(0x333F4356),
                    width: scale,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  24 * scale,
                  24 * scale,
                  24 * scale,
                  36 * scale + MediaQuery.paddingOf(modalContext).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Delete your account?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: isDeleting
                              ? null
                              : () => Navigator.of(modalContext).pop(),
                          child: Container(
                            width: 32 * scale,
                            height: 32 * scale,
                            decoration: const BoxDecoration(
                              color: Color(0x1AF7F5FF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18 * scale,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12 * scale),
                    Text(
                      "This disables your account immediately and schedules deletion of your profile, moments, and replies. This cannot be undone.",
                      style: TextStyle(
                        color: const Color(0xFFA6A6C1),
                        fontSize: 14 * scale,
                        height: 1.4,
                      ),
                    ),
                    if (localError != null) ...[
                      SizedBox(height: 16 * scale),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14 * scale,
                          vertical: 10 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFF647C),
                          borderRadius: BorderRadius.circular(12 * scale),
                          border: Border.all(
                            color: const Color(0x44FF647C),
                            width: scale,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: const Color(0xFFFF647C),
                              size: 18 * scale,
                            ),
                            SizedBox(width: 8 * scale),
                            Expanded(
                              child: Text(
                                localError!,
                                style: TextStyle(
                                  color: const Color(0xFFFF647C),
                                  fontSize: 13 * scale,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 28 * scale),
                    SizedBox(
                      width: double.infinity,
                      height: 48 * scale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0x1AFF647C),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFFF647C).withAlpha(102),
                            width: scale,
                          ),
                        ),
                        child: TextButton(
                          onPressed: isDeleting
                              ? null
                              : () async {
                                  setModalState(() {
                                    isDeleting = true;
                                    localError = null;
                                  });

                                  final apiClient =
                                      ApiClientScope.of(modalContext);
                                  final repo = AccountRepositoryImpl(
                                    AccountRemoteDataSource(apiClient),
                                  );
                                  final sheetNavigator =
                                      Navigator.of(modalContext);
                                  final rootNavigator =
                                      Navigator.of(this.context);

                                  try {
                                    await repo.deleteAccount();
                                    await apiClient.clearTokens();

                                    if (mounted) {
                                      sheetNavigator.pop();
                                      VeraPopup.show(
                                        this.context,
                                        title: 'Account Deleted',
                                        message:
                                            'Your account has been scheduled for deletion.',
                                        icon: Icons.check_circle_rounded,
                                        accent: VeraTheme.error,
                                      );
                                      rootNavigator.pushAndRemoveUntil(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const SignInScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  } on ApiException catch (e) {
                                    setModalState(() {
                                      isDeleting = false;
                                      localError = e.message;
                                    });
                                  } catch (e) {
                                    setModalState(() {
                                      isDeleting = false;
                                      localError =
                                          'Could not delete account. Please check your connection.';
                                    });
                                  }
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFF647C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: isDeleting
                              ? SizedBox(
                                  width: 20 * scale,
                                  height: 20 * scale,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFF647C),
                                    ),
                                  ),
                                )
                              : Text(
                                  'Delete Account',
                                  style: TextStyle(
                                    fontSize: 16 * scale,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFF647C),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showChangePasswordBottomSheet(BuildContext context, double scale) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;
    String? localError;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(modalContext).bottom,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF121326),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24 * scale),
                    topRight: Radius.circular(24 * scale),
                  ),
                  border: Border.all(
                    color: const Color(0x333F4356),
                    width: scale,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  24 * scale,
                  24 * scale,
                  24 * scale,
                  36 * scale + MediaQuery.paddingOf(modalContext).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Change Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: isSubmitting
                                ? null
                                : () => Navigator.of(modalContext).pop(),
                            child: Container(
                              width: 32 * scale,
                              height: 32 * scale,
                              decoration: const BoxDecoration(
                                color: Color(0x1AF7F5FF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18 * scale,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * scale),
                      Text(
                        'Enter your current password and choose a new password. You will need to sign in again after updating.',
                        style: TextStyle(
                          color: const Color(0xFFA6A6C1),
                          fontSize: 13 * scale,
                          height: 1.4,
                        ),
                      ),
                      if (localError != null) ...[
                        SizedBox(height: 16 * scale),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14 * scale,
                            vertical: 10 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x1AFF647C),
                            borderRadius: BorderRadius.circular(12 * scale),
                            border: Border.all(
                              color: const Color(0x44FF647C),
                              width: scale,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: const Color(0xFFFF647C),
                                size: 18 * scale,
                              ),
                              SizedBox(width: 8 * scale),
                              Expanded(
                                child: Text(
                                  localError!,
                                  style: TextStyle(
                                    color: const Color(0xFFFF647C),
                                    fontSize: 13 * scale,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 20 * scale),
                      Text(
                        'Current Password',
                        style: TextStyle(
                          color: const Color(0xFFA6A6C1),
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 6 * scale),
                      TextField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        enabled: !isSubmitting,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15 * scale,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter current password',
                          hintStyle: TextStyle(
                            color: const Color(0xFF6E6F87),
                            fontSize: 14 * scale,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1B1C31),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16 * scale,
                            vertical: 14 * scale,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                            borderSide: const BorderSide(
                              color: Color(0x333F4356),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                            borderSide: const BorderSide(
                              color: Color(0x333F4356),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                            borderSide: const BorderSide(
                              color: Color(0xFFB45BFF),
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrent
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFFA6A6C1),
                              size: 20 * scale,
                            ),
                            onPressed: () => setModalState(
                              () => obscureCurrent = !obscureCurrent,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16 * scale),
                      Text(
                        'New Password',
                        style: TextStyle(
                          color: const Color(0xFFA6A6C1),
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 6 * scale),
                      TextField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        enabled: !isSubmitting,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15 * scale,
                        ),
                        decoration: InputDecoration(
                          hintText: 'At least 8 characters',
                          hintStyle: TextStyle(
                            color: const Color(0xFF6E6F87),
                            fontSize: 14 * scale,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1B1C31),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16 * scale,
                            vertical: 14 * scale,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                            borderSide: const BorderSide(
                              color: Color(0x333F4356),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                            borderSide: const BorderSide(
                              color: Color(0x333F4356),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                            borderSide: const BorderSide(
                              color: Color(0xFFB45BFF),
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFFA6A6C1),
                              size: 20 * scale,
                            ),
                            onPressed: () => setModalState(
                              () => obscureNew = !obscureNew,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16 * scale),
                      Text(
                        'Confirm New Password',
                        style: TextStyle(
                          color: const Color(0xFFA6A6C1),
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 6 * scale),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        enabled: !isSubmitting,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15 * scale,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Re-enter new password',
                          hintStyle: TextStyle(
                            color: const Color(0xFF6E6F87),
                            fontSize: 14 * scale,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1B1C31),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16 * scale,
                            vertical: 14 * scale,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                            borderSide: const BorderSide(
                              color: Color(0x333F4356),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                            borderSide: const BorderSide(
                              color: Color(0x333F4356),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                            borderSide: const BorderSide(
                              color: Color(0xFFB45BFF),
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFFA6A6C1),
                              size: 20 * scale,
                            ),
                            onPressed: () => setModalState(
                              () => obscureConfirm = !obscureConfirm,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 28 * scale),
                      SizedBox(
                        width: double.infinity,
                        height: 48 * scale,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: VeraTheme.buttonGradient,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: VeraTheme.glowPurple,
                                blurRadius: 18,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final current = currentPasswordController.text;
                                    final next = newPasswordController.text;
                                    final confirm = confirmPasswordController.text;

                                    if (current.isEmpty) {
                                      setModalState(() => localError = 'Please enter your current password.');
                                      return;
                                    }
                                    if (next.length < 8) {
                                      setModalState(() => localError = 'New password must be at least 8 characters.');
                                      return;
                                    }
                                    if (next != confirm) {
                                      setModalState(() => localError = 'New passwords do not match.');
                                      return;
                                    }
                                    if (next == current) {
                                      setModalState(() => localError = 'New password cannot be the same as your current password.');
                                      return;
                                    }

                                    setModalState(() {
                                      isSubmitting = true;
                                      localError = null;
                                    });

                                    final apiClient = ApiClientScope.of(modalContext);
                                    final repo = AccountRepositoryImpl(AccountRemoteDataSource(apiClient));
                                    final sheetNavigator = Navigator.of(modalContext);
                                    final rootNavigator = Navigator.of(this.context);

                                    try {
                                      await repo.changePassword(
                                        currentPassword: current,
                                        newPassword: next,
                                      );

                                      // Per API docs: "Changes the password and revokes all refresh sessions. Login again afterward."
                                      await apiClient.clearTokens();

                                      if (mounted) {
                                        sheetNavigator.pop();
                                        VeraPopup.show(
                                          this.context,
                                          title: 'Password Changed',
                                          message: 'Your password was updated successfully. Please sign in again.',
                                          icon: Icons.check_circle_rounded,
                                          accent: VeraTheme.success,
                                        );
                                        rootNavigator.pushAndRemoveUntil(
                                          MaterialPageRoute<void>(
                                            builder: (_) => const SignInScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      }
                                    } on ApiException catch (e) {
                                      setModalState(() {
                                        isSubmitting = false;
                                        localError = e.message;
                                      });
                                    } catch (e) {
                                      setModalState(() {
                                        isSubmitting = false;
                                        localError = 'Could not update password. Please check your connection.';
                                      });
                                    }
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                            ),
                            child: isSubmitting
                                ? SizedBox(
                                    width: 20 * scale,
                                    height: 20 * scale,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Update Password',
                                    style: TextStyle(
                                      fontSize: 15 * scale,
                                      fontWeight: FontWeight.w600,
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
          },
        );
      },
    );
  }

  void _showSignOutBottomSheet(BuildContext context, double scale) {
    bool isSigningOut = false;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF121326),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24 * scale),
                    topRight: Radius.circular(24 * scale),
                  ),
                  border: Border.all(
                    color: const Color(0x333F4356),
                    width: scale,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  24 * scale,
                  24 * scale,
                  24 * scale,
                  36 * scale + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Sign out?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: isSigningOut
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Container(
                            width: 32 * scale,
                            height: 32 * scale,
                            decoration: const BoxDecoration(
                              color: Color(0x1AF7F5FF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18 * scale,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12 * scale),
                    Text(
                      'Are you sure you want to sign out of your account on this device?',
                      style: TextStyle(
                        color: const Color(0xFFA6A6C1),
                        fontSize: 14 * scale,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 28 * scale),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48 * scale,
                            child: OutlinedButton(
                              onPressed: isSigningOut
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFA6A6C1),
                                side: BorderSide(
                                  color: const Color(0x333F4356),
                                  width: scale,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14 * scale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: SizedBox(
                            height: 48 * scale,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: VeraTheme.buttonGradient,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: const [
                                  BoxShadow(
                                    color: VeraTheme.glowPurple,
                                    blurRadius: 18,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: isSigningOut
                                    ? null
                                    : () async {
                                        setSheetState(
                                            () => isSigningOut = true);
                                        final apiClient =
                                            ApiClientScope.of(sheetContext);
                                        final refreshToken =
                                            apiClient.refreshToken;
                                        final sheetNavigator =
                                            Navigator.of(sheetContext);
                                        final rootNavigator =
                                            Navigator.of(this.context);

                                        try {
                                          if (refreshToken != null &&
                                              refreshToken.isNotEmpty) {
                                            final repository =
                                                AccountRepositoryImpl(
                                              AccountRemoteDataSource(
                                                  apiClient),
                                            );
                                            await repository.logout(
                                              refreshToken: refreshToken,
                                            );
                                          }
                                        } catch (_) {
                                          // Ignore network errors to guarantee local sign out
                                        } finally {
                                          await apiClient.clearTokens();
                                        }
                                        if (mounted) {
                                          sheetNavigator.pop();
                                          VeraPopup.show(
                                            this.context,
                                            title: 'Signed out',
                                            message:
                                                'You have been signed out successfully.',
                                            icon: Icons.check_circle_rounded,
                                            accent: VeraTheme.info,
                                          );
                                          rootNavigator.pushAndRemoveUntil(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const SignInScreen(),
                                            ),
                                            (route) => false,
                                          );
                                        }
                                      },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                ),
                                child: isSigningOut
                                    ? SizedBox(
                                        width: 20 * scale,
                                        height: 20 * scale,
                                        child:
                                            const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Sign out',
                                        style: TextStyle(
                                          fontSize: 14 * scale,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionHeader(String title, double scale) {
    return Text(
      title,
      style: TextStyle(
        color: const Color(0xFFF4F2FF),
        fontSize: 24 * scale,
        height: 32 / 24,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _privacyTile({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required double scale,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52 * scale,
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        decoration: BoxDecoration(
          gradient: selected ? VeraTheme.buttonGradient : null,
          color: selected ? null : const Color(0xFF121326),
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(
            color: selected ? const Color(0x66FFFFFF) : const Color(0x333F4356),
            width: scale,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20 * scale),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationToggle({
    required String title,
    required String iconAsset,
    required bool value,
    required ValueChanged<bool> onChanged,
    required double scale,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 16 * scale, vertical: 8 * scale),
      child: Row(
        children: [
          Image.asset(
            iconAsset,
            width: 20 * scale,
            height: 20 * scale,
            fit: BoxFit.contain,
            errorBuilder: (_, error, stackTrace) => Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 20 * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: value
                ? Image.asset(
                    'assets/images/toggle-on-circle.png',
                    width: 44 * scale,
                    height: 24 * scale,
                    fit: BoxFit.contain,
                  )
                : Transform.scale(
                    scaleX: -1,
                    child: Image.asset(
                      'assets/images/toggle-on-circle.png',
                      width: 44 * scale,
                      height: 24 * scale,
                      fit: BoxFit.contain,
                      color: const Color(0xFF2D2E42),
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _divider(double scale) {
    return Divider(
      height: 1,
      thickness: 1,
      color: const Color(0x223F4356),
      indent: 48 * scale,
    );
  }

  Widget _actionTile({
    required String title,
    required String iconAsset,
    required IconData fallbackIcon,
    required VoidCallback onTap,
    bool isDestructive = false,
    required double scale,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52 * scale,
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF121326),
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(
            color: const Color(0x333F4356),
            width: scale,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 20 * scale,
              height: 20 * scale,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(
                isDestructive ? const Color(0xFFFF647C) : Colors.white,
                BlendMode.srcIn,
              ),
              placeholderBuilder: (_) => Icon(
                fallbackIcon,
                color: isDestructive ? const Color(0xFFFF647C) : Colors.white,
                size: 20 * scale,
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDestructive ? const Color(0xFFFF647C) : Colors.white,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required String title,
    required String value,
    required IconData icon,
    required double scale,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16 * scale),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 14 * scale,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFFC792EA),
              size: 20 * scale,
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: const Color(0xFFA6A6C1),
                fontSize: 14 * scale,
              ),
            ),
            if (onTap != null) ...[
              SizedBox(width: 6 * scale),
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFFA6A6C1),
                size: 18 * scale,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _settingToggleRow({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required double scale,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 12 * scale,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFC792EA), size: 20 * scale),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2 * scale),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: const Color(0xFFA6A6C1),
                      fontSize: 12 * scale,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 12 * scale),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: value
                ? Image.asset(
                    'assets/images/toggle-on-circle.png',
                    width: 44 * scale,
                    height: 24 * scale,
                    fit: BoxFit.contain,
                  )
                : Transform.scale(
                    scaleX: -1,
                    child: Image.asset(
                      'assets/images/toggle-on-circle.png',
                      width: 44 * scale,
                      height: 24 * scale,
                      fit: BoxFit.contain,
                      color: const Color(0xFF2D2E42),
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _getLanguageDisplayName(String code) {
    switch (code.toLowerCase()) {
      case 'en':
      case 'english':
        return 'English';
      case 'es':
      case 'español':
      case 'spanish':
        return 'Español';
      case 'fr':
      case 'français':
      case 'french':
        return 'Français';
      case 'de':
      case 'deutsch':
      case 'german':
        return 'Deutsch';
      case 'ar':
      case 'العربية':
      case 'arabic':
        return 'العربية';
      case 'ja':
      case '日本語':
      case 'japanese':
        return '日本語';
      default:
        return code;
    }
  }

  void _showLanguageSelector(double scale) {
    const languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'es', 'name': 'Español'},
      {'code': 'fr', 'name': 'Français'},
      {'code': 'de', 'name': 'Deutsch'},
      {'code': 'ar', 'name': 'العربية'},
      {'code': 'ja', 'name': '日本語'},
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121326),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24 * scale),
              topRight: Radius.circular(24 * scale),
            ),
            border: Border.all(
              color: const Color(0x333F4356),
              width: scale,
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24 * scale,
            24 * scale,
            24 * scale,
            36 * scale + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Language',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    child: Container(
                      width: 32 * scale,
                      height: 32 * scale,
                      decoration: const BoxDecoration(
                        color: Color(0x1AF7F5FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 18 * scale,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16 * scale),
              ...languages.map((l) {
                final isSelected = _language.toLowerCase() == l['code']!.toLowerCase() ||
                    _language.toLowerCase() == l['name']!.toLowerCase();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l['name']!,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFB45BFF) : Colors.white,
                      fontSize: 15 * scale,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded, color: const Color(0xFFB45BFF), size: 20 * scale)
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    final selectedCode = l['code']!;
                    setState(() => _language = selectedCode);
                    _updateSetting(language: selectedCode);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showTimezoneSelector(double scale) {
    const timezones = [
      {'id': 'UTC', 'label': 'UTC (Coordinated Universal Time)'},
      {'id': 'America/New_York', 'label': 'America/New_York (Eastern Time)'},
      {'id': 'America/Chicago', 'label': 'America/Chicago (Central Time)'},
      {'id': 'America/Los_Angeles', 'label': 'America/Los_Angeles (Pacific Time)'},
      {'id': 'Europe/London', 'label': 'Europe/London (GMT / BST)'},
      {'id': 'Europe/Paris', 'label': 'Europe/Paris (Central European Time)'},
      {'id': 'Asia/Dubai', 'label': 'Asia/Dubai (GST)'},
      {'id': 'Asia/Karachi', 'label': 'Asia/Karachi (PKT)'},
      {'id': 'Asia/Singapore', 'label': 'Asia/Singapore (SGT)'},
      {'id': 'Asia/Tokyo', 'label': 'Asia/Tokyo (JST)'},
      {'id': 'Australia/Sydney', 'label': 'Australia/Sydney (AEST)'},
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF121326),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24 * scale),
              topRight: Radius.circular(24 * scale),
            ),
            border: Border.all(
              color: const Color(0x333F4356),
              width: scale,
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24 * scale,
            24 * scale,
            24 * scale,
            36 * scale + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Timezone (IANA)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    child: Container(
                      width: 32 * scale,
                      height: 32 * scale,
                      decoration: const BoxDecoration(
                        color: Color(0x1AF7F5FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 18 * scale,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16 * scale),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: timezones.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: Color(0x223F4356),
                  ),
                  itemBuilder: (_, index) {
                    final tz = timezones[index];
                    final isSelected = _timezone.toLowerCase() == tz['id']!.toLowerCase();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        tz['label']!,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFB45BFF) : Colors.white,
                          fontSize: 14 * scale,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_rounded, color: const Color(0xFFB45BFF), size: 20 * scale)
                          : null,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        final selectedTz = tz['id']!;
                        setState(() => _timezone = selectedTz);
                        _updateSetting(timezone: selectedTz);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
