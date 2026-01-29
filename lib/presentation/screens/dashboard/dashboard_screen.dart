import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../providers/borrow_lend_provider.dart';

/// Dashboard screen showing financial overview
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current month date range
    final now = DateTime.now();
    final startOfMonth = app_date_utils.DateUtils.startOfMonth(now);
    final endOfMonth = app_date_utils.DateUtils.endOfMonth(now);
    final monthRange = DateRange(startOfMonth, endOfMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all data
          ref.invalidate(totalExpensesProvider);
          ref.invalidate(totalIncomeProvider);
          ref.invalidate(totalBorrowedProvider);
          ref.invalidate(totalLentProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Month selector
            _buildMonthHeader(context, now),
            const SizedBox(height: 24),

            // Net balance card
            _buildNetBalanceCard(context, ref, monthRange),
            const SizedBox(height: 16),

            // Income/Expense cards
            Row(
              children: [
                Expanded(
                  child: _buildIncomeCard(context, ref, monthRange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildExpenseCard(context, ref, monthRange),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Borrow/Lend summary
            _buildBorrowLendCard(context, ref),
            const SizedBox(height: 24),

            // Quick actions
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, DateTime date) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                // TODO: Previous month
              },
            ),
            Text(
              app_date_utils.DateUtils.formatDateLong(date).split(' ')[0] + 
              ' ${date.year}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                // TODO: Next month
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetBalanceCard(BuildContext context, WidgetRef ref, DateRange range) {
    final totalIncomeAsync = ref.watch(totalIncomeProvider(range));
    final totalExpensesAsync = ref.watch(totalExpensesProvider(range));

    return Card(
      color: AppTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Net Cash Flow',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            totalIncomeAsync.when(
              data: (income) => totalExpensesAsync.when(
                data: (expenses) {
                  final netBalance = income - expenses;
                  return Column(
                    children: [
                      Text(
                        CurrencyFormatter.format(netBalance),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This Month',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(color: Colors.white),
                error: (_, __) => const Text('Error', style: TextStyle(color: Colors.white)),
              ),
              loading: () => const CircularProgressIndicator(color: Colors.white),
              error: (_, __) => const Text('Error', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCard(BuildContext context, WidgetRef ref, DateRange range) {
    final totalIncomeAsync = ref.watch(totalIncomeProvider(range));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.arrow_downward, color: AppTheme.incomeColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Income',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            totalIncomeAsync.when(
              data: (income) => Text(
                CurrencyFormatter.format(income),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.incomeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              loading: () => const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Text('Error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, WidgetRef ref, DateRange range) {
    final totalExpensesAsync = ref.watch(totalExpensesProvider(range));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.arrow_upward, color: AppTheme.expenseColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Expenses',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            totalExpensesAsync.when(
              data: (expenses) => Text(
                CurrencyFormatter.format(expenses),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.expenseColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              loading: () => const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Text('Error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowLendCard(BuildContext context, WidgetRef ref) {
    final totalBorrowedAsync = ref.watch(totalBorrowedProvider(true));
    final totalLentAsync = ref.watch(totalLentProvider(true));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Borrow & Lend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You Owe',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      totalBorrowedAsync.when(
                        data: (borrowed) => Text(
                          CurrencyFormatter.format(borrowed),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.borrowedColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => const CircularProgressIndicator(strokeWidth: 2),
                        error: (_, __) => const Text('Error'),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.dividerColor,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Owed to You',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      totalLentAsync.when(
                        data: (lent) => Text(
                          CurrencyFormatter.format(lent),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.lentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => const CircularProgressIndicator(strokeWidth: 2),
                        error: (_, __) => const Text('Error'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.add,
                label: 'Add Expense',
                color: AppTheme.expenseColor,
                onTap: () {
                  // TODO: Navigate to add expense
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.add,
                label: 'Add Income',
                color: AppTheme.incomeColor,
                onTap: () {
                  // TODO: Navigate to add income
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}