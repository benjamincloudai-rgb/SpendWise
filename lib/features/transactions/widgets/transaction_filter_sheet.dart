import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/widgets/bottom_sheet_handle.dart';
import 'package:spendwise/features/categories/domain/category_visuals.dart';
import 'package:spendwise/features/transactions/domain/transaction_filters.dart';
import 'package:spendwise/models/transaction_model.dart';
import 'package:spendwise/services/currency_controller.dart';

/// Modal bottom sheet for filtering transactions.
///
/// Works on a temporary draft of [TransactionFilters] so nothing is committed
/// until the user presses Apply; dismissing or cancelling the sheet keeps the
/// previously active filters intact. Reset restores every control to its
/// default value (All types, All categories, All time, no amount bounds).
class TransactionFilterSheet extends StatefulWidget {
  final TransactionFilters initialFilters;
  final List<String> categoryNames;

  const TransactionFilterSheet({
    super.key,
    required this.initialFilters,
    required this.categoryNames,
  });

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late TransactionFilters _draft;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  String? _amountError;

  Color get colorPrimary => Theme.of(context).colorScheme.primary;
  Color get colorBackground => Theme.of(context).colorScheme.surface;
  Color get colorSurfaceContainerLowest =>
      Theme.of(context).colorScheme.surfaceContainerLowest;
  Color get colorSurfaceContainer =>
      Theme.of(context).colorScheme.surfaceContainer;
  Color get colorOnSurfaceVariant =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  Color get colorOnSurface => Theme.of(context).colorScheme.onSurface;
  Color get colorSecondary => Theme.of(context).colorScheme.secondary;
  Color get colorTertiary => Theme.of(context).colorScheme.tertiary;
  Color get colorError => Theme.of(context).colorScheme.error;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilters;
    _minController = TextEditingController(
      text: widget.initialFilters.minAmount?.toString(),
    );
    _maxController = TextEditingController(
      text: widget.initialFilters.maxAmount?.toString(),
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  double? _parseAmount(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || value < 0) return null;
    return value;
  }

  void _reset() {
    setState(() {
      _draft = const TransactionFilters();
      _minController.clear();
      _maxController.clear();
      _amountError = null;
    });
  }

  void _apply() {
    final minAmount = _parseAmount(_minController);
    final maxAmount = _parseAmount(_maxController);

    if (minAmount != null && maxAmount != null && minAmount > maxAmount) {
      setState(() {
        _amountError = 'Minimum amount cannot exceed maximum amount.';
      });
      return;
    }

    final applied = TransactionFilters(
      type: _draft.type,
      selectedCategory: _draft.selectedCategory,
      dateFilter: _draft.dateFilter,
      customStart: _draft.customStart,
      customEnd: _draft.customEnd,
      minAmount: minAmount,
      maxAmount: maxAmount,
    );

    Navigator.pop(context, applied);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final hasRange = _draft.customStart != null && _draft.customEnd != null;
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      initialDateRange: hasRange
          ? DateTimeRange(start: _draft.customStart!, end: _draft.customEnd!)
          : DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select transaction date range',
    );

    if (range != null) {
      setState(() {
        _draft = _draft.copyWith(
          dateFilter: TransactionDateFilter.custom,
          customStart: range.start,
          customEnd: range.end,
        );
      });
    }
  }

  String _formatRangeDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const BottomSheetHandle(),
            const SizedBox(height: 16),
            Text(
              'Filters',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorOnSurface,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Transaction Type'),
                    const SizedBox(height: 10),
                    _buildTypeChips(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Category'),
                    const SizedBox(height: 10),
                    _buildCategoryWrap(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Date'),
                    const SizedBox(height: 10),
                    _buildDateChips(),
                    if (_draft.dateFilter == TransactionDateFilter.custom) ...[
                      const SizedBox(height: 10),
                      _buildDateRangeTile(),
                    ],
                    const SizedBox(height: 24),
                    _buildSectionLabel('Amount'),
                    const SizedBox(height: 10),
                    _buildAmountFields(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _reset,
                    child: Text(
                      'Reset',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 1,
                      ),
                      child: Text(
                        'Apply Filters',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colorOnSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTypeChips() {
    final options = <(String, TransactionType?)>[
      ('All', null),
      ('Income', TransactionType.income),
      ('Expense', TransactionType.expense),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        return _buildChoiceChip(
          label: option.$1,
          selected: _draft.type == option.$2,
          onTap: () {
            setState(() {
              _draft = _draft.copyWith(
                type: option.$2,
                clearType: option.$2 == null,
              );
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCategoryWrap() {
    if (widget.categoryNames.isEmpty) {
      return Text(
        'No categories yet.',
        style: GoogleFonts.inter(fontSize: 13, color: colorSecondary),
      );
    }

    final chips = <Widget>[
      _buildChoiceChip(
        label: 'All Categories',
        selected: _draft.selectedCategory == null,
        onTap: () {
          setState(() {
            _draft = _draft.copyWith(
              selectedCategory: null,
              clearSelectedCategory: true,
            );
          });
        },
      ),
      for (final name in widget.categoryNames)
        _buildChoiceChip(
          label: name,
          icon: categoryVisualFor(name).icon,
          iconColor: categoryVisualFor(name).iconColor,
          selected: _draft.selectedCategory == name,
          onTap: () {
            setState(() {
              _draft = _draft.copyWith(selectedCategory: name);
            });
          },
        ),
    ];

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _buildDateChips() {
    final options = <(String, TransactionDateFilter)>[
      ('All Time', TransactionDateFilter.all),
      ('Current Month', TransactionDateFilter.currentMonth),
      ('Custom Range', TransactionDateFilter.custom),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        return _buildChoiceChip(
          label: option.$1,
          selected: _draft.dateFilter == option.$2,
          onTap: () {
            setState(() {
              _draft = _draft.copyWith(dateFilter: option.$2);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeTile() {
    final hasRange = _draft.customStart != null && _draft.customEnd != null;
    final label = hasRange
        ? '${_formatRangeDate(_draft.customStart!)} – ${_formatRangeDate(_draft.customEnd!)}'
        : 'Select date range';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickDateRange,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorSurfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.date_range, color: colorPrimary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorOnSurface,
                  ),
                ),
              ),
              Icon(Icons.expand_more, color: colorOnSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildAmountField(_minController, 'Minimum')),
            const SizedBox(width: 12),
            Expanded(child: _buildAmountField(_maxController, 'Maximum')),
          ],
        ),
        if (_amountError != null) ...[
          const SizedBox(height: 8),
          Text(
            _amountError!,
            style: GoogleFonts.inter(fontSize: 12, color: colorError),
          ),
        ],
      ],
    );
  }

  Widget _buildAmountField(TextEditingController controller, String label) {
    return Container(
      decoration: BoxDecoration(
        color: colorSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.inter(fontSize: 14, color: colorOnSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 12, color: colorSecondary),
          hintText: '0.00',
          hintStyle: GoogleFonts.inter(fontSize: 14, color: colorTertiary),
          prefixText: '${CurrencyController.instance.symbol} ',
          prefixStyle: GoogleFonts.inter(
            fontSize: 14,
            color: colorOnSurfaceVariant,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colorPrimary : colorSurfaceContainer,
          borderRadius: BorderRadius.circular(100),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorPrimary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : iconColor ?? colorOnSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : colorOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
