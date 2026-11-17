import 'package:flutter/material.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/server_time_manager.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../../../shared/widgets/vera_logo.dart';
import '../../../admin/presentation/pages/admin_main_screen.dart';
import '../../../splash/presentation/pages/splash_screen.dart';
import '../../data/datasources/moments_remote_data_source.dart';
import '../../data/models/moment_model.dart';
import '../../data/models/moment_thread_model.dart';
import '../../data/repositories/moments_repository_impl.dart';
import '../../domain/entities/moment.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/moment_card.dart';
import 'create_moment_screen.dart';
import 'locked_moment_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
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

  static const List<Moment> forYouMoments = [];
  static const List<Moment> discoverMoments = [];
  static const List<Moment> yourMoments = [];
  static final List<Moment> sentMoments = [];
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedTabIndex;
  int _selectedNavIndex = 0;
  int _selectedMessageTab = 0;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  bool _isLoadingMoments = false;
  String? _momentsError;
  List<Moment> _fetchedForYouMoments = [];
  List<Moment> _fetchedDiscoverMoments = [];
  List<Moment> _fetchedYourMoments = [];
  List<Moment> _fetchedInboxMoments = [];
  List<MomentThreadModel> _incomingThreads = [];
  List<MomentThreadModel> _sentThreads = [];

  List<MomentThreadModel> get incomingThreads => _incomingThreads;
  List<MomentThreadModel> get sentThreads => _sentThreads;

  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _selectedNavIndex = widget.initialNavIndex;
    _selectedMessageTab = widget.initialMessageTabIndex;
    ServerTimeManager.instance.ticker.addListener(_onTick);
    ServerTimeManager.instance.addResumedListener(_onResumed);
  }

  @override
  void dispose() {
    ServerTimeManager.instance.ticker.removeListener(_onTick);
    ServerTimeManager.instance.removeResumedListener(_onResumed);
    super.dispose();
  }

  void _onResumed() {
    if (!mounted) return;
    _fetchMoments();
  }

  void _onTick() {
    if (!mounted) return;
    final now = ServerTimeManager.instance.now;
    bool needsUpdate = false;

    List<Moment> checkAndUpdate(List<Moment> list) {
      return list.map((m) {
        if (!m.isReadyToOpen && m.status == 'PUBLISHED' && m.unlockAt != null) {
          if (!now.isBefore(m.unlockAt!)) {
            needsUpdate = true;
            return m.copyWith(isReadyToOpen: true);
          }
        }
        return m;
      }).toList();
    }

    final newForYou = checkAndUpdate(_fetchedForYouMoments);
    final newDiscover = checkAndUpdate(_fetchedDiscoverMoments);
    final newYour = checkAndUpdate(_fetchedYourMoments);
    final newInbox = checkAndUpdate(_fetchedInboxMoments);

    if (needsUpdate) {
      setState(() {
        _fetchedForYouMoments = newForYou;
        _fetchedDiscoverMoments = newDiscover;
        _fetchedYourMoments = newYour;
        _fetchedInboxMoments = newInbox;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _validateRoleGuard();
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      _fetchMoments();
    }
  }

  void _validateRoleGuard() {
    final client = ApiClientScope.of(context);
    final parsedRole = UserRole.parse(client.userRole);
    if (parsedRole == UserRole.owner) {
      // An owner/admin must never access the User Dashboard as an authenticated user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const AdminMainScreen()),
          (route) => false,
        );
      });
    } else if (parsedRole != UserRole.user) {
      // Invalid or unauthenticated session
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        client.clearTokens();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const SplashScreen()),
          (route) => false,
        );
        VeraPopup.show(
          context,
          title: 'Access Denied',
          message: 'Invalid role session. Please sign in again.',
          icon: Icons.error_outline_rounded,
          accent: VeraTheme.warning,
        );
      });
    }
  }

  Future<void> _fetchMoments({int page = 1, int limit = 20}) async {
    setState(() {
      _isLoadingMoments = true;
      _momentsError = null;
    });

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));

      final results = await Future.wait([
        repo.getHomeFeed(
          tab: 'FOR_YOU',
          page: page,
          limit: limit,
        ).catchError((_) => repo.getMoments(page: page, limit: limit)),
        repo.getDiscoverMoments(
          page: page,
          limit: limit,
          search: _searchQuery,
          category: _selectedCategory,
        ).catchError((_) => repo.getHomeFeed(
          tab: 'DISCOVER',
          page: page,
          limit: limit,
          search: _searchQuery,
          category: _selectedCategory,
        ).catchError((_) => repo.getMoments(page: page, limit: limit))),
        repo.getHomeFeed(
          tab: 'YOUR_MOMENTS',
          page: page,
          limit: limit,
        ).catchError((_) => repo.getMoments(page: page, limit: limit)),
        repo.getInboxMoments(page: page, limit: limit),
        repo.getChatThreads(box: 'INCOMING', limit: limit)
            .catchError((_) => const ChatThreadsResponse(items: [])),
        repo.getChatThreads(box: 'SENT', limit: limit)
            .catchError((_) => const ChatThreadsResponse(items: [])),
      ]);

      final forYouResponse = results[0] as MomentsListResponse;
      final discoverResponse = results[1] as MomentsListResponse;
      final yourMomentsResponse = results[2] as MomentsListResponse;
      final inboxMomentsResponse = results[3] as MomentsListResponse;
      final incomingThreadsResponse = results[4] as ChatThreadsResponse;
      final sentThreadsResponse = results[5] as ChatThreadsResponse;

      final mappedForYou = forYouResponse.moments.map((m) => m.toEntity()).toList();
      final mappedDiscover = discoverResponse.moments.map((m) => m.toEntity()).toList();
      final mappedYour = yourMomentsResponse.moments.map((m) => m.toEntity()).toList();
      final mappedInbox = inboxMomentsResponse.moments.map((m) => m.toEntity()).toList();

      if (!mounted) return;
      setState(() {
        _fetchedForYouMoments = mappedForYou;
        _fetchedDiscoverMoments = mappedDiscover;
        _fetchedYourMoments = mappedYour;
        _fetchedInboxMoments = mappedInbox;
        _incomingThreads = incomingThreadsResponse.items;
        _sentThreads = sentThreadsResponse.items;
        HomeScreen.sentMoments.clear();
        _isLoadingMoments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _momentsError = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
        _isLoadingMoments = false;
      });
    }
  }

  bool get _isDiscoverMode =>
      _selectedNavIndex == 1 || (_selectedNavIndex == 0 && _selectedTabIndex == 1);

  List<Moment> get _currentMoments {
    if (_isDiscoverMode) {
      if (_fetchedDiscoverMoments.isNotEmpty) {
        return _fetchedDiscoverMoments;
      }
      final query = _searchQuery.trim().toLowerCase();
      return _fetchedYourMoments.where((moment) {
        if (!moment.isPublicSentMoment || moment.status != 'PUBLISHED') {
          return false;
        }
        final matchesQuery = query.isEmpty ||
            '${moment.title ?? ''} ${moment.userName} ${moment.unlockCondition}'
                .toLowerCase()
                .contains(query);
        final matchesCategory = _selectedCategory == 'All' ||
            (moment.title != null && moment.title!.toLowerCase().contains(_selectedCategory.toLowerCase())) ||
            moment.unlockCondition.toLowerCase().contains(_selectedCategory.toLowerCase());
        return matchesQuery && matchesCategory;
      }).toList();
    }
    if (_selectedNavIndex == 2) {
      if (_selectedMessageTab == 0) return _fetchedInboxMoments;
      return _fetchedYourMoments;
    }
    switch (_selectedTabIndex) {
      case 0:
        return _fetchedForYouMoments.isNotEmpty
            ? _fetchedForYouMoments
            : _fetchedYourMoments;
      case 1:
        return _fetchedDiscoverMoments.isNotEmpty
            ? _fetchedDiscoverMoments
            : _fetchedYourMoments
                .where((m) => m.isPublicSentMoment && m.status == 'PUBLISHED')
                .toList();
      case 2:
      default:
        return _fetchedYourMoments;
    }
  }

  void _navigateToCreateMoment() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CreateMomentScreen(),
      ),
    );
    if (mounted) {
      _fetchMoments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width);
    final currentList = _currentMoments;

    return Scaffold(
      backgroundColor: const Color(0xFF080914),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                if (_selectedNavIndex == 3)
                  const SizedBox.shrink()
                else if (_isDiscoverMode)
                  _DiscoverHeader(
                    scale: scale,
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) {
                      setState(() => _selectedCategory = category);
                      _fetchMoments();
                    },
                    onSearchChanged: (query) {
                      setState(() => _searchQuery = query);
                      _fetchMoments();
                    },
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
                          ValueListenableBuilder<int>(
                            valueListenable: PushNotificationService.instance.unreadNotificationsCount,
                            builder: (context, unreadCount, _) {
                              return Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const NotificationsScreen(),
                                        ),
                                      );
                                      if (!mounted) return;
                                      final client = ApiClientScope.of(context);
                                      PushNotificationService.instance.refreshUnreadCount(client);
                                    },
                                    icon: Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 22 * scale,
                                    ),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 8 * scale,
                                      top: 8 * scale,
                                      child: Container(
                                        padding: EdgeInsets.all(3 * scale),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF9044FB),
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: 16 * scale,
                                          minHeight: 16 * scale,
                                        ),
                                        child: Center(
                                          child: Text(
                                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9 * scale,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
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
                  child: _selectedNavIndex == 3
                      ? ProfileScreen(
                          scale: scale,
                          onCreate: _navigateToCreateMoment,
                          moments: _fetchedYourMoments,
                        )
                      : _isLoadingMoments && currentList.isEmpty
                          ? Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2 * scale,
                                color: const Color(0xFF9044FB),
                              ),
                            )
                      : _selectedTabIndex == 2 &&
                              _momentsError != null &&
                              currentList.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.cloud_off_rounded,
                                      color: const Color(0xFF8A8EB3),
                                      size: 40 * scale,
                                    ),
                                    SizedBox(height: 12 * scale),
                                    Text(
                                      'Failed to load moments',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16 * scale,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 6 * scale),
                                    Text(
                                      _momentsError!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(0xFF8A8EB3),
                                        fontSize: 12 * scale,
                                      ),
                                    ),
                                    SizedBox(height: 16 * scale),
                                    TextButton(
                                      onPressed: () => _fetchMoments(),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF9044FB),
                                      ),
                                      child: Text(
                                        'Try again',
                                        style: TextStyle(fontSize: 13 * scale),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                      : _isDiscoverMode && currentList.isEmpty
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
                      : RefreshIndicator(
                          onRefresh: () => _fetchMoments(),
                          color: const Color(0xFF9044FB),
                          backgroundColor: const Color(0xFF17182D),
                          child: ListView.builder(
                            key: ValueKey<int>(_selectedTabIndex),
                            padding: EdgeInsets.fromLTRB(
                              (_isDiscoverMode ? 24 : 16) * scale,
                              (_selectedNavIndex == 2 ? 16 : 8) * scale,
                              (_isDiscoverMode ? 24 : 16) * scale,
                              90 * scale,
                            ),
                            itemCount: currentList.length,
                            itemBuilder: (context, index) {
                              return MomentCard(
                                moment: currentList[index],
                                scale: scale,
                                onTap: () async {
                                  final moment = currentList[index];
                                  final result = await Navigator.of(context).push<Moment>(
                                    MaterialPageRoute<Moment>(
                                      builder: (_) => moment.isReadyToOpen
                                          ? UnlockedMomentScreen(moment: moment)
                                          : LockedMomentScreen(moment: moment),
                                    ),
                                  );
                                  if (result != null && mounted) {
                                    setState(() {
                                      if (result.id.startsWith('__DELETED__:')) {
                                        final deletedId = result.id.replaceFirst('__DELETED__:', '');
                                        _fetchedForYouMoments.removeWhere((m) => m.id == deletedId);
                                        _fetchedDiscoverMoments.removeWhere((m) => m.id == deletedId);
                                        _fetchedYourMoments.removeWhere((m) => m.id == deletedId);
                                        _fetchedInboxMoments.removeWhere((m) => m.id == deletedId);
                                        HomeScreen.sentMoments.removeWhere((m) => m.id == deletedId);
                                      } else {
                                        for (final list in [
                                          _fetchedForYouMoments,
                                          _fetchedDiscoverMoments,
                                          _fetchedYourMoments,
                                          _fetchedInboxMoments,
                                        ]) {
                                          final i = list.indexWhere((m) => m.id == result.id);
                                          if (i >= 0) {
                                            list[i] = result;
                                          }
                                        }
                                      }
                                    });
                                  }
                                },
                                onMomentUpdated: (updated) {
                                  setState(() {
                                    if (updated.id.startsWith('__DELETED__:')) {
                                      final deletedId = updated.id.replaceFirst('__DELETED__:', '');
                                      _fetchedForYouMoments.removeWhere((m) => m.id == deletedId);
                                      _fetchedDiscoverMoments.removeWhere((m) => m.id == deletedId);
                                      _fetchedYourMoments.removeWhere((m) => m.id == deletedId);
                                      _fetchedInboxMoments.removeWhere((m) => m.id == deletedId);
                                      HomeScreen.sentMoments.removeWhere((m) => m.id == deletedId);
                                    } else {
                                      for (final list in [
                                        _fetchedForYouMoments,
                                        _fetchedDiscoverMoments,
                                        _fetchedYourMoments,
                                        _fetchedInboxMoments,
                                      ]) {
                                        final i = list.indexWhere((m) => m.id == updated.id);
                                        if (i >= 0) {
                                          list[i] = updated;
                                        }
                                      }
                                    }
                                  });
                                },
                                showDiscoverActions:
                                    _isDiscoverMode ||
                                    _selectedNavIndex == 2,
                              );
                            },
                          ),
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
          width: VeraResponsive.contentWidth(
            MediaQuery.sizeOf(context).width,
            horizontalPadding: 24 * scale,
          ),
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
              separatorBuilder: (_, _) => SizedBox(width: 8 * scale),
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
