import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
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
  final Map<String, String> _recipientNamesMap = {};
  final List<String> _inviteEmails = [];
  String _searchQuery = '';

  void _toggleRecipient(String id, String name) {
    setState(() {
      if (_selectedRecipientIds.contains(id)) {
        _selectedRecipientIds.remove(id);
        _recipientNamesMap.remove(id);
      } else {
        _selectedRecipientIds.add(id);
        _recipientNamesMap[id] = name;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    super.dispose();
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
                    // Back Button Frame
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

                    // Nav Item Frame
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 16 * scale),
                        child: SizedBox(
                          height: 24 * scale,
                          child: Center(
                            child: Text(
                              'Choose your audience',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFF7F5FF),
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w600,
                                height: 24 / 16,
                                letterSpacing: 0,
                              ),
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

            // Form Scrollable Body
            Expanded(
              child: SingleChildScrollView(
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
                          SizedBox(
                            width: contentWidth,
                            height: 32 * scale,
                            child: Text(
                              'Privacy',
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

                          // Option 1: Private
                          GestureDetector(
                            onTap: () => setState(() => _isPrivate = true),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: contentWidth,
                              constraints: BoxConstraints(minHeight: 68 * scale),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * scale,
                                vertical: 10 * scale,
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
                                    size: 20 * scale,
                                  ),
                                  SizedBox(width: 10 * scale),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Private',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14 * scale,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 2 * scale),
                                        Text(
                                          'Only you and the people you select can access the moment',
                                          style: TextStyle(
                                            color: const Color(0xFFD4D4E8),
                                            fontSize: 11.5 * scale,
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
                                vertical: 10 * scale,
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
                                    size: 20 * scale,
                                  ),
                                  SizedBox(width: 10 * scale),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Public',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14 * scale,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 2 * scale),
                                        Text(
                                          'Everyone can access the moment',
                                          style: TextStyle(
                                            color: const Color(0xFFD4D4E8),
                                            fontSize: 11.5 * scale,
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
                          12 * scale,
                          24 * scale,
                          24 * scale,
                        ),
                        child: Text(
                          'Public moments are reviewed by moderators before they appear in Discover. Your lock place is never shown publicly.',
                          style: TextStyle(
                            color: const Color(0xFFA6A6C1),
                            fontSize: 13.5 * scale,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Section 2: Who should get it?
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
                            SizedBox(
                              width: contentWidth,
                              height: 32 * scale,
                              child: Text(
                                'Who should get it?',
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

                            // Dynamic Search Field
                            SizedBox(
                              width: contentWidth,
                              height: 48 * scale,
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val.trim()),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14 * scale,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search people or enter User ID...',
                                  hintStyle: TextStyle(
                                    color: const Color(0xFF8A8EB3),
                                    fontSize: 14 * scale,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: const Color(0xFF8A8EB3),
                                    size: 20 * scale,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
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
                                    borderRadius:
                                        BorderRadius.circular(12 * scale),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 12 * scale),

                            // If search query is entered, offer to add as email or user ID
                            if (_searchQuery.isNotEmpty) ...[
                              if (_searchQuery.contains('@'))
                                _ContactCard(
                                  initials: '@',
                                  avatarColor: VeraTheme.purpleBright,
                                  name: 'Invite email: $_searchQuery',
                                  scale: scale,
                                  width: contentWidth,
                                  isSelected: _inviteEmails.contains(_searchQuery),
                                  onTap: () {
                                    if (!_inviteEmails.contains(_searchQuery)) {
                                      setState(() => _inviteEmails.add(_searchQuery));
                                    }
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              else
                                _ContactCard(
                                  initials: _searchQuery[0].toUpperCase(),
                                  avatarColor: VeraTheme.purple,
                                  name: 'Add recipient User ID: $_searchQuery',
                                  scale: scale,
                                  width: contentWidth,
                                  isSelected: _selectedRecipientIds.contains(_searchQuery),
                                  onTap: () {
                                    _toggleRecipient(_searchQuery, _searchQuery);
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ),
                              SizedBox(height: 10 * scale),
                            ],

                            // Selected recipient user IDs
                            if (_selectedRecipientIds.isNotEmpty) ...[
                              Text(
                                'Selected recipient IDs',
                                style: TextStyle(
                                  color: const Color(0xFFD4D4E8),
                                  fontSize: 13 * scale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                              Wrap(
                                spacing: 8 * scale,
                                runSpacing: 8 * scale,
                                children: _selectedRecipientIds.map((id) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12 * scale,
                                      vertical: 6 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF231742),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: VeraTheme.purpleBright.withAlpha(100),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person_outline_rounded,
                                          size: 14 * scale,
                                          color: VeraTheme.purpleBright,
                                        ),
                                        SizedBox(width: 4 * scale),
                                        Text(
                                          id,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12 * scale,
                                          ),
                                        ),
                                        SizedBox(width: 6 * scale),
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            _selectedRecipientIds.remove(id);
                                            _recipientNamesMap.remove(id);
                                          }),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 14 * scale,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 12 * scale),
                            ] else if (_inviteEmails.isEmpty && _searchQuery.isEmpty) ...[
                              Container(
                                width: contentWidth,
                                padding: EdgeInsets.all(14 * scale),
                                decoration: BoxDecoration(
                                  color: const Color(0x2217182D),
                                  borderRadius: BorderRadius.circular(12 * scale),
                                  border: Border.all(color: const Color(0x1AFFFFFF)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: const Color(0xFF8A8EB3),
                                      size: 18 * scale,
                                    ),
                                    SizedBox(width: 10 * scale),
                                    Expanded(
                                      child: Text(
                                        'Enter a recipient User ID or email address below to select who can unlock this moment.',
                                        style: TextStyle(
                                          color: const Color(0xFF8A8EB3),
                                          fontSize: 12 * scale,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12 * scale),
                            ],

                            SizedBox(height: 10 * scale),

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
                                              borderRadius:
                                                  BorderRadius.circular(12 * scale),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10 * scale),
                                    GestureDetector(
                                      onTap: () {
                                        final email =
                                            _emailController.text.trim();
                                        if (email.isNotEmpty &&
                                            email.contains('@')) {
                                          setState(() {
                                            if (!_inviteEmails
                                                .contains(email)) {
                                              _inviteEmails.add(email);
                                            }
                                            _emailController.clear();
                                          });
                                        }
                                      },
                                      child: Container(
                                        width: 68 * scale,
                                        height: 48 * scale,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF17182D),
                                          borderRadius:
                                              BorderRadius.circular(12 * scale),
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
                                  SizedBox(height: 10 * scale),
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
                                          color: const Color(0xFF231742),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: VeraTheme.purpleBright
                                                .withAlpha(100),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              email,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12 * scale,
                                              ),
                                            ),
                                            SizedBox(width: 6 * scale),
                                            GestureDetector(
                                              onTap: () => setState(() =>
                                                  _inviteEmails.remove(email)),
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
              child: SizedBox(
                width: contentWidth,
                height: 48 * scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: VeraTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: VeraTheme.glowPurple,
                        blurRadius: 22,
                        spreadRadius: 1,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () {
                      final typedEmail = _emailController.text.trim();
                      final emails = List<String>.from(_inviteEmails);
                      if (typedEmail.isNotEmpty &&
                          typedEmail.contains('@') &&
                          !emails.contains(typedEmail)) {
                        emails.add(typedEmail);
                      }

                      final typedSearch = _searchController.text.trim();
                      if (typedSearch.isNotEmpty) {
                        if (typedSearch.contains('@') && !emails.contains(typedSearch)) {
                          emails.add(typedSearch);
                        } else if (!typedSearch.contains('@') &&
                            !_selectedRecipientIds.contains(typedSearch)) {
                          _selectedRecipientIds.add(typedSearch);
                        }
                      }

                      // Move any email strings mistakenly added to _selectedRecipientIds into emails
                      for (final id in _selectedRecipientIds) {
                        if (id.contains('@') && !emails.contains(id)) {
                          emails.add(id);
                        }
                      }

                      final uuidRegex = RegExp(
                        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
                      );
                      final validRecipientIds = _selectedRecipientIds
                          .where((id) => uuidRegex.hasMatch(id))
                          .toList();

                      // If user entered a non-UUID and non-email ID
                      final invalidIds = _selectedRecipientIds
                          .where((id) => !id.contains('@') && !uuidRegex.hasMatch(id))
                          .toList();

                      if (_isPrivate && invalidIds.isNotEmpty && emails.isEmpty && validRecipientIds.isEmpty) {
                        VeraPopup.show(
                          context,
                          title: 'Invalid User ID',
                          message:
                              'User IDs must be a valid 36-character UUID, or use an email address to invite recipients.',
                          icon: Icons.error_outline_rounded,
                          accent: VeraTheme.warning,
                        );
                        return;
                      }

                      if (_isPrivate &&
                          validRecipientIds.isEmpty &&
                          emails.isEmpty) {
                        VeraPopup.show(
                          context,
                          title: 'Recipient required',
                          message:
                              'Please enter a recipient User ID or invite by email for your private moment.',
                          icon: Icons.person_add_outlined,
                          accent: VeraTheme.warning,
                        );
                        return;
                      }

                      final recipientNamesList = [
                        ...validRecipientIds,
                        ...emails,
                      ];

                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChooseConditionScreen(
                            title: widget.title,
                            category: widget.category,
                            teaser: widget.teaser,
                            message: widget.message,
                            isPrivate: _isPrivate,
                            recipientUserIds: validRecipientIds,
                            recipientNames: recipientNamesList.isNotEmpty
                                ? recipientNamesList.join(', ')
                                : null,
                            inviteEmails: emails,
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
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w600,
                      ),
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

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.initials,
    required this.avatarColor,
    required this.name,
    required this.scale,
    required this.width,
    required this.isSelected,
    required this.onTap,
  });

  final String initials;
  final Color avatarColor;
  final String name;
  final double scale;
  final double width;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        height: 52 * scale,
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF17182D),
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(
            color: isSelected
                ? VeraTheme.purpleBright
                : const Color(0x1AFFFFFF),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32 * scale,
              height: 32 * scale,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected
                  ? VeraTheme.purpleBright
                  : const Color(0xFF56587A),
              size: 20 * scale,
            ),
          ],
        ),
      ),
    );
  }
}
