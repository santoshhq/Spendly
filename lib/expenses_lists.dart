import 'package:expense_tracker/itemslist.dart';
import 'package:expense_tracker/models/model_expense.dart';
import 'package:flutter/material.dart';

class ExpensesLists extends StatelessWidget {
  final List<Modelexpense> newexpenses;
  final void Function(Modelexpense) onDeleteExpense;
  final void Function(Modelexpense) onEditExpense;

  const ExpensesLists({
    super.key,
    required this.newexpenses,
    required this.onDeleteExpense,
    required this.onEditExpense,
  });

  @override
  Widget build(BuildContext context) {
    return newexpenses.isEmpty
        ? const Center(child: Text("No expenses added yet."))
        : ListView.builder(
          itemCount: newexpenses.length,
          itemBuilder: (ctx, index) {
            return ItemsList(
              itemsData: newexpenses[index],
              onDelete: onDeleteExpense,
              onEdit: onEditExpense,
            );
          },
        );
  }
}
