import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/vera_popup.dart';
import '../../../../main.dart' show ApiClientScope;
import '../../data/datasources/moments_remote_data_source.dart';
import '../../data/models/create_moment_params.dart';
import '../../data/models/create_moment_result.dart';
import '../../data/models/moment_model.dart';
import '../../data/repositories/moments_repository_impl.dart';
import '../../domain/entities/moment.dart';
import 'home_screen.dart';
import 'moment_ready_screen.dart';

class _CreationResult {
  const _CreationResult({
    required this.result,
    this.uploadedMoment,
    this.publishedMoment,
  });

  final CreateMomentResult result;
  final MomentModel? uploadedMoment;
  final MomentModel? publishedMoment;
}

class ReviewMomentScreen extends StatefulWidget {
  const ReviewMomentScreen({
    super.key,
    required this.title,
    required this.category,
    required this.teaser,
    this.message,
    required this.audience,
    required this.audienceSubtitle,
    required this.condition,
    required this.conditionSubtitle,
    required this.isPrivate,
    this.recipientUserIds = const [],
    this.recipientName,
    this.inviteEmails = const [],
    required this.unlockRuleType,
    required this.unlockAt,
    required this.timezone,
    this.latitude,
    this.longitude,
    this.radiusM,
    this.placeName,
    this.expiresAt,
    this.mediaFile,
    this.mediaBytes,
    this.isVideo = false,
  });

  final String title;
  final String category;
  final String teaser;
  final String? message;
  final String audience;
  final String audienceSubtitle;
  final String condition;
  final String conditionSubtitle;
  final bool isPrivate;
  final List<String> recipientUserIds;
  final String? recipientName;
  final List<String> inviteEmails;
  final String unlockRuleType;
  final String unlockAt;
  final String timezone;
  final double? latitude;
  final double? longitude;
  final int? radiusM;
  final String? placeName;
  final String? expiresAt;
  final XFile? mediaFile;
  final Uint8List? mediaBytes;
  final bool isVideo;

  @override
  State<ReviewMomentScreen> createState() => _ReviewMomentScreenState();
}

class _ReviewMomentScreenState extends State<ReviewMomentScreen> {
  // Mutable state for all 3 cards
  late String _title;
  late String _category;
  late String _teaser;
  late String? _message;

  late bool _isPrivate;
  late String _audience;
  late String _audienceSubtitle;
  late List<String> _recipientUserIds;
  late String? _recipientName;
  late List<String> _inviteEmails;

  late String _condition;
  late String _conditionSubtitle;
  late String _unlockRuleType;
  late String _unlockAt;
  late String _timezone;
  late double? _latitude;
  late double? _longitude;
  late int? _radiusM;
  late String? _placeName;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _category = widget.category;
    _teaser = widget.teaser;
    _message = widget.message;

    _isPrivate = widget.isPrivate;
    _audience = widget.audience;
    _audienceSubtitle = widget.audienceSubtitle;
    _recipientUserIds = List<String>.from(widget.recipientUserIds);
    _recipientName = widget.recipientName;
    _inviteEmails = List<String>.from(widget.inviteEmails);

