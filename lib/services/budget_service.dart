import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/budget_model.dart';
import 'firestore_service.dart';

class BudgetService extends FirestoreService<BudgetModel> {
  CollectionReference<Map<String, dynamic>> get _budgetCollection {
    return firestore.collection('users').doc(uid).collection('budgets');
  }

  Future<void> addBudget(BudgetModel budget) => add(
        _budgetCollection,
        budget,
        label: 'budget',
        withId: (budget, id) => budget.copyWith(id: id),
        toMap: (budget) => budget.toMap(),
      );

  Future<void> updateBudget(BudgetModel budget) => update(
        _budgetCollection,
        budget.id,
        budget,
        label: 'budget',
        toMap: (budget) => budget.toMap(),
      );

  Future<void> deleteBudget(String id) =>
      delete(_budgetCollection, id, label: 'budget');

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
