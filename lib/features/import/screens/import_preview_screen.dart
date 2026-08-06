import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/category_avatar.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/features/categories/domain/category_visuals.dart';
import 'package:spendwise/features/import/domain/statement_row_info.dart';
import 'package:spendwise/features/import/domain/transaction_type.dart';
import 'package:spendwise/features/import/services/statement_import_committer.dart';
import 'package:spendwise/services/currency_controller.dart';

/// Preview of the rows parsed and classified from a statement file.
///
/// Phase 6C: each card shows the inferred merchant, category, transaction
/// type and amount alongside the raw date. Phase 6D: tapping "Import" writes
/// the rows to Firestore through [StatementImportCommitter], skipping
/// duplicates, and pops back to the dashboard after confirmation.
class ImportPreviewScreen extends StatefulWidget {
  final List<StatementRowInfo> rows;

  const ImportPreviewScreen({super.key, required this.rows});

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  final StatementImportCommitter _committer = StatementImportCommitter();
  bool _importing = false;

  ColorScheme get _scheme => Theme.of(context).colorScheme;

  Future<void> _handleImport() async {
    setState(() => _importing = true);

    try {
      final outcome = await _committer.commit(widget.rows);
      if (!mounted) return;

      setState(() => _importing = false);
      await _showSuccessDialog(outcome);
      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() => _importing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Import failed. Please try again.')),
        );
    }
  }

  Future<void> _showSuccessDialog(StatementImportOutcome outcome) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _scheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Imported Successfully',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _scheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: _scheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${outcome.imported} imported',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: _scheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.loop, color: _scheme.secondary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '${outcome.duplicates} duplicates skipped',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: _scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  color: _scheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: _scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // --- Atmospheric Background Blurs (Aligned with other SpendWise screens) ---
            Positioned(
              top: -100,
              right: -100,
              child: BlurBlob(
                color: _scheme.primaryFixed.withValues(alpha: 0.1),
                size: 500,
                blur: 100,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: BlurBlob(
                color: _scheme.secondaryFixed.withValues(alpha: 0.2),
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
                  bottom: 140, // Clears the fixed Import action bar
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

            // --- Fixed Bottom Import Action Bar ---
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomActions(context),
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
      color: _scheme.surface.withValues(alpha: 0.95),
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
                onPressed: _importing
                    ? null
                    : () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back,
                  color: _scheme.primary,
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
                  color: _scheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fixed bottom Import button, disabled with a spinner while importing
  Widget _buildBottomActions(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      color: _scheme.surface.withValues(alpha: 0.95),
      padding: EdgeInsets.only(
        left: screenWidth * 0.05,
        right: screenWidth * 0.05,
        top: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ElevatedButton.icon(
            onPressed: _importing ? null : _handleImport,
            style: ElevatedButton.styleFrom(
              backgroundColor: _scheme.primaryContainer,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _scheme.primaryContainer.withValues(
                alpha: 0.25,
              ),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.15),
            ),
            icon: _importing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.upload_file, size: 24),
            label: Text(
              _importing ? 'Importing...' : 'Import',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
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
            color: _scheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.rows.length} row${widget.rows.length == 1 ? '' : 's'} parsed and '
          'classified. Merchant, type, category and amount are inferred — '
          'nothing is saved yet.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Card list of the parsed rows
  Widget _buildRowsList() {
    if (widget.rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        decoration: BoxDecoration(
          color: _scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _scheme.surfaceContainerLow),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 48,
              color: _scheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No rows to preview',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _scheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < widget.rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _buildRowCard(widget.rows[i]),
        ],
      ],
    );
  }

  // Individual row card showing the inferred information
  Widget _buildRowCard(StatementRowInfo info) {
    final visual = categoryVisualFor(info.category);
    final amountColor = switch (info.type) {
      TransactionType.income => _scheme.primary,
      TransactionType.expense => _scheme.error,
      TransactionType.unknown => _scheme.onSurfaceVariant,
    };
    final amountPrefix = switch (info.type) {
      TransactionType.income => '+ ',
      TransactionType.expense => '- ',
      TransactionType.unknown => '',
    };
    final amountLabel = info.amount != null
        ? '$amountPrefix${CurrencyController.instance.format(info.amount!)}'
        : '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _scheme.surfaceContainerLow),
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
                        color: _scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _scheme.onSurfaceVariant,
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
                color: _scheme.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _scheme.onSurface,
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
      TransactionType.income => _scheme.primary,
      TransactionType.expense => _scheme.error,
      TransactionType.unknown => _scheme.onSurfaceVariant,
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
                color: _scheme.secondary,
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
