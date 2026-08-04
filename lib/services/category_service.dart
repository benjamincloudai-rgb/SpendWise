import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/categories/domain/default_categories.dart';
import '../models/category_model.dart';
import 'firestore_service.dart';

class CategoryService extends FirestoreService<CategoryModel> {
  CollectionReference<Map<String, dynamic>> get _categoryCollection {
    return firestore.collection('users').doc(uid).collection('categories');
  }

  Future<void> addCategory(CategoryModel category) => add(
        _categoryCollection,
        category,
        label: 'category',
        withId: (category, id) => category.copyWith(id: id),
        toMap: (category) => category.toMap(),
      );

  Future<void> updateCategory(CategoryModel category) => update(
        _categoryCollection,
        category.id,
        category,
        label: 'category',
        toMap: (category) => category.toMap(),
      );

  Future<void> deleteCategory(String id) =>
      delete(_categoryCollection, id, label: 'category');

  Future<void> seedDefaultCategories() async {
    final existing = await _categoryCollection.limit(1).get();

    if (existing.docs.isNotEmpty) {
      return;
    }

    for (final definition in defaultCategories) {
      await addCategory(
        CategoryModel(
          id: '',
          name: definition.name,
          icon: definition.icon,
          color: definition.color,
          type: definition.type,
          sortOrder: definition.sortOrder,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Stream<List<CategoryModel>> getCategories() {
    return _categoryCollection
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CategoryModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }
}
