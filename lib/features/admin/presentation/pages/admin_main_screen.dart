import 'package:flutter/material.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/auth/auth_diagnostics.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../splash/presentation/pages/splash_screen.dart';
import '../widgets/admin_bottom_nav_bar.dart';

import 'admin_dashboard_screen.dart';
import 'admin_moderation_queue_screen.dart';
import 'admin_user_list_screen.dart';
import 'admin_settings_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    AdminDashboardScreen(isActive: _currentIndex == 0),
    AdminModerationQueueScreen(isActive: _currentIndex == 1),
    const AdminUserListScreen(),
    const AdminSettingsScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _validateRoleGuard();
  }

  void _validateRoleGuard() {
    final client = ApiClientScope.of(context);
    final parsedRole = UserRole.parse(client.userRole);
    logAuthFlow('role_guard', {
      'destination': 'admin', 'savedRole': diagnosticRole(client.userRole),
      'parsedRole': parsedRole?.value ?? 'unknown',
      'hasAccessToken': client.authToken?.isNotEmpty == true,
      'decision': parsedRole == UserRole.owner ? 'allow' : 'deny_non_admin',
    });
    if (parsedRole != UserRole.owner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        client.clearTokens();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const SplashScreen()),
          (route) => false,
        );
        VeraPopup.show(
          context,
          title: 'Access Denied',
          message: 'You do not have permission to access the Admin Dashboard.',
          icon: Icons.error_outline_rounded,
          accent: VeraTheme.warning,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);

    return Scaffold(
      backgroundColor: const Color(0xFF080914),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Active Screen Content
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _pages.asMap().entries.map((entry) => TickerMode(
                      enabled: entry.key == _currentIndex,
                      child: entry.value,
                    )).toList(),
                  ),
                ),
              ],
            ),

            // Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AdminBottomNavBar(
                selectedIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                scale: scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
