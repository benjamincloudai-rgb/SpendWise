import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/utils/formatters.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;

  // Selected state variables
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeframe = 'Week';

  // Strict colors matching the SpendWise design system
  final Color colorPrimary = const Color(0xFF006E2F);
  final Color colorPrimaryContainer = const Color(0xFF22C55E);
  final Color colorBackground = const Color(0xFFF9F9F9);
  final Color colorSurfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color colorSurfaceContainerLow = const Color(0xFFF3F3F3);
  final Color colorSurfaceContainer = const Color(0xFFEEEEEE);
  final Color colorOnSurfaceVariant = const Color(0xFF3D4A3D);
  final Color colorOnSurface = const Color(0xFF1A1C1C);
  final Color colorPrimaryFixed = const Color(0xFF6BFF8F);
  final Color colorSecondaryFixed = const Color(0xFFDAE2FD);
  final Color colorOutlineVariant = const Color(0xFFBCCBB9);

  // Secondary, Tertiary, and Error colors matching specs
  final Color colorSecondary = const Color(0xFF565E74);
  final Color colorTertiary = const Color(0xFF505F76);
  final Color colorError = const Color(0xFFBA1A1A);

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // TODO: Load monthly statistics
    // TODO: Load category breakdown
    // TODO: Load spending trend
    // TODO: Load financial insights
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  // Opens Flutter date picker overlay styled with SpendWise Green theme
  Future<void> _showMonthPicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colorPrimary,
              onPrimary: Colors.white,
              onSurface: colorOnSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: colorPrimary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

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
                  top: 76, // Clears sticky top bar
                  bottom: 32, // Adjusted padding without bottom navigation
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
                          child: _buildFinancialSummaryCard(),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 180,
                          child: _buildSpendingTrendChart(screenHeight),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 240,
                          child: _buildExpenseBreakdown(),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 300,
                          child: _buildMonthlyComparison(),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 360,
                          child: _buildTopCategoriesList(),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 420,
                          child: _buildFinancialInsightsCard(),
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

  // Header Component (Top App Bar - Fixed to prevent horizontal RenderFlex overflows)
  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

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
              // Back Button on the left
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: colorOnSurface, size: 28),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),

              // Statistics title nested inside Expanded to avoid squeezing
              Expanded(
                child: Text(
                  'Statistics',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorOnSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Responsive Month Picker Selector Pill on the right (Unnecessary extra icon deleted)
              InkWell(
                onTap: () => _showMonthPicker(context),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorSurfaceContainerLow,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: colorOutlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatMonthYear(_selectedDate),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorOnSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.expand_more, size: 16, color: colorOnSurface),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Financial Summary Card Component (Zero-initialized)
  Widget _buildFinancialSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryCardColumn('Income', '₹0', colorOnSurface),
          Container(
            width: 1,
            height: 36,
            color: colorOutlineVariant.withOpacity(0.4),
          ),
          _buildSummaryCardColumn('Expenses', '₹0', colorOnSurface),
          Container(
            width: 1,
            height: 36,
            color: colorOutlineVariant.withOpacity(0.4),
          ),
          _buildSummaryCardColumn('Savings', '₹0', colorPrimary, isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryCardColumn(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorOnSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // Spending Trend Chart Section (Pill Selection + Zero Placeholder line chart)
  Widget _buildSpendingTrendChart(double screenHeight) {
    final timeframes = ['Week', 'Month', 'Year'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spending Trend',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorOnSurface,
              ),
            ),

            // Timeframe Segmented Picker
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorSurfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: timeframes.map((tf) {
                  final isSelected = _selectedTimeframe == tf;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTimeframe = tf;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        tf,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? colorPrimary
                              : colorOnSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Zero State Placeholder Chart
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
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
              SizedBox(
                height: 128,
                child: Stack(
                  children: [
                    Center(
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.show_chart,
                          size: 80,
                          color: colorTertiary,
                        ),
                      ),
                    ),

                    // Empty bottom-aligned placeholder bar segments
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: colorOutlineVariant.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (index) {
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorSurfaceContainer,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Weekday Mappings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map(
                  (day) {
                    return Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorOnSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Expense Breakdown (Empty Donut Chart + Category Legends)
  Widget _buildExpenseBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense Breakdown',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorOnSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
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
              // Symmetrical Empty Donut Shape
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 0.0,
                      strokeWidth: 12,
                      backgroundColor: colorSurfaceContainerLow,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorOnSurfaceVariant,
                          ),
                        ),
                        Text(
                          '₹0',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorOnSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Categories Legend Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3.5,
                children: [
                  _buildLegendTile('Food', colorPrimary.withOpacity(0.2)),
                  _buildLegendTile('Shopping', Colors.blue.shade200),
                  _buildLegendTile('Transport', Colors.orange.shade200),
                  _buildLegendTile('Bills', Colors.purple.shade200),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendTile(String name, Color dotColor) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: GoogleFonts.inter(fontSize: 14, color: colorOnSurfaceVariant),
        ),
        const Spacer(),
        Text(
          '0%',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorOnSurface,
          ),
        ),
      ],
    );
  }

  // Monthly Comparison (Income vs Expenses empty bars)
  Widget _buildMonthlyComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Comparison',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorOnSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
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
          child: SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildComparisonColumn('Income', 0.0),
                _buildComparisonColumn('Expenses', 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonColumn(String label, double ratio) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 64,
          height: 100 * ratio.clamp(0.04, 1.0), // Min indicator height of 4px
          decoration: BoxDecoration(
            color: colorSurfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorOnSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // Top Spending Categories list
  Widget _buildTopCategoriesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Categories',
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
                'View All',
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
        Column(
          children: [
            _buildTopCategoryCard(
              'Food',
              '0 transactions',
              '₹0',
              '0%',
              Icons.restaurant,
              colorPrimary.withOpacity(0.1),
              colorPrimary,
            ),
            const SizedBox(height: 12),
            _buildTopCategoryCard(
              'Shopping',
              '0 transactions',
              '₹0',
              '0%',
              Icons.shopping_bag,
              Colors.blue.shade50,
              Colors.blue.shade600,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopCategoryCard(
    String title,
    String count,
    String amount,
    String percentage,
    IconData icon,
    Color bgCircleColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgCircleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorOnSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorOnSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorOnSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                percentage,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Financial Insights Premium Card (Onboarding Mode)
  Widget _buildFinancialInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorPrimary.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lightbulb, color: colorPrimary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Insights',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorOnSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No spending insights yet. Start adding expenses to unlock personalized insights.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorOnSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

