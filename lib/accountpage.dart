import 'dart:io';
import 'package:csv/csv.dart';
//import 'package:pdf/pdf.dart';
//import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:expense_tracker/models/model_expense.dart';
import 'package:expense_tracker/services/firestore_service.dart';

// Separate page for Previous Months
class PreviousMonthsPage extends StatelessWidget {
  final List<Map<String, dynamic>> previousMonths;

  const PreviousMonthsPage({super.key, required this.previousMonths});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 130, // Fixed height for horizontal cards
          padding: const EdgeInsets.only(left: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  previousMonths.map((item) {
                    return Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 12),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['month'],
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text("Top Day: ${item['day']}"),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: _getCategoryColor(
                                      item['category'],
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(item['category']),
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item['category'],
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),
                              Text(
                                "Total:₹${item['expense'].toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF673AB7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String _username = '';
  String _email = '';
  String? _photoUrl;
  double _monthlyTotal = 0.0;
  String _highestCategory = '';
  String _highestDay = '';
  List<Map<String, dynamic>> _previousMonths = [];
  List<Modelexpense> _allExpenses = [];
  List<int> _daysWithExpenses = [];
  int? _highestSpendingDay;
  Map<int, String> _expenseDetailsByDay = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.reload();
    final updatedUser = FirebaseAuth.instance.currentUser!;
    final uid = updatedUser.uid;

    _username = updatedUser.displayName ?? 'User';
    _email = updatedUser.email ?? '';
    _photoUrl = updatedUser.photoURL;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .get();

    List<Modelexpense> expenses =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return Modelexpense(
            id: doc.id,
            title: data['title'] ?? '',
            amount: (data['amount'] as num).toDouble(),
            date:
                data['date'] is Timestamp
                    ? (data['date'] as Timestamp).toDate()
                    : DateTime.tryParse(data['date']) ?? DateTime.now(),
            category: Category.values.firstWhere(
              (e) => e.name == data['category'],
              orElse: () => Category.food,
            ),
          );
        }).toList();

    _allExpenses = expenses;

    final now = DateTime.now();
    final thisMonth =
        expenses
            .where((e) => e.date.month == now.month && e.date.year == now.year)
            .toList();

    final total = thisMonth.fold(0.0, (sum, e) => sum + e.amount);

    Map<String, double> grouped = {};
    Map<int, double> dailyTotals = {};
    Map<int, String> dailyCategories = {};
    for (var e in thisMonth) {
      grouped[e.category.name] = (grouped[e.category.name] ?? 0) + e.amount;
      final d = e.date.day;
      dailyTotals[d] = (dailyTotals[d] ?? 0) + e.amount;
      dailyCategories[d] = e.category.name;
    }

    _daysWithExpenses = dailyTotals.keys.toList();
    _expenseDetailsByDay = {
      for (var day in dailyTotals.keys)
        day:
            '₹${dailyTotals[day]!.toStringAsFixed(0)} • ${dailyCategories[day]!.toUpperCase()}',
    };

    double maxAmount = 0;
    int? maxDay;
    for (var e in thisMonth) {
      if ((dailyTotals[e.date.day] ?? 0) > maxAmount) {
        maxAmount = dailyTotals[e.date.day]!;
        maxDay = e.date.day;
      }
    }

    // ✅ ADD HERE: Trigger summary generation for last month
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthStr = DateFormat('MMMM yyyy').format(lastMonth);
    await FirestoreService().generateSummaryIfNeededForMonth(lastMonthStr);

    final currentMonthStr = DateFormat('MMMM yyyy').format(now);
    final summariesSnap =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('summaries')
            .orderBy('timestamp', descending: true)
            .get();

    final List<Map<String, dynamic>> monthsData =
        summariesSnap.docs.where((doc) => doc.id != currentMonthStr).map((doc) {
          final data = doc.data();
          final rawCategory = data['highestCategory'];
          final category =
              (rawCategory != null && rawCategory.toString().trim().isNotEmpty)
                  ? rawCategory.toString().toUpperCase()
                  : 'N/A';
          return {
            'month': doc.id,
            'expense': (data['totalExpense'] ?? 0.0).toDouble(),
            'day': data['topDay'] ?? 'N/A',
            'category': category,
          };
        }).toList();

    setState(() {
      _monthlyTotal = total;
      _highestCategory =
          grouped.isNotEmpty
              ? grouped.entries
                  .reduce((a, b) => a.value > b.value ? a : b)
                  .key
                  .toUpperCase()
              : 'N/A';
      _highestDay =
          maxDay != null ? '$maxDay ${DateFormat('MMMM').format(now)}' : 'N/A';
      _previousMonths = monthsData;
      _highestSpendingDay = maxDay;
    });
  }

