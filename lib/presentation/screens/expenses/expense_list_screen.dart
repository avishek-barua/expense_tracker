import 'package:flutter/material.dart';

/// Expense list screen (placeholder - we'll build this next)
class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: const Center(
        child: Text('Expense List - Coming Soon'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add expense
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}