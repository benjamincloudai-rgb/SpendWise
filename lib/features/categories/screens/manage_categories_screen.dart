import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- CATEGORY DATA MODEL ---
class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final int transactionCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.transactionCount,
  });
}

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  bool _isExpenseSelected = true;

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

  // Secondary and Tertiary colors matching specs
  final Color colorSecondary = const Color(0xFF565E74);
  final Color colorTertiary = const Color(0xFF505F76);

  // Predefined lists of active categories
  final List<CategoryModel> _expenseCategories = [
    CategoryModel(
      id: '1',
      name: 'Food',
      icon: Icons.lunch_dining,
      iconColor: Colors.orange.shade800,
      backgroundColor: Colors.orange.shade50,
      transactionCount: 54,
    ),
    CategoryModel(
      id: '2',
      name: 'Transport',
      icon: Icons.local_taxi,
      iconColor: Colors.blue.shade800,
      backgroundColor: Colors.blue.shade50,
      transactionCount: 32,
    ),
    CategoryModel(
      id: '3',
      name: 'Shopping',
      icon: Icons.shopping_cart,
      iconColor: Colors.purple.shade800,
      backgroundColor: Colors.purple.shade50,
      transactionCount: 18,
    ),
    CategoryModel(
      id: '4',
      name: 'Entertainment',
      icon: Icons.movie_outlined,
      iconColor: Colors.pink.shade800,
      backgroundColor: Colors.pink.shade50,
      transactionCount: 22,
    ),
    CategoryModel(
      id: '5',
      name: 'Health',
      icon: Icons.medical_services_outlined,
      iconColor: Colors.red.shade800,
      backgroundColor: Colors.red.shade50,
      transactionCount: 8,
    ),
    CategoryModel(
      id: '6',
      name: 'Bills',
      icon: Icons.home_outlined,
      iconColor: Colors.green.shade800,
      backgroundColor: Colors.green.shade50,
      transactionCount: 12,
    ),
    CategoryModel(
      id: '7',
      name: 'Education',
      icon: Icons.book_outlined,
      iconColor: Colors.indigo.shade800,
      backgroundColor: Colors.indigo.shade50,
      transactionCount: 4,
    ),
    CategoryModel(
      id: '8',
      name: 'Travel',
      icon: Icons.flight_outlined,
      iconColor: Colors.teal.shade800,
      backgroundColor: Colors.teal.shade50,
      transactionCount: 15,
    ),
  ];

  final List<CategoryModel> _incomeCategories = [
    CategoryModel(
      id: '101',
      name: 'Salary',
      icon: Icons.account_balance_wallet_outlined,
      iconColor: const Color(0xFF006E2F),
      backgroundColor: const Color(0xFF22C55E).withOpacity(0.15),
      transactionCount: 12,
    ),
    CategoryModel(
      id: '102',
      name: 'Freelance',
      icon: Icons.laptop,
      iconColor: Colors.teal.shade800,
      backgroundColor: Colors.teal.shade50,
      transactionCount: 24,
    ),
    CategoryModel(
      id: '103',
      name: 'Investments',
      icon: Icons.trending_up,
      iconColor: Colors.blue.shade800,
      backgroundColor: Colors.blue.shade50,
      transactionCount: 6,
    ),
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

  // Opens a custom bottom sheet to add a category dynamically
  void _showAddCategorySheet() {
    final nameController = TextEditingController();
    IconData selectedCardIcon = Icons.category_outlined;
    Color selectedCardColor = colorPrimary;
    Color selectedCardBgColor = colorPrimaryContainer.withOpacity(0.15);

    final List<IconData> iconOptions = [
      Icons.restaurant,
      Icons.shopping_bag,
      Icons.directions_car,
      Icons.movie,
      Icons.local_hospital,
      Icons.home,
      Icons.school,
      Icons.flight,
      Icons.pets,
      Icons.savings,
    ];

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
                      'Create Custom Category',
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
                          final icon = iconOptions[index];
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
                                selectedCardBgColor = color.withOpacity(0.1);
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
                          setState(() {
                            final newCategory = CategoryModel(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              name: enteredName,
                              icon: selectedCardIcon,
                              iconColor: selectedCardColor,
                              backgroundColor: selectedCardBgColor,
                              transactionCount: 0,
                            );
                            if (_isExpenseSelected) {
                              _expenseCategories.add(newCategory);
                            } else {
                              _incomeCategories.add(newCategory);
                            }
                          });
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
                        'Create Category',
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
    final activeList = _isExpenseSelected
        ? _expenseCategories
        : _incomeCategories;

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
                        _EntranceAnimation(
                          delayMs: 100,
                          child: _buildSegmentedToggle(),
                        ),
                        const SizedBox(height: 24),

                        // Empty State vs Populated Category Cards List
                        activeList.isEmpty
                            ? _EntranceAnimation(
                                delayMs: 180,
                                child: _buildEmptyState(),
                              )
                            : _EntranceAnimation(
                                delayMs: 180,
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: activeList.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    return _buildCategoryCard(
                                      activeList[index],
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
    return _AnimatedPressCard(
      onTap: () {
        // Option to edit or view list detail triggers here
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
                  onPressed: () {
                    setState(() {
                      if (_isExpenseSelected) {
                        _expenseCategories.removeWhere((c) => c.id == item.id);
                      } else {
                        _incomeCategories.removeWhere((c) => c.id == item.id);
                      }
                    });
                    Navigator.pop(context);
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.iconColor, size: 24),
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
                    '${item.transactionCount} transactions', // Reduced visual emphasis light grey count
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

// Custom wrapper to add subtle scale and shadow elevation interactions on press
class _AnimatedPressCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _AnimatedPressCard({
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_AnimatedPressCard> createState() => _AnimatedPressCardState();
}

class _AnimatedPressCardState extends State<_AnimatedPressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
