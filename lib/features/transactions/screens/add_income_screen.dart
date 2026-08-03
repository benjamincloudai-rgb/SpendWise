import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spendwise/models/transaction_model.dart';
import 'package:spendwise/services/transaction_service.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TransactionService _transactionService = TransactionService();

  // Selected state variables
  String _selectedCategory = '💼 Salary';
  IconData _selectedCategoryIcon = Icons.account_balance_wallet_outlined;
  DateTime _selectedDate = DateTime.now();
  String _selectedRepeat = 'One Time'; // Local UI state variable

  // Theme colors consistent with the SpendWise dashboard
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

  // Secondary, Tertiary, and Outline colors matching SpendWise specifications
  final Color colorSecondary = const Color(0xFF565E74);
  final Color colorTertiary = const Color(0xFF505F76);
  final Color colorOutline = const Color(0xFF6D7B6C);

  // Income categories list mapped with Material Icons and custom colors
  final List<_CategoryItem> _categories = [
    _CategoryItem(
      '💼 Salary',
      Icons.account_balance_wallet_outlined,
      color: Colors.green,
    ),
    _CategoryItem('💻 Freelance', Icons.laptop, color: Colors.teal),
    _CategoryItem('🏪 Business', Icons.storefront, color: Colors.amber),
    _CategoryItem(
      '📈 Investments',
      Icons.trending_up,
      color: Colors.lightGreen,
    ),
    _CategoryItem('🧮 Interest', Icons.percent, color: Colors.blueGrey),
    _CategoryItem('🎁 Bonus', Icons.card_giftcard, color: Colors.pink),
    _CategoryItem(
      '🏠 Rental Income',
      Icons.home_outlined,
      color: Colors.indigo,
    ),
    _CategoryItem(
      '🎨 Gift',
      Icons.featured_play_list_outlined,
      color: Colors.purple,
    ),
    _CategoryItem(
      '🐷 Cashback',
      Icons.savings_outlined,
      color: Colors.deepOrange,
    ),
    _CategoryItem('↩ Refund', Icons.replay, color: Colors.red),
  ];

  Future<void> _saveIncome() async {
    try {
      final amount = double.parse(_amountController.text.trim());

      final transaction = TransactionModel(
        id: '',
        amount: amount,
        categoryId: _selectedCategory,
        note: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        type: TransactionType.income, // Strictly set to Income type
        source: TransactionSource.manual,
        date: _selectedDate,
        createdAt: DateTime.now(),
      );

      await _transactionService.addTransaction(transaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income added successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _floatController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Helper validation computed getter
  bool get _isAmountValid {
    final text = _amountController.text.trim();
    if (text.isEmpty) return false;
    final amount = double.tryParse(text);
    return amount != null && amount > 0;
  }

  // Evaluates display date name dynamically
  String _getFormattedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (target == today) {
      return "Today";
    } else if (target == yesterday) {
      return "Yesterday";
    } else {
      final months = [
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
      return "${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}";
    }
  }

  // Opens the system date picker dialog
  Future<void> _showDatePicker() async {
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

  // Opens custom category dialog when "Other..." is tapped
  void _showCustomCategoryDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorSurfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Custom Category',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: colorOnSurface,
            ),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter category name',
              hintStyle: GoogleFonts.inter(color: colorTertiary),
              filled: true,
              fillColor: colorSurfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: GoogleFonts.inter(color: colorOnSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: colorSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final customName = textController.text.trim();
                if (customName.isNotEmpty) {
                  setState(() {
                    _selectedCategory = '➕ $customName';
                    _selectedCategoryIcon = Icons.category_outlined;
                  });
                }
                Navigator.pop(context);
              },
              child: Text(
                'Add',
                style: GoogleFonts.inter(
                  color: colorPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Opens category modal sheet selector
  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: colorSurfaceContainerLowest,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorOutlineVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Category',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorOnSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _categories.length) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colorSecondary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              color: colorSecondary,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            'Other...',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorOnSurface,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showCustomCategoryDialog();
                          },
                        );
                      }

                      final category = _categories[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (category.color ?? colorPrimary).withOpacity(
                              0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color ?? colorPrimary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorOnSurface,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedCategory = category.name;
                            _selectedCategoryIcon = category.icon;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
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
            // --- Subtle Atmospheric Background Blurs (Exact match to Dashboard) ---
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
                  top: 92, // Scaled safe app bar padding
                  bottom: 180, // Clears sticky bottom actions securely
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.035),

                        _EntranceAnimation(
                          delayMs: 150,
                          child: _buildAmountSection(),
                        ),

                        SizedBox(height: screenHeight * 0.04),

                        // Animated card entries
                        _EntranceAnimation(
                          delayMs: 250,
                          child: _buildCategorySelector(),
                        ),
                        const SizedBox(height: 16),
                        _EntranceAnimation(
                          delayMs: 320,
                          child: _buildDateSelector(),
                        ),
                        const SizedBox(height: 16),
                        _EntranceAnimation(
                          delayMs: 380,
                          child: _buildRepeatSelector(),
                        ),
                        const SizedBox(height: 16),
                        _EntranceAnimation(
                          delayMs: 440,
                          child: _buildNotesInput(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- Sticky Top Header with Entrance Animation ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _EntranceAnimation(
                delayMs: 50,
                child: _buildHeader(context),
              ),
            ),

            // --- Fixed Bottom Action Button Bar with Staggered Entrance ---
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _EntranceAnimation(
                delayMs: 500,
                child: _buildBottomActions(context),
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
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: colorPrimary, size: 28),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),
              Text(
                'Add Income', // Styled exactly like Add Expense with correct label
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorOnSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Amount Entry Section with high-contrast input rendering
  Widget _buildAmountSection() {
    return Column(
      children: [
        Text(
          'TOTAL INCOME', // Labeled correctly for income context
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '₹',
              style: GoogleFonts.inter(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: colorPrimary,
              ),
            ),
            const SizedBox(width: 10),
            IntrinsicWidth(
              child: TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  color: colorOnSurface,
                  letterSpacing: -1.5,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: GoogleFonts.inter(color: colorOutlineVariant),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Category Selector Card
  Widget _buildCategorySelector() {
    return Material(
      color: colorSurfaceContainerLowest,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _showCategoryPicker,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorSurfaceContainerLow),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorPrimaryContainer.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _selectedCategoryIcon,
                      color: colorPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedCategory,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorOnSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(Icons.keyboard_arrow_down, color: colorSecondary, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Date Selection Card
  Widget _buildDateSelector() {
    return Material(
      color: colorSurfaceContainerLowest,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _showDatePicker,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorSurfaceContainerLow),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: colorSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getFormattedDate(),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorOnSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(Icons.keyboard_arrow_down, color: colorSecondary, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Repeat Selector Segmented Control (Presents modern options from HTML layout)
  Widget _buildRepeatSelector() {
    final options = ['One Time', 'Weekly', 'Monthly', 'Quarterly', 'Yearly'];

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat, color: colorSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Repeat Income',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorSurfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: options.map((opt) {
                  final isSelected = _selectedRepeat == opt;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRepeat = opt;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        opt,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? colorPrimary : colorSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Notes Card
  Widget _buildNotesInput() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, color: colorOutline, size: 18),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Add a note...',
              hintStyle: GoogleFonts.inter(color: colorTertiary, fontSize: 16),
              filled: true,
              fillColor: colorSurfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: colorPrimaryContainer.withOpacity(0.2),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: GoogleFonts.inter(fontSize: 16, color: colorOnSurface),
          ),
        ],
      ),
    );
  }

  // Fixed Bottom Actions Container inside the layout stack
  Widget _buildBottomActions(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      color: colorBackground.withOpacity(0.95),
      padding: EdgeInsets.only(
        left: screenWidth * 0.05,
        right: screenWidth * 0.05,
        top: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _isAmountValid ? _saveIncome : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimaryContainer,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: colorPrimaryContainer.withOpacity(
                    0.25,
                  ),
                  disabledForegroundColor: Colors.white.withOpacity(0.6),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 1,
                  shadowColor: Colors.black.withOpacity(0.15),
                ),
                icon: const Icon(Icons.check_circle, size: 24),
                label: Text(
                  'Save Income', // Labeled correctly for income context
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: colorSecondary.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

// Category Item internal mapping configuration class
class _CategoryItem {
  final String name;
  final IconData icon;
  final Color? color;

  _CategoryItem(this.name, this.icon, {this.color});
}
