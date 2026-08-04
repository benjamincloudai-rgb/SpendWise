import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transaction_model.dart';
import 'firestore_service.dart';

class TransactionService extends FirestoreService<TransactionModel> {
  CollectionReference<Map<String, dynamic>> get _transactionCollection {
    return firestore.collection('users').doc(uid).collection('transactions');
  }

  Future<void> addTransaction(TransactionModel transaction) => add(
        _transactionCollection,
        transaction,
        label: 'transaction',
        withId: (transaction, id) => transaction.copyWith(id: id),
        toMap: (transaction) => transaction.toMap(),
      );

  Future<void> updateTransaction(TransactionModel transaction) => update(
        _transactionCollection,
        transaction.id,
        transaction,
        label: 'transaction',
        toMap: (transaction) => transaction.toMap(),
      );

  Future<void> deleteTransaction(String id) =>
      delete(_transactionCollection, id, label: 'transaction');

  Stream<List<TransactionModel>> getTransactions() {
    return _transactionCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return TransactionModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }
}
