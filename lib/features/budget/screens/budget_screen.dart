import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/utils/formatters.dart';
import 'package:spendwise/features/categories/domain/category_visuals.dart';
import 'package:spendwise/models/budget_model.dart';
import 'package:spendwise/models/category_model.dart';
import 'package:spendwise/services/budget_service.dart';
import 'package:spendwise/services/category_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  DateTime _selectedMonth = DateTime.now(); // Selected month shown in overview

  // Budget data loaded live from Firestore
  final BudgetService _budgetService = BudgetService();
  late final Stream<List<BudgetModel>> _budgetsStream;
  StreamSubscription<List<BudgetModel>>? _budgetSub;
  List<BudgetModel> _budgets = [];

  // Budgets for the currently selected month
  List<BudgetModel> get _visibleBudgets => _budgets
      .where((b) => b.period == _selectedMonth.year * 100 + _selectedMonth.month)
      .toList();

  // Strict colors matching the SpendWise design system
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

  // Secondary, Tertiary, and Error colors matching specs
  final Color colorSecondary = const Color(0xFF565E74);
  final Color colorTertiary = const Color(0xFF505F76);
  final Color colorError = const Color(0xFFBA1A1A);
  final Color colorErrorContainer = const Color(0xFFFFDAD6);

  // Category data loaded live from Firestore
  final CategoryService _categoryService = CategoryService();
  late final Stream<List<CategoryModel>> _categoriesStream;
  StreamSubscription<List<CategoryModel>>? _categorySub;
  List<CategoryModel> _categories = [];

  // Expense-only categories available for the budget picker
  List<CategoryModel> get _visibleCategories =>
      _categories.where((c) => c.type == CategoryType.expense).toList();

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _categoriesStream = _categoryService.getCategories();
    _categorySub = _categoriesStream.listen(
      (categories) {
        if (mounted) {
          setState(() {
            _categories = categories;
          });
        }
      },
      onError: (Object error) {
        debugPrint('Failed to load categories: $error');
      },
    );

    _budgetsStream = _budgetService.getBudgets();
    _budgetSub = _budgetsStream.listen(
      (budgets) {
        if (mounted) {
          setState(() {
            _budgets = budgets;
          });
        }
      },
      onError: (Object error) {
        debugPrint('Failed to load budgets: $error');
      },
    );
  }

  @override
  void dispose() {
    _budgetSub?.cancel();
    _categorySub?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  // Reactive computed overview metrics
  double get _totalBudget =>
      _visibleBudgets.fold(0.0, (sum, b) => sum + b.budgetAmount);
  double get _totalSpent =>
      _visibleBudgets.fold(0.0, (sum, b) => sum + b.spentAmount);
  double get _totalRemaining => _totalBudget - _totalSpent;
  double get _overallProgressRatio =>
      _totalBudget > 0 ? _totalSpent / _totalBudget : 0.0;
  int get _overallProgressPercentage => (_overallProgressRatio * 100).toInt();

  // Opens the date picker and updates only the displayed month and year
  Future<void> _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF006E2F),
              secondary: Color(0xFF22C55E),
            ),
            iconTheme: const IconThemeData(color: Color(0xFF006E2F)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }

  // Opens category modal sheet selector to add a budget
  void _showAddBudgetSheet() {
    final expenseNames =
        _visibleCategories.map((c) => c.name).toList();
    // Safe default: first expense category, or the custom "Others" entry
    String selectedCategory =
        expenseNames.isNotEmpty ? expenseNames.first : 'Others';
    final textControllerCategory = TextEditingController();
    final budgetAmountController = TextEditingController();
    final spentAmountController = TextEditingController();
    bool isCustomCategory = expenseNames.isEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: colorSurfaceContainerLowest,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorOutlineVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Add Category Budget',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorOnSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Selection
                    Text(
                      'Category',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: colorSurfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: isCustomCategory ? 'Others' : selectedCategory,
                          isExpanded: true,
                          dropdownColor: colorSurfaceContainerLowest,
                          items: [
                            ..._visibleCategories.map((CategoryModel cat) {
                              return DropdownMenuItem<String>(
                                value: cat.name,
                                child: Text(
                                  cat.name,
                                  style: GoogleFonts.inter(
                                    color: colorOnSurface,
                                  ),
                                ),
                              );
                            }),
                            DropdownMenuItem<String>(
                              value: 'Others',
                              child: Text(
                                'Others',
                                style: GoogleFonts.inter(
                                  color: colorOnSurface,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setModalState(() {
                              if (val == 'Others') {
                                isCustomCategory = true;
                              } else {
                                isCustomCategory = false;
                                selectedCategory = val!;
                              }
                            });
                          },
                        ),
                      ),
                    ),

                    if (isCustomCategory) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Custom Category Name',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: textControllerCategory,
                        decoration: InputDecoration(
                          hintText: 'Enter category name...',
                          hintStyle: GoogleFonts.inter(
                            color: colorTertiary,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: colorSurfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: GoogleFonts.inter(color: colorOnSurface),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Text(
                      'Budget Limit (₹)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: budgetAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: GoogleFonts.inter(
                          color: colorOutlineVariant,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: colorSurfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.inter(color: colorOnSurface),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Current Spent Amount (₹) - Optional',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: spentAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: GoogleFonts.inter(
                          color: colorOutlineVariant,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: colorSurfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.inter(color: colorOnSurface),
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final limitText = budgetAmountController.text.trim();
                        final spentText = spentAmountController.text.trim();
                        final limit = double.tryParse(limitText) ?? 0.0;
                        final spent = double.tryParse(spentText) ?? 0.0;

                        final finalCategoryName = isCustomCategory
                            ? textControllerCategory.text.trim()
                            : selectedCategory;

                        if (finalCategoryName.isNotEmpty && limit > 0) {
                          final period = _selectedMonth.year * 100 +
                              _selectedMonth.month;
                          final alreadyBudgeted = _visibleBudgets.any((b) =>
                              b.categoryName.trim().toLowerCase() ==
                              finalCategoryName.trim().toLowerCase());

                          if (alreadyBudgeted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'A budget for this category already exists for this month.',
                                ),
                              ),
                            );
                          } else {
                            try {
                              await _budgetService.addBudget(
                                BudgetModel(
                                  id: '',
                                  categoryName: finalCategoryName,
                                  budgetAmount: limit,
                                  spentAmount: spent,
                                  period: period,
                                  createdAt: DateTime.now(),
                                ),
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e, stackTrace) {
                              debugPrint('===== BUDGET SAVE ERROR =====');
                              debugPrint(e.toString());
                              debugPrint(stackTrace.toString());

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter a valid category name and budget limit.',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimaryContainer,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 1,
                      ),
                      child: Text(
                        'Create Budget',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
            // --- Atmospheric Background Blurs (Aligned with other screens) ---
            Positioned(
              top: -100,
              right: -100,
              child: _BlurBlob(
                color: colorPrimaryFixed.withOpacity(0.1),
                size: 500,
                blur: 100,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: _BlurBlob(
                color: colorSecondaryFixed.withOpacity(0.2),
                size: 400,
                blur: 80,
              ),
            ),

            // --- Scrollable Form Content ---
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                  top: 76, // Clears top header App Bar
                  bottom: 120, // Clears bottom space securely
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _EntranceAnimation(
                          delayMs: 100,
                          child: _buildOverviewCard(),
                        ),
                        const SizedBox(height: 28),

                        // Header text logic
                        _EntranceAnimation(
                          delayMs: 200,
                          child: _buildCategoryListHeader(),
                        ),
                        const SizedBox(height: 16),

                        // Empty State vs Populated Category Cards List
                        _visibleBudgets.isEmpty
                            ? _EntranceAnimation(
                                delayMs: 250,
                                child: _buildEmptyState(),
                              )
                            : _EntranceAnimation(
                                delayMs: 250,
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _visibleBudgets.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    return _buildCategoryCard(
                                      _visibleBudgets[index],
                                    );
                                  },
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
              child: _EntranceAnimation(
                delayMs: 50,
                child: _buildHeader(context),
              ),
            ),

            // --- Fixed Bottom Action Button ---
            Positioned(
              right: screenWidth * 0.05,
              bottom: 32,
              child: _EntranceAnimation(
                delayMs: 400,
                child: _buildFloatingActionButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header Component
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: colorOnSurface,
                      size: 28,
                    ),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Budget',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorOnSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _showMonthPicker,
                icon: Icon(Icons.calendar_today, color: colorOnSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Overall Budget Metrics Overview Card
  Widget _buildOverviewCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatMonthLabel(_selectedMonth)} ${_selectedMonth.year}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorOnSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Overall spending efficiency',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorSecondary,
                    ),
                  ),
                ],
              ),

              // Dynamic Circular Progress Ring
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _overallProgressRatio.clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: colorSurfaceContainerLow,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _overallProgressRatio >= 1.0
                            ? colorError
                            : colorPrimary,
                      ),
                    ),
                    Text(
                      '$_overallProgressPercentage%',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorOnSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorPrimaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorPrimary.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MONTHLY BUDGET',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorPrimary,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '₹${formatAmount(_totalBudget)}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${formatAmount(_totalSpent)}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: colorOnSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: colorOutlineVariant.withOpacity(0.4),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remaining',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${formatAmount(_totalRemaining)}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: colorPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Header above list of budgets
  Widget _buildCategoryListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Budget Categories',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorOnSurface,
          ),
        ),
        // "VIEW ALL" button has been completely removed as requested
      ],
    );
  }

  // Individual category metrics card
  Widget _buildCategoryCard(BudgetModel item) {
    // Resolve the real Firestore category style where possible;
    // fall back to keyword styling for legacy or deleted categories.
    final categoryMatch = _findCategory(item.categoryName);
    final style = categoryMatch != null
        ? CategoryVisual(
            icon: categoryIconFor(categoryMatch.icon),
            iconColor: Color(categoryMatch.color),
            backgroundColor: Color(categoryMatch.color).withOpacity(0.15),
          )
        : categoryVisualFor(item.categoryName);

    // Dynamic styling based on spent vs budget limits
    Color barColor = colorPrimary;
    Widget? stateBadge;

    if (item.ratio >= 1.0) {
      barColor = colorError;
      stateBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorErrorContainer,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          'OVER BUDGET',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: colorError,
          ),
        ),
      );
    } else if (item.ratio >= 0.8) {
      barColor = Colors.orange.shade700;
      stateBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          'NEAR LIMIT',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: item.ratio >= 1.0
              ? colorError.withOpacity(0.2)
              : colorSurfaceContainerLow,
        ),
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: style.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.categoryName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorOnSurface,
                          ),
                        ),
                        if (stateBadge != null) stateBadge,
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: '₹${formatAmount(item.spentAmount)} ',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorOnSurface,
                            ),
                            children: [
                              TextSpan(
                                text: '/ ₹${formatAmount(item.budgetAmount)}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: colorSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.percentage}%',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: item.ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colorSurfaceContainerLow,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  // Clean empty state with illustrative trigger action button
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: colorSurfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 56,
              color: colorOutlineVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Budgets Yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first monthly budget to start tracking your spending.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: colorSecondary),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _showAddBudgetSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              'Create Budget',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Floating Action button matching application layout system
  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        color: colorPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorPrimary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showAddBudgetSheet,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Add Budget',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Looks up a Firestore category by name (nullable to support fallback)
  CategoryModel? _findCategory(String name) {
    for (final category in _visibleCategories) {
      if (category.name == name) {
        return category;
      }
    }
    return null;
  }
}

// Background blur bubble element
class _BlurBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double blur;

  const _BlurBlob({
    required this.color,
    required this.size,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: blur, spreadRadius: blur / 2),
        ],
      ),
    );
  }
}

// Zero-dependency staggered entrance animation widget
class _EntranceAnimation extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _EntranceAnimation({required this.child, this.delayMs = 0});

  @override
  State<_EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<_EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
