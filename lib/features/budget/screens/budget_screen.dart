import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- BUDGET CATEGORY DATA MODEL ---
class BudgetCategoryModel {
  final String categoryName;
  final double budgetAmount;
  final double spentAmount;

  BudgetCategoryModel({
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
  });

  double get ratio => budgetAmount > 0 ? spentAmount / budgetAmount : 0.0;
  int get percentage => (ratio * 100).toInt();
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  DateTime _selectedMonth = DateTime.now(); // Selected month shown in overview
  final List<BudgetCategoryModel> _budgets = []; // Initializes completely empty

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

  // Predefined Categories list as required
  final List<String> _categoryOptions = [
    'Food',
    'Shopping',
    'Transport',
    'Bills',
    'Entertainment',
    'Healthcare',
    'Education',
    'Rent',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  // Reactive computed overview metrics
  double get _totalBudget =>
      _budgets.fold(0.0, (sum, b) => sum + b.budgetAmount);
  double get _totalSpent => _budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
  double get _totalRemaining => _totalBudget - _totalSpent;
  double get _overallProgressRatio =>
      _totalBudget > 0 ? _totalSpent / _totalBudget : 0.0;
  int get _overallProgressPercentage => (_overallProgressRatio * 100).toInt();

  // Helper formatting numbers with commas
  String _formatAmount(double amount) {
    final valueString = amount.toStringAsFixed(0);
    return valueString.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Uppercase month label used in the overview card header
  String get _monthLabel {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return months[_selectedMonth.month - 1];
  }

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
    String selectedCategory = _categoryOptions.first;
    final textControllerCategory = TextEditingController();
    final budgetAmountController = TextEditingController();
    final spentAmountController = TextEditingController();
    bool isCustomCategory = false;

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
                          items: _categoryOptions.map((String cat) {
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Text(
                                cat,
                                style: GoogleFonts.inter(color: colorOnSurface),
                              ),
                            );
                          }).toList(),
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
                      onPressed: () {
                        final limitText = budgetAmountController.text.trim();
                        final spentText = spentAmountController.text.trim();
                        final limit = double.tryParse(limitText) ?? 0.0;
                        final spent = double.tryParse(spentText) ?? 0.0;

                        final finalCategoryName = isCustomCategory
                            ? textControllerCategory.text.trim()
                            : selectedCategory;

                        if (finalCategoryName.isNotEmpty && limit > 0) {
                          setState(() {
                            _budgets.add(
                              BudgetCategoryModel(
                                categoryName: finalCategoryName,
                                budgetAmount: limit,
                                spentAmount: spent,
                              ),
                            );
                          });
                          Navigator.pop(context);
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
                        _budgets.isEmpty
                            ? _EntranceAnimation(
                                delayMs: 250,
                                child: _buildEmptyState(),
                              )
                            : _EntranceAnimation(
                                delayMs: 250,
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _budgets.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    return _buildCategoryCard(_budgets[index]);
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
                    '$_monthLabel ${_selectedMonth.year}',
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
                  '₹${_formatAmount(_totalBudget)}',
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
                      '₹${_formatAmount(_totalSpent)}',
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
                      '₹${_formatAmount(_totalRemaining)}',
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
  Widget _buildCategoryCard(BudgetCategoryModel item) {
    final style = _getCategoryStyle(item.categoryName);

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
                            text: '₹${_formatAmount(item.spentAmount)} ',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorOnSurface,
                            ),
                            children: [
                              TextSpan(
                                text: '/ ₹${_formatAmount(item.budgetAmount)}',
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

  // Predefined style categorizer config mapper
  _CategoryStyle _getCategoryStyle(String category) {
    final norm = category.toLowerCase().trim();
    if (norm.contains('food')) {
      return _CategoryStyle(
        Icons.restaurant,
        Colors.orange.shade800,
        Colors.orange.shade50,
      );
    } else if (norm.contains('shopping')) {
      return _CategoryStyle(
        Icons.shopping_bag,
        Colors.pink.shade800,
        Colors.pink.shade50,
      );
    } else if (norm.contains('transport') || norm.contains('commute')) {
      return _CategoryStyle(
        Icons.directions_car,
        Colors.blue.shade800,
        Colors.blue.shade50,
      );
    } else if (norm.contains('bills') || norm.contains('utility')) {
      return _CategoryStyle(
        Icons.payments,
        Colors.indigo.shade800,
        Colors.indigo.shade50,
      );
    } else if (norm.contains('entertainment') || norm.contains('movie')) {
      return _CategoryStyle(
        Icons.movie,
        Colors.purple.shade800,
        Colors.purple.shade50,
      );
    } else if (norm.contains('healthcare') || norm.contains('medical')) {
      return _CategoryStyle(
        Icons.local_hospital,
        Colors.teal.shade800,
        Colors.teal.shade50,
      );
    } else if (norm.contains('education') || norm.contains('school')) {
      return _CategoryStyle(
        Icons.school,
        Colors.brown.shade800,
        Colors.brown.shade50,
      );
    } else if (norm.contains('rent')) {
      return _CategoryStyle(
        Icons.home,
        Colors.amber.shade900,
        Colors.amber.shade50,
      );
    }
    return _CategoryStyle(
      Icons.category,
      Colors.grey.shade800,
      Colors.grey.shade100,
    );
  }
}

// Category Style model structure
class _CategoryStyle {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  _CategoryStyle(this.icon, this.iconColor, this.backgroundColor);
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
