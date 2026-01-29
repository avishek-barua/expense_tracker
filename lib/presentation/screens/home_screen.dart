import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
import 'expenses/expense_list_screen.dart';
import 'income/income_list_screen.dart';
import 'borrow_lend/borrow_lend_list_screen.dart';

/// Main home screen with bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = [
    const DashboardScreen(),
    const ExpenseListScreen(),
    const IncomeListScreen(),
    const BorrowLendListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Income',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Borrow/Lend',
          ),
        ],
      ),
    );
  }
}