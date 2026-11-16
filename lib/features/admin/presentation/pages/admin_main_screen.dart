import 'package:flutter/material.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../../shared/widgets/vera_logo.dart';
import '../../../splash/presentation/pages/splash_screen.dart';
import '../widgets/admin_bottom_nav_bar.dart';

import 'admin_dashboard_screen.dart';
import 'admin_moderation_queue_screen.dart';
import 'admin_user_list_screen.dart';
import 'admin_audit_log_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    AdminModerationQueueScreen(),
    AdminUserListScreen(),
    AdminAuditLogScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _validateRoleGuard();
  }

  void _validateRoleGuard() {
    final client = ApiClientScope.of(context);
    final parsedRole = UserRole.parse(client.userRole);
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
                // Top Bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20 * scale,
                    vertical: 8 * scale,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          VeraLogo(height: 18 * scale),
                          SizedBox(width: 8 * scale),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9044FB).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4 * scale),
                            ),
                            child: Text(
                              'ADMIN',
                              style: TextStyle(
                                color: const Color(0xFFC857FF),
                                fontSize: 10 * scale,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/');
                            },
                            icon: Icon(
                              Icons.exit_to_app,
                              color: Colors.white,
                              size: 22 * scale,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Active Screen Content
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _pages,
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
