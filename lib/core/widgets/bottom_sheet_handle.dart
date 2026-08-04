import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centered grab-handle pill shown at the top of SpendWise bottom sheets.
///
/// Replaces the repeated inline 40x4 handle containers.
class BottomSheetHandle extends StatelessWidget {
  final Color color;

  const BottomSheetHandle({
    super.key,
    this.color = AppColors.outlineVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
