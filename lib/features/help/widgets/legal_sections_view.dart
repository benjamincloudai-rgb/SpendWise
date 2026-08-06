import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LegalSection {
  const LegalSection({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

/// Shared expandable-section list used by the legal pages (Privacy Policy and
/// Terms & Conditions) so every legal screen keeps the same SpendWise layout.
class LegalSectionsView extends StatelessWidget {
  const LegalSectionsView({super.key, required this.sections});

  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorPrimary = colorScheme.primary;
    final colorOnSurface = colorScheme.onSurface;
    final colorSecondary = colorScheme.secondary;
    final colorSurfaceContainerLowest = colorScheme.surfaceContainerLowest;
    final colorSurfaceContainerLow = colorScheme.surfaceContainerLow;
    final colorPrimaryContainer = colorScheme.primaryContainer;

    return Column(
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colorSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorSurfaceContainerLow),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ExpansionTile(
              key: PageStorageKey<String>(sections[i].title),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorPrimaryContainer.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  sections[i].icon,
                  color: colorPrimary,
                  size: 22,
                ),
              ),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              childrenPadding: const EdgeInsets.only(
                left: 76,
                right: 20,
                bottom: 18,
              ),
              iconColor: colorPrimary,
              collapsedIconColor: colorPrimary,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                sections[i].title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorOnSurface,
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    sections[i].body,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.5,
                      color: colorSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
