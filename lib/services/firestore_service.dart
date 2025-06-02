// firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/models/model_expense.dart';
import 'package:flutter/foundation.dart' hide Category;

// 👇 Added missing import
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> generateSummaryIfNeededForMonth(String monthYear) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('summaries')
        .doc(monthYear);

    final docSnap = await docRef.get();
    if (docSnap.exists) return; // already exists

    // Get all expenses of that month
    final allExpenses = await getUserExpenses();
    final DateTime monthDate = DateFormat('MMMM yyyy').parse(monthYear);
    final monthExpenses =
        allExpenses
            .where(
              (e) =>
                  e.date.month == monthDate.month &&
                  e.date.year == monthDate.year,
            )
            .toList();

    if (monthExpenses.isEmpty) return;

    final total = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);

    Map<String, double> categoryTotals = {};
    Map<int, double> dayTotals = {};
    for (var e in monthExpenses) {
      categoryTotals[e.category.name] =
          (categoryTotals[e.category.name] ?? 0) + e.amount;
      dayTotals[e.date.day] = (dayTotals[e.date.day] ?? 0) + e.amount;
    }

    final highestCategory =
        categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final topDay =
        dayTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    await docRef.set({
      'totalExpense': total,
      'highestCategory': highestCategory.toUpperCase(),
      'topDay': '$topDay ${monthYear.split(" ")[0]}',
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> addExpense(Modelexpense expense) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      await _db
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expense.id)
          .set({
            'title': expense.title,
            'amount': expense.amount,
            // ✅ Store as Timestamp for better performance
            'date': Timestamp.fromDate(expense.date),
            'category': expense.category.name,
            'month': DateFormat('MMMM yyyy').format(expense.date),
          });
    } catch (e) {
      debugPrint("🔥 Failed to add expense: $e");
      rethrow;
    }
  }

  Future<List<Modelexpense>> getUserExpenses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final snapshot =
          await _db
              .collection('users')
              .doc(user.uid)
              .collection('expenses')
              .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            try {
              return Modelexpense(
                id: doc.id,
                title: data['title'] ?? '',
                amount: (data['amount'] as num).toDouble(),
                // ✅ Handle Timestamp or fallback to parsing ISO strings
                date: (data['date'] as Timestamp).toDate().toUtc(),
                category: Category.values.firstWhere(
                  (e) => e.name == data['category'],
                  orElse: () {
                    debugPrint("⚠️ Unknown category: ${data['category']}");
                    return Category.food;
                  },
                ),
              );
            } catch (e) {
              debugPrint("🔥 Error parsing document ${doc.id}: $e");
              return null;
            }
          })
          .whereType<Modelexpense>()
          .toList();
    } catch (e) {
      debugPrint("🔥 Failed to fetch user expenses: $e");
      rethrow;
    }
  }

  Stream<List<Modelexpense>> streamUserExpenses() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.error("No authenticated user.");
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                try {
                  return Modelexpense(
                    id: doc.id,
                    title: data['title'] ?? '',
                    amount: (data['amount'] as num).toDouble(),
                    date:
                        data['date'] is Timestamp
                            ? data['date'].toDate()
                            : DateTime.parse(data['date']),
                    category: Category.values.firstWhere(
                      (e) => e.name == data['category'],
                      orElse: () {
                        debugPrint(
                          "⚠️ Unknown category in stream: ${data['category']}",
                        );
                        return Category.food;
                      },
                    ),
                  );
                } catch (e) {
                  debugPrint("🔥 Stream error on doc ${doc.id}: $e");
                  return null;
                }
              })
              .whereType<Modelexpense>()
              .toList();
        });
  }

  // ✅ Safely delete all expenses in a specific month
  // ✅ Corrected Firestore query with proper typing
  Future<void> deleteExpensesByMonth(String monthYear) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Parsing the month-year string to a DateTime object
    final DateTime monthDate = DateFormat('MMMM yyyy').parse(monthYear);

    // Safely increment month to next (e.g., 12 -> 1 of next year)
    final DateTime startOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final DateTime startOfNextMonth =
        monthDate.month < 12
            ? DateTime(monthDate.year, monthDate.month + 1, 1)
            : DateTime(monthDate.year + 1, 1, 1);

    try {
      // ✅ Query using Timestamp now directly
      final Query<Map<String, dynamic>> query = _db
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('date', isLessThan: Timestamp.fromDate(startOfNextMonth));

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        debugPrint("✅ No expenses found for $monthYear");
        return;
      }

      final WriteBatch batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint("✅ Deleted ${snapshot.docs.length} expenses for $monthYear");
    } catch (e, s) {
      debugPrint(
        "🔥 Failed to delete expenses for $monthYear\nError: $e\nStack: $s",
      );
      rethrow;
    }
  }
}
