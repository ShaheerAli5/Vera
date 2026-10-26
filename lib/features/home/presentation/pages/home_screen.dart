import 'package:flutter/material.dart';

import '../../../../shared/widgets/vera_logo.dart';
import '../../domain/entities/moment.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/moment_card.dart';
import 'create_moment_screen.dart';
import 'locked_moment_screen.dart';
import 'unlocked_moment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialNavIndex = 0,
    this.initialMessageTabIndex = 0,
  });

  final int initialTabIndex;
  final int initialNavIndex;
  final int initialMessageTabIndex;

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
  static final List<Moment> sentMoments = [];
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedTabIndex;
  int _selectedNavIndex = 0;
  int _selectedMessageTab = 0;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _selectedNavIndex = widget.initialNavIndex;
    _selectedMessageTab = widget.initialMessageTabIndex;
  }

  List<Moment> get _currentMoments {
    if (_selectedNavIndex == 1) {
      final query = _searchQuery.trim().toLowerCase();
      return HomeScreen.discoverMoments.where((moment) {
        final matchesQuery = query.isEmpty ||
            '${moment.userName} ${moment.unlockCondition}'
                .toLowerCase()
                .contains(query);
        final matchesCategory = _selectedCategory == 'All' ||
            (_selectedCategory == 'Travel' &&
                moment.unlockCondition.toLowerCase().contains('tokyo')) ||
            (_selectedCategory == 'Nature' &&
                moment.unlockCondition.toLowerCase().contains('nature')) ||
            (_selectedCategory == 'Love' &&
                moment.userName.toLowerCase().contains('love'));
        return matchesQuery && matchesCategory;
      }).toList();
    }
    if (_selectedNavIndex == 2) {
      if (_selectedMessageTab == 0) return const [];
      return HomeScreen.sentMoments;
    }
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
    final scale = (screen.width / 393).clamp(.82, 1.12);
    final currentList = _currentMoments;

    return Scaffold(
      backgroundColor: const Color(0xFF080914),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                if (_selectedNavIndex == 1)
                  _DiscoverHeader(
                    scale: scale,
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) =>
                        setState(() => _selectedCategory = category),
                    onSearchChanged: (query) =>
                        setState(() => _searchQuery = query),
                  )
                else if (_selectedNavIndex == 2)
                  _MessagesHeader(
                    scale: scale,
                    selectedTab: _selectedMessageTab,
                    onTabSelected: (tab) =>
                        setState(() => _selectedMessageTab = tab),
                  )
                else ...[
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

                ],

                if (_selectedNavIndex == 0)
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
                              onTap: () =>
                                  setState(() => _selectedTabIndex = 0),
                              scale: scale,
                            ),
                            _TabItem(
                              title: 'Discover',
                              isSelected: _selectedTabIndex == 1,
                              onTap: () =>
                                  setState(() => _selectedTabIndex = 1),
                              scale: scale,
                            ),
                            _TabItem(
                              title: 'Your Moments',
                              isSelected: _selectedTabIndex == 2,
                              onTap: () =>
                                  setState(() => _selectedTabIndex = 2),
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
                  child: _selectedNavIndex == 1 && currentList.isEmpty
                      ? _NoDiscoverMatches(scale: scale)
                      : _selectedNavIndex == 2 &&
                              _selectedMessageTab == 0 &&
                              currentList.isEmpty
                          ? _NoIncomingMessages(scale: scale)
                      : _selectedNavIndex == 2 &&
                              _selectedMessageTab == 1 &&
                              currentList.isEmpty
                          ? _NoSentMoments(
                              scale: scale,
                              onCreateMomentTap: _navigateToCreateMoment,
                            )
                      : currentList.isEmpty
                          ? _EmptyMomentsState(
                              scale: scale,
                              onCreateMomentTap: _navigateToCreateMoment,
                            )
                      : ListView.builder(
                          key: ValueKey<int>(_selectedTabIndex),
                          padding: EdgeInsets.fromLTRB(
                            (_selectedNavIndex == 0 ? 16 : 24) * scale,
                            (_selectedNavIndex == 2 ? 16 : 8) * scale,
                            (_selectedNavIndex == 0 ? 16 : 24) * scale,
                            90 * scale,
                          ),
                          itemCount: currentList.length,
                          itemBuilder: (context, index) {
                            return MomentCard(
                              moment: currentList[index],
                              scale: scale,
                              onTap: () {
                                final moment = currentList[index];
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => moment.isReadyToOpen
                                        ? UnlockedMomentScreen(moment: moment)
                                        : LockedMomentScreen(moment: moment),
                                  ),
                                );
                              },
                              showDiscoverActions:
                                  _selectedNavIndex == 1 ||
                                  _selectedNavIndex == 2,
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
                onTap: (index) => setState(() {
                  _selectedNavIndex = index;
                  if (index == 0) _selectedTabIndex = 0;
                }),
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

class _NoDiscoverMatches extends StatelessWidget {
  const _NoDiscoverMatches({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        // Header content ends around y=272 in the reference; center the copy
        // in the remaining viewport above the bottom navigation.
        padding: EdgeInsets.only(top: 158 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No moments match',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFF7F5FF),
                fontSize: 20 * scale,
                fontWeight: FontWeight.w600,
                letterSpacing: -.2,
                height: 1.25,
              ),
            ),
            SizedBox(height: 14 * scale),
            Text(
              'Try another topic or search.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFA2A5C2),
                fontSize: 14 * scale,
                fontWeight: FontWeight.w400,
                height: 1.4,
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

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader({
    required this.scale,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final double scale;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24 * scale,
        16 * scale,
        24 * scale,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Messages',
            style: TextStyle(
              color: const Color(0xFFF7F5FF),
              fontSize: 28 * scale,
              fontWeight: FontWeight.w600,
              height: 36 / 28,
              letterSpacing: -.3,
            ),
          ),
          SizedBox(height: 16 * scale),
          Row(
            children: [
              for (var index = 0; index < 2; index++) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTabSelected(index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 49 * scale,
                          child: Center(
                            child: Text(
                              index == 0 ? 'Incoming' : 'Sent',
                              style: TextStyle(
                                color: selectedTab == index
                                    ? const Color(0xFFE9E5F4)
                                    : const Color(0xFF9295B3),
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 2 * scale,
                          decoration: BoxDecoration(
                            color: selectedTab == index
                                ? const Color(0xFFC057FF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(scale),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (index == 0) SizedBox(width: 8 * scale),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NoIncomingMessages extends StatelessWidget {
  const _NoIncomingMessages({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 214 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nothing waiting for you',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFF7F5FF),
                fontSize: 20 * scale,
                fontWeight: FontWeight.w600,
                height: 1.25,
                letterSpacing: -.2,
              ),
            ),
            SizedBox(height: 14 * scale),
            Text(
              'Invitations from friends appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFA2A5C2),
                fontSize: 14 * scale,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSentMoments extends StatelessWidget {
  const _NoSentMoments({
    required this.scale,
    required this.onCreateMomentTap,
  });

  final double scale;
  final VoidCallback onCreateMomentTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24 * scale, 170 * scale, 24 * scale, 16 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 250 * scale,
              height: 64 * scale,
              child: Text(
                "You haven't sent a moment yet",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFF7F5FF),
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w500,
                  height: 32 / 24,
                ),
              ),
            ),
            SizedBox(height: 16 * scale),
            SizedBox(
              width: 280 * scale,
              height: 24 * scale,
              child: Text(
                'Moments you create appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFA2A5C2),
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w400,
                  height: 24 / 16,
                ),
              ),
            ),
            SizedBox(height: 16 * scale),
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
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: onCreateMomentTap,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
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
    );
  }
}

class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader({
    required this.scale,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onSearchChanged,
  });

  final double scale;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onSearchChanged;

  static const _categories = <(String, IconData?)>[
    ('All', null),
    ('Travel', Icons.airplanemode_active_outlined),
    ('Nature', Icons.eco_outlined),
    ('Love', Icons.favorite_border_rounded),
    ('Food', Icons.restaurant_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20 * scale, 16 * scale, 0, 8 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 20 * scale),
            child: Text(
              'Discover',
              style: TextStyle(
                color: const Color(0xFFF7F5FF),
                fontSize: 24 * scale,
                fontWeight: FontWeight.w700,
                letterSpacing: -.4,
              ),
            ),
          ),
          SizedBox(height: 14 * scale),
          Padding(
            padding: EdgeInsets.only(right: 20 * scale),
            child: SizedBox(
              height: 46 * scale,
              child: TextField(
                onChanged: onSearchChanged,
                style: TextStyle(color: Colors.white, fontSize: 13 * scale),
                cursorColor: const Color(0xFFC057FF),
                decoration: InputDecoration(
                  hintText: 'Search people, places or topics...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF9295B3),
                    fontSize: 12.5 * scale,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: const Color(0xFF9DA2C2), size: 21 * scale),
                  filled: true,
                  fillColor: const Color(0xFF0D0E1C),
                  contentPadding: EdgeInsets.symmetric(vertical: 12 * scale),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14 * scale),
                    borderSide: const BorderSide(color: Color(0xFF454657)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14 * scale),
                    borderSide: const BorderSide(color: Color(0xFF9B4DFF)),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16 * scale),
          SizedBox(
            height: 42 * scale,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => SizedBox(width: 8 * scale),
              itemBuilder: (context, index) {
                final (label, icon) = _categories[index];
                final selected = selectedCategory == label;
                return Material(
                  color: selected
                      ? const Color(0xFF39205E)
                      : const Color(0xFF191A28),
                  borderRadius: BorderRadius.circular(24 * scale),
                  child: InkWell(
                    onTap: () => onCategorySelected(label),
                    borderRadius: BorderRadius.circular(24 * scale),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15 * scale),
                      child: Row(
                        children: [
                          if (icon != null) ...[
                            Icon(icon,
                                size: 15 * scale,
                                color: const Color(0xFFB0B2CC)),
                            SizedBox(width: 5 * scale),
                          ],
                          Text(label,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFFB0B2CC),
                                fontSize: 12.5 * scale,
                                fontWeight: FontWeight.w500,
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
