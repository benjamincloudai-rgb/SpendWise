import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/core/utils/aggregations.dart';
import 'package:spendwise/features/transactions/domain/transaction_filters.dart';
import 'package:spendwise/models/transaction_model.dart';

TransactionModel _tx({
  required DateTime date,
  double amount = 100,
  TransactionType type = TransactionType.expense,
  String categoryId = 'Food',
  String? note,
}) {
  return TransactionModel(
    id: 'tx-${date.year}-${date.month}-${date.day}-$amount-${type.name}',
    amount: amount,
    categoryId: categoryId,
    note: note,
    type: type,
    source: TransactionSource.manual,
    date: date,
    createdAt: date,
  );
}

void main() {
  final now = DateTime.now();
  final firstDayOfMonth = DateTime(now.year, now.month, 1);
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
  final previousMonthStart = previousMonth(DateTime(now.year, now.month, 1));

  group('filterTransactions', () {
    test('no filters returns all transactions and preserves order', () {
      final transactions = [
        _tx(date: DateTime(2026, 1, 5)),
        _tx(date: DateTime(2026, 1, 4)),
        _tx(date: DateTime(2026, 1, 3)),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(),
        '',
      );
      expect(result.length, 3);
      expect(result[0].id, transactions[0].id);
      expect(result[1].id, transactions[1].id);
      expect(result[2].id, transactions[2].id);
    });

    test('income filter returns only income transactions', () {
      final transactions = [
        _tx(date: DateTime(2026, 1, 5), type: TransactionType.expense),
        _tx(date: DateTime(2026, 1, 6), type: TransactionType.income),
        _tx(date: DateTime(2026, 1, 7), type: TransactionType.income),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(type: TransactionType.income),
        '',
      );
      expect(result.length, 2);
      expect(result.every((tx) => tx.type == TransactionType.income), isTrue);
    });

    test('expense filter returns only expense transactions', () {
      final transactions = [
        _tx(date: DateTime(2026, 1, 5), type: TransactionType.expense),
        _tx(date: DateTime(2026, 1, 6), type: TransactionType.income),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(type: TransactionType.expense),
        '',
      );
      expect(result.length, 1);
      expect(result.single.type, TransactionType.expense);
    });

    test('single category filter returns only that category', () {
      final transactions = [
        _tx(date: DateTime(2026, 1, 5), categoryId: 'Food'),
        _tx(date: DateTime(2026, 1, 6), categoryId: 'Shopping'),
        _tx(date: DateTime(2026, 1, 7), categoryId: 'Food'),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(selectedCategory: 'Shopping'),
        '',
      );
      expect(result.length, 1);
      expect(result.single.categoryId, 'Shopping');
    });

    test('all categories (null category) returns every transaction', () {
      final transactions = [
        _tx(date: DateTime(2026, 1, 5), categoryId: 'Food'),
        _tx(date: DateTime(2026, 1, 6), categoryId: 'Shopping'),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(),
        '',
      );
      expect(result.length, 2);
    });

    test('current month filter includes transactions in the current month', () {
      final transactions = [
        _tx(date: firstDayOfMonth),
        _tx(date: lastDayOfMonth),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(
          dateFilter: TransactionDateFilter.currentMonth,
        ),
        '',
      );
      expect(result.length, 2);
    });

    test('current month filter excludes the previous month', () {
      final transactions = [
        _tx(date: previousMonthStart),
        _tx(date: lastDayOfMonth),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(
          dateFilter: TransactionDateFilter.currentMonth,
        ),
        '',
      );
      expect(result.length, 1);
      expect(result.single.date.month, now.month);
    });

    test('current month filter handles year boundaries correctly', () {
      final nextMonthStart = DateTime(now.year, now.month + 1, 1);
      final transactions = [
        _tx(date: previousMonthStart), // may cross into the previous year
        _tx(date: lastDayOfMonth),
        _tx(date: nextMonthStart),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(
          dateFilter: TransactionDateFilter.currentMonth,
        ),
        '',
      );
      expect(result.length, 1);
      expect(result.single.date.month, now.month);
    });

    test('custom range returns transactions within the range', () {
      final transactions = [
        _tx(date: DateTime(2026, 1, 9)),
        _tx(date: DateTime(2026, 1, 15)),
        _tx(date: DateTime(2026, 1, 21)),
      ];
      final result = filterTransactions(
        transactions,
        TransactionFilters(
          dateFilter: TransactionDateFilter.custom,
          customStart: DateTime(2026, 1, 10),
          customEnd: DateTime(2026, 1, 20),
        ),
        '',
      );
      expect(result.length, 1);
      expect(result.single.date.day, 15);
    });

    test('custom range includes the start date', () {
      final transactions = [_tx(date: DateTime(2026, 1, 10, 0, 1))];
      final result = filterTransactions(
        transactions,
        TransactionFilters(
          dateFilter: TransactionDateFilter.custom,
          customStart: DateTime(2026, 1, 10),
          customEnd: DateTime(2026, 1, 20),
        ),
        '',
      );
      expect(result.length, 1);
    });

    test('custom range includes the end date', () {
      final transactions = [_tx(date: DateTime(2026, 1, 20, 23, 59))];
      final result = filterTransactions(
        transactions,
        TransactionFilters(
          dateFilter: TransactionDateFilter.custom,
          customStart: DateTime(2026, 1, 10),
          customEnd: DateTime(2026, 1, 20),
        ),
        '',
      );
      expect(result.length, 1);
    });

    test('minimum amount filters out smaller transactions', () {
      final transactions = [
        _tx(date: DateTime(2026, 1, 5), amount: 99.99),
        _tx(date: DateTime(2026, 1, 6), amount: 100.01),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(minAmount: 100),
        '',
      );
      expect(result.length, 1);
      expect(result.single.amount, 100.01);
    });

    test('maximum amount filters out larger transactions', () {
      final transactions = [
        _tx(date: DateTime(2026, 1, 5), amount: 99.99),
        _tx(date: DateTime(2026, 1, 6), amount: 100.01),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(maxAmount: 100),
        '',
      );
      expect(result.length, 1);
      expect(result.single.amount, 99.99);
    });

    test('minimum and maximum amounts bound the results', () {
      final transactions = [
        _tx(date: DateTime(2026, 1, 5), amount: 50),
        _tx(date: DateTime(2026, 1, 6), amount: 150),
        _tx(date: DateTime(2026, 1, 7), amount: 100),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(minAmount: 75, maxAmount: 125),
        '',
      );
      expect(result.length, 1);
      expect(result.single.amount, 100);
    });

    test('null (empty) amounts act as no bounds', () {
      final transactions = [
        _tx(date: DateTime(2026, 1, 5), amount: 5),
        _tx(date: DateTime(2026, 1, 6), amount: 5000),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(),
        '',
      );
      expect(result.length, 2);
    });

    test('a minimum greater than the maximum yields no results', () {
      final transactions = [_tx(date: DateTime(2026, 1, 5), amount: 100)];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(minAmount: 200, maxAmount: 100),
        '',
      );
      expect(result, isEmpty);
    });

    test('combined filters apply AND logic', () {
      final transactions = [
        _tx(
          date: firstDayOfMonth,
          amount: 80,
          categoryId: 'Food',
          type: TransactionType.expense,
        ),
        _tx(
          date: firstDayOfMonth,
          amount: 200,
          categoryId: 'Food',
          type: TransactionType.expense,
        ),
        _tx(
          date: firstDayOfMonth,
          amount: 150,
          categoryId: 'Shopping',
          type: TransactionType.expense,
        ),
        _tx(
          date: DateTime(2026, 1, 5),
          amount: 150,
          categoryId: 'Food',
          type: TransactionType.expense,
        ),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(
          type: TransactionType.expense,
          selectedCategory: 'Food',
          dateFilter: TransactionDateFilter.currentMonth,
          minAmount: 100,
        ),
        '',
      );
      expect(result.length, 1);
      expect(result.single.amount, 200);
    });

    test('search and filters apply together', () {
      final transactions = [
        _tx(
          date: DateTime(2026, 1, 5),
          categoryId: 'Food',
          note: 'Lunch at cafe',
          type: TransactionType.expense,
        ),
        _tx(
          date: DateTime(2026, 1, 6),
          categoryId: 'Food',
          note: 'Dinner',
          type: TransactionType.expense,
        ),
        _tx(
          date: DateTime(2026, 1, 7),
          categoryId: 'Shopping',
          note: 'Lunch box',
          type: TransactionType.expense,
        ),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(selectedCategory: 'Food'),
        'lunch',
      );
      expect(result.length, 1);
      expect(result.single.note, 'Lunch at cafe');
    });

    test('no matching transactions returns an empty list', () {
      final transactions = [
        _tx(date: DateTime(2026, 1, 5), categoryId: 'Food'),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(selectedCategory: 'Shopping'),
        '',
      );
      expect(result, isEmpty);
    });

    test('handles large amounts', () {
      final transactions = [
        _tx(date: DateTime(2026, 1, 5), amount: 1234567.89),
        _tx(date: DateTime(2026, 1, 6), amount: 9876543.21),
        _tx(date: DateTime(2026, 1, 7), amount: 5000000),
      ];
      final result = filterTransactions(
        transactions,
        const TransactionFilters(minAmount: 2000000, maxAmount: 8000000),
        '',
      );
      expect(result.length, 1);
      expect(result.single.amount, 5000000);
    });

    test('filters across different dates and years', () {
      final transactions = [
        _tx(date: DateTime(2025, 6, 1)),
        _tx(date: DateTime(2025, 12, 31)),
        _tx(date: DateTime(2026, 1, 1)),
        _tx(date: DateTime(2026, 6, 2)),
      ];
      final result = filterTransactions(
        transactions,
        TransactionFilters(
          dateFilter: TransactionDateFilter.custom,
          customStart: DateTime(2025, 12, 31),
          customEnd: DateTime(2026, 1, 1),
        ),
        '',
      );
      expect(result.length, 2);
      expect(result[0].date.year, 2025);
      expect(result[1].date.year, 2026);
    });

    test('does not mutate the original transaction list', () {
      final transactions = [
        _tx(date: DateTime(2026, 1, 5), categoryId: 'Food'),
        _tx(date: DateTime(2026, 1, 6), categoryId: 'Shopping'),
        _tx(date: DateTime(2026, 1, 7), categoryId: 'Food'),
      ];
      final original = List<TransactionModel>.from(transactions);

      filterTransactions(
        transactions,
        const TransactionFilters(selectedCategory: 'Food'),
        '',
      );

      expect(identical(transactions, original), isFalse);
      expect(transactions.length, 3);
      for (var i = 0; i < transactions.length; i++) {
        expect(transactions[i].id, original[i].id);
        expect(transactions[i].amount, original[i].amount);
        expect(transactions[i].categoryId, original[i].categoryId);
      }
    });
  });
}
