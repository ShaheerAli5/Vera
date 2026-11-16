import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/repositories/admin_repository_impl.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final AdminUserModel user;

  const AdminUserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late AdminUserModel _user;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _updateRole(String newRole) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      final updated = await repo.updateUserRole(
        _user.id,
        role: newRole,
        version: _user.version,
      );
      if (!mounted) return;

      setState(() {
        _user = updated;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User role updated to ${updated.role}.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update role: ${e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateStatus(bool newIsActive) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      final updated = await repo.updateUserStatus(
        _user.id,
        isActive: newIsActive,
        version: _user.version,
      );
      if (!mounted) return;

      setState(() {
        _user = updated;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User status updated to ${updated.isActive ? "Active" : "Suspended"}.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRoleDialog() {
    final isAdmin = _user.role.toUpperCase() == 'ADMIN';
    String selectedRole = isAdmin ? 'ADMIN' : 'USER';

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
                ListTile(
                  title: const Text('USER', style: TextStyle(color: Colors.white)),
                  leading: Radio<String>(
                    value: 'USER',
                    groupValue: selectedRole,
                    activeColor: const Color(0xFF9044FB),
                    onChanged: (val) => setSheetState(() => selectedRole = val!),
                  ),
                  onTap: () => setSheetState(() => selectedRole = 'USER'),
                ),
                ListTile(
                  title: const Text('ADMIN', style: TextStyle(color: Colors.white)),
                  leading: Radio<String>(
                    value: 'ADMIN',
                    groupValue: selectedRole,
                    activeColor: const Color(0xFF9044FB),
                    onChanged: (val) => setSheetState(() => selectedRole = val!),
                  ),
                  onTap: () => setSheetState(() => selectedRole = 'ADMIN'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateRole(selectedRole);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9044FB)),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
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
    String selectedStatus = _user.isActive ? 'Active' : 'Suspended';

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
                ListTile(
                  title: const Text('Active', style: TextStyle(color: Colors.white)),
                  leading: Radio<String>(
                    value: 'Active',
                    groupValue: selectedStatus,
                    activeColor: const Color(0xFF9044FB),
                    onChanged: (val) => setSheetState(() => selectedStatus = val!),
                  ),
                  onTap: () => setSheetState(() => selectedStatus = 'Active'),
                ),
                ListTile(
                  title: const Text('Suspended', style: TextStyle(color: Colors.white)),
                  leading: Radio<String>(
                    value: 'Suspended',
                    groupValue: selectedStatus,
                    activeColor: const Color(0xFF9044FB),
                    onChanged: (val) => setSheetState(() => selectedStatus = val!),
                  ),
                  onTap: () => setSheetState(() => selectedStatus = 'Suspended'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateStatus(selectedStatus == 'Active');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9044FB)),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
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

    final isAdmin = _user.role.toUpperCase() == 'ADMIN';
    final createdDateStr = _user.createdAt.split('T').first;

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
                      onTap: () => Navigator.of(context).maybePop(_user),
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
                            _user.displayName,
                            style: TextStyle(color: Colors.white, fontSize: 24 * scale, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            _user.email,
                            style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 16 * scale),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32 * scale),
                    _buildInfoRow('Email', _user.email, scale),
                    _buildInfoRow('Registration Date', createdDateStr, scale),
                    _buildInfoRow('Current Role', isAdmin ? 'Admin' : 'User', scale),
                    _buildInfoRow('Account Status', _user.isActive ? 'Active' : 'Suspended', scale),

                    SizedBox(height: 48 * scale),
                    Text('Account Actions', style: TextStyle(color: const Color(0xFFF7F5FF), fontSize: 18 * scale, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16 * scale),

                    if (_isSaving)
                      const Center(child: CircularProgressIndicator(color: Color(0xFF9044FB)))
                    else ...[
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
