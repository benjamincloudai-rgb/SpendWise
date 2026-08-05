import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/theme/app_colors.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/features/import/domain/statement_row.dart';

/// Preview of the rows parsed from a statement file.
///
/// Phase 6B: the raw values are displayed exactly as parsed — no formatting,
/// no calculations, no categorisation, no duplicate detection, and nothing is
/// saved to Firestore.
class ImportPreviewScreen extends StatelessWidget {
  final List<StatementRow> rows;

  const ImportPreviewScreen({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // --- Atmospheric Background Blurs (Aligned with other SpendWise screens) ---
            Positioned(
              top: -100,
              right: -100,
              child: BlurBlob(
                color: AppColors.primaryFixed.withValues(alpha: 0.1),
                size: 500,
                blur: 100,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: BlurBlob(
                color: AppColors.secondaryFixed.withValues(alpha: 0.2),
                size: 400,
                blur: 80,
              ),
            ),

            // --- Scrollable Layout ---
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                  top: 92, // Clears sticky top header
                  bottom: 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        EntranceAnimation(
                          delayMs: 100,
                          child: _buildSummaryHeader(),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 200,
                          child: _buildRowsList(),
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
              child: _buildHeader(context),
            ),
          ],
        ),
      ),
    );
  }

  // Header Component (Top App Bar)
  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      color: AppColors.background.withValues(alpha: 0.95),
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
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.primary,
                  size: 28,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),
              Text(
                'Import Preview',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Summary heading above the parsed rows
  Widget _buildSummaryHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statement Rows',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${rows.length} row${rows.length == 1 ? '' : 's'} parsed from your file. '
          'Values are shown exactly as they appear in the file.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Card list of the parsed rows
  Widget _buildRowsList() {
    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceContainerLow),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 48,
              color: AppColors.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No rows to preview',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _buildRowCard(rows[i]),
        ],
      ],
    );
  }

  // Individual row card preserving the five raw values
  Widget _buildRowCard(StatementRow row) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceContainerLow),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Date', row.date),
          _buildDetailRow('Description', row.description),
          _buildDetailRow('Debit', row.debit),
          _buildDetailRow('Credit', row.credit),
          _buildDetailRow('Balance', row.balance),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
