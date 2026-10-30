import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import 'choose_condition_screen.dart';

class ChooseAudienceScreen extends StatefulWidget {
  const ChooseAudienceScreen({super.key});

  @override
  State<ChooseAudienceScreen> createState() => _ChooseAudienceScreenState();
}

class _ChooseAudienceScreenState extends State<ChooseAudienceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isPrivate = true;
  final Set<String> _selectedRecipients = {};

  void _toggleRecipient(String name) {
    setState(() {
      if (!_selectedRecipients.add(name)) _selectedRecipients.remove(name);
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
    final scale = (screen.width / 390).clamp(.82, 1.12);

    return Scaffold(
      backgroundColor: VeraTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (div.nav: 390 x 56)
            SizedBox(
              height: 56 * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                child: Row(
                  children: [
                    // Back Button Frame (Back: 48 x 48, radius 24)
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

                    // Nav Item Frame (h1: Fill 254 x 24 Hug)
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

                    // Step Meta (span.nav-meta: Fixed 64 x 22 Hug)
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

            // 3-Step Progress Bar (Step 1 and 2 Active)
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
                    // Section 1: Privacy (div.seg:margin - Padding Top 16, H 24, Bottom 16, Gap 16)
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
                          // Heading Text (345 x 32)
                          SizedBox(
                            width: 345 * scale,
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

                          // Privacy Option 1: Private (Frame 1618874370: Fill 345 x Hug 68, radius 16)
                          GestureDetector(
                            onTap: () => setState(() => _isPrivate = true),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 345 * scale,
                              height: 68 * scale,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * scale,
                                vertical: 8 * scale,
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

                          // Privacy Option 2: Public (Frame 1618874369: Fill 345 x Fixed 68, radius 16)
                          GestureDetector(
                            onTap: () => setState(() => _isPrivate = false),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 345 * scale,
                              height: 68 * scale,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * scale,
                                vertical: 8 * scale,
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

                    // Conditional Content: Moderation Notice for Public OR Recipient Selection for Private
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
                            // Heading Text (345 x 32)
                            SizedBox(
                              width: 345 * scale,
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

                            // Search Field (div.input: Fill 345 x Fixed 48, radius 12, fill #17182D)
                            SizedBox(
                              width: 345 * scale,
                              height: 48 * scale,
                              child: TextField(
                                controller: _searchController,
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
                                  filled: true,
                                  fillColor: const Color(0xFF17182D),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16 * scale,
                                    vertical: 12 * scale,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12 * scale),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 12 * scale),

                            // Person Card 1: Annas (Frame 1618874370: Fill 345 x Hug 48, radius 16)
                            _ContactCard(
                              initials: 'A',
                              avatarColor: const Color(0xFF3B82F6),
                              name: 'Annas',
                              scale: scale,
                              isSelected: _selectedRecipients.contains('Annas'),
                              onTap: () => _toggleRecipient('Annas'),
                            ),

                            SizedBox(height: 10 * scale),

                            // Person Card 2: Marcus (Frame 1618874370: Fill 345 x Hug 48, radius 16)
                            _ContactCard(
                              initials: 'M',
                              avatarColor: const Color(0xFF8B5CF6),
                              name: 'Marcus',
                              scale: scale,
                              isSelected: _selectedRecipients.contains('Marcus'),
                              onTap: () => _toggleRecipient('Marcus'),
                            ),

                            SizedBox(height: 20 * scale),

                            // Frame 2147224484: Fill 345 x Hug 78 (Invite by email)
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

                                // Invite Email Row
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
                                    Container(
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
                                  ],
                                ),
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

            // Bottom Navigation Action Container (nav bar: 393 x 88, radius bottom 44)
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
                width: 345 * scale,
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
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChooseConditionScreen(
                            isPrivate: _isPrivate,
                            recipientName: _selectedRecipients.isEmpty
                                ? null
                                : _selectedRecipients.join(', '),
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

class _ContactCard extends StatefulWidget {
  const _ContactCard({
    required this.initials,
    required this.avatarColor,
    required this.name,
    required this.scale,
    required this.isSelected,
    required this.onTap,
  });

  final String initials;
  final Color avatarColor;
  final String name;
  final double scale;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 345 * widget.scale,
      height: 48 * widget.scale,
      padding: EdgeInsets.symmetric(
        horizontal: 12 * widget.scale,
        vertical: 8 * widget.scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF17182D),
        borderRadius: BorderRadius.circular(16 * widget.scale),
          border: Border.all(
            color: widget.isSelected
              ? VeraTheme.purpleBright
              : const Color(0x1AFFFFFF),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32 * widget.scale,
                height: 32 * widget.scale,
                decoration: BoxDecoration(
                  color: widget.avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13 * widget.scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12 * widget.scale),
              Text(
                widget.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14 * widget.scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              widget.isSelected ? Icons.check_circle_rounded : Icons.add_rounded,
              color: widget.isSelected ? VeraTheme.purpleBright : const Color(0xFF8A8EB3),
              size: 20 * widget.scale,
            ),
          ),
        ],
      ),
    );
  }
}
