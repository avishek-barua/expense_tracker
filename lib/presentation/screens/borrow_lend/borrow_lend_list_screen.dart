import 'package:flutter/material.dart';

/// Borrow/Lend list screen (placeholder - we'll build this next)
class BorrowLendListScreen extends StatelessWidget {
  const BorrowLendListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow & Lend'),
      ),
      body: const Center(
        child: Text('Borrow/Lend List - Coming Soon'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add transaction
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}