import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/core/utils/aggregations.dart';
import 'package:spendwise/models/transaction_model.dart';

TransactionModel _tx({
  required DateTime date,
  double amount = 100,
  TransactionType type = TransactionType.expense,
}) {
  return TransactionModel(
    id: 'tx-${date.year}-${date.month}-${date.day}-$amount-${type.name}',
    amount: amount,
    categoryId: 'Food',
    type: type,
    source: TransactionSource.manual,
    date: date,
    createdAt: date,
  );
}

void main() {
  final january = DateTime(2026, 1, 15);
  final januaryLater = DateTime(2026, 1, 20);
  final february = DateTime(2026, 2, 3);
  final decemberPreviousYear = DateTime(2025, 12, 10);
  final januaryNextYear = DateTime(2027, 1, 5);

  group('isInMonth', () {
    test('returns true for the same year and month', () {
      expect(isInMonth(_tx(date: january), DateTime(2026, 1, 1)), isTrue);
      expect(isInMonth(_tx(date: januaryLater), DateTime(2026, 1, 31)), isTrue);
    });

    test('returns false for another month of the same year', () {
      expect(isInMonth(_tx(date: january), february), isFalse);
    });

    test('returns false for the same month of another year', () {
      expect(isInMonth(_tx(date: january), DateTime(2027, 1, 1)), isFalse);
    });
  });

  group('expenseTotalForMonth', () {
    test('sums the current month expense total', () {
      final transactions = [
        _tx(date: january, amount: 500),
        _tx(date: januaryLater, amount: 250),
      ];
      expect(expenseTotalForMonth(transactions, DateTime(2026, 1, 1)), 750);
    });

    test('excludes income transactions', () {
      final transactions = [
        _tx(date: january, amount: 500),
        _tx(date: january, amount: 1000, type: TransactionType.income),
      ];
      expect(expenseTotalForMonth(transactions, DateTime(2026, 1, 1)), 500);
    });

    test('sums multiple expense transactions', () {
      final transactions = [
        _tx(date: january, amount: 100),
        _tx(date: january, amount: 200),
        _tx(date: january, amount: 300),
      ];
      expect(expenseTotalForMonth(transactions, DateTime(2026, 1, 1)), 600);
    });

    test('excludes previous months and other years', () {
      final transactions = [
        _tx(date: january, amount: 500),
        _tx(date: decemberPreviousYear, amount: 900),
        _tx(date: januaryNextYear, amount: 700),
      ];
      expect(expenseTotalForMonth(transactions, DateTime(2026, 1, 1)), 500);
    });

    test('returns 0 when the month has no expenses', () {
      final transactions = [
        _tx(date: decemberPreviousYear, amount: 900),
        _tx(date: january, amount: 1000, type: TransactionType.income),
      ];
      expect(expenseTotalForMonth(transactions, february), 0);
    });

    test('handles large amounts', () {
      final transactions = [
        _tx(date: january, amount: 1234567.89),
        _tx(date: january, amount: 9876543.21),
      ];
      expect(
        expenseTotalForMonth(transactions, DateTime(2026, 1, 1)),
        closeTo(11111111.10, 0.001),
      );
    });

    test('mixes income and expense across the month', () {
      final transactions = [
        _tx(date: january, amount: 1000, type: TransactionType.income),
        _tx(date: january, amount: 250),
        _tx(date: januaryLater, amount: 350),
        _tx(date: february, amount: 999),
      ];
      expect(expenseTotalForMonth(transactions, DateTime(2026, 1, 1)), 600);
    });
  });

  group('previousMonth', () {
    test('January resolves to December of the previous year', () {
      final result = previousMonth(DateTime(2026, 1, 15));
      expect(result.year, 2025);
      expect(result.month, 12);
      expect(result.day, 1);
    });

    test('December resolves to November of the same year', () {
      final result = previousMonth(DateTime(2026, 12, 31));
      expect(result.year, 2026);
      expect(result.month, 11);
      expect(result.day, 1);
    });
  });

  group('percentChange', () {
    test('returns null when previous is zero', () {
      expect(percentChange(100, 0), isNull);
      expect(percentChange(0, 0), isNull);
    });

    test('returns a positive percentage when spending increased', () {
      expect(percentChange(120, 100), closeTo(20.0, 0.0001));
    });

    test('returns a negative percentage when spending decreased', () {
      expect(percentChange(80, 100), closeTo(-20.0, 0.0001));
    });

    test('returns -100 when current is zero and previous had spending', () {
      expect(percentChange(0, 100), closeTo(-100.0, 0.0001));
    });
  });
}
