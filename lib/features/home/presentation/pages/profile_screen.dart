import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.scale, required this.onCreate});

  final double scale;
  final VoidCallback onCreate;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            24 * scale,
            8 * scale,
            12 * scale,
            8 * scale,
          ),
          child: Row(
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  color: const Color(0xFFF4F2FF),
                  fontSize: 28,
                  height: 36 / 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 22 * scale,
                ),
                constraints: BoxConstraints.tightFor(
                  width: 48 * scale,
                  height: 48 * scale,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 100 * scale),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 164 * scale,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF211431),
                        Color(0xFF100D1C),
                        Color(0xFF080914),
                      ],
                      stops: [0, .48, 1],
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 12 * scale),
                      Container(
                        width: 96.67 * scale,
                        height: 96.67 * scale,
                        child: ClipOval(
                          child: Transform.translate(
                            offset: Offset(0, -11.67 * scale),
                            child: SizedBox(
                              width: 96.67 * scale,
                              height: 145 * scale,
                              child: Image.network(
                                'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=256&auto=format&fit=crop',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF383145),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                    size: 44 * scale,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        'Sam Rivera',
                        style: TextStyle(
                          color: const Color(0xFFF5F2FF),
                          fontSize: 24 * scale,
                          height: 32 / 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.45,
                        ),
                      ),
                      Text(
                        '@samrivera',
                        style: TextStyle(
                          color: const Color(0xFFAAA6C2),
                          fontSize: 12 * scale,
                          height: 16 / 12,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                  child: SizedBox(
                    height: 84 * scale,
                    child: Row(
                      children: [
                        _ProfileStat(
                          iconAsset: 'assets/images/profile_created.png',
                          label: 'Created',
                          value: '0',
                          scale: scale,
                        ),
                        _ProfileStat(
                          iconAsset: 'assets/images/profile_received.png',
                          label: 'Received',
                          value: '3',
                          scale: scale,
                        ),
                        _ProfileStat(
                          iconAsset: 'assets/images/profile_replies.png',
                          label: 'Replies',
                          value: '0',
                          scale: scale,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                  child: Row(
                    children: [
                      _ProfileTab(
                        title: 'Created',
                        selected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                        scale: scale,
                      ),
                      _ProfileTab(
                        title: 'Received',
                        selected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                        scale: scale,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16 * scale,
                    24 * scale,
                    16 * scale,
                    24 * scale,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedTab == 0
                            ? "You haven't sent a\nmoment yet"
                            : "You haven't received a\nmoment yet",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFF4F2FF),
                          fontSize: 24 * scale,
                          height: 32 / 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 16 * scale),
                      Text(
                        _selectedTab == 0
                            ? 'Moments you create appear here.'
                            : 'Moments sent to you appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFAAA6C2),
                          fontSize: 14 * scale,
                          height: 20 / 14,
                        ),
                      ),
                      SizedBox(height: 16 * scale),
                      SizedBox(
                        width: 181 * scale,
                        height: 46 * scale,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9044FB), Color(0xFF4BBBEA)],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x558D42FF),
                                blurRadius: 20,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: widget.onCreate,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              'Create a moment',
                              style: TextStyle(fontSize: 14 * scale),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.iconAsset,
    required this.label,
    required this.value,
    required this.scale,
  });

  final String iconAsset;
  final String label;
  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          iconAsset,
          width: 24 * scale,
          height: 24 * scale,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 4 * scale),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFFAAA6C2),
            fontSize: 12 * scale,
            height: 16 / 12,
          ),
        ),
        SizedBox(height: 2 * scale),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFFF4F2FF),
            fontSize: 24 * scale,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.scale,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48 * scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFFA33EFF) : Colors.transparent,
              width: 2.5 * scale,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? const Color(0xFFC9C5D8) : const Color(0xFF777487),
            fontSize: 10 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}
