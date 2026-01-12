import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GnavBar extends StatelessWidget {
  final void Function(int)? onTabChange;
  final int selectedIndex;

  const GnavBar({
    super.key,
    required this.onTabChange,
    this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
                isSelected: selectedIndex == 0,
              ),
              _buildNavItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                label: 'Appointments',
                index: 1,
                isSelected: selectedIndex == 1,
              ),
              _buildNavItem(
                icon: Icons.message_outlined,
                activeIcon: Icons.message,
                label: 'Messages',
                index: 2,
                isSelected: selectedIndex == 2,
              ),
              _buildNavItem(
                icon: Icons.group_outlined,
                activeIcon: Icons.group,
                label: 'Staff',
                index: 3,
                isSelected: selectedIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTabChange?.call(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? const Color(0xFF608BC1).withOpacity(0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected 
                  ? const Color(0xFF608BC1) 
                  : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                  ? const Color(0xFF608BC1) 
                  : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}