    _condition = widget.condition;
    _conditionSubtitle = widget.conditionSubtitle;
    _unlockRuleType = widget.unlockRuleType;
    _unlockAt = widget.unlockAt;
    _timezone = widget.timezone;
    _latitude = widget.latitude;
    _longitude = widget.longitude;
    _radiusM = widget.radiusM;
    _placeName = widget.placeName;
  }

  // --- Modal 1: Edit Content ---
  void _showEditContentModal(double scale) {
    final titleController = TextEditingController(text: _title);
    final teaserController = TextEditingController(text: _teaser);
    final messageController = TextEditingController(text: _message ?? '');
    String selectedCategory = _category;
    const categories = ['TRAVEL', 'NATURE', 'BIRTHDAY', 'LOVE', 'OTHER'];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24 * scale),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16172E),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24 * scale),
                      ),
                      border: Border.all(
                        color: const Color(0xFF373657),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            20 * scale,
                            18 * scale,
                            20 * scale,
                            12 * scale,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Edit content',
                                style: TextStyle(
                                  color: const Color(0xFFF7F5FF),
                                  fontSize: 18 * scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(sheetContext).pop(),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: 32 * scale,
                                  height: 32 * scale,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 16 * scale,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Color(0x1AFFFFFF), height: 1),

                        // Form Fields
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(20 * scale),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Title',
                                  style: TextStyle(
                                    color: const Color(0xFFD4D4E8),
                                    fontSize: 13 * scale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8 * scale),
                                TextField(
                                  controller: titleController,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14 * scale,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Moment title',
                                    hintStyle: TextStyle(
                                      color: const Color(0xFF8A8EB3),
                                      fontSize: 14 * scale,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF17182D),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14 * scale,
                                      vertical: 12 * scale,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12 * scale),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16 * scale),

                                Text(
                                  'Category',
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
                                  children: categories.map((cat) {
                                    final isSelected =
                                        selectedCategory.toUpperCase() == cat;
                                    return GestureDetector(
                                      onTap: () => setModalState(
                                          () => selectedCategory = cat),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14 * scale,
                                          vertical: 8 * scale,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? VeraTheme.buttonGradient
                                              : null,
                                          color: isSelected
                                              ? null
                                              : const Color(0xFF17182D),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.transparent
                                                : const Color(0x1AFFFFFF),
                                          ),
                                        ),
                                        child: Text(
                                          cat,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFFA6A6C1),
                                            fontSize: 12 * scale,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                SizedBox(height: 16 * scale),

                                Text(
                                  'Teaser',
                                  style: TextStyle(
                                    color: const Color(0xFFD4D4E8),
                                    fontSize: 13 * scale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8 * scale),
                                TextField(
                                  controller: teaserController,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14 * scale,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Short preview text shown before unlock',
                                    hintStyle: TextStyle(
                                      color: const Color(0xFF8A8EB3),
                                      fontSize: 14 * scale,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF17182D),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14 * scale,
                                      vertical: 12 * scale,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12 * scale),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16 * scale),

                                Text(
                                  'Hidden message (optional)',
                                  style: TextStyle(
                                    color: const Color(0xFFD4D4E8),
                                    fontSize: 13 * scale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8 * scale),
                                TextField(
                                  controller: messageController,
                                  maxLines: 3,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14 * scale,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Revealed only after unlocking...',
                                    hintStyle: TextStyle(
                                      color: const Color(0xFF8A8EB3),
                                      fontSize: 14 * scale,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF17182D),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14 * scale,
                                      vertical: 12 * scale,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12 * scale),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 24 * scale),

                                SizedBox(
                                  width: double.infinity,
                                  height: 48 * scale,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: VeraTheme.buttonGradient,
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: VeraTheme.glowPurple,
                                          blurRadius: 18,
                                          spreadRadius: 1,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        final newTitle =
                                            titleController.text.trim();
                                        final newTeaser =
                                            teaserController.text.trim();
                                        final newMsg =
                                            messageController.text.trim();
                                        if (newTitle.isEmpty) return;
                                        setState(() {
                                          _title = newTitle;
                                          _category = selectedCategory;
                                          _teaser = newTeaser.isNotEmpty
                                              ? newTeaser
                                              : _teaser;
                                          _message = newMsg.isNotEmpty
                                              ? newMsg
                                              : null;
                                        });
                                        Navigator.of(sheetContext).pop();
                                      },
                                      child: Text(
                                        'Save changes',
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Modal 2: Edit Audience ---
  void _showEditAudienceModal(double scale) {
    bool editIsPrivate = _isPrivate;
    final editRecipientIds = List<String>.from(_recipientUserIds);
    final editInviteEmails = List<String>.from(_inviteEmails);
    final emailController = TextEditingController();
    final userIdController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24 * scale),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16172E),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24 * scale),
                      ),
                      border: Border.all(
                        color: const Color(0xFF373657),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            20 * scale,
                            18 * scale,
                            20 * scale,
                            12 * scale,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Edit audience',
                                style: TextStyle(
                                  color: const Color(0xFFF7F5FF),
                                  fontSize: 18 * scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(sheetContext).pop(),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: 32 * scale,
                                  height: 32 * scale,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 16 * scale,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Color(0x1AFFFFFF), height: 1),

                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(20 * scale),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Audience type',
                                  style: TextStyle(
                                    color: const Color(0xFFD4D4E8),
                                    fontSize: 13 * scale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 12 * scale),

                                // Private Card
                                GestureDetector(
                                  onTap: () => setModalState(
                                      () => editIsPrivate = true),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: EdgeInsets.all(12 * scale),
                                    decoration: BoxDecoration(
                                      gradient: editIsPrivate
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF9044FB),
                                                Color(0xFFC057FF),
                                              ],
                                            )
                                          : null,
                                      color: editIsPrivate
                                          ? null
                                          : const Color(0xFF17182D),
                                      borderRadius:
                                          BorderRadius.circular(14 * scale),
                                      border: Border.all(
                                        color: editIsPrivate
                                            ? const Color(0xFFC057FF)
                                            : const Color(0x1AFFFFFF),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.lock_outline_rounded,
                                          color: Colors.white,
                                          size: 20 * scale,
                                        ),
                                        SizedBox(width: 10 * scale),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Private',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14 * scale,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                'Only you and select recipients can unlock',
                                                style: TextStyle(
                                                  color:
                                                      const Color(0xFFD4D4E8),
                                                  fontSize: 11.5 * scale,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10 * scale),

                                // Public Card
                                GestureDetector(
                                  onTap: () => setModalState(
                                      () => editIsPrivate = false),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: EdgeInsets.all(12 * scale),
                                    decoration: BoxDecoration(
                                      gradient: !editIsPrivate
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF9044FB),
                                                Color(0xFFC057FF),
                                              ],
                                            )
                                          : null,
                                      color: !editIsPrivate
                                          ? null
                                          : const Color(0xFF17182D),
                                      borderRadius:
                                          BorderRadius.circular(14 * scale),
                                      border: Border.all(
                                        color: !editIsPrivate
                                            ? const Color(0xFFC057FF)
                                            : const Color(0x1AFFFFFF),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.language_rounded,
                                          color: Colors.white,
                                          size: 20 * scale,
                                        ),
                                        SizedBox(width: 10 * scale),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Public',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14 * scale,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                'Discoverable by anyone once reviewed',
                                                style: TextStyle(
                                                  color:
                                                      const Color(0xFFD4D4E8),
                                                  fontSize: 11.5 * scale,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                if (editIsPrivate) ...[
                                  SizedBox(height: 18 * scale),
                                  Text(
                                    'Invite by email',
                                    style: TextStyle(
                                      color: const Color(0xFFD4D4E8),
                                      fontSize: 13 * scale,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8 * scale),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: emailController,
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
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 14 * scale,
                                              vertical: 10 * scale,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      12 * scale),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8 * scale),
                                      GestureDetector(
                                        onTap: () {
                                          final email =
                                              emailController.text.trim();
                                          if (email.isNotEmpty &&
                                              email.contains('@')) {
                                            if (!editInviteEmails
                                                .contains(email)) {
                                              setModalState(() =>
                                                  editInviteEmails.add(email));
                                            }
                                            emailController.clear();
                                          }
                                        },
                                        child: Container(
                                          height: 44 * scale,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16 * scale,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: VeraTheme.buttonGradient,
                                            borderRadius:
                                                BorderRadius.circular(12 * scale),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Add',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13 * scale,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (editInviteEmails.isNotEmpty) ...[
                                    SizedBox(height: 10 * scale),
                                    Wrap(
                                      spacing: 8 * scale,
                                      runSpacing: 8 * scale,
                                      children: editInviteEmails.map((email) {
                                        return Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10 * scale,
                                            vertical: 5 * scale,
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
                                              Icon(
                                                Icons.email_outlined,
                                                size: 13 * scale,
                                                color: VeraTheme.purpleBright,
                                              ),
                                              SizedBox(width: 4 * scale),
                                              Text(
                                                email,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11.5 * scale,
                                                ),
                                              ),
                                              SizedBox(width: 6 * scale),
                                              GestureDetector(
                                                onTap: () => setModalState(() =>
                                                    editInviteEmails
                                                        .remove(email)),
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
                                  ],
                                  SizedBox(height: 16 * scale),

                                  Text(
                                    'Recipient User ID (UUID)',
                                    style: TextStyle(
                                      color: const Color(0xFFD4D4E8),
                                      fontSize: 13 * scale,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8 * scale),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: userIdController,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.5 * scale,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter user UUID...',
                                            hintStyle: TextStyle(
                                              color: const Color(0xFF8A8EB3),
                                              fontSize: 13.5 * scale,
                                            ),
                                            filled: true,
                                            fillColor: const Color(0xFF17182D),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 14 * scale,
                                              vertical: 10 * scale,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      12 * scale),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8 * scale),
                                      GestureDetector(
                                        onTap: () {
                                          final uid =
                                              userIdController.text.trim();
                                          if (uid.isNotEmpty) {
                                            if (!editRecipientIds
                                                .contains(uid)) {
                                              setModalState(() =>
                                                  editRecipientIds.add(uid));
                                            }
                                            userIdController.clear();
                                          }
                                        },
                                        child: Container(
                                          height: 44 * scale,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16 * scale,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: VeraTheme.buttonGradient,
                                            borderRadius:
                                                BorderRadius.circular(12 * scale),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Add',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13 * scale,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (editRecipientIds.isNotEmpty) ...[
                                    SizedBox(height: 10 * scale),
                                    Wrap(
                                      spacing: 8 * scale,
                                      runSpacing: 8 * scale,
                                      children: editRecipientIds.map((id) {
                                        return Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10 * scale,
                                            vertical: 5 * scale,
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
                                              Icon(
                                                Icons.person_outline_rounded,
                                                size: 13 * scale,
                                                color: VeraTheme.purpleBright,
                                              ),
                                              SizedBox(width: 4 * scale),
                                              Text(
                                                id,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11.5 * scale,
                                                ),
                                              ),
                                              SizedBox(width: 6 * scale),
                                              GestureDetector(
                                                onTap: () => setModalState(() =>
                                                    editRecipientIds.remove(id)),
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
                                  ],
                                ],

                                SizedBox(height: 24 * scale),

                                SizedBox(
                                  width: double.infinity,
                                  height: 48 * scale,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: VeraTheme.buttonGradient,
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: VeraTheme.glowPurple,
                                          blurRadius: 18,
                                          spreadRadius: 1,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isPrivate = editIsPrivate;
                                          _recipientUserIds = editRecipientIds;
                                          _inviteEmails = editInviteEmails;
                                          if (_isPrivate) {
                                            _audience = 'Private';
                                            if (_inviteEmails.isNotEmpty) {
                                              _audienceSubtitle =
                                                  'To ${_inviteEmails.first}${_inviteEmails.length > 1 ? " +${_inviteEmails.length - 1} more" : ""}';
                                            } else if (_recipientUserIds
                                                .isNotEmpty) {
                                              _audienceSubtitle =
                                                  'To ${_recipientUserIds.first}${_recipientUserIds.length > 1 ? " +${_recipientUserIds.length - 1} more" : ""}';
                                            } else {
                                              _audienceSubtitle =
                                                  'Only select recipients';
                                            }
                                          } else {
                                            _audience = 'Public';
                                            _audienceSubtitle =
                                                'Discoverable by other users';
                                          }
                                        });
                                        Navigator.of(sheetContext).pop();
                                      },
                                      child: Text(
                                        'Save changes',
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Modal 3: Edit Unlock Condition ---
  void _showEditConditionModal(double scale) {
    bool isDateType = _unlockRuleType == 'DATE';
    DateTime selectedDate = DateTime.tryParse(_unlockAt)?.toLocal() ??
        DateTime.now()
            .add(const Duration(days: 1))
            .copyWith(hour: 9, minute: 0, second: 0, millisecond: 0);
    String selectedTz = _timezone;
    String selectedLocation = _placeName ?? 'Tokyo Tower';

    const locationPresets = [
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

    String formatDateString(DateTime dt) {
      const monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      final m = monthNames[dt.month - 1];
      final d = dt.day;
      final y = dt.year;
      final hour =
          dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final min = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$m $d, $y · $hour:$min $ampm';
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24 * scale),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16172E),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24 * scale),
                      ),
                      border: Border.all(
                        color: const Color(0xFF373657),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            20 * scale,
                            18 * scale,
                            20 * scale,
                            12 * scale,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Edit unlock condition',
                                style: TextStyle(
                                  color: const Color(0xFFF7F5FF),
                                  fontSize: 18 * scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(sheetContext).pop(),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: 32 * scale,
                                  height: 32 * scale,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 16 * scale,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Color(0x1AFFFFFF), height: 1),

                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(20 * scale),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Condition type',
                                  style: TextStyle(
                                    color: const Color(0xFFD4D4E8),
                                    fontSize: 13 * scale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 12 * scale),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setModalState(
                                            () => isDateType = true),
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          padding: EdgeInsets.all(12 * scale),
                                          decoration: BoxDecoration(
                                            gradient: isDateType
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color(0xFF9044FB),
                                                      Color(0xFFC057FF),
                                                    ],
                                                  )
                                                : null,
                                            color: isDateType
                                                ? null
                                                : const Color(0xFF17182D),
                                            borderRadius:
                                                BorderRadius.circular(14 * scale),
                                            border: Border.all(
                                              color: isDateType
                                                  ? const Color(0xFFC057FF)
                                                  : const Color(0x1AFFFFFF),
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.calendar_month_outlined,
                                                color: Colors.white,
                                                size: 22 * scale,
                                              ),
                                              SizedBox(height: 6 * scale),
                                              Text(
                                                'Date & Time',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13 * scale,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12 * scale),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setModalState(
                                            () => isDateType = false),
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          padding: EdgeInsets.all(12 * scale),
                                          decoration: BoxDecoration(
                                            gradient: !isDateType
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color(0xFF9044FB),
                                                      Color(0xFFC057FF),
                                                    ],
                                                  )
                                                : null,
                                            color: !isDateType
                                                ? null
                                                : const Color(0xFF17182D),
                                            borderRadius:
                                                BorderRadius.circular(14 * scale),
                                            border: Border.all(
                                              color: !isDateType
                                                  ? const Color(0xFFC057FF)
                                                  : const Color(0x1AFFFFFF),
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                color: Colors.white,
                                                size: 22 * scale,
                                              ),
                                              SizedBox(height: 6 * scale),
                                              Text(
                                                'Location',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13 * scale,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 18 * scale),

                                if (isDateType) ...[
                                  Text(
                                    'Unlock date & time',
                                    style: TextStyle(
                                      color: const Color(0xFFD4D4E8),
                                      fontSize: 13 * scale,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8 * scale),
                                  GestureDetector(
                                    onTap: () async {
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now()
                                            .add(const Duration(days: 3650)),
                                        builder: (ctx, child) {
                                          return Theme(
                                            data: ThemeData.dark().copyWith(
                                              colorScheme:
                                                  const ColorScheme.dark(
                                                primary: VeraTheme.purple,
                                                onPrimary: Colors.white,
                                                surface: Color(0xFF17182D),
                                                onSurface: Colors.white,
                                              ),
                                            ),
                                            child: child ??
                                                const SizedBox.shrink(),
                                          );
                                        },
                                      );
                                      if (pickedDate == null || !sheetContext.mounted) return;
                                      final pickedTime = await showTimePicker(
                                        context: sheetContext,
                                        initialTime: TimeOfDay(
                                          hour: selectedDate.hour,
                                          minute: selectedDate.minute,
                                        ),
                                        builder: (ctx, child) {
                                          return Theme(
                                            data: ThemeData.dark().copyWith(
                                              colorScheme:
                                                  const ColorScheme.dark(
                                                primary: VeraTheme.purple,
                                                onPrimary: Colors.white,
                                                surface: Color(0xFF17182D),
                                                onSurface: Colors.white,
                                              ),
                                            ),
                                            child: child ??
                                                const SizedBox.shrink(),
                                          );
                                        },
                                      );
                                      if (pickedTime == null || !mounted) return;
                                      setModalState(() {
                                        selectedDate = DateTime(
                                          pickedDate.year,
                                          pickedDate.month,
                                          pickedDate.day,
                                          pickedTime.hour,
                                          pickedTime.minute,
                                        );
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14 * scale,
                                        vertical: 12 * scale,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF17182D),
                                        borderRadius:
                                            BorderRadius.circular(12 * scale),
                                        border: Border.all(
                                          color: const Color(0x1AFFFFFF),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            formatDateString(selectedDate),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14 * scale,
                                            ),
                                          ),
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            color: const Color(0xFF8A8EB3),
                                            size: 18 * scale,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 14 * scale),

                                  Text(
                                    'Timezone (IANA)',
                                    style: TextStyle(
                                      color: const Color(0xFFD4D4E8),
                                      fontSize: 13 * scale,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8 * scale),
                                  GestureDetector(
                                    onTap: () {
                                      _pickTimezone(scale, (newTz) {
                                        setModalState(() => selectedTz = newTz);
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14 * scale,
                                        vertical: 12 * scale,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF17182D),
                                        borderRadius:
                                            BorderRadius.circular(12 * scale),
                                        border: Border.all(
                                          color: const Color(0x1AFFFFFF),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.public_rounded,
                                                size: 16 * scale,
                                                color: VeraTheme.purpleBright,
                                              ),
                                              SizedBox(width: 8 * scale),
                                              Text(
                                                selectedTz,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13 * scale,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down_rounded,
                                            color: const Color(0xFF8A8EB3),
                                            size: 20 * scale,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'Choose location',
                                    style: TextStyle(
                                      color: const Color(0xFFD4D4E8),
                                      fontSize: 13 * scale,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 10 * scale),
                                  ...locationPresets.map((loc) {
                                    final name = loc['name'] as String;
                                    final flag = loc['flag'] as String;
                                    final isSelected =
                                        selectedLocation == name;
                                    return GestureDetector(
                                      onTap: () => setModalState(
                                          () => selectedLocation = name),
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        margin:
                                            EdgeInsets.only(bottom: 8 * scale),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14 * scale,
                                          vertical: 12 * scale,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF231742)
                                              : const Color(0xFF17182D),
                                          borderRadius:
                                              BorderRadius.circular(12 * scale),
                                          border: Border.all(
                                            color: isSelected
                                                ? VeraTheme.purpleBright
                                                : const Color(0x1AFFFFFF),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              flag,
                                              style: TextStyle(
                                                fontSize: 20 * scale,
                                              ),
                                            ),
                                            SizedBox(width: 12 * scale),
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14 * scale,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check_circle_rounded,
                                                color: VeraTheme.purpleBright,
                                                size: 18 * scale,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],

                                SizedBox(height: 24 * scale),

                                SizedBox(
                                  width: double.infinity,
                                  height: 48 * scale,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: VeraTheme.buttonGradient,
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: VeraTheme.glowPurple,
                                          blurRadius: 18,
                                          spreadRadius: 1,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          if (isDateType) {
                                            _unlockRuleType = 'DATE';
                                            _condition =
                                                formatDateString(selectedDate);
                                            _conditionSubtitle =
                                                'Date & time ($selectedTz)';
                                            _unlockAt = selectedDate
                                                .toUtc()
                                                .toIso8601String();
                                            _timezone = selectedTz;
                                            _latitude = null;
                                            _longitude = null;
                                            _radiusM = null;
                                            _placeName = null;
                                          } else {
                                            final matched =
                                                locationPresets.firstWhere(
                                              (l) =>
                                                  l['name'] == selectedLocation,
                                              orElse: () =>
                                                  locationPresets.first,
                                            );
                                            _unlockRuleType = 'LOCATION';
                                            _condition =
                                                "Opens when you're at $selectedLocation";
                                            _conditionSubtitle =
                                                '$selectedLocation (200m radius)';
                                            _placeName = selectedLocation;
                                            _latitude = (matched['latitude']
                                                    as num)
                                                .toDouble();
                                            _longitude = (matched['longitude']
                                                    as num)
                                                .toDouble();
                                            _radiusM =
                                                (matched['radiusM'] as num)
                                                    .toInt();
                                          }
                                        });
                                        Navigator.of(sheetContext).pop();
                                      },
                                      child: Text(
                                        'Save changes',
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _pickTimezone(double scale, ValueChanged<String> onSelected) {
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
      {
        'id': 'America/Los_Angeles',
        'label': 'America/Los_Angeles (Pacific Time)'
      },
      {'id': 'Asia/Singapore', 'label': 'Asia/Singapore (SGT)'},
      {'id': 'Asia/Tokyo', 'label': 'Asia/Tokyo (JST)'},
      {'id': 'Australia/Sydney', 'label': 'Australia/Sydney (AEST)'},
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF16172E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24 * scale),
              topRight: Radius.circular(24 * scale),
            ),
            border: Border.all(color: const Color(0xFF373657), width: 1),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 20 * scale,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select timezone',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Icon(
                      Icons.close_rounded,
                      color: const Color(0xFF8A8EB3),
                      size: 20 * scale,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12 * scale),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: timezones.length,
                  separatorBuilder: (ctx, index) =>
                      const Divider(color: Color(0x1AFFFFFF), height: 1),
                  itemBuilder: (_, i) {
                    final tz = timezones[i];
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8 * scale,
                        vertical: 2 * scale,
                      ),
                      title: Text(
                        tz['label']!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14 * scale,
                        ),
                      ),
                      subtitle: Text(
                        tz['id']!,
                        style: TextStyle(
                          color: const Color(0xFF8A8EB3),
                          fontSize: 12 * scale,
                        ),
                      ),
                      onTap: () {
                        onSelected(tz['id']!);
                        Navigator.of(ctx).pop();
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

  void _showUploadingModal(BuildContext context, double scale) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (modalContext) {
        return _UploadingModalContent(
          scale: scale,
          uploadFuture: () async {
            final client = ApiClientScope.of(context);
            final repository =
                MomentsRepositoryImpl(MomentsRemoteDataSource(client));

            final params = CreateMomentParams(
              title: _title,
              category: _category,
              teaser: _teaser,
              message: _message,
              visibility: _isPrivate ? 'PRIVATE' : 'PUBLIC',
              recipientUserIds: _recipientUserIds,
              inviteEmails: _inviteEmails,
              unlockRule: MomentUnlockRule(
                type: _unlockRuleType,
                unlockAt: _unlockAt,
                timezone: _timezone,
                latitude: _latitude,
                longitude: _longitude,
                radiusM: _radiusM,
                placeName: _placeName,
              ),
              expiresAt: widget.expiresAt,
            );

            final result = await repository.createMoment(params);
            var currentVersion = result.version;

            MomentModel? uploadedMoment;
            if (widget.mediaBytes != null || widget.mediaFile != null) {
              final bytes = widget.mediaBytes ??
                  await widget.mediaFile!.readAsBytes();
              final filename = widget.mediaFile?.name ??
                  (widget.isVideo ? 'moment.mp4' : 'moment.jpg');
              uploadedMoment = await repository.uploadMomentMedia(
                momentId: result.id,
                version: currentVersion,
                bytes: bytes,
                filename: filename,
              );
              currentVersion = uploadedMoment.version;
            }

            // Publish the moment (Step 07 - Submits for mandatory admin review)
            final publishedMoment = await repository.publishMoment(
              momentId: result.id,
              version: currentVersion,
            );

            return _CreationResult(
              result: result,
              uploadedMoment: uploadedMoment,
              publishedMoment: publishedMoment,
            );
          }(),
          onSuccess: (creation) {
            Navigator.of(modalContext).pop();
            final result = creation.result;
            final finalModel =
                creation.publishedMoment ?? creation.uploadedMoment;
            final isTimeLocked = _unlockRuleType == 'DATE';
            final momentVersion = finalModel?.version ?? result.version;
            final mediaUrl = finalModel?.mediaUrl;

            final recipientLabel = _isPrivate
                ? (_recipientName ??
                    (_inviteEmails.isNotEmpty
                        ? _inviteEmails.first
                        : (_recipientUserIds.isNotEmpty
                            ? _recipientUserIds.first
                            : 'Recipient')))
                : 'Everyone (Public)';

            final createdMoment = finalModel?.toEntity() ??
                Moment(
                  id: result.id,
                  userName: 'You',
                  userAvatarUrl: '',
                  timeAgo: 'Just now',
                  backgroundImageUrl: mediaUrl ??
                      (result.id.isNotEmpty
                          ? 'https://vera.aptechmedia.com/api/v1/moments/${result.id}/media'
                          : ''),
                  unlockCondition: isTimeLocked
                      ? 'Opens $_condition'
                      : _condition,
                  unlockType: isTimeLocked
                      ? MomentUnlockType.time
                      : MomentUnlockType.location,
                  sentBadgeTitle: _isPrivate
                      ? 'To $recipientLabel'
                      : 'To Everyone (public)',
                  sentBadgeSubtitle: 'Pending review',
                  isPublicSentMoment: !_isPrivate,
                  message: _message,
                  title: _title,
                  teaser: _teaser,
                  version: momentVersion,
                  status: 'PENDING_REVIEW',
                );
            HomeScreen.sentMoments.insert(0, createdMoment);

            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => MomentReadyScreen(
                  title: _title,
                  recipient: recipientLabel,
                  unlockTime: _condition,
                  isPublic: !_isPrivate,
                  shareUrl: 'https://vera.aptechmedia.com/m/${result.id}',
                ),
              ),
            );
          },
          onError: (error) {
            Navigator.of(modalContext).pop();
            final msg = error is ApiException
                ? error.message
                : error
                    .toString()
                    .replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
            VeraPopup.show(
              context,
              title: 'Upload Error',
              message: msg,
              icon: Icons.error_outline_rounded,
              accent: VeraTheme.warning,
            );
          },
        );
      },
    );
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
            // Top Navigation Bar (div.nav: 390 x 56)
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
                              'Review moment',
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

            // 3-Step Progress Bar (Complete)
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

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24 * scale, 16 * scale, 24 * scale, 24 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Title Frame
                    SizedBox(
                      width: contentWidth,
                      height: 32 * scale,
                      child: Text(
                        'Review your moment',
                        style: TextStyle(
                          color: const Color(0xFFF7F5FF),
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.w500,
                          height: 32 / 24,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    SizedBox(height: 20 * scale),

                    // Card 1: Content Summary Card (Editable)
                    GestureDetector(
                      onTap: () => _showEditContentModal(scale),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: contentWidth,
                        height: 124 * scale,
                        padding: EdgeInsets.all(12 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17182D),
                          borderRadius: BorderRadius.circular(16 * scale),
                          border: Border.all(
                            color: const Color(0x1AFFFFFF),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail Frame
                            Container(
                              width: 100 * scale,
                              height: 100 * scale,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12 * scale),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFC026D3),
                                    Color(0xFF1E1B4B),
                                    Color(0xFF0284C7),
                                  ],
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12 * scale),
                                child: widget.mediaBytes != null && !widget.isVideo
                                    ? Image.memory(
                                        widget.mediaBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : Center(
                                        child: Icon(
                                          widget.isVideo
                                              ? Icons.play_arrow_rounded
                                              : (widget.mediaBytes != null
                                                  ? Icons.photo_rounded
                                                  : Icons.play_arrow_rounded),
                                          color: Colors.white,
                                          size: 36 * scale,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(width: 12 * scale),

                            // Text Info Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Content',
                                        style: TextStyle(
                                          color: const Color(0xFFA6A6C1),
                                          fontSize: 12 * scale,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _showEditContentModal(scale),
                                        behavior: HitTestBehavior.opaque,
                                        child: Padding(
                                          padding: EdgeInsets.all(2 * scale),
                                          child: Icon(
                                            Icons.mode_edit_outline_rounded,
                                            color: const Color(0xFFA6A6C1),
                                            size: 16 * scale,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    _title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14 * scale,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    'Category: $_category',
                                    style: TextStyle(
                                      color: const Color(0xFFA6A6C1),
                                      fontSize: 12 * scale,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _message != null && _message!.isNotEmpty
                                              ? _message!
                                              : 'Teaser: $_teaser',
                                          style: TextStyle(
                                            color: const Color(0xFFA6A6C1),
                                            fontSize: 11.5 * scale,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: const Color(0xFFA6A6C1),
                                        size: 18 * scale,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 12 * scale),

                    // Card 2: Audience Summary Card (Editable)
                    GestureDetector(
                      onTap: () => _showEditAudienceModal(scale),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: contentWidth,
                        height: 88 * scale,
                        padding: EdgeInsets.all(12 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17182D),
                          borderRadius: BorderRadius.circular(16 * scale),
                          border: Border.all(
                            color: const Color(0x1AFFFFFF),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              _isPrivate
                                  ? Icons.lock_outline_rounded
                                  : Icons.language_rounded,
                              color: Colors.white,
                              size: 20 * scale,
                            ),
                            SizedBox(width: 12 * scale),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Audience',
                                        style: TextStyle(
                                          color: const Color(0xFFA6A6C1),
                                          fontSize: 12 * scale,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            _showEditAudienceModal(scale),
                                        behavior: HitTestBehavior.opaque,
                                        child: Padding(
                                          padding: EdgeInsets.all(2 * scale),
                                          child: Icon(
                                            Icons.mode_edit_outline_rounded,
                                            color: const Color(0xFFA6A6C1),
                                            size: 16 * scale,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    _audience,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14 * scale,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    _audienceSubtitle,
                                    style: TextStyle(
                                      color: const Color(0xFFA6A6C1),
                                      fontSize: 12 * scale,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 12 * scale),

                    // Card 3: Unlock Condition Summary Card (Editable)
                    GestureDetector(
                      onTap: () => _showEditConditionModal(scale),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: contentWidth,
                        height: 88 * scale,
                        padding: EdgeInsets.all(12 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17182D),
                          borderRadius: BorderRadius.circular(16 * scale),
                          border: Border.all(
                            color: const Color(0x1AFFFFFF),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              _unlockRuleType == 'DATE'
                                  ? Icons.calendar_month_outlined
                                  : Icons.location_on_outlined,
                              color: Colors.white,
                              size: 20 * scale,
                            ),
                            SizedBox(width: 12 * scale),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Unlock condition',
                                        style: TextStyle(
                                          color: const Color(0xFFA6A6C1),
                                          fontSize: 12 * scale,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            _showEditConditionModal(scale),
                                        behavior: HitTestBehavior.opaque,
                                        child: Padding(
                                          padding: EdgeInsets.all(2 * scale),
                                          child: Icon(
                                            Icons.mode_edit_outline_rounded,
                                            color: const Color(0xFFA6A6C1),
                                            size: 16 * scale,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    _condition,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14 * scale,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    _conditionSubtitle,
                                    style: TextStyle(
                                      color: const Color(0xFFA6A6C1),
                                      fontSize: 12 * scale,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                    onPressed: () => _showUploadingModal(context, scale),
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

class _UploadingModalContent extends StatefulWidget {
  const _UploadingModalContent({
    required this.scale,
    required this.uploadFuture,
    required this.onSuccess,
    required this.onError,
  });

  final double scale;
  final Future<_CreationResult> uploadFuture;
  final ValueChanged<_CreationResult> onSuccess;
  final ValueChanged<Object> onError;

  @override
  State<_UploadingModalContent> createState() => _UploadingModalContentState();
}

class _UploadingModalContentState extends State<_UploadingModalContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _startUpload();
  }

  Future<void> _startUpload() async {
    try {
      final results = await Future.wait([
        widget.uploadFuture,
        Future.delayed(const Duration(milliseconds: 1200)),
      ]);
      if (!mounted || _cancelled) return;
      widget.onSuccess(results.first as _CreationResult);
    } catch (e) {
      if (!mounted || _cancelled) return;
      widget.onError(e);
    }
  }

  @override
  void dispose() {
    _cancelled = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24 * scale),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF16172E),
                  Color(0xFF0C0D1A),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24 * scale),
              ),
              border: Border.all(
                color: const Color(0xFF373657),
                width: 1,
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              24 * scale,
              20 * scale,
              24 * scale,
              24 * scale + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Uploading your moment...',
                      style: TextStyle(
                        color: const Color(0xFFF7F5FF),
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _cancelled = true;
                        _controller.stop();
                        Navigator.of(context).pop();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32 * scale,
                        height: 32 * scale,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(18),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 16 * scale,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24 * scale),

                // Animated Progress Bar
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      width: double.infinity,
                      height: 6 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1F36),
                        borderRadius: BorderRadius.circular(3 * scale),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _controller.value,
                          child: Container(
                            height: 6 * scale,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF9044FB),
                                  Color(0xFFC057FF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3 * scale),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
