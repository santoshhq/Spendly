import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Expense {
  String id;
  double amount;
  String category;
  String description;
  DateTime date;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });
}

class EditExpensePage extends StatefulWidget {
  final Expense expense;

  const EditExpensePage({Key? key, required this.expense}) : super(key: key);

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _selectedCategory;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Work',
    'Shopping',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.expense.amount.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.expense.description,
    );
    _selectedCategory = widget.expense.category;
    _selectedDate = widget.expense.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveEditedExpense() {
    final updatedExpense = Expense(
      id: widget.expense.id,
      amount: double.tryParse(_amountController.text) ?? 0.0,
      category: _selectedCategory,
      description: _descriptionController.text,
      date: _selectedDate,
    );

    Navigator.pop(context, updatedExpense);
  }

  void _presentDatePicker() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Amount'),
            ),

            SizedBox(height: 12),

            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(labelText: 'Category'),
              items:
                  _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),

            SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),

            SizedBox(height: 12),

            // Date Picker
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: ${DateFormat.yMMMd().format(_selectedDate)}',
                  ),
                ),
                TextButton(
                  onPressed: _presentDatePicker,
                  child: Text('Change Date'),
                ),
              ],
            ),

            SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _saveEditedExpense,
              icon: Icon(Icons.save),
              label: Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
