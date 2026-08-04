import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/utils/formatters.dart';
import 'package:spendwise/features/categories/domain/category_visuals.dart';
import 'package:spendwise/models/transaction_model.dart';
import 'package:spendwise/services/transaction_service.dart';
import 'package:spendwise/features/transactions/screens/add_expense_screen.dart';
import 'package:spendwise/features/transactions/screens/add_income_screen.dart';

class RecentTransactionsWidget extends StatelessWidget {
  RecentTransactionsWidget({super.key});

  final TransactionService _transactionService = TransactionService();

  // Strict colors matching the SpendWise design system
  final Color colorPrimary = const Color(0xFF006E2F);
  final Color colorBackground = const Color(0xFFF9F9F9);
  final Color colorSurfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color colorSurfaceContainerLow = const Color(0xFFF3F3F3);
  final Color colorOnSurfaceVariant = const Color(0xFF3D4A3D);
  final Color colorOnSurface = const Color(0xFF1A1C1C);
  final Color colorOutlineVariant = const Color(0xFFBCCBB9);
  final Color colorSecondary = const Color(0xFF565E74);
  final Color colorError = const Color(0xFFBA1A1A);
  final Color colorErrorContainer = const Color(0xFFFFDAD6);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionService.getTransactions(),
      builder: (context, snapshot) {
        // Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorSurfaceContainerLow),
            ),
            child: Center(
              child: CircularProgressIndicator(color: colorPrimary),
            ),
          );
        }

        // Error State
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorError.withOpacity(0.2)),
            ),
            child: Text(
              snapshot.error.toString(),
              style: GoogleFonts.inter(color: colorError),
            ),
          );
        }

        final transactions = snapshot.data ?? [];

        // Empty State
        if (transactions.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            decoration: BoxDecoration(
              color: colorSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorSurfaceContainerLow),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: colorSurfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: colorOutlineVariant.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorOnSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start by adding your first expense.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: colorSecondary),
                ),
              ],
            ),
          );
        }

        // Transaction List View
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorOnSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length > 5 ? 5 : transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final style = categoryVisualFor(tx.categoryId);
                final isExpense = tx.type == TransactionType.expense;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      // Determines appropriate editing form
                      final Widget targetScreen = isExpense
                          ? AddExpenseScreen(transaction: tx)
                          : AddIncomeScreen(transaction: tx);

                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  targetScreen,
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: Tween<double>(begin: 0.0, end: 1.0)
                                      .animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves
                                              .linear, // Symmetric 200ms fade transition
                                        ),
                                      ),
                                  child: child,
                                );
                              },
                          transitionDuration: const Duration(milliseconds: 200),
                          reverseTransitionDuration: const Duration(
                            milliseconds: 200,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorSurfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorSurfaceContainerLow),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: style.backgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              style.icon,
                              color: style.iconColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.categoryId,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colorOnSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tx.note ?? "No note",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: colorOnSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${isExpense ? '- ' : '+ '}₹${formatAmount(tx.amount)}",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isExpense ? colorError : colorPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
