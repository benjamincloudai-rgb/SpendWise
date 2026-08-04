import 'package:flutter/material.dart';

/// Atmospheric circular background blur bubble used by most SpendWise screens.
///
/// Replaces the private `_BlurBlob` classes.
class BlurBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double blur;

  const BlurBlob({
    super.key,
    required this.color,
    required this.size,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: blur, spreadRadius: blur / 2),
        ],
      ),
    );
  }
}
