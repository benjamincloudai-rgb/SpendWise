import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/models/transaction_model.dart';
import 'package:spendwise/services/transaction_service.dart';

class RecentTransactionsWidget extends StatelessWidget {
  RecentTransactionsWidget({super.key});

  final TransactionService _transactionService = TransactionService();

  // Strict colors matching the SpendWise design system
  final Color colorPrimary = const Color(0xFF006E2F);
  final Color colorPrimaryContainer = const Color(0xFF22C55E);
  final Color colorBackground = const Color(0xFFF9F9F9);
  final Color colorSurfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color colorSurfaceContainerLow = const Color(0xFFF3F3F3);
  final Color colorOnSurfaceVariant = const Color(0xFF3D4A3D);
  final Color colorOnSurface = const Color(0xFF1A1C1C);
  final Color colorOutlineVariant = const Color(0xFFBCCBB9);
  final Color colorSecondary = const Color(0xFF565E74);
  final Color colorError = const Color(0xFFBA1A1A);
  final Color colorErrorContainer = const Color(0xFFFFDAD6);

  // Helper formatting numbers with commas
  String _formatAmount(double amount) {
    final valueString = amount.toStringAsFixed(0);
    return valueString.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

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
                final style = _getCategoryStyle(tx.categoryId, tx.type);
                final isExpense = tx.type == TransactionType.expense;

                return Container(
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
                        "${isExpense ? '- ' : '+ '}₹${_formatAmount(tx.amount)}",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isExpense ? colorError : colorPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Categories style configuration mapper matching your app's catalog
  _CategoryStyle _getCategoryStyle(String category, TransactionType type) {
    final normalized = category.toLowerCase().trim();

    IconData icon = Icons.attach_money;
    Color iconColor = colorPrimary;
    Color bgColor = colorPrimaryContainer.withOpacity(0.15);

    if (normalized.contains('food') ||
        normalized.contains('dining') ||
        normalized.contains('restaurant')) {
      icon = Icons.restaurant;
      iconColor = Colors.orange.shade800;
      bgColor = Colors.orange.shade50;
    } else if (normalized.contains('transport') ||
        normalized.contains('commute')) {
      icon = Icons.directions_car_outlined;
      iconColor = Colors.blue.shade800;
      bgColor = Colors.blue.shade50;
    } else if (normalized.contains('shopping')) {
      icon = Icons.shopping_bag_outlined;
      iconColor = Colors.pink.shade800;
      bgColor = Colors.pink.shade50;
    } else if (normalized.contains('bills') ||
        normalized.contains('utilities')) {
      icon = Icons.electrical_services_outlined;
      iconColor = Colors.red.shade800;
      bgColor = Colors.red.shade50;
    } else if (normalized.contains('entertainment') ||
        normalized.contains('movie')) {
      icon = Icons.movie_outlined;
      iconColor = Colors.purple.shade800;
      bgColor = Colors.purple.shade50;
    } else if (normalized.contains('healthcare') ||
        normalized.contains('medical')) {
      icon = Icons.local_hospital_outlined;
      iconColor = Colors.teal.shade800;
      bgColor = Colors.teal.shade50;
    } else if (normalized.contains('travel') || normalized.contains('flight')) {
      icon = Icons.flight_outlined;
      iconColor = Colors.cyan.shade800;
      bgColor = Colors.cyan.shade50;
    } else if (normalized.contains('education') ||
        normalized.contains('school')) {
      icon = Icons.school_outlined;
      iconColor = Colors.brown.shade800;
      bgColor = Colors.brown.shade50;
    } else if (normalized.contains('groceries')) {
      icon = Icons.shopping_basket_outlined;
      iconColor = Colors.amber.shade900;
      bgColor = Colors.amber.shade50;
    } else if (normalized.contains('salary')) {
      icon = Icons.account_balance_wallet_outlined;
      iconColor = colorPrimary;
      bgColor = colorPrimaryContainer.withOpacity(0.15);
    } else if (normalized.contains('freelance') ||
        normalized.contains('work')) {
      icon = Icons.work_outline;
      iconColor = Colors.indigo.shade800;
      bgColor = Colors.indigo.shade50;
    } else if (normalized.contains('investment')) {
      icon = Icons.trending_up_outlined;
      iconColor = Colors.lightGreen.shade800;
      bgColor = Colors.lightGreen.shade50;
    } else if (normalized.contains('business')) {
      icon = Icons.storefront_outlined;
      iconColor = Colors.blueGrey.shade800;
      bgColor = Colors.blueGrey.shade50;
    } else if (normalized.contains('gift')) {
      icon = Icons.card_giftcard_outlined;
      iconColor = Colors.pinkAccent.shade700;
      bgColor = Colors.pink.shade50;
    } else if (normalized.contains('cashback')) {
      icon = Icons.savings_outlined;
      iconColor = Colors.deepOrange.shade800;
      bgColor = Colors.deepOrange.shade50;
    } else if (normalized.contains('transfer')) {
      icon = Icons.swap_horiz;
      iconColor = Colors.blue.shade800;
      bgColor = Colors.blue.shade50;
    } else if (normalized.contains('savings')) {
      icon = Icons.savings_outlined;
      iconColor = Colors.green.shade800;
      bgColor = Colors.green.shade50;
    }

    return _CategoryStyle(icon, iconColor, bgColor);
  }
}

// Inner structure mapping individual category properties
class _CategoryStyle {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  _CategoryStyle(this.icon, this.iconColor, this.backgroundColor);
}
