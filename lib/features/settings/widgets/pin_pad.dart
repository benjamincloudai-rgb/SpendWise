import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Row of circular dots that reflects how many PIN digits have been entered.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, this.total = 4});

  final int length;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (index) {
        final filled = index < length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? colorScheme.primary : Colors.transparent,
            border: Border.all(
              color: filled ? colorScheme.primary : colorScheme.outlineVariant,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

/// Numeric keypad (0-9 + backspace) used by the lock and PIN setup screens.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspace,
    this.disabled = false,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspace;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      children: [
        for (var i = 1; i <= 9; i++)
          _PinKey(
            label: '$i',
            onTap: disabled ? null : () => onDigitPressed('$i'),
          ),
        const SizedBox.shrink(),
        _PinKey(
          label: '0',
          onTap: disabled ? null : () => onDigitPressed('0'),
        ),
        _PinKey(
          icon: Icons.backspace_outlined,
          onTap: disabled ? null : onBackspace,
        ),
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({this.label, this.icon, this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainerLow,
          ),
          alignment: Alignment.center,
          child: label != null
              ? Text(
                  label!,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                )
              : Icon(icon, color: colorScheme.onSurface, size: 26),
        ),
      ),
    );
  }
}
