import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/model_expense.dart';
import 'package:expense_tracker/services/firestore_service.dart';

final formatter = DateFormat.yMd();

class UserInput extends StatefulWidget {
  const UserInput({super.key, required this.newExpenses, this.existingExpense});

  final void Function(Modelexpense expense) newExpenses;
  final Modelexpense? existingExpense;

  @override
  State<UserInput> createState() => _UserInputState();
}

class _UserInputState extends State<UserInput> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;

  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingExpense?.title ?? '',
    );
    _amountController = TextEditingController(
      text: widget.existingExpense?.amount.toString() ?? '',
    );
    _selectedDate = widget.existingExpense?.date ?? DateTime.now();
    _selectedCategory = widget.existingExpense?.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text);

    final isInvalid =
        title.isEmpty ||
        amount == null ||
        amount <= 0 ||
        _selectedCategory == null;

    if (isInvalid) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Invalid Input'),
              content: const Text(
                'Please complete all fields with valid data.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Okay'),
                ),
              ],
            ),
      );
      return;
    }

    final expense = Modelexpense(
      id: widget.existingExpense?.id,
      title: title,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory!,
    );

    await FirestoreService().addExpense(expense);
    widget.newExpenses(expense);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder:
          (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleController,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'Expense Title',
                    border: OutlineInputBorder(),
                  ),
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹',
                          border: OutlineInputBorder(),
                        ),
                        style: textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          formatter.format(_selectedDate),
                          style: textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<Category?>(
                  value: _selectedCategory,
                  hint: const Text('Select Category'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select')),
                    ...Category.values.map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat.name.toUpperCase()),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}
