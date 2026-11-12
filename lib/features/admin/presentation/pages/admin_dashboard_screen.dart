import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16 * scale, 16 * scale, 16 * scale, 100 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: TextStyle(
              color: const Color(0xFFF7F5FF),
              fontSize: 24 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: -.3,
            ),
          ),
          SizedBox(height: 24 * scale),
          _buildStatCardsRow(scale, 'Total Users', '12,345', 'Active Users', '11,200', const Color(0xFF9044FB), const Color(0xFFC057FF)),
          SizedBox(height: 16 * scale),
          _buildStatCardsRow(scale, 'Suspended', '145', 'Pending Moments', '45', const Color(0xFFE291FF), const Color(0xFF9044FB)),
          SizedBox(height: 16 * scale),
          _buildStatCardsRow(scale, 'Approved Moments', '8,900', 'Rejected Moments', '320', const Color(0xFFC057FF), const Color(0xFF8A8EB3)),
          SizedBox(height: 32 * scale),
          Text(
            'Recent Activities',
            style: TextStyle(
              color: const Color(0xFFF7F5FF),
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: -.2,
            ),
          ),
          SizedBox(height: 16 * scale),
          _buildActivityList(scale),
        ],
      ),
    );
  }

  Widget _buildStatCardsRow(double scale, String title1, String val1, String title2, String val2, Color c1, Color c2) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(scale, title1, val1, c1)),
        SizedBox(width: 16 * scale),
        Expanded(child: _buildStatCard(scale, title2, val2, c2)),
      ],
    );
  }

  Widget _buildStatCard(double scale, String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF161626),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: const Color(0xFF282842)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8 * scale,
                height: 8 * scale,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 13 * scale, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 28 * scale, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(double scale) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: 12 * scale),
      itemBuilder: (context, index) {
        return Container(
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            color: const Color(0xFF161626),
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(color: const Color(0xFF282842)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20 * scale,
                backgroundColor: const Color(0xFF1B152E),
                child: Icon(Icons.person, color: const Color(0xFFC68CFF), size: 20 * scale),
              ),
              SizedBox(width: 16 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New User Registration',
                      style: TextStyle(color: Colors.white, fontSize: 14 * scale, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      'user${index}@example.com joined.',
                      style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 12 * scale),
                    ),
                  ],
                ),
              ),
              Text(
                '${index + 1}m ago',
                style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 12 * scale),
              ),
            ],
          ),
        );
      },
    );
  }
}
