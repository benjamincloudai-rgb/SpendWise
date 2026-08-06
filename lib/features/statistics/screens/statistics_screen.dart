import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/theme/app_colors.dart';
import 'package:spendwise/core/utils/formatters.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/models/category_model.dart';
import 'package:spendwise/models/statistics_summary_model.dart';
import 'package:spendwise/models/transaction_model.dart';
import 'package:spendwise/services/statistics_service.dart';
import 'package:spendwise/services/currency_controller.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;

  // Keeps the horizontally scrollable chart bars and their labels in sync
  final ScrollController _chartScrollController = ScrollController();

  // Selected state variables
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeframe = 'Week';
  // Index of the tapped bar within the displayed trend series (null = none)
  int? _selectedTrendIndex;

  // Live statistics data from Firestore
  final StatisticsService _statisticsService = StatisticsService();
  List<TransactionModel> _allTransactions = [];
  StatisticsSummaryModel _monthlySummary = StatisticsSummaryModel.zero();
  List<CategoryModel> _categories = [];
  List<CategorySpending> _categoryBreakdown = [];
  MonthActivity _monthActivity = const MonthActivity(
    totalTransactions: 0,
    expenseCount: 0,
    averageExpense: 0.0,
  );
  MonthComparison _monthComparison = const MonthComparison.zero();
  TransactionModel? _largestExpense;
  int _spendingDays = 0;
  StreamSubscription<List<TransactionModel>>? _transactionsSub;
  StreamSubscription<List<CategoryModel>>? _categoriesSub;

  // Strict colors matching the SpendWise design system
  final Color colorPrimary = AppColors.primary;
  final Color colorPrimaryContainer = AppColors.primaryContainer;
  final Color colorBackground = AppColors.background;
  final Color colorSurfaceContainerLowest = AppColors.surfaceContainerLowest;
  final Color colorSurfaceContainerLow = AppColors.surfaceContainerLow;
  final Color colorSurfaceContainer = AppColors.surfaceContainer;
  final Color colorOnSurfaceVariant = AppColors.onSurfaceVariant;
  final Color colorOnSurface = AppColors.onSurface;
  final Color colorPrimaryFixed = AppColors.primaryFixed;
  final Color colorSecondaryFixed = AppColors.secondaryFixed;
  final Color colorOutlineVariant = AppColors.outlineVariant;

  // Secondary, Tertiary, and Error colors matching specs
  final Color colorSecondary = AppColors.secondary;
  final Color colorTertiary = AppColors.tertiary;
  final Color colorError = AppColors.error;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _transactionsSub = _statisticsService.getTransactions().listen(
      (transactions) {
        if (mounted) {
          setState(() {
            _allTransactions = transactions;
            _monthlySummary = _statisticsService.computeMonthSummary(
              transactions,
              _selectedDate,
            );
            _categoryBreakdown = _statisticsService.computeCategoryBreakdown(
              transactions,
              _categories,
              _selectedDate,
            );
            _monthActivity = _statisticsService.computeMonthActivity(
              transactions,
              _selectedDate,
            );
            _monthComparison = _statisticsService.computeMonthComparison(
              transactions,
              _selectedDate,
            );
            _largestExpense = _statisticsService.computeLargestExpense(
              transactions,
              _selectedDate,
            );
            _spendingDays = _statisticsService.computeSpendingDays(
              transactions,
              _selectedDate,
            );
          });
        }
      },
      onError: (Object error) {
        debugPrint('Failed to load statistics transactions: $error');
      },
    );

    _categoriesSub = _statisticsService.getCategories().listen(
      (categories) {
        if (mounted) {
          setState(() {
            _categories = categories;
            _categoryBreakdown = _statisticsService.computeCategoryBreakdown(
              _allTransactions,
              categories,
              _selectedDate,
            );
          });
        }
      },
      onError: (Object error) {
        debugPrint('Failed to load statistics categories: $error');
      },
    );
  }

  @override
  void dispose() {
    _transactionsSub?.cancel();
    _categoriesSub?.cancel();
    _chartScrollController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  // Resets the shared chart scroll offset when switching timeframe/month so
  // the next chart never starts mid-scroll.
  void _resetChartScroll() {
    if (_chartScrollController.hasClients) {
      _chartScrollController.jumpTo(0);
    }
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
      _resetChartScroll();
      setState(() {
        _selectedDate = picked;
        _selectedTrendIndex = null;
        _monthlySummary = _statisticsService.computeMonthSummary(
          _allTransactions,
          picked,
        );
        _categoryBreakdown = _statisticsService.computeCategoryBreakdown(
          _allTransactions,
          _categories,
          picked,
        );
        _monthActivity = _statisticsService.computeMonthActivity(
          _allTransactions,
          picked,
        );
        _monthComparison = _statisticsService.computeMonthComparison(
          _allTransactions,
          picked,
        );
        _largestExpense = _statisticsService.computeLargestExpense(
          _allTransactions,
          picked,
        );
        _spendingDays = _statisticsService.computeSpendingDays(
          _allTransactions,
          picked,
        );
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
          _buildSummaryCardColumn(
            'Income',
            CurrencyController.instance.format(_monthlySummary.income),
            colorOnSurface,
          ),
          Container(
            width: 1,
            height: 36,
            color: colorOutlineVariant.withOpacity(0.4),
          ),
          _buildSummaryCardColumn(
            'Expenses',
            CurrencyController.instance.format(_monthlySummary.expense),
            colorOnSurface,
          ),
          Container(
            width: 1,
            height: 36,
            color: colorOutlineVariant.withOpacity(0.4),
          ),
          _buildSummaryCardColumn(
            'Savings',
            CurrencyController.instance.format(_monthlySummary.savings),
            colorPrimary,
            isBold: true,
          ),
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

  // Spending Trend Chart Section (Pill Selection + Bar Chart)
  Widget _buildSpendingTrendChart(double screenHeight) {
    final timeframes = ['Week', 'Month', 'Year'];

    // Real trend series for the selected month/year and timeframe
    final trend = _statisticsService.computeTrendSeries(
      _allTransactions,
      _selectedDate,
      _selectedTimeframe,
    );
    final hasTrendData = trend.any((point) => point.amount > 0);
    final double maxTrendAmount = trend.fold(
      0.0,
      (max, point) => point.amount > max ? point.amount : max,
    );

    // Preserve the exact original zero-state (7 grey Mon-Sun bars)
    const emptyTrend = [
      TrendPoint(label: 'Mon', amount: 0),
      TrendPoint(label: 'Tue', amount: 0),
      TrendPoint(label: 'Wed', amount: 0),
      TrendPoint(label: 'Thu', amount: 0),
      TrendPoint(label: 'Fri', amount: 0),
      TrendPoint(label: 'Sat', amount: 0),
      TrendPoint(label: 'Sun', amount: 0),
    ];
    final displayTrend = hasTrendData ? trend : emptyTrend;

    // Selected bar detail, read straight from the already-computed series
    // (null when nothing is selected or the index is out of range).
    final TrendPoint? selectedPoint =
        _selectedTrendIndex != null &&
            _selectedTrendIndex! >= 0 &&
            _selectedTrendIndex! < displayTrend.length
        ? displayTrend[_selectedTrendIndex!]
        : null;

    // Month and Year carry more buckets than comfortably fit a phone-width
    // card, so the chart area scrolls horizontally (bars + labels together)
    // with fixed slot widths to keep bars and labels readable. The card itself
    // keeps its size; Week and the empty state keep the original fixed layout.
    final bool useScrollableBars =
        hasTrendData && _selectedTimeframe != 'Week';
    final double trendSlotWidth = _trendSlotWidth(
      MediaQuery.sizeOf(context).width,
      _selectedTimeframe,
    );

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
                      _resetChartScroll();
                      setState(() {
                        _selectedTrendIndex = null;
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

        // Spending Trend Bar Chart
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
              // Selected bar detail (amount + label) shown above the chart
              if (selectedPoint != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _trendCaption(selectedPoint),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorOnSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyController.instance.format(selectedPoint.amount),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorOnSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Scrollable Month/Year chart: bars, baseline, and labels live in
              // one horizontally scrollable unit so the whole chart moves
              // together when dragged anywhere inside it.
              if (useScrollableBars)
                Stack(
                  children: [
                    // Faint background icon stays fixed behind the bars area
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 128,
                      child: Center(
                        child: Opacity(
                          opacity: 0.1,
                          child: Icon(
                            Icons.show_chart,
                            size: 80,
                            color: colorTertiary,
                          ),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _chartScrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 128,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                padding: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: colorOutlineVariant.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: displayTrend.asMap().entries.map(
                                    (entry) {
                                      final int index = entry.key;
                                      final point = entry.value;
                                      final hasSpend = point.amount > 0;
                                      final bool isSelected =
                                          _selectedTrendIndex == index;
                                      final double barHeight = hasSpend
                                          ? (point.amount / maxTrendAmount) *
                                              120
                                          : 4;
                                      return GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          setState(() {
                                            _selectedTrendIndex =
                                                isSelected ? null : index;
                                          });
                                        },
                                        child: SizedBox(
                                          width: trendSlotWidth,
                                          child: Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Container(
                                              width: trendSlotWidth - 8,
                                              height: barHeight < 4
                                                  ? 4
                                                  : barHeight,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? colorPrimaryContainer
                                                    : hasSpend
                                                        ? colorPrimary
                                                        : colorSurfaceContainer,
                                                borderRadius: hasTrendData
                                                    ? const BorderRadius
                                                        .vertical(
                                                        top: Radius.circular(8),
                                                      )
                                                    : BorderRadius.circular(
                                                        100,
                                                      ),
                                                boxShadow: isSelected
                                                    ? [
                                                        BoxShadow(
                                                          color: colorPrimary
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                          blurRadius: 8,
                                                          offset:
                                                              const Offset(
                                                                0,
                                                                2,
                                                              ),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ).toList(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: displayTrend.map((point) {
                              return SizedBox(
                                width: trendSlotWidth,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    point.label,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorOnSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
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

                      // Bottom-aligned bar segments scaled to the trend series
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
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: displayTrend.asMap().entries.map(
                              (entry) {
                                final int index = entry.key;
                                final point = entry.value;
                                final hasSpend = point.amount > 0;
                                final bool isSelected =
                                    _selectedTrendIndex == index;
                                final double barHeight = hasSpend
                                    ? (point.amount / maxTrendAmount) * 120
                                    : 4;
                                return Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        _selectedTrendIndex =
                                            isSelected ? null : index;
                                      });
                                    },
                                    child: Container(
                                      height: barHeight < 4 ? 4 : barHeight,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? colorPrimaryContainer
                                            : hasSpend
                                                ? colorPrimary
                                                : colorSurfaceContainer,
                                        borderRadius: hasTrendData
                                            ? const BorderRadius.vertical(
                                                top: Radius.circular(8),
                                              )
                                            : BorderRadius.circular(100),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: colorPrimary
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: displayTrend.map((point) {
                    return Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          point.label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorOnSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Width of a single bar slot for the scrollable Month/Year chart.
  ///
  /// Month days use compact slots that still leave a readable 12px bar. Year
  /// months use wider slots so the month labels never collide; on narrow
  /// cards the chart scrolls horizontally instead of compressing the labels.
  double _trendSlotWidth(double screenWidth, String timeframe) {
    if (timeframe == 'Month') return 20;
    if (timeframe == 'Year') {
      final cardInnerWidth = math.min(screenWidth * 0.9, 440.0) - 48;
      return math.max((cardInnerWidth / 12).floorToDouble(), 32);
    }
    return 0;
  }

  /// Presentation-only caption for the selected bar's amount. Derives a full
  /// label from the existing [TrendPoint.label] plus the selected month; it
  /// never recomputes any total.
  String _trendCaption(TrendPoint point) {
    switch (_selectedTimeframe) {
      case 'Week':
        const fullDays = {
          'Mon': 'Monday',
          'Tue': 'Tuesday',
          'Wed': 'Wednesday',
          'Thu': 'Thursday',
          'Fri': 'Friday',
          'Sat': 'Saturday',
          'Sun': 'Sunday',
        };
        return fullDays[point.label] ?? point.label;
      case 'Month':
        // The synthetic empty-state series carries weekday labels; only
        // decorate numeric day buckets.
        if (int.tryParse(point.label) == null) return point.label;
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${point.label} ${months[_selectedDate.month - 1]}';
      case 'Year':
        const fullMonths = {
          'Jan': 'January',
          'Feb': 'February',
          'Mar': 'March',
          'Apr': 'April',
          'May': 'May',
          'Jun': 'June',
          'Jul': 'July',
          'Aug': 'August',
          'Sep': 'September',
          'Oct': 'October',
          'Nov': 'November',
          'Dec': 'December',
        };
        return fullMonths[point.label] ?? point.label;
      default:
        return point.label;
    }
  }

  // Expense Breakdown (Donut Chart + Category Legends)
  Widget _buildExpenseBreakdown() {
    final breakdown = _categoryBreakdown.take(4).toList();

    // Donut segments reuse the Phase 5C breakdown directly: the same
    // percentages and colors power the legend, Top Categories, and the chart.
    final donutSegments = _categoryBreakdown
        .where((item) => item.percentage > 0)
        .map(
          (item) => (
            sweepFraction: item.percentage / 100,
            color: item.color,
          ),
        )
        .toList();

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
              // Donut Chart (real segments from the category breakdown)
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DonutChartPainter(
                          segments: donutSegments,
                          strokeWidth: 12,
                          backgroundColor: colorSurfaceContainerLow,
                        ),
                      ),
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
                          CurrencyController.instance.format(_monthlySummary.expense),
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
                childAspectRatio: 3.2,
                children: breakdown.isEmpty
                    ? [
                        _buildLegendTile('Food', colorPrimary.withOpacity(0.2), 0.0),
                        _buildLegendTile('Shopping', Colors.blue.shade200, 0.0),
                        _buildLegendTile('Transport', Colors.orange.shade200, 0.0),
                        _buildLegendTile('Bills', Colors.purple.shade200, 0.0),
                      ]
                    : breakdown
                        .map(
                          (item) => _buildLegendTile(
                            item.name,
                            item.color.withValues(alpha: 0.2),
                            item.percentage,
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendTile(String name, Color dotColor, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorOnSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorOnSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Monthly Comparison (Income vs Expenses bars)
  Widget _buildMonthlyComparison() {
    final double income = _monthlySummary.income;
    final double expense = _monthlySummary.expense;
    final double maxValue = income > expense ? income : expense;
    final double incomeRatio = maxValue > 0 ? income / maxValue : 0.0;
    final double expenseRatio = maxValue > 0 ? expense / maxValue : 0.0;

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
            height: 176,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildComparisonColumn(
                  label: 'Income',
                  amount: CurrencyController.instance.format(income),
                  ratio: incomeRatio,
                  color: colorPrimary,
                ),
                _buildComparisonColumn(
                  label: 'Expenses',
                  amount: CurrencyController.instance.format(expense),
                  ratio: expenseRatio,
                  color: colorTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonColumn({
    required String label,
    required String amount,
    required double ratio,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          amount,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorOnSurface,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 64,
          height: 100 * ratio.clamp(0.04, 1.0), // Min indicator height of 4px
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorOnSurfaceVariant,
              ),
            ),
          ],
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
        if (_categoryBreakdown.isEmpty)
          Column(
            children: [
              _buildTopCategoryCard(
                'Food',
                '0 transactions',
                CurrencyController.instance.format(0),
                '0%',
                Icons.restaurant,
                colorPrimary.withOpacity(0.1),
                colorPrimary,
              ),
              const SizedBox(height: 12),
              _buildTopCategoryCard(
                'Shopping',
                '0 transactions',
                CurrencyController.instance.format(0),
                '0%',
                Icons.shopping_bag,
                Colors.blue.shade50,
                Colors.blue.shade600,
              ),
            ],
          )
        else
          Column(
            children: [
              for (var i = 0; i < _categoryBreakdown.length && i < 2; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _buildTopCategoryCard(
                  _categoryBreakdown[i].name,
                  '${_categoryBreakdown[i].count} transactions',
                  CurrencyController.instance.format(_categoryBreakdown[i].amount),
                  '${_categoryBreakdown[i].percentage.toStringAsFixed(0)}%',
                  _categoryBreakdown[i].icon,
                  _categoryBreakdown[i].color.withValues(alpha: 0.1),
                  _categoryBreakdown[i].color,
                ),
              ],
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
                    fontWeight: FontWeight.w700,
                    color: colorOnSurface,
                  ),
                ),
                const SizedBox(height: 6),
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
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colorOnSurface,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorSurfaceContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  percentage,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorOnSurfaceVariant,
                  ),
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
    final bool hasData =
        _monthlySummary.income > 0 || _monthActivity.totalTransactions > 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorPrimary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Text(
                  'Financial Insights',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorOnSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasData)
            Text(
              'No transactions found for this month. Add or import transactions to see your statistics.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorOnSurfaceVariant,
                height: 1.5,
              ),
            )
          else ...[
            _buildInsightRow(
              Icons.trending_up,
              'Savings Rate',
              _monthlySummary.income > 0
                  ? '${_monthlySummary.savingsRate.toStringAsFixed(0)}% of income saved'
                  : '0%',
            ),
            _buildInsightRow(
              Icons.category,
              'Highest Spending Category',
              _categoryBreakdown.isNotEmpty
                  ? _categoryBreakdown.first.name
                  : '—',
            ),
            _buildInsightRow(
              Icons.bolt,
              'Largest Single Expense',
              _largestExpense != null
                  ? CurrencyController.instance.format(_largestExpense!.amount)
                  : '—',
            ),
            _buildInsightRow(
              Icons.calendar_month,
              'Spending Days',
              '$_spendingDays',
            ),
            _buildInsightRow(
              Icons.receipt_long,
              'Total Transactions',
              '${_monthActivity.totalTransactions}',
            ),
            _buildInsightRow(
              Icons.currency_rupee,
              'Average Expense Transaction',
              _monthActivity.expenseCount > 0
                  ? '${CurrencyController.instance.format(_monthActivity.averageExpense)} per transaction'
                  : CurrencyController.instance.format(0),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: colorOutlineVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'vs Last Month',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorOnSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            _buildComparisonRow('Income', _monthComparison.income),
            _buildComparisonRow('Expense', _monthComparison.expense),
            _buildComparisonRow('Savings', _monthComparison.savings),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Icon(icon, color: colorPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorOnSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorOnSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Renders one previous-month comparison row (Income, Expense, or Savings).
  ///
  /// Shows the percent change with a direction icon when the previous month had
  /// a nonzero total; 'New' when the metric exists only in the selected month;
  /// and an em dash when neither month had any value for the metric.
  Widget _buildComparisonRow(String label, MonthDelta delta) {
    final bool hasPrevious = delta.previous > 0;
    final bool hasCurrent = delta.current > 0;
    final IconData icon;
    final String value;
    if (hasPrevious) {
      final double percent = delta.percentChange!;
      if (percent > 0) {
        icon = Icons.trending_up;
        value = '${percent.abs().toStringAsFixed(1)}%';
      } else if (percent < 0) {
        icon = Icons.trending_down;
        value = '${percent.abs().toStringAsFixed(1)}%';
      } else {
        icon = Icons.remove;
        value = '0%';
      }
    } else if (hasCurrent) {
      icon = Icons.add;
      value = 'New';
    } else {
      icon = Icons.remove;
      value = '—';
    }
    return _buildInsightRow(icon, label, value);
  }
}

/// Reusable donut chart painter.
///
/// Draws a grey background ring plus one colored arc per segment. Each segment
/// is a sweep fraction (0.0-1.0 of a full circle) and a color, so the painter
/// stays generic and can be reused for any proportion ring. Consumes the
/// precomputed percentages from [CategorySpending] rather than recalculating
/// them.
class _DonutChartPainter extends CustomPainter {
  final List<({double sweepFraction, Color color})> segments;
  final double strokeWidth;
  final Color backgroundColor;

  const _DonutChartPainter({
    required this.segments,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = backgroundColor;
    canvas.drawCircle(center, radius, backgroundPaint);

    double startAngle = -math.pi / 2;
    for (final segment in segments) {
      if (segment.sweepFraction <= 0) continue;
      final sweepAngle = segment.sweepFraction * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = segment.color;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    if (oldDelegate.strokeWidth != strokeWidth) return true;
    if (oldDelegate.backgroundColor != backgroundColor) return true;
    if (oldDelegate.segments.length != segments.length) return true;
    for (var i = 0; i < segments.length; i++) {
      if (oldDelegate.segments[i] != segments[i]) return true;
    }
    return false;
  }
}

