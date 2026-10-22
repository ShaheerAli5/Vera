import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import 'choose_audience_screen.dart';

class CreateMomentScreen extends StatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  State<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends State<CreateMomentScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  int _selectedCategoryIndex = -1;
  bool _hasUploadedMedia = false;

  final List<Map<String, dynamic>> _categories = const [
    {'icon': Icons.airplanemode_active_rounded, 'label': 'Travel'},
    {'icon': Icons.eco_outlined, 'label': 'Nature'},
    {'icon': Icons.favorite_border_rounded, 'label': 'Love'},
    {'icon': Icons.cake_outlined, 'label': 'Birthdays'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onMediaSelected() {
    setState(() {
      _hasUploadedMedia = true;
      if (_messageController.text.isEmpty) {
        _messageController.text = "Whenever you read this, I hope your da...";
      }
    });
  }

  void _removeMedia() {
    setState(() {
      _hasUploadedMedia = false;
    });
  }

  void _navigateToNextStep() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ChooseAudienceScreen(),
      ),
    );
  }

  void _showSelectTypeModal(BuildContext context, double scale) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24 * scale),
            topRight: Radius.circular(24 * scale),
            bottomLeft: Radius.circular(28 * scale),
            bottomRight: Radius.circular(28 * scale),
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
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24 * scale),
                  topRight: Radius.circular(24 * scale),
                  bottomLeft: Radius.circular(28 * scale),
                  bottomRight: Radius.circular(28 * scale),
                ),
                border: Border.all(
                  color: const Color(0xFF373657),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24 * scale,
                16 * scale,
                24 * scale,
                28 * scale,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Select a type',
                          style: TextStyle(
                            color: const Color(0xFFF7F5FF),
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
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

                  SizedBox(height: 20 * scale),

                  // Options Row
                  Row(
                    children: [
                      Expanded(
                        child: _MediaTypeOption(
                          icon: Icons.camera_alt_outlined,
                          label: 'Camera',
                          scale: scale,
                          onTap: () {
                            Navigator.of(context).pop();
                            _onMediaSelected();
                          },
                        ),
                      ),
                      SizedBox(width: 12 * scale),
                      Expanded(
                        child: _MediaTypeOption(
                          icon: Icons.image_outlined,
                          label: 'Gallery',
                          scale: scale,
                          onTap: () {
                            Navigator.of(context).pop();
                            _onMediaSelected();
                          },
                        ),
                      ),
                      SizedBox(width: 12 * scale),
                      Expanded(
                        child: _MediaTypeOption(
                          icon: Icons.play_circle_outline_rounded,
                          label: 'Video',
                          scale: scale,
                          onTap: () {
                            Navigator.of(context).pop();
                            _onMediaSelected();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
                    // Back Button Frame (48 x 48, radius 24)
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
                              'Create a moment',
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
                          '1 of 3',
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
                        color: const Color(0xFF1E1F36),
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

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(top: 16 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Title
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 345 * scale,
                            height: 32 * scale,
                            child: Text(
                              'Give your moment a title',
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
                          // Title Input Box
                          SizedBox(
                            width: 345 * scale,
                            height: 48 * scale,
                            child: TextField(
                              controller: _titleController,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14 * scale,
                              ),
                              decoration: InputDecoration(
                                hintText: 'What is this moment?',
                                hintStyle: TextStyle(
                                  color: const Color(0xFF8A8EB3),
                                  fontSize: 14 * scale,
                                  fontWeight: FontWeight.w400,
                                  height: 24 / 14,
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
                        ],
                      ),
                    ),

                    SizedBox(height: 24 * scale),

                    // Uploaded Media Preview Card OR Category Selection
                    if (_hasUploadedMedia) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                        child: Container(
                          width: 345 * scale,
                          height: 180 * scale,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20 * scale),
                            border: Border.all(
                              color: const Color(0x33FFFFFF),
                              width: 0.8,
                            ),
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
                            borderRadius: BorderRadius.circular(20 * scale),
                            child: Stack(
                              children: [
                                // Top Left Duration Badge
                                Positioned(
                                  top: 12 * scale,
                                  left: 12 * scale,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10 * scale,
                                      vertical: 4 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x99000000),
                                      borderRadius: BorderRadius.circular(20 * scale),
                                    ),
                                    child: Text(
                                      '0:12',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11 * scale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                                // Top Right Delete/Close Button
                                Positioned(
                                  top: 12 * scale,
                                  right: 12 * scale,
                                  child: GestureDetector(
                                    onTap: _removeMedia,
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      width: 32 * scale,
                                      height: 32 * scale,
                                      decoration: const BoxDecoration(
                                        color: Color(0x99000000),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 16 * scale,
                                      ),
                                    ),
                                  ),
                                ),

                                // Center Play Button
                                Center(
                                  child: Container(
                                    width: 52 * scale,
                                    height: 52 * scale,
                                    decoration: const BoxDecoration(
                                      color: Color(0x99000000),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 30 * scale,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Section 2: Categories
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select a category',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16 * scale),
                            Wrap(
                              spacing: 10 * scale,
                              runSpacing: 10 * scale,
                              children: List.generate(_categories.length, (index) {
                                final category = _categories[index];
                                final isSelected = _selectedCategoryIndex == index;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategoryIndex =
                                          isSelected ? -1 : index;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16 * scale,
                                      vertical: 10 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? VeraTheme.purple
                                          : const Color(0xFF17182D),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: isSelected
                                            ? VeraTheme.purpleBright
                                            : const Color(0x1AFFFFFF),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          category['icon'] as IconData,
                                          size: 16 * scale,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 8 * scale),
                                        Text(
                                          category['label'] as String,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.5 * scale,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24 * scale),

                      // Section 3: Add something to remember
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add something to remember',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            Text(
                              'Add a message, photo or video to your moment. All are optional.',
                              style: TextStyle(
                                color: VeraTheme.textSecondary,
                                fontSize: 13 * scale,
                                height: 1.45,
                                fontWeight: FontWeight.w400,
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

            // Bottom Action Area
            Container(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Notice Label
                  SizedBox(
                    width: 345 * scale,
                    height: 24 * scale,
                    child: Center(
                      child: Text(
                        'You can continue without adding a message',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF8A8EB3),
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w400,
                          height: 24 / 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),

                  // Message & Media Row
                  Row(
                    children: [
                      // Plus Button Frame
                      GestureDetector(
                        onTap: () => _showSelectTypeModal(context, scale),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 48 * scale,
                          height: 48 * scale,
                          padding: EdgeInsets.all(10 * scale),
                          decoration: BoxDecoration(
                            color: const Color(0xFF17182D),
                            borderRadius: BorderRadius.circular(16 * scale),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 22 * scale,
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: SizedBox(
                          height: 48 * scale,
                          child: TextField(
                            controller: _messageController,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5 * scale,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Write an optional message...',
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
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12 * scale),

                  // Continue Button
                  SizedBox(
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
                        onPressed: _navigateToNextStep,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaTypeOption extends StatelessWidget {
  const _MediaTypeOption({
    required this.icon,
    required this.label,
    required this.scale,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 71 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFF17182D),
          borderRadius: BorderRadius.circular(35.5 * scale),
          border: Border.all(
            color: const Color(0x1AFFFFFF),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 22 * scale,
            ),
            SizedBox(height: 4 * scale),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
