import 'package:flutter/material.dart';

/// Income list screen (placeholder - we'll build this next)
class IncomeListScreen extends StatelessWidget {
  const IncomeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
      ),
      body: const Center(
        child: Text('Income List - Coming Soon'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add income
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}