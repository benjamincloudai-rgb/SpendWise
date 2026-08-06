import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/utils/aggregations.dart';
import 'package:spendwise/core/utils/formatters.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/bottom_sheet_handle.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/features/categories/domain/category_visuals.dart';
import 'package:spendwise/models/category_model.dart';
import 'package:spendwise/models/transaction_model.dart';
import 'package:spendwise/services/category_service.dart';
import 'package:spendwise/services/transaction_service.dart';
import 'package:spendwise/services/currency_controller.dart';

class AddExpenseScreen extends StatefulWidget {
  final TransactionModel?
  transaction; // Optional transaction parameter for editing

  const AddExpenseScreen({super.key, this.transaction});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TransactionService _transactionService = TransactionService();

  // Selected state variables
  String _selectedCategory = '🛒 Shopping';
  IconData _selectedCategoryIcon = Icons.shopping_bag;
  DateTime _selectedDate = DateTime.now();
  bool _userPickedCategory = false;

  // Category data from Firestore
  final CategoryService _categoryService = CategoryService();
  late final Stream<List<CategoryModel>> _categoriesStream;
  StreamSubscription<List<CategoryModel>>? _categorySub;
  List<CategoryModel> _categories = [];
  bool _categoriesLoading = true;
  bool _categoriesLoadFailed = false;
  bool _categoryStateInitialized = false;

  // Theme colors consistent with the SpendWise dashboard
  Color get colorPrimary => Theme.of(context).colorScheme.primary;
  Color get colorPrimaryContainer => Theme.of(context).colorScheme.primaryContainer;
  Color get colorBackground => Theme.of(context).colorScheme.surface;
  Color get colorSurfaceContainerLowest =>
      Theme.of(context).colorScheme.surfaceContainerLowest;
  Color get colorSurfaceContainerLow => Theme.of(context).colorScheme.surfaceContainerLow;
  Color get colorOnSurfaceVariant => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get colorOnSurface => Theme.of(context).colorScheme.onSurface;
  Color get colorPrimaryFixed => Theme.of(context).colorScheme.primaryFixed;
  Color get colorSecondaryFixed => Theme.of(context).colorScheme.secondaryFixed;
  Color get colorOutlineVariant => Theme.of(context).colorScheme.outlineVariant;

  // Secondary, Tertiary, and Outline colors matching SpendWise specifications
  Color get colorSecondary => Theme.of(context).colorScheme.secondary;
  Color get colorTertiary => Theme.of(context).colorScheme.tertiary;
  Color get colorOutline => Theme.of(context).colorScheme.outline;

  Future<void> _saveExpense() async {
    try {
      final amount = double.parse(_amountController.text.trim());
      final bool isEditing = widget.transaction != null;

      final transaction = TransactionModel(
        id: isEditing
            ? widget.transaction!.id
            : '', // Preserves original id when updating
        amount: amount,
        categoryId: _selectedCategory,
        note: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        type: TransactionType.expense,
        source: isEditing
            ? widget.transaction!.source
            : TransactionSource.manual,
        date: _selectedDate,
        createdAt: isEditing
            ? widget.transaction!.createdAt
            : DateTime.now(), // Preserves original createdAt
      );

      if (isEditing) {
        await _transactionService.updateTransaction(transaction);
      } else {
        await _transactionService.addTransaction(transaction);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Expense updated successfully!'
                : 'Expense added successfully!',
          ),
        ),
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

    // If editing, pre-fill form properties from existing transaction
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _amountController.text = tx.amount % 1 == 0
          ? tx.amount.toStringAsFixed(0)
          : tx.amount.toString();
      _notesController.text = tx.note ?? '';
      _selectedCategory = tx.categoryId;
      _selectedDate = tx.date;
      _selectedCategoryIcon = Icons.shopping_bag;
    }

