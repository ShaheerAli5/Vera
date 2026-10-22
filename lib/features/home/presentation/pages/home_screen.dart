import 'package:flutter/material.dart';

import '../../../../shared/widgets/vera_logo.dart';
import '../../domain/entities/moment.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/moment_card.dart';
import 'create_moment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static const List<Moment> forYouMoments = [
    Moment(
      id: 'fy_1',
      userName: 'John Travolta',
      userAvatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
      timeAgo: '2h ago',
      backgroundImageUrl:
          'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?q=80&w=800',
      unlockCondition: "Opens when you're at Tokyo\nTower",
      unlockType: MomentUnlockType.location,
      isReadyToOpen: false,
    ),
    Moment(
      id: 'fy_2',
      userName: 'John Travolta',
      userAvatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
      timeAgo: '2h ago',
      backgroundImageUrl:
          'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?q=80&w=800',
      unlockCondition: "Opens Oct 1, 2026, 8:00 AM",
      unlockType: MomentUnlockType.time,
      isReadyToOpen: false,
    ),
    Moment(
      id: 'fy_3',
      userName: 'John Travolta',
      userAvatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
      timeAgo: '2h ago',
      backgroundImageUrl:
          'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?q=80&w=800',
      unlockCondition: "Opens when you're at Tokyo\nTower",
      unlockType: MomentUnlockType.location,
      isReadyToOpen: true,
    ),
  ];

  static const List<Moment> discoverMoments = [
    Moment(
      id: 'disc_1',
      userName: 'John Travolta',
      userAvatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
      timeAgo: '2h ago',
      backgroundImageUrl:
          'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?q=80&w=800',
      unlockCondition: "Opens when you're at Tokyo\nTower",
      unlockType: MomentUnlockType.location,
      isReadyToOpen: false,
    ),
    Moment(
      id: 'disc_2',
      userName: 'John Travolta',
      userAvatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
      timeAgo: '2h ago',
      backgroundImageUrl:
          'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?q=80&w=800',
      unlockCondition: "Opens when you're at Tokyo\nTower",
      unlockType: MomentUnlockType.location,
      isReadyToOpen: false,
    ),
    Moment(
      id: 'disc_3',
      userName: 'Sarah Connor',
      userAvatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200',
      timeAgo: '5h ago',
      backgroundImageUrl:
          'https://images.unsplash.com/photo-1514565131-fce0801e5785?q=80&w=800',
      unlockCondition: "Opens when you're at Shibuya\nCrossing",
      unlockType: MomentUnlockType.location,
      isReadyToOpen: false,
    ),
  ];

  static const List<Moment> yourMoments = [];
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedTabIndex;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
  }

  List<Moment> get _currentMoments {
    switch (_selectedTabIndex) {
      case 1:
        return HomeScreen.discoverMoments;
      case 2:
        return HomeScreen.yourMoments;
      case 0:
      default:
        return HomeScreen.forYouMoments;
    }
  }

  void _navigateToCreateMoment() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CreateMomentScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = (screen.width / 390).clamp(.82, 1.12);
    final currentList = _currentMoments;

    return Scaffold(
      backgroundColor: const Color(0xFF080914),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Top Bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20 * scale,
                    vertical: 8 * scale,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      VeraLogo(height: 18 * scale),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 22 * scale,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 22 * scale,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Sub Header Tabs
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _TabItem(
                            title: 'For You',
                            isSelected: _selectedTabIndex == 0,
                            onTap: () => setState(() => _selectedTabIndex = 0),
                            scale: scale,
                          ),
                          _TabItem(
                            title: 'Discover',
                            isSelected: _selectedTabIndex == 1,
                            onTap: () => setState(() => _selectedTabIndex = 1),
                            scale: scale,
                          ),
                          _TabItem(
                            title: 'Your Moments',
                            isSelected: _selectedTabIndex == 2,
                            onTap: () => setState(() => _selectedTabIndex = 2),
                            scale: scale,
                          ),
                        ],
                      ),
                      SizedBox(height: 12 * scale),
                    ],
                  ),
                ),

                // Feed / Moments List OR Empty State
                Expanded(
                  child: currentList.isEmpty
                      ? _EmptyMomentsState(
                          scale: scale,
                          onCreateMomentTap: _navigateToCreateMoment,
                        )
                      : ListView.builder(
                          key: ValueKey<int>(_selectedTabIndex),
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            8 * scale,
                            16 * scale,
                            90 * scale,
                          ),
                          itemCount: currentList.length,
                          itemBuilder: (context, index) {
                            return MomentCard(
                              moment: currentList[index],
                              scale: scale,
                            );
                          },
                        ),
                ),
              ],
            ),

            // Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VeraBottomNavBar(
                selectedIndex: _selectedNavIndex,
                onTap: (index) => setState(() => _selectedNavIndex = index),
                onCreateMomentTap: _navigateToCreateMoment,
                scale: scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMomentsState extends StatelessWidget {
  const _EmptyMomentsState({
    required this.scale,
    required this.onCreateMomentTap,
  });

  final double scale;
  final VoidCallback onCreateMomentTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24 * scale,
        16 * scale,
        24 * scale,
        16 * scale,
      ),
      child: Center(
        child: Container(
          width: 345 * scale,
          height: 264 * scale,
          padding: EdgeInsets.fromLTRB(
            16 * scale,
            48 * scale,
            16 * scale,
            48 * scale,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title Text (230px x 64px)
              SizedBox(
                width: 230 * scale,
                height: 64 * scale,
                child: Text(
                  "You haven't created a moment yet",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFF7F5FF),
                    fontSize: 24 * scale,
                    fontWeight: FontWeight.w500,
                    height: 32 / 24,
                    letterSpacing: 0,
                  ),
                ),
              ),
              SizedBox(height: 16 * scale),
              // Subtitle Text (240px x 24px)
              SizedBox(
                width: 240 * scale,
                height: 24 * scale,
                child: Text(
                  "Moments you create appear here.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFA2A5C2),
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w400,
                    height: 24 / 16,
                    letterSpacing: 0,
                  ),
                ),
              ),
              SizedBox(height: 16 * scale),
              // CTA Button (181px x 48px)
              SizedBox(
                width: 181 * scale,
                height: 48 * scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF9044FB),
                        Color(0xFFC057FF),
                        Color(0xFF9044FB),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x889044FB),
                        blurRadius: 28,
                        spreadRadius: 0,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: onCreateMomentTap,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Create a moment',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w600,
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
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.scale,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * scale,
              vertical: 6 * scale,
            ),
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFA6A6C1),
                fontSize: 13.5 * scale,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 2 * scale),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2.5 * scale,
            width: isSelected ? 64 * scale : 0,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9044FB), Color(0xFFC057FF)],
              ),
              borderRadius: BorderRadius.circular(2 * scale),
            ),
          ),
        ],
      ),
    );
  }
}
