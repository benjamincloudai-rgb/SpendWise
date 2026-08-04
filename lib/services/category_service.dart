import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _categoryCollection {
    return _firestore.collection('users').doc(_uid).collection('categories');
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      final docRef = _categoryCollection.doc();

      final categoryWithId = category.copyWith(id: docRef.id);

      await docRef.set(categoryWithId.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Failed to add category: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // --- NEW: Update existing Firestore category document ---
  Future<void> updateCategory(CategoryModel category) async {
    try {
      // Targets the existing document by its ID and overwrites with updated properties
      await _categoryCollection.doc(category.id).set(category.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Failed to update category: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // --- NEW: Delete existing Firestore category document ---
  Future<void> deleteCategory(String id) async {
    try {
      // Targets the document by its ID and deletes it asynchronously
      await _categoryCollection.doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete category: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
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
