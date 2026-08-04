import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendwise/features/transactions/screens/add_expense_screen.dart';
import 'package:spendwise/features/transactions/screens/add_income_screen.dart';
import 'package:spendwise/features/transactions/screens/transfer_screen.dart';
import 'package:spendwise/features/budget/screens/budget_screen.dart';
import 'package:spendwise/features/transactions/screens/transactions_screen.dart';
import 'package:spendwise/features/statistics/screens/statistics_screen.dart';
import 'package:spendwise/features/profile/screens/profile_screen.dart';
import 'package:spendwise/features/dashboard/widgets/recent_transactions_widget.dart';
import 'package:spendwise/models/dashboard_summary_model.dart';
import 'package:spendwise/services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  String userName = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        setState(() {
          userName = doc['fullName'] ?? 'User';
        });
      }
    } catch (e) {
      debugPrint("Error loading user: $e");
    }
  }

  // Strict colors inherited from the login/register theme
  final Color colorPrimary = const Color(0xFF006E2F);
  final Color colorPrimaryContainer = const Color(0xFF22C55E);
  final Color colorBackground = const Color(0xFFF9F9F9);
  final Color colorSurfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color colorSurfaceContainerLow = const Color(0xFFF3F3F3);
  final Color colorOnSurfaceVariant = const Color(0xFF3D4A3D);
  final Color colorOnSurface = const Color(0xFF1A1C1C);
  final Color colorPrimaryFixed = const Color(0xFF6BFF8F);
  final Color colorSecondaryFixed = const Color(0xFFDAE2FD);
  final Color colorOutlineVariant = const Color(0xFFBCCBB9);

  // Secondary, Tertiary, and Error values matching the HTML specification
  final Color colorSecondary = const Color(0xFF565E74);
  final Color colorTertiary = const Color(0xFF505F76);
  final Color colorTertiaryContainer = const Color(0xFF9DADC6);
  final Color colorError = const Color(0xFFBA1A1A);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // --- Atmospheric Background Blurs (Aligned with Login & Register screens) ---
            Positioned(
              top: -100,
              right: -100,
              child: BlurBlob(
                color: colorPrimaryFixed.withOpacity(0.1),
                size: 500,
                blur: 100,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: BlurBlob(
                color: colorSecondaryFixed.withOpacity(0.2),
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
                  top: 72, // Clears sticky top bar
                  bottom: 120, // Clears bottom navigation
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewCard(),
                        const SizedBox(height: 24),
                        _buildQuickActionsGrid(),
                        const SizedBox(height: 24),
                        _buildMonthlySpendingSection(),
                        const SizedBox(height: 24),
                        RecentTransactionsWidget(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- Sticky Top App Bar ---
            Positioned(top: 0, left: 0, right: 0, child: _buildHeader(context)),
          ],
        ),
      ),
    );
  }

  // Header Component (Top App Bar)
  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      color: colorBackground.withOpacity(0.95),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Hello, $userName 👋",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorOnSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.notifications_none, color: colorSecondary),
              ),
              CircleAvatar(
                backgroundColor: colorSurfaceContainerLow,
                foregroundColor: colorSecondary,
                child: const Icon(Icons.person),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Overview Card Widget (Refactored to cleanly consume DashboardSummaryModel streams)
  Widget _buildOverviewCard() {
    return StreamBuilder<DashboardSummaryModel>(
      stream: _dashboardService.getDashboardSummary(),
      initialData: DashboardSummaryModel.zero(),
      builder: (context, snapshot) {
        final summary = snapshot.data ?? DashboardSummaryModel.zero();

        return Container(
          decoration: BoxDecoration(
            color: colorSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorSurfaceContainerLow),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle overview card internal blur glow
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorPrimary.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT BALANCE',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${summary.currentBalance.toStringAsFixed(0)}",
                      style: GoogleFonts.inter(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: colorOnSurface,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: colorSurfaceContainerLow),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildOverviewColumn(
                          'Income',
                          "₹${summary.totalIncome.toStringAsFixed(0)}",
                          colorPrimary,
                        ),
                        _buildOverviewColumn(
                          'Expenses',
                          "₹${summary.totalExpense.toStringAsFixed(0)}",
                          colorError,
                        ),
                        _buildOverviewColumn(
                          'Savings',
                          "₹${summary.savings.toStringAsFixed(0)}",
                          colorTertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // Quick Actions Grid (2x2 Structure)
  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildQuickActionButton(
          'Add Expense',
          Icons.add_circle,
          colorPrimaryContainer.withOpacity(0.1),
          colorPrimary,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
            );
          },
        ),
        _buildQuickActionButton(
          'Add Income',
          Icons.payments,
          colorSecondaryFixed.withOpacity(0.3),
          colorSecondary,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
            );
          },
        ),
        _buildQuickActionButton(
          'Transfer',
          Icons.sync,
          colorTertiaryContainer.withOpacity(0.2),
          colorTertiary,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            );
          },
        ),
        _buildQuickActionButton(
          'Budget',
          Icons.account_balance_wallet,
          colorOnSurfaceVariant.withOpacity(0.05),
          colorOnSurfaceVariant,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color bgCircleColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorSurfaceContainerLow),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgCircleColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorOnSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Monthly Spending Section with Custom Dashed Empty State
  Widget _buildMonthlySpendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monthly Spending',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorOnSurface,
              ),
            ),
            TextButton(
              onPressed: () {},
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
        CustomPaint(
          painter: _DashedBorderPainter(
            color: colorOutlineVariant.withOpacity(0.5),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: colorSurfaceContainerLow.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Minimal Placeholder Bar Chart Graphic
                SizedBox(
                  height: 128,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildSpendingBar(0.25),
                      const SizedBox(width: 8),
                      _buildSpendingBar(0.50),
                      const SizedBox(width: 8),
                      _buildSpendingBar(0.33),
                      const SizedBox(width: 8),
                      _buildSpendingBar(0.66),
                      const SizedBox(width: 8),
                      _buildSpendingBar(0.50),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No spending data available',
                  style: GoogleFonts.inter(fontSize: 14, color: colorSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingBar(double ratio) {
    return Container(
      width: 24,
      height: 128 * ratio,
      decoration: BoxDecoration(
        color: colorOutlineVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
      ),
    );
  }
}

// Custom painter for dashed borders on card states
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double strokeLength;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.gap = 4.0,
    this.strokeLength = 6.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final extract = metric.extractPath(distance, distance + strokeLength);
        canvas.drawPath(extract, paint);
        distance += strokeLength + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
