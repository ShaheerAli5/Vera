import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/theme.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  String _privacyOption = 'Everyone'; // 'Everyone', 'Contacts', 'Nobody'
  bool _allowLocationChecks = true;
  bool _pushNotifications = true;
  bool _invitations = false;
  bool _unlocks = true;
  bool _replies = true;

  final List<Map<String, String>> _blockedUsers = [
    {
      'name': 'Annas',
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
    },
    {
      'name': 'Marcus',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 393).clamp(.82, 1.12);

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
                        child: Text(
                          'Privacy & Settings',
                          style: TextStyle(
                            color: const Color(0xFFF7F5FF),
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w500,
                          ),
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
                          onTap: () => setState(() => _privacyOption = 'Everyone'),
                          scale: scale,
                        ),
                        SizedBox(height: 16 * scale),
                        _privacyTile(
                          title: 'Contacts',
                          icon: Icons.contacts_outlined,
                          selected: _privacyOption == 'Contacts',
                          onTap: () => setState(() => _privacyOption = 'Contacts'),
                          scale: scale,
                        ),
                        SizedBox(height: 16 * scale),
                        _privacyTile(
                          title: 'Nobody',
                          icon: Icons.person_off_outlined,
                          selected: _privacyOption == 'Nobody',
                          onTap: () => setState(() => _privacyOption = 'Nobody'),
                          scale: scale,
                        ),
                      ],
                    ),
                    SizedBox(height: 24 * scale),

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
                            onTap: () => setState(
                                () => _allowLocationChecks = !_allowLocationChecks),
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
                            value: _pushNotifications,
                            onChanged: (val) =>
                                setState(() => _pushNotifications = val),
                            scale: scale,
                          ),
                          _divider(scale),
                          _notificationToggle(
                            title: 'Invitations',
                            iconAsset: 'assets/images/sms-notification.png',
                            value: _invitations,
                            onChanged: (val) =>
                                setState(() => _invitations = val),
                            scale: scale,
                          ),
                          _divider(scale),
                          _notificationToggle(
                            title: 'Unlocks',
                            iconAsset: 'assets/images/unlock.png',
                            value: _unlocks,
                            onChanged: (val) => setState(() => _unlocks = val),
                            scale: scale,
                          ),
                          _divider(scale),
                          _notificationToggle(
                            title: 'Replies',
                            iconAsset: 'assets/images/send-2.png',
                            value: _replies,
                            onChanged: (val) => setState(() => _replies = val),
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
                                  ClipOval(
                                    child: Image.network(
                                      _blockedUsers[i]['avatar']!,
                                      width: 36 * scale,
                                      height: 36 * scale,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, error, stackTrace) => Container(
                                        width: 36 * scale,
                                        height: 36 * scale,
                                        color: const Color(0xFF6B42FF),
                                        child: const Icon(Icons.person,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12 * scale),
                                  Expanded(
                                    child: Text(
                                      _blockedUsers[i]['name']!,
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
                                      onPressed: () {
                                        final user = _blockedUsers[i];
                                        setState(() {
                                          _blockedUsers.removeAt(i);
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Unblocked ${user['name']}'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
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
                    Column(
                      children: [
                        _actionTile(
                          title: 'Export my data',
                          iconAsset: 'assets/images/export.svg',
                          fallbackIcon: Icons.upload_rounded,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Exporting data...'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          scale: scale,
                        ),
                        SizedBox(height: 16 * scale),
                        _actionTile(
                          title: 'Sign out',
                          iconAsset: 'assets/images/logout.svg',
                          fallbackIcon: Icons.logout_rounded,
                          onTap: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          scale: scale,
                        ),
                        SizedBox(height: 16 * scale),
                        _actionTile(
                          title: 'Delete account',
                          iconAsset: 'assets/images/profile-delete.svg',
                          fallbackIcon: Icons.person_remove_rounded,
                          isDestructive: true,
                          onTap: () {
                            showModalBottomSheet<void>(
                              context: context,
                              backgroundColor: Colors.transparent,
                              barrierColor: Colors.black.withAlpha(160),
                              isScrollControlled: true,
                              builder: (context) {
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
                                      36 * scale,
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
                                              onTap: () => Navigator.of(context).pop(),
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
                                          "This permanently deletes your profile, moments and replies. This can't be undone.",
                                          style: TextStyle(
                                            color: const Color(0xFFA6A6C1),
                                            fontSize: 14 * scale,
                                            height: 1.4,
                                          ),
                                        ),
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
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.of(context)
                                                    .popUntil((route) => route.isFirst);
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: const Color(0xFFFF647C),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(999),
                                                ),
                                              ),
                                              child: Text(
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
}
