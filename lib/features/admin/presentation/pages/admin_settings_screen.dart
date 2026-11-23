import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../account/data/datasources/account_remote_data_source.dart';
import '../../../account/data/models/user_profile.dart';
import '../../../account/data/repositories/account_repository_impl.dart';
import '../../../account/presentation/pages/sign_in_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  UserProfile? _profile;
  bool _isLoadingProfile = true;
  bool _twoStep = true;
  bool _biometric = true;
  bool _loginAlerts = false;
  bool _highPriority = true;
  bool _appeals = true;
  bool _dailyDigest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    try {
      final client = ApiClientScope.of(context);
      final repo = AccountRepositoryImpl(AccountRemoteDataSource(client));
      final profile = await repo.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'AD';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);

    final name = _profile?.displayName.isNotEmpty == true ? _profile!.displayName : 'Admin User';
    final email = _profile?.email.isNotEmpty == true ? _profile!.email : 'admin@vera.app';
    final initials = _getInitials(name);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 110 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28 * scale,
                  height: 36 / 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Admin 1.0.0',
                style: TextStyle(
                  color: const Color(0xFF8A8EB3),
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 20 * scale),

          // Admin Account Card (Fill 342px, Hug 79px, radius 20px, border 1.5px 14% white, padding 14px, gap 12px, bg 6% white)
          Container(
            padding: EdgeInsets.all(14 * scale),
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF), // 6% white
              borderRadius: BorderRadius.circular(20 * scale),
              border: Border.all(
                color: const Color(0x24FFFFFF), // 14% white border
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52 * scale,
                  height: 52 * scale,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF58C3F4), Color(0xFF8E37FF)],
                    ),
                  ),
                  child: Center(
                    child: _isLoadingProfile
                        ? SizedBox(
                            width: 20 * scale,
                            height: 20 * scale,
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            initials,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18 * scale,
                              fontWeight: FontWeight.bold,
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
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 * scale,
                          height: 24 / 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        'Super admin · $email',
                        style: TextStyle(
                          color: const Color(0xFF8A8EB3),
                          fontSize: 12 * scale,
                          height: 18 / 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Badge (Hug 52px x 22px, radius 999, padding 4 top/bottom, 10 left/right, bg #9451FF at 16%)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0x299451FF), // 16% #9451FF
                    borderRadius: BorderRadius.circular(999 * scale),
                  ),
                  child: Text(
                    'Admin',
                    style: TextStyle(
                      color: const Color(0xFFC857FF),
                      fontSize: 11 * scale,
                      height: 14 / 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24 * scale),

          // Security Section Header
          Text(
            'Security',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18 * scale,
              height: 26 / 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12 * scale),

          // Security Card Container (Fill 342px, Hug 157px, radius 20px, border 1.5px 14% white, bg 6% white, padding 2 top/bottom, 16 left/right)
          Container(
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF), // 6% white
              borderRadius: BorderRadius.circular(20 * scale),
              border: Border.all(
                color: const Color(0x24FFFFFF), // 14% white border
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 2 * scale),
              child: Column(
                children: [
                  _buildSettingRow(
                    scale,
                    icon: Icons.vpn_key_outlined,
                    title: 'Two-step verification',
                    value: _twoStep,
                    onChanged: (val) => setState(() => _twoStep = val),
                  ),
                  Divider(height: 1, color: const Color(0x24FFFFFF)),
                  _buildSettingRow(
                    scale,
                    icon: Icons.visibility_outlined,
                    title: 'Biometric unlock',
                    value: _biometric,
                    onChanged: (val) => setState(() => _biometric = val),
                  ),
                  Divider(height: 1, color: const Color(0x24FFFFFF)),
                  _buildSettingRow(
                    scale,
                    icon: Icons.warning_amber_rounded,
                    title: 'Login alerts',
                    value: _loginAlerts,
                    onChanged: (val) => setState(() => _loginAlerts = val),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24 * scale),

          // Notifications Section Header
          Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18 * scale,
              height: 26 / 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12 * scale),

          // Notifications Card Container (Fill 342px, Hug 157px, radius 20px, border 1.5px 14% white, bg 6% white, padding 2 top/bottom, 16 left/right)
          Container(
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF), // 6% white
              borderRadius: BorderRadius.circular(20 * scale),
              border: Border.all(
                color: const Color(0x24FFFFFF), // 14% white border
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 2 * scale),
              child: Column(
                children: [
                  _buildSettingRow(
                    scale,
                    icon: Icons.flag_outlined,
                    title: 'High-priority reports',
                    value: _highPriority,
                    onChanged: (val) => setState(() => _highPriority = val),
                  ),
                  Divider(height: 1, color: const Color(0x24FFFFFF)),
                  _buildSettingRow(
                    scale,
                    icon: Icons.mail_outline_rounded,
                    title: 'Appeals',
                    value: _appeals,
                    onChanged: (val) => setState(() => _appeals = val),
                  ),
                  Divider(height: 1, color: const Color(0x24FFFFFF)),
                  _buildSettingRow(
                    scale,
                    icon: Icons.access_time_rounded,
                    title: 'Daily digest',
                    value: _dailyDigest,
                    onChanged: (val) => setState(() => _dailyDigest = val),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 28 * scale),

          // Sign out of all devices Button (Fill 342px, Fixed 52px, radius 999, border 1.5px #FF6B6B at 70%, bg #FF6B6B at 12%)
          Container(
            width: double.infinity,
            height: 52 * scale,
            decoration: BoxDecoration(
              color: const Color(0x1FFF6B6B), // 12% #FF6B6B
              borderRadius: BorderRadius.circular(999 * scale),
              border: Border.all(
                color: const Color(0xB3FF6B6B), // 70% #FF6B6B
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final client = ApiClientScope.of(context);
                  await client.clearTokens();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
                    (route) => false,
                  );
                },
                borderRadius: BorderRadius.circular(999 * scale),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: const Color(0xFFFF6B6B), size: 20 * scale),
                    SizedBox(width: 8 * scale),
                    Text(
                      'Sign out of all devices',
                      style: TextStyle(
                        color: const Color(0xFFFF6B6B),
                        fontSize: 16 * scale,
                        height: 24 / 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    double scale, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12 * scale),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8A8EB3), size: 20 * scale),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15 * scale,
                height: 24 / 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF8E37FF),
            inactiveThumbColor: const Color(0xFF8A8EB3),
            inactiveTrackColor: const Color(0xFF1B152E),
          ),
        ],
      ),
    );
  }
}
