/// Shared formatting helpers used across SpendWise screens.
///
/// Each helper is a faithful extraction of the private methods that were
/// previously duplicated in multiple screens, preserving the exact output.
library;

/// Formats a number with Indian-style comma grouping, e.g. `1234567` -> `12,34,567`.
///
/// Matches the previous `_formatAmount` implementations.
String formatAmount(double amount) {
  final valueString = amount.toStringAsFixed(0);
  return valueString.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

/// Formats a [DateTime] into a 12-hour AM/PM string, e.g. `3:05 PM`.
///
/// Matches the previous `_formatTime` implementation.
String formatTime(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute;
  final amPm = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  final displayMinute = minute < 10 ? '0$minute' : '$minute';
  return '$displayHour:$displayMinute $amPm';
}

/// Returns `Today`, `Yesterday`, or a `d Mon yyyy` label for [date].
///
/// Matches the previous `_getFormattedDate` implementations.
String formatRelativeDate(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final target = DateTime(date.year, date.month, date.day);

  if (target == today) {
    return 'Today';
  } else if (target == yesterday) {
    return 'Yesterday';
  } else {
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
}

/// Returns the uppercase full month name, e.g. `JANUARY`.
///
/// Matches the previous `_monthLabel` getter.
String formatMonthLabel(DateTime date) {
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
  return months[date.month - 1];
}

/// Returns the full month name and year, e.g. `January 2026`.
///
/// Matches the previous `_getFormattedSelectedMonth` implementation.
String formatMonthYear(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

/// Returns the numeric month period key `yyyyMM` for [date].
///
/// Matches the inline `year * 100 + month` budget period computations.
int monthPeriodFor(DateTime date) {
  return date.year * 100 + date.month;
}
