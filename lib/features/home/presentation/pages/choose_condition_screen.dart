import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/server_time_manager.dart';
import '../../data/models/create_moment_params.dart';
import 'review_moment_screen.dart';

class ChooseConditionScreen extends StatefulWidget {
  const ChooseConditionScreen({
    super.key,
    required this.title,
    required this.category,
    required this.teaser,
    this.message,
    this.isPrivate = true,
    this.recipientUserIds = const [],
    this.recipientNames,
    this.inviteEmails = const [],
    this.mediaFile,
    this.mediaBytes,
    this.isVideo = false,
  });

  final String title;
  final String category;
  final String teaser;
  final String? message;
  final bool isPrivate;
  final List<String> recipientUserIds;
  final String? recipientNames;
  final List<String> inviteEmails;
  final XFile? mediaFile;
  final Uint8List? mediaBytes;
  final bool isVideo;

  @override
  State<ChooseConditionScreen> createState() => _ChooseConditionScreenState();
}

class _ChooseConditionScreenState extends State<ChooseConditionScreen> {
  bool _isDateTimeCondition = true;
  late DateTime _selectedDateTime;
  final TextEditingController _dateController = TextEditingController();
  late String _timezone;

  final List<Map<String, dynamic>> _locationPresets = const [
    {
      'flag': '🇯🇵',
      'name': 'Tokyo Tower',
      'latitude': 35.6586,
      'longitude': 139.7454,
      'radiusM': 200,
    },
    {
      'flag': '🇫🇷',
      'name': 'Eiffel Tower',
      'latitude': 48.8584,
      'longitude': 2.2945,
      'radiusM': 200,
    },
    {
      'flag': '🇮🇸',
      'name': 'Reykjavik harbor',
      'latitude': 64.1508,
      'longitude': -21.9406,
      'radiusM': 200,
    },
  ];
  String _selectedLocation = 'Tokyo Tower';
  final String _selectedRadius = '200m';

  Map<String, dynamic> get _activeLocationPreset =>
      _locationPresets.firstWhere(
        (loc) => loc['name'] == _selectedLocation,
        orElse: () => _locationPresets.first,
      );

  @override
  void initState() {
    super.initState();
    _isDateTimeCondition = true;
    _timezone = MomentUnlockRule.normalizeIanaTimezone(DateTime.now().timeZoneName);
    _selectedDateTime = DateTime.now()
        .add(const Duration(days: 1))
        .copyWith(hour: 9, minute: 0, second: 0, millisecond: 0);
    _updateDateController();
  }

