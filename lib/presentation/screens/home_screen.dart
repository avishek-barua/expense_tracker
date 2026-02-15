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
  // Key to force dashboard rebuild when switching to it
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey();

  // Build screen on demand instead of keeping all in memory
  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(key: _dashboardKey);
      case 1:
        return const ExpenseListScreen();
      case 2:
        return const IncomeListScreen();
      case 3:
        return const BorrowLendListScreen();
      default:
        return DashboardScreen(key: _dashboardKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Refresh dashboard when switching to it (with delay to ensure it's mounted)
          if (index == 0) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _dashboardKey.currentState?.refresh();
            });
          }
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
