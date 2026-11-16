import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/models/admin_audit_log_model.dart';
import '../../data/repositories/admin_repository_impl.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  List<AdminAuditLogModel> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAuditLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuditLogs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      final response = await repo.getAuditLogs(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (!mounted) return;
      setState(() {
        _logs = response.items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);

    return RefreshIndicator(
      onRefresh: _fetchAuditLogs,
      color: const Color(0xFF9044FB),
      backgroundColor: const Color(0xFF161626),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16 * scale, 16 * scale, 16 * scale, 8 * scale),
            child: Text(
              'Audit Log',
              style: TextStyle(
                color: const Color(0xFFF7F5FF),
                fontSize: 24 * scale,
                fontWeight: FontWeight.w600,
                letterSpacing: -.3,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16 * scale),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48 * scale,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: Colors.white, fontSize: 14 * scale),
                      cursorColor: const Color(0xFF9044FB),
                      onSubmitted: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                        _fetchAuditLogs();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search actions...',
                        hintStyle: TextStyle(color: const Color(0xFF535370), fontSize: 14 * scale),
                        filled: true,
                        fillColor: const Color(0xFF161626),
                        prefixIcon: Icon(Icons.search, color: const Color(0xFF535370), size: 20 * scale),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: const Color(0xFF535370), size: 18 * scale),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                  _fetchAuditLogs();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12 * scale),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12 * scale),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12 * scale),
                          borderSide: BorderSide(
                            color: const Color(0xFF9044FB),
                            width: 1 * scale,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 14 * scale),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12 * scale),
                Container(
                  height: 48 * scale,
                  width: 48 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161626),
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  child: IconButton(
                    onPressed: _fetchAuditLogs,
                    icon: Icon(Icons.refresh, color: const Color(0xFFC68CFF), size: 24 * scale),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(scale),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double scale) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9044FB)),
      );
    }

    if (_errorMessage != null && _logs.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.amber, size: 48 * scale),
              SizedBox(height: 16 * scale),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 14 * scale),
              ),
              SizedBox(height: 16 * scale),
              ElevatedButton.icon(
                onPressed: _fetchAuditLogs,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9044FB)),
              ),
            ],
          ),
        ),
      );
    }

    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: const Color(0xFFC68CFF), size: 56 * scale),
            SizedBox(height: 16 * scale),
            Text(
              'No audit logs found',
              style: TextStyle(color: Colors.white, fontSize: 18 * scale, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8 * scale),
            Text(
              'Admin activity logs will appear here.',
              style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 14 * scale),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 100 * scale),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return _buildLogItem(context, scale, log);
      },
    );
  }

  Widget _buildLogItem(BuildContext context, double scale, AdminAuditLogModel log) {
    final dateStr = log.createdAt != null
        ? log.createdAt!.toLocal().toString().split('.').first
        : 'Recently';

    return Container(
      margin: EdgeInsets.only(bottom: 12 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF161626),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: const Color(0xFF282842)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                log.actorName,
                style: TextStyle(color: Colors.white, fontSize: 14 * scale, fontWeight: FontWeight.bold),
              ),
              Text(
                dateStr,
                style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 12 * scale),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),
          Text(
            log.action,
            style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 14 * scale),
          ),
          if (log.targetName.isNotEmpty) ...[
            SizedBox(height: 8 * scale),
            Text(
              'Target: ${log.targetName}',
              style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 12 * scale),
            ),
          ],
        ],
      ),
    );
  }
}
