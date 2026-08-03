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
      await _categoryCollection.doc(category.id).set(category.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Failed to add category: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Stream<List<CategoryModel>> getCategories() {
    return _categoryCollection.orderBy('createdAt').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}
