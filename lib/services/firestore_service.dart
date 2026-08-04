import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class FirestoreService<T> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  String get uid {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.uid;
  }

  Future<void> add(
    CollectionReference<Map<String, dynamic>> collection,
    T model, {
    required String label,
    required T Function(T model, String id) withId,
    required Map<String, dynamic> Function(T model) toMap,
  }) async {
    try {
      final docRef = collection.doc();

      final modelWithId = withId(model, docRef.id);

      await docRef.set(toMap(modelWithId));
    } on FirebaseException catch (e) {
      throw Exception('Failed to add $label: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> update(
    CollectionReference<Map<String, dynamic>> collection,
    String id,
    T model, {
    required String label,
    required Map<String, dynamic> Function(T model) toMap,
  }) async {
    try {
      await collection.doc(id).set(toMap(model));
    } on FirebaseException catch (e) {
      throw Exception('Failed to update $label: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> delete(
    CollectionReference<Map<String, dynamic>> collection,
    String id, {
    required String label,
  }) async {
    try {
      await collection.doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete $label: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
