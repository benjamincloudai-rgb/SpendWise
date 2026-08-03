import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _transactionCollection {
    return _firestore.collection('users').doc(_uid).collection('transactions');
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      final docRef = _transactionCollection.doc();

      final transactionWithId = transaction.copyWith(id: docRef.id);

      await docRef.set(transactionWithId.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Failed to add transaction: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

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
