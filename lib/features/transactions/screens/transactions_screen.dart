import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/models/transaction_model.dart';
import 'package:spendwise/services/transaction_service.dart';
import 'package:spendwise/features/transactions/screens/add_expense_screen.dart';
import 'package:spendwise/features/transactions/screens/add_income_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  final TextEditingController _searchController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  late final Stream<List<TransactionModel>> _transactionsStream;
  String _selectedFilter = 'All';

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
  final Color colorErrorContainer = const Color(0xFFFFDAD6);

  // Dynamically populated via Firestore snapshots stream
  List<TransactionModel> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _transactionsStream = _transactionService.getTransactions();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _floatController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Reactive computed total sums
  double get _totalIncome {
    return _allTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get _totalExpenses {
    return _allTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get _netBalance {
    return _totalIncome - _totalExpenses;
  }

  // Reactive computed transaction filters (Excludes obsolete Transfers filter)
  List<TransactionModel> get _filteredTransactions {
    return _allTransactions.where((tx) {
      if (_selectedFilter == 'Expenses' && tx.type != TransactionType.expense) {
        return false;
      }
      if (_selectedFilter == 'Income' && tx.type != TransactionType.income) {
        return false;
      }

      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final categoryMatch = tx.categoryId.toLowerCase().contains(query);
        final noteMatch = tx.note?.toLowerCase().contains(query) ?? false;
        final amountMatch = tx.amount.toString().contains(query);
        return categoryMatch || noteMatch || amountMatch;
      }
      return true;
    }).toList();
  }

  // Groups transactions by date dynamically
  Map<String, List<TransactionModel>> _groupTransactions(
    List<TransactionModel> list,
  ) {
    final Map<String, List<TransactionModel>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var tx in list) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String groupKey;
      if (txDate == today) {
        groupKey = 'Today';
      } else if (txDate == yesterday) {
        groupKey = 'Yesterday';
      } else {
        groupKey = 'Older';
      }

      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = [];
      }
      groups[groupKey]!.add(tx);
    }
    return groups;
  }

  // Helper formatting numbers with commas
  String _formatAmount(double amount) {
    final valueString = amount.toStringAsFixed(0);
    return valueString.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Formats DateTime value into AM/PM string formats
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute < 10 ? '0$minute' : '$minute';
    return "$displayHour:$displayMinute $amPm";
  }

  // Confirmation dialog before asynchronous document deletion
  void _showDeleteConfirmationDialog(
    BuildContext context,
    TransactionModel tx,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorSurfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Delete Transaction',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: colorOnSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this transaction of ₹${_formatAmount(tx.amount)}?',
            style: GoogleFonts.inter(color: colorSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: colorSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                try {
                  await _transactionService.deleteTransaction(tx.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction deleted successfully!'),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: colorError,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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
            // --- Atmospheric Background Blurs (Exact match to Dashboard) ---
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

            // --- Scrollable main view body with StreamBuilder integration ---
            Positioned.fill(
              child: StreamBuilder<List<TransactionModel>>(
                stream: _transactionsStream,
                builder: (context, snapshot) {
                  // Loading State
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF006E2F),
                      ),
                    );
                  }

                  // Error State
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(
                          color: colorError,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  // Data Extraction
                  _allTransactions = snapshot.data ?? [];
                  final filteredList = _filteredTransactions;
                  final groupedMap = _groupTransactions(filteredList);

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.05,
                      right: screenWidth * 0.05,
                      top: 76, // Clears top header App Bar
                      bottom: 120, // Clears bottom navigation bar securely
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
                              child: _buildSummaryCard(),
                            ),
                            const SizedBox(height: 24),
                            _EntranceAnimation(
                              delayMs: 180,
                              child: _buildSearchBar(),
                            ),
                            const SizedBox(height: 20),
                            _EntranceAnimation(
                              delayMs: 240,
                              child: _buildFilterChips(),
                            ),
                            const SizedBox(height: 24),
                            filteredList.isEmpty
                                ? _EntranceAnimation(
                                    delayMs: 300,
                                    child: _buildEmptyState(),
                                  )
                                : Column(
                                    children: groupedMap.keys.map((groupTitle) {
                                      return _EntranceAnimation(
                                        delayMs: 300,
                                        child: _buildTransactionGroup(
                                          groupTitle,
                                          groupedMap[groupTitle]!,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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

            // --- Fixed Bottom Navigation Bar ---
            
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
                    icon: Icon(Icons.arrow_back, color: colorPrimary, size: 28),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Transactions',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Formatted strictly in black
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.search, color: colorOnSurfaceVariant),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.filter_list, color: colorOnSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Monthly Summary Card
  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
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
              Text(
                'AUGUST 2026',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorOnSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '₹${_formatAmount(_netBalance)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Balance',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorSecondary,
            ),
          ),
          Text(
            '₹${_formatAmount(_netBalance)}',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colorOnSurface,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorPrimaryContainer.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Income',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_formatAmount(_totalIncome)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorErrorContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expenses',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorError,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_formatAmount(_totalExpenses)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorError,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Rounded Search Bar Component
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: colorSurfaceContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(fontSize: 14, color: colorOnSurface),
        decoration: InputDecoration(
          hintText: 'Search by amount, note or category...',
          hintStyle: GoogleFonts.inter(color: colorTertiary, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: colorTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // Filters Selection Pill Chips Row
  Widget _buildFilterChips() {
    final filters = [
      'All',
      'Expenses',
      'Income',
    ]; // Excludes obsolete Transfers filter

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? colorPrimary : colorSurfaceContainer,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorPrimary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : colorOnSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Vertical transaction date group
  Widget _buildTransactionGroup(
    String title,
    List<TransactionModel> transactions,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorOnSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildTransactionCard(transactions[index]);
            },
          ),
        ],
      ),
    );
  }

  // Individual Transaction Card (Redesigned with Inkwell tap routing & long-press delete confirmations)
  Widget _buildTransactionCard(TransactionModel tx) {
    final style = _getCategoryStyle(
      tx.categoryId,
      tx.type,
    ); // Maps exactly to categoryId
    final isExpense = tx.type == TransactionType.expense;
    final isIncome = tx.type == TransactionType.income;

    Color amountColor = Colors.blue.shade700;
    String prefix = '';
    if (isExpense) {
      amountColor = colorError;
      prefix = '- ';
    } else if (isIncome) {
      amountColor = colorPrimary;
      prefix = '+ ';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          // Binds active transaction and routes symmetrically
          final Widget targetScreen = isExpense
              ? AddExpenseScreen(transaction: tx)
              : AddIncomeScreen(transaction: tx);

          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  targetScreen,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves
                              .linear, // Symmetric linear fade transitions
                        ),
                      ),
                      child: child,
                    );
                  },
              transitionDuration: const Duration(milliseconds: 200),
              reverseTransitionDuration: const Duration(milliseconds: 200),
            ),
          );
        },
        onLongPress: () =>
            _showDeleteConfirmationDialog(context, tx), // Deletion Dialog
        child: Container(
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
                child: Icon(style.icon, color: style.iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.categoryId, // Maps exactly to categoryId
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorOnSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_formatTime(tx.date)}${tx.note != null ? ' • ${tx.note}' : ''}", // Maps exactly to date formatter
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
                "$prefix₹${_formatAmount(tx.amount)}",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Empty State Widget when transactions are filtered to zero
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
              Icons.receipt_long,
              size: 56,
              color: colorOutlineVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding expenses and income to build your financial history.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: colorSecondary),
          ),
        ],
      ),
    );
  }

  // Sticky Bottom Navigation Bar (Copied exactly from Dashboard and swapped active tab)
  

  // Style mapper for category circle structures
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

    return _CategoryStyle(
      icon: icon,
      iconColor: iconColor,
      backgroundColor: bgColor,
    );
  }
}

// Category Style model structure
class _CategoryStyle {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  _CategoryStyle({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
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
