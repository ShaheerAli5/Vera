import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/models/admin_report_model.dart';
import '../../data/repositories/admin_repository_impl.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedType = 'ALL'; // ALL, MOMENT, USER
  String _selectedStatus = 'PENDING'; // PENDING, RESOLVED
  List<AdminReportModel> _reports = [];
  bool _isLoading = true;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchReports());
  }

  Future<void> _fetchReports() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));

      final res = await repo.getReports(
        page: 1,
        limit: 50,
        status: _selectedStatus,
        type: _selectedType,
      );

      if (!mounted) return;
      setState(() {
        _reports = res.items;
        _totalCount = res.total;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      VeraPopup.show(
        context,
        title: 'Error Loading Reports',
        message: e.toString().replaceAll('Exception: ', ''),
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    }
  }

  Future<void> _resolveReport(
    AdminReportModel report,
    String resolution,
    String resolutionLabel,
  ) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161626),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x33FFFFFF)),
          ),
          title: Text(
            'Confirm $resolutionLabel',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to mark this report as "$resolutionLabel"?',
                style: const TextStyle(color: Color(0xFFC0BDD1), fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Optional resolution note...',
                  hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F0E17),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0x22FFFFFF)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: resolution == 'DISMISSED'
                    ? const Color(0xFF4C4765)
                    : const Color(0xFFFF4D4D),
              ),
              child: Text(
                resolutionLabel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final client = ApiClientScope.of(context);
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(client));

      await repo.resolveReport(
        reportId: report.id,
        resolution: resolution,
        note: noteController.text.trim(),
      );

      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Report Resolved',
        message: 'Report resolved as $resolutionLabel successfully.',
        icon: Icons.check_circle_outline_rounded,
        accent: const Color(0xFF22C55E),
      );
      _fetchReports();
    } catch (e) {
      if (!mounted) return;
      VeraPopup.show(
        context,
        title: 'Resolution Failed',
        message: e.toString().replaceAll('Exception: ', ''),
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
    }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Community Reports ($_totalCount)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterRow(scale),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF9044FB),
                    ),
                  )
                : _reports.isEmpty
                    ? _buildEmptyState(scale)
                    : RefreshIndicator(
                        onRefresh: _fetchReports,
                        color: const Color(0xFF9044FB),
                        backgroundColor: const Color(0xFF161626),
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            12 * scale,
                            16 * scale,
                            40 * scale,
                          ),
                          itemCount: _reports.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12 * scale),
                          itemBuilder: (context, index) {
                            return _buildReportCard(_reports[index], scale);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
      color: const Color(0xFF0F0E1A),
      child: Column(
        children: [
          Row(
            children: [
              _filterChip('All Reports', 'ALL', _selectedType, (v) {
                setState(() => _selectedType = v);
                _fetchReports();
              }, scale),
              SizedBox(width: 8 * scale),
              _filterChip('Moments', 'MOMENT', _selectedType, (v) {
                setState(() => _selectedType = v);
                _fetchReports();
              }, scale),
              SizedBox(width: 8 * scale),
              _filterChip('Users', 'USER', _selectedType, (v) {
                setState(() => _selectedType = v);
                _fetchReports();
              }, scale),
            ],
          ),
          SizedBox(height: 8 * scale),
          Row(
            children: [
              _filterChip('Pending', 'PENDING', _selectedStatus, (v) {
                setState(() => _selectedStatus = v);
                _fetchReports();
              }, scale),
              SizedBox(width: 8 * scale),
              _filterChip('Resolved', 'RESOLVED', _selectedStatus, (v) {
                setState(() => _selectedStatus = v);
                _fetchReports();
              }, scale),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    String value,
    String current,
    ValueChanged<String> onSelected,
    double scale,
  ) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF9044FB).withValues(alpha: 0.25)
              : const Color(0xFF1E1C2E),
          borderRadius: BorderRadius.circular(20 * scale),
          border: Border.all(
            color: isSelected ? const Color(0xFF9044FB) : const Color(0x22FFFFFF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFE291FF) : const Color(0xFF8A8EB3),
            fontSize: 12 * scale,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(AdminReportModel report, double scale) {
    final isUserReport = report.type == 'USER';
    final isPending = report.status == 'PENDING';

    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF141324),
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(
          color: isPending ? const Color(0x33FF6B6B) : const Color(0x1AFFFFFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 3 * scale),
                decoration: BoxDecoration(
                  color: isUserReport
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                      : const Color(0xFFEAB308).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUserReport ? Icons.person_rounded : Icons.camera_alt_rounded,
                      size: 13 * scale,
                      color: isUserReport ? const Color(0xFF60A5FA) : const Color(0xFFFDE047),
                    ),
                    SizedBox(width: 4 * scale),
                    Text(
                      isUserReport ? 'USER REPORT' : 'MOMENT REPORT',
                      style: TextStyle(
                        color: isUserReport ? const Color(0xFF60A5FA) : const Color(0xFFFDE047),
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 3 * scale),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFFF4D4D).withValues(alpha: 0.2)
                      : const Color(0xFF22C55E).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
                child: Text(
                  report.status,
                  style: TextStyle(
                    color: isPending ? const Color(0xFFFF7B7B) : const Color(0xFF4ADE80),
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * scale),
          Text(
            isUserReport
                ? 'Reported User: ${report.targetUserName ?? report.targetUserId ?? 'Unknown'}'
                : 'Reported Moment: "${report.momentTitle ?? 'Untitled Moment'}"',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            'Reason: ${report.reason}',
            style: TextStyle(
              color: const Color(0xFFFFA05C),
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (report.details != null && report.details!.trim().isNotEmpty) ...[
            SizedBox(height: 4 * scale),
            Text(
              'Details: ${report.details}',
              style: TextStyle(
                color: const Color(0xFFC0BDD1),
                fontSize: 12 * scale,
              ),
            ),
          ],
          SizedBox(height: 6 * scale),
          Row(
            children: [
              Icon(Icons.person_pin_circle_outlined, size: 13 * scale, color: const Color(0xFF8A8EB3)),
              SizedBox(width: 4 * scale),
              Text(
                'Reported by: ${report.reporterName ?? report.reporterId ?? 'Anonymous'}',
                style: TextStyle(
                  color: const Color(0xFF8A8EB3),
                  fontSize: 11 * scale,
                ),
              ),
            ],
          ),
          if (report.resolution != null) ...[
            SizedBox(height: 6 * scale),
            Text(
              'Resolution: ${report.resolution}${report.resolutionNote != null ? ' (${report.resolutionNote})' : ''}',
              style: TextStyle(
                color: const Color(0xFF8A8EB3),
                fontSize: 11 * scale,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (isPending) ...[
            SizedBox(height: 12 * scale),
            const Divider(color: Color(0x1FFFFFFF), height: 1),
            SizedBox(height: 10 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _resolveReport(report, 'DISMISSED', 'Dismiss'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8A8EB3),
                    side: const BorderSide(color: Color(0x33FFFFFF)),
                    padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
                  ),
                  child: Text('Dismiss', style: TextStyle(fontSize: 12 * scale)),
                ),
                SizedBox(width: 8 * scale),
                if (!isUserReport)
                  ElevatedButton(
                    onPressed: () => _resolveReport(report, 'MOMENT_REMOVED', 'Remove Moment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D4D),
                      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
                    ),
                    child: Text(
                      'Remove Moment',
                      style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _resolveReport(report, 'USER_SUSPENDED', 'Suspend User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D4D),
                      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
                    ),
                    child: Text(
                      'Suspend User',
                      style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(double scale) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 48 * scale, color: const Color(0x44FFFFFF)),
          SizedBox(height: 12 * scale),
          Text(
            'No reports found',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            'There are no ${_selectedStatus.toLowerCase()} ${_selectedType.toLowerCase()} reports at this time.',
            style: TextStyle(
              color: const Color(0xFF8A8EB3),
              fontSize: 12 * scale,
            ),
          ),
        ],
      ),
    );
  }
}