  void _showTimezonePicker(double scale) {
    const timezones = [
      {'id': 'Asia/Karachi', 'label': 'Asia/Karachi (PKT)'},
      {'id': 'UTC', 'label': 'UTC (Coordinated Universal Time)'},
      {'id': 'Asia/Dubai', 'label': 'Asia/Dubai (GST)'},
      {'id': 'Asia/Kolkata', 'label': 'Asia/Kolkata (IST)'},
      {'id': 'Europe/London', 'label': 'Europe/London (GMT / BST)'},
      {'id': 'Europe/Paris', 'label': 'Europe/Paris (CET / CEST)'},
      {'id': 'America/New_York', 'label': 'America/New_York (Eastern Time)'},
      {'id': 'America/Chicago', 'label': 'America/Chicago (Central Time)'},
      {'id': 'America/Denver', 'label': 'America/Denver (Mountain Time)'},
      {'id': 'America/Los_Angeles', 'label': 'America/Los_Angeles (Pacific Time)'},
      {'id': 'Asia/Singapore', 'label': 'Asia/Singapore (SGT)'},
      {'id': 'Asia/Tokyo', 'label': 'Asia/Tokyo (JST)'},
      {'id': 'Australia/Sydney', 'label': 'Australia/Sydney (AEST)'},
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF16172E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24 * scale),
              topRight: Radius.circular(24 * scale),
            ),
            border: Border.all(
              color: const Color(0x333F4356),
              width: scale,
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24 * scale,
            24 * scale,
            24 * scale,
            36 * scale,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Timezone (IANA)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16 * scale),
              Expanded(
                child: ListView.separated(
                  itemCount: timezones.length,
                  separatorBuilder: (context, index) => Divider(
                    color: const Color(0x1AFFFFFF),
                    height: 1 * scale,
                  ),
                  itemBuilder: (context, index) {
                    final tz = timezones[index];
                    final isSelected = _timezone.toLowerCase() == tz['id']!.toLowerCase();
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 4 * scale,
                        horizontal: 8 * scale,
                      ),
                      title: Text(
                        tz['label']!,
                        style: TextStyle(
                          color: isSelected ? VeraTheme.purpleBright : Colors.white,
                          fontSize: 14 * scale,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: VeraTheme.purpleBright,
                              size: 20 * scale,
                            )
                          : null,
                      onTap: () {
                        setState(() => _timezone = tz['id']!);
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateDateController() {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final m = monthNames[_selectedDateTime.month - 1];
    final d = _selectedDateTime.day;
    final y = _selectedDateTime.year;
    final hour = _selectedDateTime.hour > 12
        ? _selectedDateTime.hour - 12
        : (_selectedDateTime.hour == 0 ? 12 : _selectedDateTime.hour);
    final min = _selectedDateTime.minute.toString().padLeft(2, '0');
    final ampm = _selectedDateTime.hour >= 12 ? 'PM' : 'AM';
    _dateController.text = '$m $d, $y · $hour:$min $ampm';
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: VeraTheme.purple,
              onPrimary: Colors.white,
              surface: Color(0xFF17182D),
              onSurface: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _selectedDateTime.hour,
        minute: _selectedDateTime.minute,
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: VeraTheme.purple,
              onPrimary: Colors.white,
              surface: Color(0xFF17182D),
              onSurface: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _updateDateController();
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
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

                          // Option 1: Date & Time
                          GestureDetector(
                            onTap: () => setState(() => _isDateTimeCondition = true),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: contentWidth,
                              constraints: BoxConstraints(minHeight: 68 * scale),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * scale,
                                vertical: 10 * scale,
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
                                          'Your audience will be able to access the moment on a specific date and time',
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
                              width: contentWidth,
                              constraints: BoxConstraints(minHeight: 68 * scale),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * scale,
                                vertical: 10 * scale,
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
                                          'Your audience will be able to access the moment at a specific location',
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
                              width: contentWidth,
                              height: 48 * scale,
                              child: TextField(
                                controller: _dateController,
                                readOnly: true,
                                onTap: _pickDateTime,
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
                                  suffixIcon: GestureDetector(
                                    onTap: _pickDateTime,
                                    child: Icon(
                                      Icons.calendar_today_outlined,
                                      color: const Color(0xFF8A8EB3),
                                      size: 20 * scale,
                                    ),
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
                            SizedBox(height: 10 * scale),
                            GestureDetector(
                              onTap: () => _showTimezonePicker(scale),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14 * scale,
                                  vertical: 8 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x3317182D),
                                  borderRadius: BorderRadius.circular(10 * scale),
                                  border: Border.all(color: const Color(0x22FFFFFF)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.public_rounded,
                                      size: 16 * scale,
                                      color: VeraTheme.purpleBright,
                                    ),
                                    SizedBox(width: 8 * scale),
                                    Text(
                                      'Timezone: $_timezone',
                                      style: TextStyle(
                                        color: const Color(0xFFD4D4E8),
                                        fontSize: 12 * scale,
                                      ),
                                    ),
                                    SizedBox(width: 6 * scale),
                                    Icon(
                                      Icons.arrow_drop_down_rounded,
                                      size: 18 * scale,
                                      color: const Color(0xFF8A8EB3),
                                    ),
                                  ],
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

                            // Dynamic Location Preset Cards
                            ..._locationPresets.map((loc) {
                              final name = loc['name']!;
                              final flag = loc['flag']!;
                              return _LocationPresetCard(
                                flag: flag,
                                name: name,
                                scale: scale,
                                isSelected: _selectedLocation == name,
                                onTap: () =>
                                    setState(() => _selectedLocation = name),
                              );
                            }),

                            SizedBox(height: 12 * scale),

                            // Unlock Radius Sub-heading
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
                              width: contentWidth,
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
                                    _selectedRadius,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14 * scale,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Icon(
                                    Icons.location_pin,
                                    color: const Color(0xFF8A8EB3),
                                    size: 20 * scale,
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
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ReviewMomentScreen(
                            title: widget.title,
                            category: widget.category,
                            teaser: widget.teaser,
                            message: widget.message,
                            audience: widget.isPrivate ? 'Private' : 'Public',
                            audienceSubtitle: widget.isPrivate
                                ? 'Only select recipients'
                                : 'Discoverable by other users',
                            condition: _isDateTimeCondition
                                ? _dateController.text
                                : "Opens when you're at $_selectedLocation",
                            conditionSubtitle: _isDateTimeCondition
                                ? 'Date & time ($_timezone)'
                                : '$_selectedLocation ($_selectedRadius radius)',
                            isPrivate: widget.isPrivate,
                            recipientUserIds: widget.recipientUserIds,
                            recipientName: widget.recipientNames,
                            inviteEmails: widget.inviteEmails,
                            unlockRuleType:
                                _isDateTimeCondition ? 'DATE' : 'LOCATION',
                            unlockAt: ServerTimeManager.computeUtcIsoString(
                              year: _selectedDateTime.year,
                              month: _selectedDateTime.month,
                              day: _selectedDateTime.day,
                              hour: _selectedDateTime.hour,
                              minute: _selectedDateTime.minute,
                              timezone: _timezone,
                            ),
                            timezone: _timezone,
                            latitude: _isDateTimeCondition
                                ? null
                                : (_activeLocationPreset['latitude'] as num?)?.toDouble(),
                            longitude: _isDateTimeCondition
                                ? null
                                : (_activeLocationPreset['longitude'] as num?)?.toDouble(),
                            radiusM: _isDateTimeCondition
                                ? null
                                : (_activeLocationPreset['radiusM'] as num?)?.toInt(),
                            placeName: _isDateTimeCondition ? null : _selectedLocation,
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

class _LocationPresetCard extends StatelessWidget {
  const _LocationPresetCard({
    required this.flag,
    required this.name,
    required this.scale,
    required this.isSelected,
    required this.onTap,
  });

  final String flag;
  final String name;
  final double scale;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: VeraResponsive.contentWidth(
          MediaQuery.sizeOf(context).width,
          horizontalPadding: 24 * scale,
        ),
        height: 48 * scale,
        margin: EdgeInsets.only(bottom: 12 * scale),
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF17182D),
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(
            color: isSelected
                ? VeraTheme.purpleBright
                : const Color(0x1AFFFFFF),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: TextStyle(fontSize: 18 * scale),
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
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: VeraTheme.purpleBright,
                size: 20 * scale,
              ),
          ],
        ),
      ),
    );
  }
}
