import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';

class AdminAuditLogScreen extends StatelessWidget {
  const AdminAuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);

    return Column(
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
                    style: TextStyle(color: Colors.white, fontSize: 14 * scale),
                    cursorColor: const Color(0xFF9044FB),
                    decoration: InputDecoration(
                      hintText: 'Search actions...',
                      hintStyle: TextStyle(color: const Color(0xFF535370), fontSize: 14 * scale),
                      filled: true,
                      fillColor: const Color(0xFF161626),
                      prefixIcon: Icon(Icons.search, color: const Color(0xFF535370), size: 20 * scale),
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
                  onPressed: () {},
                  icon: Icon(Icons.date_range, color: const Color(0xFFC68CFF), size: 24 * scale),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 100 * scale),
            itemCount: 20,
            itemBuilder: (context, index) {
              return _buildLogItem(context, scale, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(BuildContext context, double scale, int index) {
    final actions = [
      'Role changed from User to Admin',
      'Moment Approved',
      'User Suspended',
      'Moment Rejected',
      'Account Activated'
    ];
    final action = actions[index % actions.length];

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
                'Admin User',
                style: TextStyle(color: Colors.white, fontSize: 14 * scale, fontWeight: FontWeight.bold),
              ),
              Text(
                'Oct 25, 2023 - 10:${10 + index} AM',
                style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 12 * scale),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),
          Text(
            action,
            style: TextStyle(color: const Color(0xFFA2A5C2), fontSize: 14 * scale),
          ),
          SizedBox(height: 8 * scale),
          Text(
            'Target: @user_$index',
            style: TextStyle(color: const Color(0xFF8A8EB3), fontSize: 12 * scale),
          ),
        ],
      ),
    );
  }
}
