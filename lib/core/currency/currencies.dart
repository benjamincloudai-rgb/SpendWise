import '../utils/formatters.dart';

/// A selectable currency option shown across SpendWise.
class CurrencyOption {
  final String code;
  final String name;
  final String symbol;

  const CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
  });
}

/// Canonical list of supported currencies.
///
/// The first entry (INR) is the default fallback when no currency is stored.
const List<CurrencyOption> currencyOptions = [
  CurrencyOption(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
  CurrencyOption(code: 'USD', name: 'US Dollar', symbol: r'$'),
  CurrencyOption(code: 'EUR', name: 'Euro', symbol: '€'),
  CurrencyOption(code: 'GBP', name: 'British Pound', symbol: '£'),
  CurrencyOption(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
  CurrencyOption(code: 'CAD', name: 'Canadian Dollar', symbol: r'C$'),
  CurrencyOption(code: 'AUD', name: 'Australian Dollar', symbol: r'A$'),
  CurrencyOption(code: 'AED', name: 'UAE Dirham', symbol: 'AED'),
  CurrencyOption(code: 'SGD', name: 'Singapore Dollar', symbol: 'SGD'),
  CurrencyOption(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF'),
];

/// Resolves a [CurrencyOption] from its ISO code, falling back to INR.
CurrencyOption currencyOptionFor(String code) {
  for (final option in currencyOptions) {
    if (option.code == code) return option;
  }
  return currencyOptions.first;
}

/// Returns the display symbol for [code], e.g. `₹`, `$`, `€`.
String currencySymbolFor(String code) => currencyOptionFor(code).symbol;

/// Returns a human-friendly label for [code], e.g. `Indian Rupee (₹)`.
String currencyLabelFor(String code) {
  final option = currencyOptionFor(code);
  return '${option.name} (${option.symbol})';
}

/// The single source of truth for displaying money in SpendWise.
///
/// Returns the selected currency symbol followed by the amount formatted
/// with Indian-style comma grouping. No exchange-rate conversion is applied;
/// only the symbol changes and amounts remain identical.
String formatCurrency(double amount, String code) {
  return '${currencySymbolFor(code)}${formatAmount(amount)}';
}
