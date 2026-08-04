import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/budget_model.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _budgetCollection {
    return _firestore.collection('users').doc(_uid).collection('budgets');
  }

  Future<void> addBudget(BudgetModel budget) async {
    try {
      final docRef = _budgetCollection.doc();

      final budgetWithId = budget.copyWith(id: docRef.id);

      await docRef.set(budgetWithId.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Failed to add budget: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // --- NEW: Update existing Firestore budget document ---
  Future<void> updateBudget(BudgetModel budget) async {
    try {
      // Targets the existing document by its ID and overwrites with updated properties
      await _budgetCollection.doc(budget.id).set(budget.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Failed to update budget: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // --- NEW: Delete existing Firestore budget document ---
  Future<void> deleteBudget(String id) async {
    try {
      // Targets the document by its ID and deletes it asynchronously
      await _budgetCollection.doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete budget: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Stream<List<BudgetModel>> getBudgets() {
    return _budgetCollection
        .orderBy('categoryName')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BudgetModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }
}
