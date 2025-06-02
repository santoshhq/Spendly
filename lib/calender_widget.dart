import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarWidget extends StatelessWidget {
  final int selectedDay;
  final List<int> daysWithExpenses;
  final int? highestSpendingDay;
  final Map<int, String> expenseInfo;
  final Function(int day)? onDayTap; // ✅ New optional callback

  const CalendarWidget({
    super.key,
    required this.selectedDay,
    required this.daysWithExpenses,
    required this.highestSpendingDay,
    required this.expenseInfo,
    this.onDayTap, // ✅ Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final int year = now.year;
    final int month = now.month;
    final int daysInMonth = DateUtils.getDaysInMonth(year, month);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: daysInMonth,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // 7 days in a week
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final int day = index + 1;
        final DateTime date = DateTime(year, month, day);

        final bool isToday = DateUtils.isSameDay(date, now);
        final bool isExpenseDay = daysWithExpenses.contains(day);
        final bool isHighestDay = highestSpendingDay == day;

        // Define color logic
        Color bgColor = Colors.transparent;
        Color borderColor = Colors.grey.shade300;
        Color textColor = Colors.black87;

        if (isHighestDay) {
          bgColor = Colors.red;
          borderColor = Colors.red;
          textColor = Colors.white;
        } else if (isToday) {
          bgColor = Colors.deepPurple;
          borderColor = Colors.deepPurple;
          textColor = Colors.white;
        } else if (isExpenseDay) {
          bgColor = Colors.deepPurple.shade100;
          borderColor = Colors.deepPurple.withOpacity(0.4);
        }

        return GestureDetector(
          onTap: () {
            final selectedDate = DateTime(now.year, now.month, day);
            //noinspection UseBuildContextLocators
            if (onDayTap != null) onDayTap!(selectedDate.day); // Pass DAY only
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('E').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
