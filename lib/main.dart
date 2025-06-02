import 'package:expense_tracker/loginpage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:expense_tracker/start_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    runApp(const ExpenseTrackerApp());
  } catch (e) {
    print('🔥 Firebase initialization error: $e');
  }
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      home: const StartPage(),
      routes: {
        '/login': (context) => const LoginPage(), // You must define this widget
      },
    );
  }
}