  Future<void> _downloadReportCSV() async {
    final rows = [
      ['Title', 'Amount', 'Category', 'Date'],
      ..._allExpenses.map(
        (e) => [
          e.title,
          e.amount.toStringAsFixed(2),
          e.category.name,
          DateFormat('yyyy-MM-dd').format(e.date),
        ],
      ),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/monthly_report.csv';
    final file = File(path);
    await file.writeAsString(csv);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Your Monthly CSV Report');
  }

  void _showDayDetails(int day) {
    final now = DateTime.now();
    final selectedDate = DateTime(now.year, now.month, day);
    final dayExpenses =
        _allExpenses
            .where(
              (e) =>
                  e.date.day == day &&
                  e.date.month == selectedDate.month &&
                  e.date.year == selectedDate.year,
            )
            .toList();

    if (dayExpenses.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (context, scrollController) {
            final total = dayExpenses.fold(0.0, (sum, e) => sum + e.amount);
            final topCategory =
                dayExpenses
                    .fold<Map<String, double>>({}, (map, e) {
                      map[e.category.name] =
                          (map[e.category.name] ?? 0) + e.amount;
                      return map;
                    })
                    .entries
                    .reduce((a, b) => a.value > b.value ? a : b)
                    .key;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Details for $day ${DateFormat('MMMM yyyy').format(selectedDate)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Top Category: ${topCategory.toUpperCase()}"),
                  Text("Total Spent: ₹${total.toStringAsFixed(2)}"),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: dayExpenses.length,
                      itemBuilder: (_, i) {
                        final e = dayExpenses[i];
                        return ListTile(
                          title: Text(e.title),
                          subtitle: Text(e.category.name.toUpperCase()),
                          trailing: Text('₹${e.amount.toStringAsFixed(2)}'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Account', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF673AB7), // Deep purple from image
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _downloadReportCSV,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Profile Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage:
                        _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    child:
                        _photoUrl == null
                            ? const Icon(Icons.person, size: 32)
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Monthly Expense Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(
                  0xFFF3E5F5,
                ), // Light purple background from image
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Monthly Expense",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF673AB7),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "₹${_monthlyTotal.toStringAsFixed(0)}",
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Highest Expense Day: $_highestDay",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Top Category: $_highestCategory",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CalendarWidget(
                        selectedDay: now.day,
                        daysWithExpenses: _daysWithExpenses,
                        highestSpendingDay: _highestSpendingDay,
                        expenseInfo: _expenseDetailsByDay,
                        onDaySelected: _showDayDetails,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Previous Months Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Previous Months',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 2), // 10px vertical gap as requested
                  _previousMonths.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No Previous Data',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      )
                      : PreviousMonthsPage(previousMonths: _previousMonths),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarWidget extends StatelessWidget {
  final int selectedDay;
  final List<int> daysWithExpenses;
  final int? highestSpendingDay;
  final Map<int, String>? expenseInfo;
  final Function(int) onDaySelected;

  const CalendarWidget({
    super.key,
    required this.selectedDay,
    required this.daysWithExpenses,
    this.highestSpendingDay,
    this.expenseInfo,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalDays = DateUtils.getDaysInMonth(now.year, now.month);
    final startWeekday = DateTime(now.year, now.month, 1).weekday;
    final leading = (startWeekday % 7);
    final List<Widget> days = List.generate(leading, (_) => const SizedBox());

    for (int i = 1; i <= totalDays; i++) {
      final isToday = i == now.day;
      final hasExpense = daysWithExpenses.contains(i);
      final isHighest = highestSpendingDay == i;

      Color bg = Colors.grey[200]!;
      Color fg = Colors.black;

      if (isToday) {
        bg = const Color(0xFF673AB7); // Deep purple for today
        fg = Colors.white;
      } else if (isHighest) {
        bg = Colors.red; // Red for highest spending day
        fg = Colors.white;
      } else if (hasExpense) {
        bg = const Color(0xFFE1BEE7); // Light purple for days with expenses
      }

      days.add(
        GestureDetector(
          onTap: () => onDaySelected(i),
          child: CircleAvatar(
            backgroundColor: bg,
            radius: 16,
            child: Text(
              '$i',
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    while (days.length < 42) days.add(const SizedBox());

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((e) {
                return Text(
                  e,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 8),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: days,
        ),
      ],
    );
  }
}

IconData _getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'food':
      return Icons.lunch_dining;
    case 'travel':
      return Icons.flight;
    case 'entertainment':
      return Icons.movie;
    case 'health':
      return Icons.local_hospital;
    case 'shopping':
      return Icons.shopping_bag;
    case 'work':
      return Icons.work;
    case 'education':
      return Icons.book_outlined;
    case 'housing':
      return Icons.home;
    case 'bills':
      return Icons.receipt_long;
    case 'fitness':
      return Icons.fitness_center;
    case 'investment':
      return Icons.trending_up;
    case 'personal':
      return Icons.man;
    default:
      return Icons.subscriptions_outlined;
  }
}

Color _getCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'food':
      return Colors.deepOrange;
    case 'travel':
      return Colors.blue;
    case 'entertainment':
      return Colors.purple;
    case 'health':
      return Colors.green;
    case 'shopping':
      return Colors.teal;
    case 'work':
      return Colors.indigo;
    case 'education':
      return Colors.lightGreen;
    case 'housing':
      return Colors.brown;
    case 'bills':
      return Colors.orangeAccent;
    case 'fitness':
      return Colors.redAccent;
    case 'investment':
      return Colors.cyan;
    case 'personal':
      return Colors.pink;
    case 'subscriptions':
      return Colors.deepPurpleAccent;
    default:
      return Colors.grey;
  }
}

final Map<Category, IconData> categoryicon = {
  Category.work: Icons.work,
  Category.entertainment: Icons.movie,
  Category.food: Icons.lunch_dining,
  Category.travel: Icons.flight,
  Category.education: Icons.book_outlined,
  Category.housing: Icons.home,
  Category.bills: Icons.receipt_long,
  Category.health: Icons.health_and_safety,
  Category.fitness: Icons.fitness_center,
  Category.investment: Icons.trending_up,
  Category.shopping: Icons.shopping_bag,
  Category.personal: Icons.man,
  Category.subscriptions: Icons.subscriptions_outlined,
};
final Map<Category, Color> categorycolor = {
  Category.work: Colors.indigo,
  Category.entertainment: Colors.purple,
  Category.food: Colors.deepOrange,
  Category.travel: Colors.blue,
  Category.education: Colors.lightGreen,
  Category.housing: Colors.brown,
  Category.bills: Colors.orangeAccent,
  Category.health: Colors.green,
  Category.fitness: Colors.redAccent,
  Category.investment: Colors.cyan,
  Category.shopping: Colors.teal,
  Category.personal: Colors.pink,
  Category.subscriptions: Colors.deepPurpleAccent,
};
