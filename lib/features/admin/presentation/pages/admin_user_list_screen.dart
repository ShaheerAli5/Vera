import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../data/models/admin_user_model.dart';
import 'admin_user_detail_screen.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final List<AdminUserModel> _users = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Active, Flagged, Suspended
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      final result = await repo.getUsers(search: _searchQuery);
      if (mounted) {
        setState(() {
          _users.clear();
          _users.addAll(result.items);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
          _isLoading = false;
        });
      }
    }
  }

  List<AdminUserModel> get _filteredUsers {
    return _users.where((user) {
      if (_selectedFilter == 'Active') return user.isActive;
      if (_selectedFilter == 'Suspended') return !user.isActive;
      if (_selectedFilter == 'Flagged') return false; // or based on flag status if available
      return true; // 'All'
    }).toList();
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
    final displayUsers = _filteredUsers;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 110 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Fill 342px, Hug 56px, space-between)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Users',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28 * scale,
                      height: 36 / 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    '${_users.length} total · 38 new today',
                    style: TextStyle(
                      color: const Color(0xFF8A8EB3),
                      fontSize: 12 * scale,
                      height: 18 / 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Filter tune button (44x44, radius 999, border 1.2px 14% white, bg 7% white)
              Container(
                width: 44 * scale,
                height: 44 * scale,
                decoration: BoxDecoration(
                  color: const Color(0x12FFFFFF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x24FFFFFF),
                    width: 1.2,
                  ),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.tune_rounded, color: Colors.white, size: 20 * scale),
                  tooltip: 'Filter options',
                ),
              ),
            ],
          ),
          SizedBox(height: 20 * scale),

          // Search Field (Fill 342px, Fixed 48px, radius 999px, border 1.2px at 20% white, bg 4% white)
          Container(
            height: 48 * scale,
            decoration: BoxDecoration(
              color: const Color(0x0AFFFFFF), // 4% white
              borderRadius: BorderRadius.circular(999 * scale),
              border: Border.all(
                color: const Color(0x33FFFFFF), // 20% white border
                width: 1.2,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white, fontSize: 14 * scale),
              cursorColor: const Color(0xFF58C3F4),
              decoration: InputDecoration(
                hintText: 'Search name, @handle or email',
                hintStyle: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 14 * scale),
                prefixIcon: Icon(Icons.search_rounded, color: const Color(0xFF8A8EB3), size: 20 * scale),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, color: const Color(0xFF8A8EB3), size: 18 * scale),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                          _fetchUsers();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
                _fetchUsers();
              },
            ),
          ),
          SizedBox(height: 16 * scale),

          // Filter Chips Row (gap 8px)
          Row(
            children: [
              _buildFilterChip('All', scale),
              SizedBox(width: 8 * scale),
              _buildFilterChip('Active', scale),
              SizedBox(width: 8 * scale),
              _buildFilterChip('Flagged', scale),
              SizedBox(width: 8 * scale),
              _buildFilterChip('Suspended', scale),
            ],
          ),
          SizedBox(height: 20 * scale),

          // Users List Card (Fill 342px, radius 20px, border 1.5px 14% white, bg 6% white, padding top/bottom 2px, left/right 16px)
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
              child: _isLoading
                  ? Padding(
                      padding: EdgeInsets.all(40 * scale),
                      child: Center(
                        child: CircularProgressIndicator(color: const Color(0xFF58C3F4)),
                      ),
                    )
                  : _error != null
                      ? Padding(
                          padding: EdgeInsets.all(24 * scale),
                          child: Center(
                            child: Text(
                              'Error: $_error',
                              style: TextStyle(color: Colors.red, fontSize: 14 * scale),
                            ),
                          ),
                        )
                      : displayUsers.isEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(vertical: 60 * scale, horizontal: 24 * scale),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64 * scale,
                                    height: 64 * scale,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B152E),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF8E37FF).withValues(alpha: 0.5),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.search_rounded,
                                      color: const Color(0xFFC68CFF),
                                      size: 32 * scale,
                                    ),
                                  ),
                                  SizedBox(height: 20 * scale),
                                  Text(
                                    'No users found',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18 * scale,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8 * scale),
                                  Text(
                                    'Check the spelling or try a different name, handle or email.',
                                    style: TextStyle(
                                      color: const Color(0xFF8A8EB3),
                                      fontSize: 13 * scale,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 24 * scale),
                                  Container(
                                    width: 180 * scale,
                                    height: 48 * scale,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF8E37FF), Color(0xFF58C3F4)],
                                      ),
                                      borderRadius: BorderRadius.circular(999 * scale),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF8E37FF).withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _searchQuery = '';
                                            _searchController.clear();
                                          });
                                          _fetchUsers();
                                        },
                                        borderRadius: BorderRadius.circular(999 * scale),
                                        child: Center(
                                          child: Text(
                                            'Clear search',
                                            style: TextStyle(
                                              color: Colors.white,
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
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayUsers.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: const Color(0x24FFFFFF),
                              ),
                              itemBuilder: (context, index) {
                                final user = displayUsers[index];
                                return _buildUserItem(context, scale, user);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, double scale) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = label);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 8 * scale),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E2452) : const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(999 * scale),
          border: Border.all(
            color: isSelected ? const Color(0xFF8E37FF) : const Color(0x24FFFFFF),
            width: isSelected ? 1.5 : 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF8A8EB3),
            fontSize: 12 * scale,
            height: 14 / 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildUserItem(BuildContext context, double scale, AdminUserModel user) {
    final initials = _getInitials(user.displayName);
    final isSuspended = !user.isActive;
    final statusText = isSuspended ? 'Suspended' : 'Active';
    final statusColor = isSuspended ? const Color(0xFFFF4E7E) : const Color(0xFF58C3F4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final updatedUser = await Navigator.of(context).push<AdminUserModel>(
            MaterialPageRoute(
              builder: (_) => AdminUserDetailScreen(user: user),
            ),
          );
          if (updatedUser != null) {
            _fetchUsers();
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12 * scale),
          child: Row(
            children: [
              // Circular Gradient Avatar with Initials (44x44)
              Container(
                width: 44 * scale,
                height: 44 * scale,
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
                      fontSize: 15 * scale,
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
                      user.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * scale,
                        height: 24 / 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      '@${user.email.split('@').first}',
                      style: TextStyle(
                        color: const Color(0xFF8A8EB3),
                        fontSize: 12 * scale,
                        height: 18 / 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge (Hug 51px x 22px, radius 999, padding 4 top/bottom, 10 left/right)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999 * scale),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11 * scale,
                    height: 14 / 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 12 * scale),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: const Color(0xFF8A8EB3),
                size: 14 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
