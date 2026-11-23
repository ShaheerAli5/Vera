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

  String _formatRelativeTime(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return 'Recently';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inSeconds < 45) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Recently';
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
    final isOwner = _user.role?.toUpperCase() == 'OWNER';
    final isAdmin = _user.role?.toUpperCase() == 'ADMIN';

    if (isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot change the role of the Owner.'), backgroundColor: Colors.red),
      );
      return;
    }

    final newRole = isAdmin ? 'USER' : 'ADMIN';

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF111426),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0x28FFFFFF), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF58C3F4).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Color(0xFF58C3F4),
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAdmin ? 'Demote ${_user.displayName}?' : 'Promote ${_user.displayName}?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 28 / 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isAdmin
                    ? 'They will lose access to the Admin Dashboard and all moderation privileges.'
                    : 'They will gain access to the Admin Dashboard and moderation privileges.',
                style: const TextStyle(
                  color: Color(0xFFA2A5C2),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 22 / 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Confirm Button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E37FF), Color(0xFF58C3F4)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _updateRole(newRole);
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Center(
                      child: Text(
                        isAdmin ? 'Demote to User' : 'Promote to Admin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Cancel Button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0x12FFFFFF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0x28FFFFFF),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(999),
                    child: const Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
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

  Future<void> _updateRole(String newRole) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      final updated = await repo.updateUserRole(
        _user.id,
        role: newRole,
        version: _user.version ?? 1,
      );
      if (!mounted) return;

      setState(() {
        _user = updated;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User role updated to ${updated.role}.'),
          backgroundColor: Colors.green,
        ),
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

  void _showSuspendDialog() {
    final isSuspended = !_user.isActive;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF111426),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0x28FFFFFF), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isSuspended ? const Color(0xFF00FF85) : const Color(0xFFFF4E7E)).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuspended ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                  color: isSuspended ? const Color(0xFF00FF85) : const Color(0xFFFF4E7E),
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSuspended ? 'Activate ${_user.displayName}?' : 'Suspend ${_user.displayName}?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 28 / 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isSuspended
                    ? 'They will regain access to send or open moments immediately.'
                    : 'They won’t be able to send or open moments until you lift the suspension. They’ll be notified by email.',
                style: const TextStyle(
                  color: Color(0xFFA2A5C2),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 22 / 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Suspend / Activate Button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: isSuspended ? const Color(0x1F00FF85) : const Color(0x1FFF6B6B),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSuspended ? const Color(0xB300FF85) : const Color(0xB3FF6B6B),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _updateStatus(!_user.isActive);
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSuspended ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                          color: isSuspended ? const Color(0xFF00FF85) : const Color(0xFFFF6B6B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isSuspended ? 'Activate account' : 'Suspend account',
                          style: TextStyle(
                            color: isSuspended ? const Color(0xFF00FF85) : const Color(0xFFFF6B6B),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Cancel Button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0x12FFFFFF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0x28FFFFFF),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(999),
                    child: const Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
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

  Future<void> _revokeSessions() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      await repo.revokeUserSessions(_user.id);
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User active sessions revoked.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to revoke sessions: ${e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111426),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to permanently delete ${_user.displayName}\'s account?', style: const TextStyle(color: Color(0xFFA2A5C2))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4E7E)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      await repo.deleteUser(_user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User account permanently deleted.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: ${e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
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

    final initials = _getInitials(_user.displayName);
    final joinedDate = _user.createdAt.isNotEmpty ? _user.createdAt.split('T').first : 'Oct 2, 2026';
    final isSuspended = !_user.isActive;

    return Scaffold(
      backgroundColor: VeraTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            SizedBox(
              height: 56 * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(_user),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 40 * scale,
                        height: 40 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0x12FFFFFF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x24FFFFFF), width: 1.2),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 18 * scale,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Container(
                        width: 40 * scale,
                        height: 40 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0x12FFFFFF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x24FFFFFF), width: 1.2),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.more_horiz_rounded,
                            color: Colors.white,
                            size: 18 * scale,
                          ),
                        ),
                      ),
                      color: const Color(0xFF1B152E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * scale)),
                      onSelected: (action) {
                        if (action == 'admin') {
                          _showRoleDialog();
                        } else if (action == 'user') {
                          _showRoleDialog();
                        }
                      },
                      itemBuilder: (context) {
                        final isOwner = _user.role?.toUpperCase() == 'OWNER';
                        final isAdmin = _user.role?.toUpperCase() == 'ADMIN';
                        return [
                          if (!isOwner && !isAdmin)
                            PopupMenuItem(
                              value: 'admin',
                              child: Text('Promote to Admin', style: TextStyle(color: Colors.white, fontSize: 13 * scale)),
                            ),
                          if (!isOwner && isAdmin)
                            PopupMenuItem(
                              value: 'user',
                              child: Text('Demote to User', style: TextStyle(color: Colors.white, fontSize: 13 * scale)),
                            ),
                        ];
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24 * scale, 12 * scale, 24 * scale, 40 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Hero Section (Fill 342px, Hug 180px, gap 6px)
                    Column(
                      children: [
                        Container(
                          width: 88 * scale,
                          height: 88 * scale,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF58C3F4), Color(0xFF8E37FF)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12 * scale),
                        Text(
                          _user.displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          '@${_user.email.split('@').first}',
                          style: TextStyle(
                            color: const Color(0xFF8A8EB3),
                            fontSize: 14 * scale,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 4 * scale),
                          decoration: BoxDecoration(
                            color: (isSuspended ? const Color(0xFFFF4E7E) : const Color(0xFF00FF85)).withOpacity(0.16),
                            borderRadius: BorderRadius.circular(999 * scale),
                          ),
                          child: Text(
                            isSuspended ? 'Suspended' : 'Active',
                            style: TextStyle(
                              color: isSuspended ? const Color(0xFFFF4E7E) : const Color(0xFF00FF85),
                              fontSize: 11 * scale,
                              height: 14 / 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24 * scale),

                    // Counts Section (Fill 342px, Hug 72px, space-between)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildStatColumn(scale, 'assets/images/send.png', 'Created', '24')),
                        Expanded(child: _buildStatColumn(scale, 'assets/images/inbox.png', 'Received', '31')),
                        Expanded(child: _buildStatColumn(scale, 'assets/images/profile_replies.png', 'Replies', '12')),
                      ],
                    ),
                    SizedBox(height: 24 * scale),

                    // Account Info Card (Fill 342px, Hug 195px, radius 20px, border 1.5px 14% white, bg 6% white, padding 4 top/bottom, 16 left/right)
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
                        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 4 * scale),
                        child: Column(
                          children: [
                            _buildDetailRow(scale, 'Email', _user.email),
                            Divider(height: 1, color: const Color(0x24FFFFFF)),
                            _buildDetailRow(scale, 'Joined', joinedDate),
                            Divider(height: 1, color: const Color(0x24FFFFFF)),
                            _buildDetailRow(scale, 'Last active', _formatRelativeTime(_user.updatedAt ?? _user.createdAt)),
                            Divider(height: 1, color: const Color(0x24FFFFFF)),
                            _buildDetailRow(scale, 'Reports against', '3 open', isRed: true),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24 * scale),

                    // Action Buttons
                    if (_isSaving)
                      const CircularProgressIndicator(color: Color(0xFF58C3F4))
                    else ...[
                      // Button / Danger (Fill 342px, Fixed 52px, radius 999px, border 1.5px #FF6B6B at 70%, bg #FF6B6B at 12%)
                      Container(
                        width: double.infinity,
                        height: 52 * scale,
                        decoration: BoxDecoration(
                          color: isSuspended ? const Color(0x1F00FF85) : const Color(0x1FFF6B6B),
                          borderRadius: BorderRadius.circular(999 * scale),
                          border: Border.all(
                            color: isSuspended ? const Color(0xB300FF85) : const Color(0xB3FF6B6B),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _showSuspendDialog,
                            borderRadius: BorderRadius.circular(999 * scale),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isSuspended ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                                  color: isSuspended ? const Color(0xFF00FF85) : const Color(0xFFFF6B6B),
                                  size: 20 * scale,
                                ),
                                SizedBox(width: 8 * scale),
                                Text(
                                  isSuspended ? 'Activate account' : 'Suspend account',
                                  style: TextStyle(
                                    color: isSuspended ? const Color(0xFF00FF85) : const Color(0xFFFF6B6B),
                                    fontSize: 15 * scale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12 * scale),
                      // Button / Secondary (Fill 342px, Fixed 52px, radius 999px, border 1.5px 16% white, bg 7% white)
                      Container(
                        width: double.infinity,
                        height: 52 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0x12FFFFFF), // 7% white
                          borderRadius: BorderRadius.circular(999 * scale),
                          border: Border.all(
                            color: const Color(0x28FFFFFF), // 16% white border
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Warning sent to user.'), backgroundColor: Colors.purple),
                              );
                            },
                            borderRadius: BorderRadius.circular(999 * scale),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mail_outline_rounded, color: Colors.white, size: 20 * scale),
                                SizedBox(width: 8 * scale),
                                Text(
                                  'Send warning',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15 * scale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildStatColumn(double scale, String assetPath, String label, String value) {
    return Column(
      children: [
        Image.asset(
          assetPath,
          width: 20 * scale,
          height: 20 * scale,
        ),
        SizedBox(height: 4 * scale),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF8A8EB3),
            fontSize: 12 * scale,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2 * scale),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(double scale, String label, String value, {bool isRed = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 11 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF8A8EB3),
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isRed ? const Color(0xFFFF6B6B) : Colors.white,
              fontSize: 14 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
