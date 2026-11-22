import 'package:flutter/material.dart';

class AdminBottomNavBar extends StatelessWidget {
  const AdminBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.scale,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      height: 88 * scale + bottomPad,
      decoration: const BoxDecoration(
        color: Color(0xFF090A17),
        border: Border(
          top: BorderSide(
            color: Color(0x24FFFFFF),
            width: 1.0,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24 * scale,
          0,
          24 * scale,
          12 * scale + bottomPad,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tabs Container (Hug 202px, Hug 28px, gap 30px)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavAssetItem(
                  assetPath: 'assets/images/nav_home.png',
                  isSelected: selectedIndex == 0,
                  onTap: () => onTap(0),
                  scale: scale,
                ),
                SizedBox(width: 30 * scale),
                _NavAssetItem(
                  assetPath: 'assets/images/users-nav.png',
                  isSelected: selectedIndex == 2,
                  onTap: () => onTap(2),
                  scale: scale,
                ),
                SizedBox(width: 30 * scale),
                _NavAssetItem(
                  assetPath: 'assets/images/shield.png',
                  isSelected: selectedIndex == 1,
                  onTap: () => onTap(1),
                  scale: scale,
                ),
                SizedBox(width: 30 * scale),
                _NavAssetItem(
                  assetPath: 'assets/images/sliders.png',
                  isSelected: selectedIndex == 3,
                  onTap: () => onTap(3),
                  scale: scale,
                ),
              ],
            ),
            // Broadcast Action Button (Fixed 52x52, radius 999, bg #58C3F4, icon 24x24 send.png)
            Container(
              width: 52 * scale,
              height: 52 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFF58C3F4),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF58C3F4).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(1),
                  borderRadius: BorderRadius.circular(26 * scale),
                  child: Center(
                    child: Image.asset(
                      'assets/images/send.png',
                      width: 24 * scale,
                      height: 24 * scale,
                      color: const Color(0xFF090A17),
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

class _NavAssetItem extends StatelessWidget {
  const _NavAssetItem({
    required this.assetPath,
    required this.isSelected,
    required this.onTap,
    required this.scale,
  });

  final String assetPath;
  final bool isSelected;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Image.asset(
        assetPath,
        width: 26 * scale,
        height: 26 * scale,
        color: isSelected ? const Color(0xFF58C3F4) : const Color(0xFF8A8EB3),
      ),
    );
  }
}
