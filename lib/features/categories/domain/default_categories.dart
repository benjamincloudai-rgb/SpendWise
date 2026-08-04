import '../../../models/category_model.dart';

typedef DefaultCategoryDefinition = ({
  String name,
  String icon,
  int color,
  CategoryType type,
  int sortOrder,
});

const List<DefaultCategoryDefinition> defaultCategories = [
  (name: 'Shopping', icon: 'shopping_bag', color: 0xFFC2185B, type: CategoryType.expense, sortOrder: 0),
  (name: 'Food', icon: 'restaurant', color: 0xFFEF6C00, type: CategoryType.expense, sortOrder: 1),
  (name: 'Bills', icon: 'category', color: 0xFFD32F2F, type: CategoryType.expense, sortOrder: 2),
  (name: 'Entertainment', icon: 'movie', color: 0xFF7B1FA2, type: CategoryType.expense, sortOrder: 3),
  (name: 'Transport', icon: 'directions_car', color: 0xFF1565C0, type: CategoryType.expense, sortOrder: 4),
  (name: 'Health', icon: 'local_hospital', color: 0xFF00897B, type: CategoryType.expense, sortOrder: 5),
  (name: 'Education', icon: 'school', color: 0xFF6D4C41, type: CategoryType.expense, sortOrder: 6),
  (name: 'Rent', icon: 'home', color: 0xFF455A64, type: CategoryType.expense, sortOrder: 7),
  (name: 'Others', icon: 'category', color: 0xFF616161, type: CategoryType.expense, sortOrder: 8),
  (name: 'Salary', icon: 'savings', color: 0xFF388E3C, type: CategoryType.income, sortOrder: 0),
  (name: 'Freelance', icon: 'category', color: 0xFF303F9F, type: CategoryType.income, sortOrder: 1),
  (name: 'Investment', icon: 'category', color: 0xFFF57C00, type: CategoryType.income, sortOrder: 2),
  (name: 'Other', icon: 'category', color: 0xFF757575, type: CategoryType.income, sortOrder: 3),
];
