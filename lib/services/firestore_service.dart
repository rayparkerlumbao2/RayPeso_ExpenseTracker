import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../models/expense.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._internal();

  FirebaseFirestore? _firestore;
  bool _isInitialized = false;
  static const String _collectionName = 'expenses';
  static const Duration _timeoutDuration = Duration(seconds: 4);

  FirestoreService._internal();

  bool get isInitialized => _isInitialized;

  /// Check if the current platform is supported by the generated FirebaseOptions
  static bool get isPlatformSupported {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.android) return true;
    return false;
  }

  /// Initialize Firebase and Firestore
  Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      if (!isPlatformSupported) {
        debugPrint(
          'Firebase is not configured for $defaultTargetPlatform. Cloud sync will be inactive on this platform.',
        );
        return false;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(_timeoutDuration);

      _firestore = FirebaseFirestore.instance;

      // Enable offline persistence where supported
      if (!kIsWeb) {
        _firestore!.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }

      _isInitialized = true;
      debugPrint(
        'Firestore initialized successfully for project ${DefaultFirebaseOptions.currentPlatform.projectId}',
      );
      return true;
    } catch (e) {
      debugPrint('Firestore initialization failed/timed out: $e');
      _isInitialized = false;
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (!_isInitialized || _firestore == null) return null;
    return _firestore!.collection(_collectionName);
  }

  /// Upsert a single expense to Firestore
  Future<void> syncExpense(Expense expense) async {
    final col = _collection;
    if (col == null) return;

    try {
      await col.doc(expense.id).set({
        'id': expense.id,
        'amount': expense.amount,
        'categoryId': expense.categoryId,
        'date': Timestamp.fromDate(expense.date),
        'note': expense.note,
        'createdAt': Timestamp.fromDate(expense.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(_timeoutDuration);
      debugPrint('Expense ${expense.id} synced to Firestore');
    } catch (e) {
      debugPrint('Failed to sync expense to Firestore: $e');
    }
  }

  /// Delete an expense from Firestore
  Future<void> deleteExpense(String id) async {
    final col = _collection;
    if (col == null) return;

    try {
      await col.doc(id).delete().timeout(_timeoutDuration);
      debugPrint('Expense $id deleted from Firestore');
    } catch (e) {
      debugPrint('Failed to delete expense from Firestore: $e');
    }
  }

  /// Upload a list of local expenses in batches
  Future<void> syncAllExpenses(List<Expense> expenses) async {
    final col = _collection;
    final fs = _firestore;
    if (col == null || fs == null || expenses.isEmpty) return;

    try {
      final batch = fs.batch();
      for (final expense in expenses) {
        final docRef = col.doc(expense.id);
        batch.set(docRef, {
          'id': expense.id,
          'amount': expense.amount,
          'categoryId': expense.categoryId,
          'date': Timestamp.fromDate(expense.date),
          'note': expense.note,
          'createdAt': Timestamp.fromDate(expense.createdAt),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit().timeout(_timeoutDuration);
      debugPrint('Batch synced ${expenses.length} expenses to Firestore');
    } catch (e) {
      debugPrint('Failed to batch sync expenses to Firestore: $e');
    }
  }

  /// Pull all expenses from Firestore with timeout protection
  Future<List<Expense>> fetchExpenses() async {
    final col = _collection;
    if (col == null) return [];

    try {
      final snapshot = await col
          .orderBy('date', descending: true)
          .get()
          .timeout(_timeoutDuration);

      final list = <Expense>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawDate = data['date'];
        final rawCreated = data['createdAt'];

        DateTime date;
        if (rawDate is Timestamp) {
          date = rawDate.toDate();
        } else if (rawDate is String) {
          date = DateTime.tryParse(rawDate) ?? DateTime.now();
        } else {
          date = DateTime.now();
        }

        DateTime createdAt;
        if (rawCreated is Timestamp) {
          createdAt = rawCreated.toDate();
        } else if (rawCreated is String) {
          createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
        } else {
          createdAt = DateTime.now();
        }

        list.add(
          Expense(
            id: doc.id,
            amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
            categoryId: data['categoryId'] as String? ?? 'other',
            date: date,
            note: data['note'] as String?,
            createdAt: createdAt,
          ),
        );
      }

      return list;
    } catch (e) {
      debugPrint('Failed to fetch expenses from Firestore: $e');
      return [];
    }
  }

  /// Listen to real-time changes from Firestore
  Stream<List<Expense>>? streamExpenses() {
    final col = _collection;
    if (col == null) return null;

    return col
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final rawDate = data['date'];
        final rawCreated = data['createdAt'];

        final date = rawDate is Timestamp
            ? rawDate.toDate()
            : (rawDate is String
                ? (DateTime.tryParse(rawDate) ?? DateTime.now())
                : DateTime.now());

        final createdAt = rawCreated is Timestamp
            ? rawCreated.toDate()
            : (rawCreated is String
                ? (DateTime.tryParse(rawCreated) ?? DateTime.now())
                : DateTime.now());

        return Expense(
          id: doc.id,
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          categoryId: data['categoryId'] as String? ?? 'other',
          date: date,
          note: data['note'] as String?,
          createdAt: createdAt,
        );
      }).toList();
    });
  }

  /// Clear all expenses in Firestore
  Future<void> clearAll() async {
    final col = _collection;
    final fs = _firestore;
    if (col == null || fs == null) return;

    try {
      final snapshot = await col.get().timeout(_timeoutDuration);
      final batch = fs.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit().timeout(_timeoutDuration);
      debugPrint('Cleared all expenses from Firestore');
    } catch (e) {
      debugPrint('Failed to clear Firestore collection: $e');
    }
  }
}
