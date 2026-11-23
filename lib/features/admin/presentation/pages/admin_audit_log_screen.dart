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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLogs();
    });
  }

  Future<void> _fetchLogs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));
      final logs = await repo.getAuditLogs(page: 1, limit: 25);

      if (!mounted) return;
      setState(() {
        _logs = logs.items;
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

  String _formatAction(String action) {
    return action.replaceAll('_', ' ').toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);

    return Scaffold(
      backgroundColor: const Color(0xFF080914),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080914),
        elevation: 0,
        title: Text(
          'Audit Log',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(scale),
    );
  }

  Widget _buildBody(double scale) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF58C3F4)),
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
                onPressed: _fetchLogs,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF58C3F4)),
              ),
            ],
          ),
        ),
      );
    }

    if (_logs.isEmpty) {
      return Center(
        child: Text(
          'No audit logs found.',
          style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 16 * scale),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLogs,
      color: const Color(0xFF58C3F4),
      backgroundColor: const Color(0xFF1B152E),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16 * scale, 16 * scale, 16 * scale, 110 * scale),
        itemCount: _logs.length,
        separatorBuilder: (context, index) => SizedBox(height: 12 * scale),
        itemBuilder: (context, index) {
          final log = _logs[index];
          final actorName = log.actorAdmin?['displayName'] ?? log.actorAdmin?['email'] ?? 'Unknown Admin';
          final targetName = log.targetUser?['displayName'] ?? log.targetUser?['email'] ?? 'Unknown User';

          final timeStr = log.createdAt != null
              ? log.createdAt!.toLocal().toString().split('.').first
              : 'Recently';

          return Container(
            padding: EdgeInsets.all(16 * scale),
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(color: const Color(0x24FFFFFF), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: const Color(0xFF8A8EB3),
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 2 * scale),
                      decoration: BoxDecoration(
                        color: const Color(0xFF58C3F4).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _formatAction(log.action),
                        style: TextStyle(
                          color: const Color(0xFF58C3F4),
                          fontSize: 10 * scale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12 * scale),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14 * scale,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: actorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9451FF)),
                      ),
                      const TextSpan(text: ' changed '),
                      TextSpan(
                        text: targetName,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF58C3F4)),
                      ),
                      const TextSpan(text: '\'s '),
                      TextSpan(
                        text: log.action.contains('ROLE') ? 'role' : 'status',
                      ),
                      const TextSpan(text: ' from '),
                      TextSpan(
                        text: log.previousValue,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFFF4E7E)),
                      ),
                      const TextSpan(text: ' to '),
                      TextSpan(
                        text: log.newValue,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00FF85)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
