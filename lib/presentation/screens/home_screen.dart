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
  final PageController _pageController = PageController();
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey();
  bool _isRefreshing = false;

  // Keep all screens in memory
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(key: _dashboardKey),
      const ExpenseListScreen(),
      const IncomeListScreen(),
      const BorrowLendListScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _refreshDashboard() {
    // Debounce: Don't refresh if already refreshing
    if (_isRefreshing) return;

    _isRefreshing = true;
    _dashboardKey.currentState?.refresh();

    // Reset flag after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Refresh dashboard when switching to it
          if (index == 0) {
            _refreshDashboard();
          }
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
          // Refresh dashboard when tapping to switch to it
          if (index == 0) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _refreshDashboard();
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
