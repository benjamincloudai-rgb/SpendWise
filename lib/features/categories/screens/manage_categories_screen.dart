import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/utils/aggregations.dart';
import 'package:spendwise/core/widgets/animated_press_card.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/bottom_sheet_handle.dart';
import 'package:spendwise/core/widgets/category_avatar.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';

import '../../../models/category_model.dart';
import '../../../services/category_service.dart';
import '../domain/category_visuals.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  bool _isExpenseSelected = true;

  final CategoryService _categoryService = CategoryService();

  List<CategoryModel> _categories = [];

  late final Stream<List<CategoryModel>> _categoriesStream;

  // Strict colors matching the SpendWise design system
  final Color colorPrimary = const Color(0xFF006E2F);
  final Color colorBackground = const Color(0xFFF9F9F9);
  final Color colorSurfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color colorSurfaceContainerLow = const Color(0xFFF3F3F3);
  final Color colorSurfaceContainer = const Color(0xFFEEEEEE);
  final Color colorOnSurfaceVariant = const Color(0xFF3D4A3D);
  final Color colorOnSurface = const Color(0xFF1A1C1C);
  final Color colorPrimaryFixed = const Color(0xFF6BFF8F);
  final Color colorSecondaryFixed = const Color(0xFFDAE2FD);
  final Color colorOutlineVariant = const Color(0xFFBCCBB9);

  // Secondary and Tertiary colors matching specs
  final Color colorSecondary = const Color(0xFF565E74);
  final Color colorTertiary = const Color(0xFF505F76);

  @override
  void initState() {
    super.initState();
    _categoriesStream = _categoryService.getCategories();
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

  // Opens a custom bottom sheet to add or edit a category
  void _showAddCategorySheet([CategoryModel? existing]) {
    final nameController = TextEditingController();
    IconData selectedCardIcon = existing != null
        ? categoryIconFor(existing.icon)
        : Icons.category_outlined;
    Color selectedCardColor =
        existing != null ? Color(existing.color) : colorPrimary;

    if (existing != null) {
      nameController.text = existing.name;
    }

    final List<(String, IconData)> iconOptions = categoryIconOptions;

    final List<Color> colorOptions = [
      colorPrimary,
      Colors.orange.shade800,
      Colors.blue.shade800,
      Colors.purple.shade800,
      Colors.pink.shade800,
      Colors.red.shade800,
      Colors.indigo.shade800,
      Colors.teal.shade800,
    ];

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
                    BottomSheetHandle(),
                    const SizedBox(height: 24),
                    Text(
                      existing == null
                          ? 'Create Custom Category'
                          : 'Edit Category',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorOnSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Category Name',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      autofocus: true,
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
                    const SizedBox(height: 20),
                    Text(
                      'Choose Icon',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: iconOptions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final icon = iconOptions[index].$2;
                          final isSelected = selectedCardIcon == icon;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedCardIcon = icon;
                              });
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorPrimary.withOpacity(0.1)
                                    : colorSurfaceContainerLow,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: colorPrimary, width: 2)
                                    : null,
                              ),
                              child: Icon(
                                icon,
                                color: isSelected
                                    ? colorPrimary
                                    : colorSecondary,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Choose Theme Color',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: colorOptions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final color = colorOptions[index];
                          final isSelected = selectedCardColor == color;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedCardColor = color;
                              });
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () {
                        final enteredName = nameController.text.trim();
                        if (enteredName.isNotEmpty) {
                          final type = _isExpenseSelected
                              ? CategoryType.expense
                              : CategoryType.income;
                          final category = CategoryModel(
                            id: existing?.id ?? '',
                            name: enteredName,
                            icon: categoryKeyFor(selectedCardIcon),
                            color: selectedCardColor.toARGB32(),
                            type: type,
                            sortOrder: existing?.sortOrder ??
                                nextSortOrder(_categories, type),
                            createdAt: existing?.createdAt ?? DateTime.now(),
                          );
                          _saveCategory(category, isEditing: existing != null);
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a category name.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 1,
                      ),
                      child: Text(
                        existing == null ? 'Create Category' : 'Save Category',
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

  Future<void> _saveCategory(CategoryModel category,
      {required bool isEditing}) async {
    try {
      if (isEditing) {
        await _categoryService.updateCategory(category);
      } else {
        await _categoryService.addCategory(category);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Failed to update category'
                  : 'Failed to add category',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // --- Atmospheric Background Blurs (Aligned with your other screens) ---
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
                  top: 92, // Clears top sticky App Bar with subtitle spacing
                  bottom: 40, // Secure padding at the bottom
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Segmented Toggle
                        EntranceAnimation(
                          delayMs: 100,
                          child: _buildSegmentedToggle(),
                        ),
                        const SizedBox(height: 24),

                        // Empty State vs Populated Category Cards List
                        StreamBuilder<List<CategoryModel>>(
                          stream: _categoriesStream,
                          builder: (context, snapshot) {
                            _categories = snapshot.data ?? [];

                            if (snapshot.hasError) {
                              return EntranceAnimation(
                                delayMs: 180,
                                child: _buildEmptyState(),
                              );
                            }

                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                _categories.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 60),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final activeList = _isExpenseSelected
                                ? _categories
                                    .where(
                                        (c) => c.type == CategoryType.expense)
                                    .toList()
                                : _categories
                                    .where(
                                        (c) => c.type == CategoryType.income)
                                    .toList();

                            return activeList.isEmpty
                                ? EntranceAnimation(
                                    delayMs: 180,
                                    child: _buildEmptyState(),
                                  )
                                : EntranceAnimation(
                                    delayMs: 180,
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: activeList.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        return _buildCategoryCard(
                                          activeList[index],
                                        );
                                      },
                                    ),
                                  );
                          },
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: colorOnSurface, size: 28),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),

              // Header title block nested inside Expanded to avoid squeezing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categories',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Explicitly black
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your income and expense categories',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Responsive Header circular add button
              InkWell(
                onTap: _showAddCategorySheet,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: 44, // Proportional height and width sizing
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorPrimary.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Segmented Toggle Tab Component
  Widget _buildSegmentedToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorSurfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpenseSelected = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isExpenseSelected
                      ? colorSurfaceContainerLowest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isExpenseSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Expense',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isExpenseSelected ? colorPrimary : colorSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpenseSelected = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isExpenseSelected
                      ? colorSurfaceContainerLowest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: !_isExpenseSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Income',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: !_isExpenseSelected ? colorPrimary : colorSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Individual Category Card Widget with Premium Ripple and Press scale animation
  Widget _buildCategoryCard(CategoryModel item) {
    return AnimatedPressCard(
      onTap: () {
        _showAddCategorySheet(item);
      },
      onLongPress: () {
        // Allows user to easily delete categories to test empty states
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: colorSurfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Delete Category',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: colorOnSurface,
                ),
              ),
              content: Text(
                'Are you sure you want to delete "${item.name}"?',
                style: GoogleFonts.inter(color: colorSecondary),
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
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    try {
                      await _categoryService.deleteCategory(item.id);
                    } catch (_) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Failed to delete category'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Delete',
                    style: GoogleFonts.inter(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CategoryAvatar(
              icon: categoryIconFor(item.icon),
              color: Color(item.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorOnSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No transactions',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorSecondary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorOutlineVariant, size: 24),
          ],
        ),
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
              Icons.category_outlined,
              size: 56,
              color: colorOutlineVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Categories Yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first category to organize your finances.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: colorSecondary),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _showAddCategorySheet,
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
              'Add Category',
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
}

