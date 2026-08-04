import 'package:flutter/material.dart';

/// Circular category avatar with a tinted background and icon.
///
/// Replaces the repeated inline 48x48 circle containers. The default matches
/// the category-card rendering (15% tinted background, full-strength icon).
class CategoryAvatar extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const CategoryAvatar({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
