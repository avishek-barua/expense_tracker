import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'data/datasources/local_database.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-initialize database to avoid blocking UI later
  try {
    await LocalDatabase.instance.database;
  } catch (e) {
    debugPrint('Database initialization error: $e');
  }

  runApp(
    // Wrap entire app with ProviderScope for Riverpod
    const ProviderScope(child: ExpenseTrackerApp()),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Start with home screen
      home: const HomeScreen(),
    );
  }
}
