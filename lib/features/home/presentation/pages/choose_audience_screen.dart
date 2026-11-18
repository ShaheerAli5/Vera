import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/moments_remote_data_source.dart';
import '../../data/models/recipient_user_model.dart';
import '../../data/repositories/moments_repository_impl.dart';
import 'choose_condition_screen.dart';

class ChooseAudienceScreen extends StatefulWidget {
  const ChooseAudienceScreen({
    super.key,
    required this.title,
    required this.category,
    required this.teaser,
    this.message,
    this.mediaFile,
    this.mediaBytes,
    this.isVideo = false,
  });

  final String title;
  final String category;
  final String teaser;
  final String? message;
  final XFile? mediaFile;
  final Uint8List? mediaBytes;
  final bool isVideo;

  @override
  State<ChooseAudienceScreen> createState() => _ChooseAudienceScreenState();
}

class _ChooseAudienceScreenState extends State<ChooseAudienceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isPrivate = true;

  final Set<String> _selectedRecipientIds = {};
  final Map<String, RecipientUserModel> _selectedUsersMap = {};
  final List<String> _inviteEmails = [];

  List<RecipientUserModel> _searchResults = [];
  bool _isLoadingUsers = false;
  String? _searchError;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUsers('');
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoadingUsers = true;
      _searchError = null;
    });

    try {
      final client = ApiClientScope.of(context);
      final repo = MomentsRepositoryImpl(MomentsRemoteDataSource(client));
      final users = await repo.searchUsers(query);
      if (!mounted) return;
      setState(() {
        _searchResults = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingUsers = false;
        _searchError = e.toString();
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchUsers(value);
    });
  }

  void _toggleRecipient(RecipientUserModel user) {
    setState(() {
      if (_selectedRecipientIds.contains(user.id)) {
        _selectedRecipientIds.remove(user.id);
        _selectedUsersMap.remove(user.id);
      } else {
        _selectedRecipientIds.add(user.id);
        _selectedUsersMap[user.id] = user;
      }
    });
  }

  void _addEmailInvite() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    if (!email.contains('@') || !email.contains('.')) {
      VeraPopup.show(
        context,
        title: 'Invalid Email',
        message: 'Please enter a valid email address (e.g. name@example.com).',
        icon: Icons.error_outline_rounded,
        accent: VeraTheme.warning,
      );
      return;
    }

    final lower = email.toLowerCase();
    setState(() {
      if (!_inviteEmails.contains(lower)) {
        _inviteEmails.add(lower);
      }
      _emailController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scale = VeraResponsive.scale(screen.width, designWidth: 390);
    final contentWidth = VeraResponsive.contentWidth(screen.width, horizontalPadding: 24 * scale);

    return Scaffold(
      backgroundColor: VeraTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            SizedBox(
              height: 56 * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                child: Row(
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 48 * scale,
                        height: 48 * scale,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24 * scale),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18 * scale,
                          ),
                        ),
                      ),
                    ),

                    // Nav Title
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 16 * scale),
                        child: Center(
                          child: Text(
                            'Choose your audience',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFF7F5FF),
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Step Meta
                    SizedBox(
                      width: 64 * scale,
                      height: 22 * scale,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '2 of 3',
                          style: TextStyle(
                            color: VeraTheme.textSecondary,
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3-Step Progress Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 6 * scale),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3 * scale,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9044FB), Color(0xFF38BDF8)],
                        ),
                        borderRadius: BorderRadius.circular(2 * scale),
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Container(
                      height: 3 * scale,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9044FB), Color(0xFF38BDF8)],
                        ),
                        borderRadius: BorderRadius.circular(2 * scale),
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Container(
                      height: 3 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1F36),
                        borderRadius: BorderRadius.circular(2 * scale),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 24 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Privacy
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24 * scale,
                        16 * scale,
                        24 * scale,
                        16 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privacy',
                            style: TextStyle(
                              color: const Color(0xFFF7F5FF),
                              fontSize: 24 * scale,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 16 * scale),

                          // Option 1: Private
                          GestureDetector(
                            onTap: () => setState(() => _isPrivate = true),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: contentWidth,
                              constraints: BoxConstraints(minHeight: 68 * scale),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * scale,
                                vertical: 12 * scale,
                              ),
                              decoration: BoxDecoration(
                                gradient: _isPrivate
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF9044FB),
                                          Color(0xFFC057FF),
                                          Color(0xFF9044FB),
                                        ],
                                      )
                                    : null,
                                color: _isPrivate ? null : const Color(0xFF17182D),
                                borderRadius: BorderRadius.circular(16 * scale),
                                border: Border.all(
                                  color: _isPrivate
                                      ? const Color(0xFFC057FF)
                                      : const Color(0x1AFFFFFF),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    color: Colors.white,
                                    size: 22 * scale,
                                  ),
                                  SizedBox(width: 12 * scale),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Private',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15 * scale,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 2 * scale),
                                        Text(
                                          'Only you and the people you select can access the moment',
                                          style: TextStyle(
                                            color: const Color(0xFFD4D4E8),
                                            fontSize: 12 * scale,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 12 * scale),

                          // Option 2: Public
                          GestureDetector(
                            onTap: () => setState(() => _isPrivate = false),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: contentWidth,
                              constraints: BoxConstraints(minHeight: 68 * scale),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * scale,
                                vertical: 12 * scale,
                              ),
                              decoration: BoxDecoration(
                                gradient: !_isPrivate
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF9044FB),
                                          Color(0xFFC057FF),
                                          Color(0xFF9044FB),
                                        ],
                                      )
                                    : null,
                                color: !_isPrivate ? null : const Color(0xFF17182D),
                                borderRadius: BorderRadius.circular(16 * scale),
                                border: Border.all(
                                  color: !_isPrivate
                                      ? const Color(0xFFC057FF)
                                      : const Color(0x1AFFFFFF),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.language_rounded,
                                    color: Colors.white,
                                    size: 22 * scale,
                                  ),
                                  SizedBox(width: 12 * scale),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Public',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15 * scale,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 2 * scale),
                                        Text(
                                          'Everyone can access the moment',
                                          style: TextStyle(
                                            color: const Color(0xFFD4D4E8),
                                            fontSize: 12 * scale,
                                            height: 1.25,
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
                      ),
                    ),

                    if (!_isPrivate) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          24 * scale,
                          8 * scale,
                          24 * scale,
                          12 * scale,
                        ),
                        child: Text(
                          'Public moments appear in Discover once approved. You can also optionally tag friends below to notify them directly.',
                          style: TextStyle(
                            color: const Color(0xFFA6A6C1),
                            fontSize: 13.5 * scale,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],

                    // Section 2: Who should get it?
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24 * scale,
                        8 * scale,
                        24 * scale,
                        16 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPrivate ? 'Who should get it?' : 'Who should get it? (Optional)',
                            style: TextStyle(
                              color: const Color(0xFFF7F5FF),
                              fontSize: 24 * scale,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 16 * scale),

                          // Dynamic Search Field
                            SizedBox(
                              width: contentWidth,
                              height: 50 * scale,
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14 * scale,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search people...',
                                  hintStyle: TextStyle(
                                    color: const Color(0xFF8A8EB3),
                                    fontSize: 14 * scale,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: const Color(0xFF8A8EB3),
                                    size: 20 * scale,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            _searchController.clear();
                                            _fetchUsers('');
                                          },
                                          child: Icon(
                                            Icons.clear_rounded,
                                            color: const Color(0xFF8A8EB3),
                                            size: 18 * scale,
                                          ),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: const Color(0xFF17182D),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16 * scale,
                                    vertical: 12 * scale,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14 * scale),
                                    borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14 * scale),
                                    borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14 * scale),
                                    borderSide: const BorderSide(color: Color(0xFF9044FB), width: 1.5),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 16 * scale),

                            // Search Results / Suggested Registered Users
                            if (_isLoadingUsers)
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24 * scale),
                                  child: const CircularProgressIndicator(color: Color(0xFF9044FB)),
                                ),
                              )
                            else if (_searchResults.isEmpty)
                              Container(
                                width: contentWidth,
                                padding: EdgeInsets.all(16 * scale),
                                decoration: BoxDecoration(
                                  color: const Color(0x2217182D),
                                  borderRadius: BorderRadius.circular(14 * scale),
                                  border: Border.all(color: const Color(0x1AFFFFFF)),
                                ),
                                child: Center(
                                  child: Text(
                                    _searchController.text.trim().isEmpty
                                        ? 'No registered users available.'
                                        : 'No registered users found matching "${_searchController.text.trim()}".',
                                    style: TextStyle(
                                      color: const Color(0xFF8A8EB3),
                                      fontSize: 13 * scale,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final user = _searchResults[index];
                                  final isSelected = _selectedRecipientIds.contains(user.id);
                                  return _UserSearchResultCard(
                                    user: user,
                                    isSelected: isSelected,
                                    scale: scale,
                                    width: contentWidth,
                                    onTap: () => _toggleRecipient(user),
                                  );
                                },
                              ),

                            // Selected recipient chips
                            if (_selectedRecipientIds.isNotEmpty) ...[
                              SizedBox(height: 12 * scale),
                              Text(
                                'Selected people (${_selectedRecipientIds.length}):',
                                style: TextStyle(
                                  color: const Color(0xFFD4D4E8),
                                  fontSize: 13 * scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                              Wrap(
                                spacing: 8 * scale,
                                runSpacing: 8 * scale,
                                children: _selectedRecipientIds.map((id) {
                                  final user = _selectedUsersMap[id];
                                  final name = user?.displayName ?? id;
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12 * scale,
                                      vertical: 6 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF231742),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: const Color(0xFF9044FB).withValues(alpha: 0.6),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person_rounded,
                                          size: 14 * scale,
                                          color: const Color(0xFFC057FF),
                                        ),
                                        SizedBox(width: 6 * scale),
                                        Text(
                                          name,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12 * scale,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 6 * scale),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedRecipientIds.remove(id);
                                              _selectedUsersMap.remove(id);
                                            });
                                          },
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],

                            SizedBox(height: 20 * scale),

                            // Frame: Invite by email
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invite by email',
                                  style: TextStyle(
                                    color: const Color(0xFFD4D4E8),
                                    fontSize: 13 * scale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 10 * scale),

                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 48 * scale,
                                        child: TextField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          onSubmitted: (_) => _addEmailInvite(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.5 * scale,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'name@example.com',
                                            hintStyle: TextStyle(
                                              color: const Color(0xFF8A8EB3),
                                              fontSize: 13.5 * scale,
                                            ),
                                            filled: true,
                                            fillColor: const Color(0xFF17182D),
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16 * scale,
                                              vertical: 12 * scale,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12 * scale),
                                              borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12 * scale),
                                              borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12 * scale),
                                              borderSide: const BorderSide(color: Color(0xFF9044FB), width: 1.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10 * scale),
                                    GestureDetector(
                                      onTap: _addEmailInvite,
                                      child: Container(
                                        width: 72 * scale,
                                        height: 48 * scale,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF17182D),
                                          borderRadius: BorderRadius.circular(12 * scale),
                                          border: Border.all(color: const Color(0x1AFFFFFF)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Add',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.5 * scale,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                if (_inviteEmails.isNotEmpty) ...[
                                  SizedBox(height: 12 * scale),
                                  Wrap(
                                    spacing: 8 * scale,
                                    runSpacing: 8 * scale,
                                    children: _inviteEmails.map((email) {
                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12 * scale,
                                          vertical: 6 * scale,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A263D),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(
                                            color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.mail_outline_rounded,
                                              size: 14 * scale,
                                              color: const Color(0xFF38BDF8),
                                            ),
                                            SizedBox(width: 6 * scale),
                                            Text(
                                              email,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12 * scale,
                                              ),
                                            ),
                                            SizedBox(width: 6 * scale),
                                            GestureDetector(
                                              onTap: () => setState(() => _inviteEmails.remove(email)),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                size: 14,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Navigation Action Container
            Container(
              height: 88 * scale,
              decoration: const BoxDecoration(
                color: Color(0x59090A17),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(44),
                  bottomRight: Radius.circular(44),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24 * scale,
                16 * scale,
                24 * scale,
                24 * scale,
              ),
              child: Container(
                width: contentWidth,
                height: 48 * scale,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9044FB), Color(0xFF38BDF8)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TextButton(
                  onPressed: () {
                    if (_isPrivate &&
                        _selectedRecipientIds.isEmpty &&
                        _inviteEmails.isEmpty) {
                      VeraPopup.show(
                        context,
                        title: 'Recipient Required',
                        message:
                            'Please search and select at least one person or add an invite email for your private moment.',
                        icon: Icons.person_add_outlined,
                        accent: VeraTheme.warning,
                      );
                      return;
                    }

                    final recipientNamesList = [
                      ..._selectedRecipientIds.map((id) =>
                          _selectedUsersMap[id]?.displayName ?? id),
                      ..._inviteEmails,
                    ];

                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChooseConditionScreen(
                          title: widget.title,
                          category: widget.category,
                          teaser: widget.teaser,
                          message: widget.message,
                          isPrivate: _isPrivate,
                          recipientUserIds: _selectedRecipientIds.toList(),
                          recipientNames: recipientNamesList.isNotEmpty
                              ? recipientNamesList.join(', ')
                              : null,
                          inviteEmails: _inviteEmails,
                          mediaFile: widget.mediaFile,
                          mediaBytes: widget.mediaBytes,
                          isVideo: widget.isVideo,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
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

class _UserSearchResultCard extends StatelessWidget {
  const _UserSearchResultCard({
    required this.user,
    required this.isSelected,
    required this.onTap,
    required this.scale,
    required this.width,
  });

  final RecipientUserModel user;
  final bool isSelected;
  final VoidCallback onTap;
  final double scale;
  final double width;

  @override
  Widget build(BuildContext context) {
    final initials = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : 'U';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        height: 56 * scale,
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        margin: EdgeInsets.only(bottom: 10 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF17182D),
          borderRadius: BorderRadius.circular(14 * scale),
          border: Border.all(
            color: isSelected ? const Color(0xFF9044FB) : const Color(0x1AFFFFFF),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18 * scale,
              backgroundColor: const Color(0xFF2C1338),
              backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                  ? Text(
                      initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 14 * scale),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.username != null && user.username!.isNotEmpty)
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        color: const Color(0xFF8A8EB3),
                        fontSize: 12 * scale,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              width: 32 * scale,
              height: 32 * scale,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF9044FB)
                    : Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.add_rounded,
                color: Colors.white,
                size: 18 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
