import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/features/import/screens/import_preview_screen.dart';
import 'package:spendwise/features/import/services/statement_import_service.dart';
import 'package:spendwise/features/import/widgets/pdf_password_dialog.dart';

/// Entry point for the Bank Statement Import feature.
///
/// Phase 6B: tapping "Import CSV" opens the native file picker, parses the
/// selected file generically, and opens the preview screen. Phase 8A adds the
/// same flow for Excel (`.xlsx`) workbooks. Phase 10B adds the same flow for
/// text-based PDF statements. Phase 10C adds support for password-protected
/// PDFs: the pdfrx password provider drives a password dialog, and the import
/// continues downstream exactly as it does today once the file is unlocked.
class ImportStatementScreen extends StatelessWidget {
  ImportStatementScreen({super.key});

  final StatementImportService _statementImportService =
      StatementImportService();

  Future<void> _handleImportCsv(BuildContext context) async {
    final result = await _statementImportService.importCsv();
    if (context.mounted) await _handleImportResult(context, result);
  }

  Future<void> _handleImportExcel(BuildContext context) async {
    final result = await _statementImportService.importExcel();
    if (context.mounted) await _handleImportResult(context, result);
  }

  Future<void> _handleImportPdf(BuildContext context) async {
    // One controller per import keeps a single dialog alive across every
    // password attempt; it is discarded as soon as the import finishes.
    final controller = PdfPasswordDialogController(context: context);
    final result = await _statementImportService.importPdf(
      passwordProvider: () => controller.awaitPassword(),
    );
    controller.closeDialog();
    if (context.mounted) await _handleImportResult(context, result);
  }

  Future<void> _handleImportResult(
    BuildContext context,
    StatementImportResult result,
  ) async {
    if (result.cancelled) return;

    if (result.error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }

    final imported = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ImportPreviewScreen(rows: result.rows),
      ),
    );

    // The preview pops with `true` once the statement has been imported, so
    // return all the way to the Dashboard.
    if (imported == true && context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final Color colorPrimary = Theme.of(context).colorScheme.primary;
    final Color colorPrimaryContainer =
        Theme.of(context).colorScheme.primaryContainer;
    final Color colorBackground = Theme.of(context).colorScheme.surface;
    final Color colorPrimaryFixed = Theme.of(context).colorScheme.primaryFixed;
    final Color colorSecondaryFixed =
        Theme.of(context).colorScheme.secondaryFixed;
    final Color colorSecondary = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // --- Atmospheric Background Blurs (Aligned with other SpendWise screens) ---
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
                          delayMs: 150,
                          child: _buildIntroText(context),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 250,
                          child: _buildFileTypeCard(
                            context: context,
                            icon: Icons.table_chart,
                            title: 'Import CSV',
                            subtitle:
                                'Comma-separated values exported from your bank',
                            iconColor: colorPrimary,
                            iconBgColor: colorPrimaryContainer.withValues(
                              alpha: 0.1,
                            ),
                            onTap: () => _handleImportCsv(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        EntranceAnimation(
                          delayMs: 320,
                          child: _buildFileTypeCard(
                            context: context,
                            icon: Icons.grid_on,
                            title: 'Import Excel (.xlsx)',
                            subtitle:
                                'Spreadsheet workbook exported from your bank',
                            iconColor: colorSecondary,
                            iconBgColor: colorSecondaryFixed.withValues(
                              alpha: 0.3,
                            ),
                            onTap: () => _handleImportExcel(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        EntranceAnimation(
                          delayMs: 390,
                          child: _buildFileTypeCard(
                            context: context,
                            icon: Icons.picture_as_pdf,
                            title: 'Import PDF',
                            subtitle:
                                'Text-based statement from your bank',
                            iconColor: colorSecondary,
                            iconBgColor: colorSecondaryFixed.withValues(
                              alpha: 0.3,
                            ),
                            onTap: () => _handleImportPdf(context),
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

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface.withValues(alpha: 0.95),
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
                  color: colorScheme.primary,
                  size: 28,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),
              Text(
                'Import Statement',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Intro heading and helper text for the import flow
  Widget _buildIntroText(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Import Bank Statement',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a file type to begin importing your bank statement.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Large tappable file type card following the SpendWise card language
  Widget _buildFileTypeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.surfaceContainerLow),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right,
                color: colorScheme.secondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
