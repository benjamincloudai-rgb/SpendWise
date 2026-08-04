import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String categoryName;
  final double budgetAmount;
  final double spentAmount;
  final int period;
  final DateTime createdAt;

  const BudgetModel({
    required this.id,
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.period,
    required this.createdAt,
  });

  double get ratio => budgetAmount > 0 ? spentAmount / budgetAmount : 0.0;
  int get percentage => (ratio * 100).toInt();

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'budgetAmount': budgetAmount,
      'spentAmount': spentAmount,
      'period': period,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BudgetModel.fromMap(String id, Map<String, dynamic> map) {
    return BudgetModel(
      id: id,
      categoryName: map['categoryName'] ?? '',
      budgetAmount: (map['budgetAmount'] as num?)?.toDouble() ?? 0.0,
      spentAmount: (map['spentAmount'] as num?)?.toDouble() ?? 0.0,
      period: (map['period'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime(2000),
    );
  }

  BudgetModel copyWith({
    String? id,
    String? categoryName,
    double? budgetAmount,
    double? spentAmount,
    int? period,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
