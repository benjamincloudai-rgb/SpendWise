import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/currency/currencies.dart';
import 'package:spendwise/core/theme/app_colors.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/services/currency_controller.dart';

class CurrencySelectionScreen extends StatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  State<CurrencySelectionScreen> createState() =>
      _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {
  // Strict colors matching the SpendWise design system
  final Color colorPrimary = AppColors.primary;
  final Color colorBackground = AppColors.background;
  final Color colorSurfaceContainerLowest = AppColors.surfaceContainerLowest;
  final Color colorSurfaceContainerLow = AppColors.surfaceContainerLow;
  final Color colorOnSurfaceVariant = AppColors.onSurfaceVariant;
  final Color colorOnSurface = AppColors.onSurface;
  final Color colorPrimaryFixed = AppColors.primaryFixed;
  final Color colorSecondaryFixed = AppColors.secondaryFixed;
  final Color colorOutlineVariant = AppColors.outlineVariant;
  final Color colorSecondary = AppColors.secondary;

  String _selectedCode = CurrencyController.instance.code;

  void _selectCurrency(CurrencyOption option) {
    if (option.code == _selectedCode) return;

    setState(() {
      _selectedCode = option.code;
    });

    CurrencyController.instance.setCode(option.code);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Currency updated to ${currencyLabelFor(option.code)}',
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // --- Atmospheric Background Blurs (Aligned with other screens) ---
            Positioned(
              top: -100,
              right: -100,
              child: BlurBlob(
                color: colorPrimaryFixed.withValues(alpha: 0.1),
                size: 500,
                blur: 100,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: BlurBlob(
                color: colorSecondaryFixed.withValues(alpha: 0.2),
                size: 400,
                blur: 80,
              ),
            ),

            // --- Scrollable Content ---
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                  top: 76, // Clears top sticky App Bar
                  bottom: 40, // Secure padding at the bottom
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        EntranceAnimation(
                          delayMs: 100,
                          child: _buildCurrencyCard(),
                        ),
                        const SizedBox(height: 16),
                        EntranceAnimation(
                          delayMs: 180,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'The symbol updates across the entire app. Amounts are never converted.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colorSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- Sticky Top App Bar ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EntranceAnimation(
                delayMs: 50,
                child: _buildHeader(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header Component (Sticky Top App Bar)
  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      color: colorBackground.withValues(alpha: 0.95),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: colorOnSurface, size: 28),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),
              Text(
                'Currency',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorSecondary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Single rounded card containing all currency rows
  Widget _buildCurrencyCard() {
    return Container(
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
      child: Column(
        children: [
          for (var i = 0; i < currencyOptions.length; i++) ...[
            if (i > 0) _buildDivider(),
            _buildCurrencyRow(currencyOptions[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrencyRow(CurrencyOption option) {
    final isSelected = option.code == _selectedCode;

    return InkWell(
      onTap: () => _selectCurrency(option),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorPrimary.withValues(alpha: 0.12)
                    : colorSurfaceContainerLow,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: colorPrimary, width: 2)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                option.symbol,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colorPrimary : colorOnSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorOnSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.code,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorPrimary, size: 22)
            else
              Icon(
                Icons.check_circle_outline,
                color: colorOutlineVariant,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: colorOutlineVariant.withValues(alpha: 0.2),
    );
  }
}
