import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String userId;
  final String username;
  final bool isAdmin;
  final bool isSuspended;

  const AdminUserDetailScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.isAdmin,
    required this.isSuspended,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late bool _isAdmin;
  late bool _isSuspended;

  @override
  void initState() {
    super.initState();
    _isAdmin = widget.isAdmin;
    _isSuspended = widget.isSuspended;
  }

  void _showRoleDialog() {
    String selectedRole = _isAdmin ? 'Admin' : 'User';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161626),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Change Role', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                RadioListTile<String>(
                  title: const Text('User', style: TextStyle(color: Colors.white)),
                  value: 'User',
                  groupValue: selectedRole,
                  activeColor: const Color(0xFF9044FB),
                  onChanged: (val) => setSheetState(() => selectedRole = val!),
                ),
                RadioListTile<String>(
                  title: const Text('Admin', style: TextStyle(color: Colors.white)),
                  value: 'Admin',
                  groupValue: selectedRole,
                  activeColor: const Color(0xFF9044FB),
                  onChanged: (val) => setSheetState(() => selectedRole = val!),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9044FB), Color(0xFFC057FF)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x889044FB),
                          blurRadius: 28,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isAdmin = selectedRole == 'Admin';
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Role updated to $selectedRole.')));
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _showStatusDialog() {
    String selectedStatus = _isSuspended ? 'Suspended' : 'Active';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161626),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Change Status', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                RadioListTile<String>(
                  title: const Text('Active', style: TextStyle(color: Colors.white)),
                  value: 'Active',
                  groupValue: selectedStatus,
                  activeColor: const Color(0xFF9044FB),
                  onChanged: (val) => setSheetState(() => selectedStatus = val!),
                ),
                RadioListTile<String>(
                  title: const Text('Suspended', style: TextStyle(color: Colors.white)),
                  value: 'Suspended',
                  groupValue: selectedStatus,
                  activeColor: const Color(0xFF9044FB),
                  onChanged: (val) => setSheetState(() => selectedStatus = val!),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9044FB), Color(0xFFC057FF)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x889044FB),
                          blurRadius: 28,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isSuspended = selectedStatus == 'Suspended';
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $selectedStatus.')));
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);

    return Scaffold(
      backgroundColor: VeraTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            SizedBox(
              height: 56 * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 48 * scale,
                        height: 48 * scale,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24 * scale),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18 * scale,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 16 * scale),
                        child: SizedBox(
                          height: 24 * scale,
                          child: Text(
                            'User Profile',
                            style: TextStyle(
                              color: const Color(0xFFF7F5FF),
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w600,
                              height: 24 / 16,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48 * scale,
                            backgroundColor: const Color(0xFF1B152E),
                            child: Icon(Icons.person, color: const Color(0xFFC68CFF), size: 48 * scale),
                          ),
                          SizedBox(height: 16 * scale),
                          Text(
                            'User Name',
                            style: TextStyle(color: Colors.white, fontSize: 24 * scale, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            '@${widget.username}',
                            style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 16 * scale),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32 * scale),
                    _buildInfoRow('Email', '${widget.username}@example.com', scale),
                    _buildInfoRow('Registration Date', 'Oct 12, 2023', scale),
                    _buildInfoRow('Current Role', _isAdmin ? 'Admin' : 'User', scale),
                    _buildInfoRow('Account Status', _isSuspended ? 'Suspended' : 'Active', scale),

                    SizedBox(height: 48 * scale),
                    Text('Account Actions', style: TextStyle(color: const Color(0xFFF7F5FF), fontSize: 18 * scale, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16 * scale),

                    ListTile(
                      onTap: _showRoleDialog,
                      tileColor: const Color(0xFF161626),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * scale), side: const BorderSide(color: Color(0xFF282842))),
                      leading: Icon(Icons.security, color: const Color(0xFF9044FB), size: 24 * scale),
                      title: Text('Change User Role', style: TextStyle(color: Colors.white, fontSize: 15 * scale)),
                      trailing: Icon(Icons.chevron_right, color: const Color(0xFFA2A5C2), size: 20 * scale),
                    ),
                    SizedBox(height: 12 * scale),
                    ListTile(
                      onTap: _showStatusDialog,
                      tileColor: const Color(0xFF161626),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * scale), side: const BorderSide(color: Color(0xFF282842))),
                      leading: Icon(Icons.gavel, color: const Color(0xFFC057FF), size: 24 * scale),
                      title: Text('Change Account Status', style: TextStyle(color: Colors.white, fontSize: 15 * scale)),
                      trailing: Icon(Icons.chevron_right, color: const Color(0xFFA2A5C2), size: 20 * scale),
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

  Widget _buildInfoRow(String label, String value, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 14 * scale)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 14 * scale, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
