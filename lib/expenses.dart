import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/accountpage.dart';
import 'package:expense_tracker/expenses_lists.dart';
import 'package:expense_tracker/models/model_expense.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:expense_tracker/userInput.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/categorychart.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  void _openExpenseOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return UserInput(newExpenses: (_) {});
      },
    );
  }

  void _editExpense(Modelexpense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return UserInput(existingExpense: expense, newExpenses: (_) {});
      },
    );
  }

  void _deleteExpense(Modelexpense expense) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expense.id)
          .delete();

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 2,
        titleSpacing: 0,
        centerTitle: true,
        title: Text(
          'SpendX',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountPage()),
                );
              },
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.15),
                radius: 18,
                child: const Icon(
                  Icons.account_circle,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder<List<Modelexpense>>(
        stream: FirestoreService().streamUserExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          final allExpenses = snapshot.data ?? [];

          final now = DateTime.now();
          final todayExpenses =
              allExpenses
                  .where(
                    (e) =>
                        e.date.year == now.year &&
                        e.date.month == now.month &&
                        e.date.day == now.day,
                  )
                  .toList();

          return Column(
            children: [
              const SizedBox(height: 10),
              todayExpenses.isEmpty
                  ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No expenses recorded today.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 200,
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'Bar chart will appear here when you add expenses.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  : CategoryChart(expenses: todayExpenses),
              const SizedBox(height: 10),
              Expanded(
                child: ExpensesLists(
                  newexpenses: todayExpenses,
                  onDeleteExpense: _deleteExpense,
                  onEditExpense: _editExpense,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.deepPurple,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openExpenseOverlay,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add Expense',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
