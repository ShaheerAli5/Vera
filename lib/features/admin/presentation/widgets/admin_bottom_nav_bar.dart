import 'dart:ui';
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
      height: (88 * scale) + bottomPad,
      decoration: BoxDecoration(
        color: const Color(0x59090A17),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(44 * scale),
          bottomRight: Radius.circular(44 * scale),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(44 * scale),
          bottomRight: Radius.circular(44 * scale),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24 * scale,
              16 * scale,
              24 * scale,
              24 * scale + bottomPad,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xD91B152E),
                  Color(0xF2120D22),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(44),
                bottomRight: Radius.circular(44),
              ),
              border: Border(
                top: BorderSide(
                  color: Color(0x1FFFFFFF),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  isSelected: selectedIndex == 0,
                  onTap: () => onTap(0),
                  scale: scale,
                ),
                _NavItem(
                  icon: Icons.gavel_outlined,
                  activeIcon: Icons.gavel,
                  isSelected: selectedIndex == 1,
                  onTap: () => onTap(1),
                  scale: scale,
                ),
                _NavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  isSelected: selectedIndex == 2,
                  onTap: () => onTap(2),
                  scale: scale,
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  isSelected: selectedIndex == 3,
                  onTap: () => onTap(3),
                  scale: scale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
    required this.scale,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
        child: isSelected
            ? ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [Color(0xFF8E37FF), Color(0xFFC857FF)],
                  ).createShader(bounds);
                },
                child: Icon(activeIcon, color: Colors.white, size: 28 * scale),
              )
            : Icon(icon, color: const Color(0xFFC68CFF), size: 28 * scale),
      ),
    );
  }
}