    _categoriesStream = _categoryService.getCategories();
    _categorySub = _categoriesStream.listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _categories = list;
          _categoriesLoading = false;
          if (!_categoryStateInitialized) {
            _categoryStateInitialized = true;
            if (widget.transaction != null) {
              _resolveEditCategoryIcon();
            } else if (!_userPickedCategory) {
              _applyFirstCategory();
            }
          }
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _categoriesLoading = false;
          _categoriesLoadFailed = true;
        });
      },
    );

    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _categorySub?.cancel();
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

  // Resolves the icon for the currently selected category (edit pre-fill)
  void _resolveEditCategoryIcon() {
    for (final category in _visibleCategories) {
      if (category.name == _selectedCategory) {
        _selectedCategoryIcon = categoryIconFor(category.icon);
        return;
      }
    }
  }

  // Applies the first available category when a new entry is created
  void _applyFirstCategory() {
    if (_visibleCategories.isEmpty) return;
    final first = _visibleCategories.first;
    _selectedCategory = first.name;
    _selectedCategoryIcon = categoryIconFor(first.icon);
  }

  // Expense-only categories from the Firestore stream
  List<CategoryModel> get _visibleCategories =>
      _categories.where((c) => c.type == CategoryType.expense).toList();

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
              onPressed: () async {
                final customName = textController.text.trim();
                if (customName.isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                final messenger = ScaffoldMessenger.of(context);
                final category = CategoryModel(
                  id: '',
                  name: customName,
                  icon: 'category',
                  color: colorPrimary.toARGB32(),
                  type: CategoryType.expense,
                  sortOrder: nextSortOrder(_categories, CategoryType.expense),
                  createdAt: DateTime.now(),
                );
                try {
                  await _categoryService.addCategory(category);
                } catch (_) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Failed to create category'),
                    ),
                  );
                }
                if (!context.mounted) return;
                Navigator.pop(context);
                if (mounted) {
                  setState(() {
                    _selectedCategory = customName;
                    _selectedCategoryIcon = Icons.category_outlined;
                    _userPickedCategory = true;
                  });
                }
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
                BottomSheetHandle(),
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
                  child: Column(
                    children: [
                      if (_categoriesLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_categoriesLoadFailed)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Couldn\'t load categories. Use "Other..." to create one.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: colorSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_visibleCategories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Text(
                            'No categories yet. Use "Other..." to create one.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: colorSecondary,
                            ),
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _visibleCategories.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _visibleCategories.length) {
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

                            final category = _visibleCategories[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Color(category.color).withOpacity(
                                    0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  categoryIconFor(category.icon),
                                  color: Color(category.color),
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
                                  _selectedCategoryIcon = categoryIconFor(
                                    category.icon,
                                  );
                                  _userPickedCategory = true;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
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

                        EntranceAnimation(
                          delayMs: 150,
                          child: _buildAmountSection(),
                        ),

                        SizedBox(height: screenHeight * 0.04),

                        // Animated card entries
                        EntranceAnimation(
                          delayMs: 250,
                          child: _buildCategorySelector(),
                        ),
                        const SizedBox(height: 16),
                        EntranceAnimation(
                          delayMs: 320,
                          child: _buildDateSelector(),
                        ),
                        const SizedBox(height: 16),
                        EntranceAnimation(
                          delayMs: 380,
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
              child: EntranceAnimation(
                delayMs: 50,
                child: _buildHeader(context),
              ),
            ),

            // --- Fixed Bottom Action Button Bar with Staggered Entrance ---
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: EntranceAnimation(
                delayMs: 440,
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
                widget.transaction != null
                    ? 'Edit Expense'
                    : 'Add Expense', // Dynamic Header title
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
          'TOTAL AMOUNT',
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
              CurrencyController.instance.symbol,
              style: GoogleFonts.inter(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: colorPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
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
                        formatRelativeDate(_selectedDate),
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
                onPressed: _isAmountValid ? _saveExpense : null,
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
                  widget.transaction != null
                      ? 'Update Expense'
                      : 'Save Expense', // Dynamic button text
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


