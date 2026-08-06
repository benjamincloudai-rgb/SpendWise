import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SharedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SharedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color colorPrimary = Theme.of(context).colorScheme.primary;
    final Color colorPrimaryContainer =
        Theme.of(context).colorScheme.primaryContainer;
    final Color colorSecondary = Theme.of(context).colorScheme.secondary;
    final Color colorSurface =
        Theme.of(context).colorScheme.surfaceContainerLowest;

    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      color: colorSurface,
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.paddingOf(context).bottom + 8,
        left: screenWidth * 0.05,
        right: screenWidth * 0.05,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0, // Constrains the vertically expanding slot tightly
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  colorPrimary: colorPrimary,
                  colorPrimaryContainer: colorPrimaryContainer,
                  colorSecondary: colorSecondary,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.receipt_long,
                  label: 'History',
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  colorPrimary: colorPrimary,
                  colorPrimaryContainer: colorPrimaryContainer,
                  colorSecondary: colorSecondary,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.leaderboard,
                  label: 'Stats',
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  colorPrimary: colorPrimary,
                  colorPrimaryContainer: colorPrimaryContainer,
                  colorSecondary: colorSecondary,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.person,
                  label: 'Profile',
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  colorPrimary: colorPrimary,
                  colorPrimaryContainer: colorPrimaryContainer,
                  colorSecondary: colorSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required ValueChanged<int> onTap,
    required Color colorPrimary,
    required Color colorPrimaryContainer,
    required Color colorSecondary,
  }) {
    final isActive = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? colorPrimaryContainer : Colors.transparent,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isActive ? Colors.white : colorSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? colorPrimary : colorSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
