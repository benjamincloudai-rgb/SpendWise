import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/theme/app_colors.dart';
import 'package:spendwise/core/utils/formatters.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/category_avatar.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/features/categories/domain/category_visuals.dart';
import 'package:spendwise/features/import/domain/statement_row_info.dart';
import 'package:spendwise/features/import/domain/transaction_type.dart';

/// Preview of the rows parsed and classified from a statement file.
///
/// Phase 6C: each card shows the inferred merchant, category, transaction
/// type and amount alongside the raw date. Nothing is formatted from the raw
/// strings themselves and nothing is saved to Firestore.
class ImportPreviewScreen extends StatelessWidget {
  final List<StatementRowInfo> rows;

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
          '${rows.length} row${rows.length == 1 ? '' : 's'} parsed and '
          'classified. Merchant, type, category and amount are inferred — '
          'nothing is saved yet.',
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

  // Individual row card showing the inferred information
  Widget _buildRowCard(StatementRowInfo info) {
    final visual = categoryVisualFor(info.category);
    final amountColor = switch (info.type) {
      TransactionType.income => AppColors.primary,
      TransactionType.expense => AppColors.error,
      TransactionType.unknown => AppColors.onSurfaceVariant,
    };
    final amountPrefix = switch (info.type) {
      TransactionType.income => '+ ',
      TransactionType.expense => '- ',
      TransactionType.unknown => '',
    };
    final amountLabel = info.amount != null
        ? '$amountPrefix₹${formatAmount(info.amount!)}'
        : '—';

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
          Row(
            children: [
              CategoryAvatar(
                icon: visual.icon,
                color: visual.iconColor,
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.merchant.isEmpty ? '—' : info.merchant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                amountLabel,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Date', info.row.date),
          _buildTypeRow(info.type),
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

  Widget _buildTypeRow(TransactionType type) {
    final label = switch (type) {
      TransactionType.income => 'Income',
      TransactionType.expense => 'Expense',
      TransactionType.unknown => 'Unknown',
    };
    final color = switch (type) {
      TransactionType.income => AppColors.primary,
      TransactionType.expense => AppColors.error,
      TransactionType.unknown => AppColors.onSurfaceVariant,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              'Type',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
