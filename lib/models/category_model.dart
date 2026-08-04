import 'package:cloud_firestore/cloud_firestore.dart';

enum CategoryType { expense, income }

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final int color;
  final CategoryType type;
  final int sortOrder;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.type = CategoryType.expense,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'type': type.name,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      icon: map['icon'] ?? '',
      color: map['color'] ?? 0,
      type: map['type'] == 'income'
          ? CategoryType.income
          : CategoryType.expense,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    CategoryType? type,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
