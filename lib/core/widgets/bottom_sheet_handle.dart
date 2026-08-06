import 'package:flutter/material.dart';

/// Centered grab-handle pill shown at the top of SpendWise bottom sheets.
///
/// Replaces the repeated inline 40x4 handle containers.
class BottomSheetHandle extends StatelessWidget {
  final Color? color;

  const BottomSheetHandle({
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final handleColor =
        color ?? Theme.of(context).colorScheme.outlineVariant;
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: handleColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
