import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

enum TransactionSource { manual, bankImport }

class TransactionModel extends Equatable {
  final String id;
  final double amount;
  final String categoryId;
  final String? note;
  final TransactionType type;
  final TransactionSource source;
  final DateTime date;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.type,
    required this.source,
    required this.date,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    amount,
    categoryId,
    note,
    type,
    source,
    date,
    createdAt,
  ];

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'note': note,
      'type': type.name,
      'source': source.name,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] ?? '',
      note: map['note'],
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      source: map['source'] == 'bankImport'
          ? TransactionSource.bankImport
          : TransactionSource.manual,
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? categoryId,
    String? note,
    TransactionType? type,
    TransactionSource? source,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      type: type ?? this.type,
      source: source ?? this.source,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
  