import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import 'review_moment_screen.dart';

class ChooseConditionScreen extends StatefulWidget {
  const ChooseConditionScreen({
    super.key,
    this.isPrivate = true,
  });

  final bool isPrivate;

  @override
  State<ChooseConditionScreen> createState() => _ChooseConditionScreenState();
}

class _ChooseConditionScreenState extends State<ChooseConditionScreen> {
  bool _isDateTimeCondition = false; // Default to Location or Date & Time toggle
  final TextEditingController _dateController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
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
                              'Choose your condition',
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
                          '3 of 3',
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

            // 3-Step Progress Bar (Step 1, 2 and 3 Active)
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9044FB), Color(0xFF38BDF8)],
                        ),
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
                    // Section 1: Privacy Heading
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

                          // Option 1: Date & Time
                          GestureDetector(
                            onTap: () => setState(() => _isDateTimeCondition = true),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 345 * scale,
                              height: 68 * scale,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * scale,
                                vertical: 8 * scale,
                              ),
                              decoration: BoxDecoration(
                                gradient: _isDateTimeCondition
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
                                color: _isDateTimeCondition
                                    ? null
                                    : const Color(0xFF17182D),
                                borderRadius: BorderRadius.circular(16 * scale),
                                border: Border.all(
                                  color: _isDateTimeCondition
                                      ? const Color(0xFFC057FF)
                                      : const Color(0x1AFFFFFF),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_month_outlined,
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
                                          'Date & Time',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14 * scale,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 2 * scale),
                                        Text(
                                          'Your audience will be able access the moment on a specific date and time',
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

                          // Option 2: Location
                          GestureDetector(
                            onTap: () => setState(() => _isDateTimeCondition = false),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 345 * scale,
                              height: 68 * scale,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * scale,
                                vertical: 8 * scale,
                              ),
                              decoration: BoxDecoration(
                                gradient: !_isDateTimeCondition
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
                                color: !_isDateTimeCondition
                                    ? null
                                    : const Color(0xFF17182D),
                                borderRadius: BorderRadius.circular(16 * scale),
                                border: Border.all(
                                  color: !_isDateTimeCondition
                                      ? const Color(0xFFC057FF)
                                      : const Color(0x1AFFFFFF),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
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
                                          'Location',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14 * scale,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 2 * scale),
                                        Text(
                                          'Your audience will be able access the moment on a specific location',
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

                    // Section 2: When or Where should it unlock?
                    if (_isDateTimeCondition) ...[
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
                              'When should it unlock?',
                              style: TextStyle(
                                color: const Color(0xFFF7F5FF),
                                fontSize: 22 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16 * scale),
                            SizedBox(
                              width: 345 * scale,
                              height: 48 * scale,
                              child: TextField(
                                controller: _dateController,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14 * scale,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'mm/dd/yyyy  -  hh:mm',
                                  hintStyle: TextStyle(
                                    color: const Color(0xFF8A8EB3),
                                    fontSize: 14 * scale,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.calendar_today_outlined,
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
                                    borderRadius:
                                        BorderRadius.circular(12 * scale),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
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
                              'Where should it unlock?',
                              style: TextStyle(
                                color: const Color(0xFFF7F5FF),
                                fontSize: 22 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16 * scale),

                            // Location Preset Cards
                            _LocationPresetCard(
                              flag: '🇯🇵',
                              name: 'Tokyo Tower',
                              scale: scale,
                            ),
                            _LocationPresetCard(
                              flag: '🇫🇷',
                              name: 'Eiffel Tower',
                              scale: scale,
                            ),
                            _LocationPresetCard(
                              flag: '🇮🇸',
                              name: 'Reykjavik harbor',
                              scale: scale,
                            ),

                            SizedBox(height: 12 * scale),

                            // Unlock Radius Sub-heading & Dropdown
                            Text(
                              'Unlock radius',
                              style: TextStyle(
                                color: const Color(0xFFD4D4E8),
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 10 * scale),

                            Container(
                              width: 345 * scale,
                              height: 48 * scale,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16 * scale),
                              decoration: BoxDecoration(
                                color: const Color(0xFF17182D),
                                borderRadius:
                                    BorderRadius.circular(12 * scale),
                                border: Border.all(
                                  color: const Color(0x1AFFFFFF),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '200m',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14 * scale,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: const Color(0xFF8A8EB3),
                                    size: 22 * scale,
                                  ),
                                ],
                              ),
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
                          builder: (_) => ReviewMomentScreen(
                            title: widget.isPrivate
                                ? 'To my best friend'
                                : 'Midnight at the tower',
                            audience: widget.isPrivate ? 'Private' : 'Public',
                            audienceSubtitle: widget.isPrivate
                                ? 'Only select recipients'
                                : 'Discoverable by other users',
                            condition: _isDateTimeCondition
                                ? 'October 25, 2026 · 9:00 AM'
                                : "Opens when you're at Tokyo Tower",
                            conditionSubtitle: _isDateTimeCondition
                                ? 'Date & time (UTC+05:00)'
                                : 'Location condition (200m radius)',
                            isPrivate: widget.isPrivate,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'Create moment',
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

class _LocationPresetCard extends StatefulWidget {
  const _LocationPresetCard({
    required this.flag,
    required this.name,
    required this.scale,
  });

  final String flag;
  final String name;
  final double scale;

  @override
  State<_LocationPresetCard> createState() => _LocationPresetCardState();
}

class _LocationPresetCardState extends State<_LocationPresetCard> {
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSelected = !_isSelected;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 345 * widget.scale,
        height: 48 * widget.scale,
        margin: EdgeInsets.only(bottom: 12 * widget.scale),
        padding: EdgeInsets.symmetric(horizontal: 16 * widget.scale),
        decoration: BoxDecoration(
          color: const Color(0xFF17182D),
          borderRadius: BorderRadius.circular(12 * widget.scale),
          border: Border.all(
            color: _isSelected
                ? VeraTheme.purpleBright
                : const Color(0x1AFFFFFF),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              widget.flag,
              style: TextStyle(fontSize: 18 * widget.scale),
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
      ),
    );
  }
}
