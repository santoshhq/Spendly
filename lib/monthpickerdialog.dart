// 📦 Reusable Month Picker Dialog Class for Download
import 'package:flutter/material.dart';

class MonthPickerDialog extends StatelessWidget {
  final List<Map<String, dynamic>> previousMonths;
  final void Function(String month) onMonthSelected;

  const MonthPickerDialog({
    super.key,
    required this.previousMonths,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Month to Download"),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: previousMonths.length,
          itemBuilder: (ctx, i) {
            final month = previousMonths[i]['month'];
            return ListTile(
              title: Text(month),
              onTap: () {
                Navigator.of(context).pop();
                onMonthSelected(month);
              },
            );
          },
        ),
      ),
    );
  }
}
