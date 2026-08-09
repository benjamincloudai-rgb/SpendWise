import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/utils/aggregations.dart';
import 'package:spendwise/core/utils/formatters.dart';
import 'package:spendwise/features/statistics/screens/statistics_screen.dart';
import 'package:spendwise/models/transaction_model.dart';
import 'package:spendwise/services/currency_controller.dart';
import 'package:spendwise/services/statistics_service.dart';
import 'package:spendwise/services/transaction_service.dart';

/// Displays the current calendar month's total expense on the Dashboard,
/// compared against the previous month.
///
/// Uses the same Firestore transaction stream pattern as every other screen
/// ([TransactionService.getTransactions]) and delegates all aggregation to the
/// shared helpers used by the Statistics screen, so both screens always agree
/// on what "monthly spending" means.
class MonthlySpendingWidget extends StatelessWidget {
  MonthlySpendingWidget({super.key});

  final TransactionService _transactionService = TransactionService();
  final StatisticsService _statisticsService = StatisticsService();

  @override
  Widget build(BuildContext context) {
    // Strict colors matching the SpendWise design system
    final scheme = Theme.of(context).colorScheme;
    final colorPrimary = scheme.primary;
    final colorOnSurfaceVariant = scheme.onSurfaceVariant;
    final colorOnSurface = scheme.onSurface;
    final colorError = scheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Monthly Spending',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorOnSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StatisticsScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Analysis',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<TransactionModel>>(
          stream: _transactionService.getTransactions(),
          builder: (context, snapshot) {
            // Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildCardShell(
                context,
                child: SizedBox(
                  height: 84,
                  child: Center(
                    child: CircularProgressIndicator(color: colorPrimary),
                  ),
                ),
              );
            }

            // Error State
            if (snapshot.hasError) {
              return _buildCardShell(
                context,
                child: SizedBox(
                  height: 84,
                  child: Center(
                    child: Text(
                      'Unable to load spending data',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colorError,
                      ),
                    ),
                  ),
                ),
              );
            }

            final transactions = snapshot.data ?? [];

            final DateTime now = DateTime.now();
            final summary = _statisticsService.computeMonthSummary(
              transactions,
              now,
            );
            final comparison = _statisticsService.computeMonthComparison(
              transactions,
              now,
            );
            final DateTime previousMonthDate = previousMonth(now);
            final String amount = CurrencyController.instance.format(
              summary.expense,
            );

            final bool hasSpending = summary.expense > 0;

            return _buildCardShell(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main amount
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      amount,
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: colorOnSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  hasSpending
                      ? _buildComparisonLine(
                          comparison.expense.percentChange,
                          previousMonthDate,
                          colorError,
                          colorPrimary,
                          colorOnSurfaceVariant,
                        )
                      : Text(
                          'No expenses recorded this month',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colorOnSurfaceVariant,
                          ),
                        ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Shared card shell matching the Dashboard's Overview Card visual language.
  Widget _buildCardShell(BuildContext context, {required Widget child}) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.surfaceContainerLow),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Previous-month comparison line. Renders a delta chip plus the previous
  /// month label, or a muted "no data" message when the previous month has no
  /// expenses ([percentChange] is null).
  Widget _buildComparisonLine(
    double? percentChange,
    DateTime previousMonthDate,
    Color colorError,
    Color colorPrimary,
    Color colorOnSurfaceVariant,
  ) {
    if (percentChange == null) {
      return Row(
        children: [
          Icon(Icons.trending_flat, size: 16, color: colorOnSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'No previous month data',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colorOnSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    final bool isIncrease = percentChange > 0;
    final Color deltaColor = isIncrease ? colorError : colorPrimary;

    return Row(
      children: [
        Icon(
          isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
          size: 16,
          color: deltaColor,
        ),
        const SizedBox(width: 4),
        Text(
          '${percentChange.abs().toStringAsFixed(0)}%',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: deltaColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'vs ${formatMonthYear(previousMonthDate)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colorOnSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
