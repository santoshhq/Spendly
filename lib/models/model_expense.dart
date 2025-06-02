import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

var formater = DateFormat.yMd();
const uuid = Uuid();

enum Category {
  work,
  entertainment,
  travel,
  food,
  education,
  housing,
  bills,
  health,
  fitness,
  investment,
  shopping,
  personal,
  subscriptions,
  // Add more here if needed
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

final categoryLabels = {
  Category.food: 'FOOD',
  Category.entertainment: 'ENTERTAINMENT',
  Category.travel: 'TRAVEL',
  Category.work: 'WORK',
  Category.education: 'EDU',
  Category.housing: 'HOU',
  Category.bills: 'BIL',
  Category.fitness: 'FIT',
  Category.investment: 'INV',
  Category.shopping: 'SHP',
  Category.personal: 'PER',
  Category.subscriptions: 'SUB',
};

class Modelexpense {
  Modelexpense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;

  String get formattedDate {
    return formater.format(date);
  }
}
