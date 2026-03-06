import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../presentation/providers/expense_provider.dart';
import '../../../presentation/providers/income_provider.dart';
import '../../../presentation/providers/borrow_lend_provider.dart';
import '../../../presentation/providers/opening_balance_provider.dart';
import '../expenses/add_expense_screen.dart';
import '../income/add_income_screen.dart';

/// Dashboard screen showing financial overview
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends ConsumerState<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  DateTime _selectedMonth = DateTime.now();

  @override
  bool get wantKeepAlive => true;

  /// Public refresh method that can be called from parent
  void refresh() {
    if (mounted) {
      // Invalidate all providers in batch (no setState to avoid immediate rebuild)
      // The providers will rebuild widgets automatically when data arrives
      ref.invalidate(totalExpensesProvider);
      ref.invalidate(totalIncomeProvider);
      ref.invalidate(totalBorrowedProvider);
      ref.invalidate(totalLentProvider);
      ref.invalidate(openingBalanceProvider);
      ref.invalidate(closingBalanceProvider);
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Get selected month date range
    final startOfMonth = app_date_utils.DateUtils.startOfMonth(_selectedMonth);
    final endOfMonth = app_date_utils.DateUtils.endOfMonth(_selectedMonth);
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
          refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Month selector
            _buildMonthHeader(context, _selectedMonth),
            const SizedBox(height: 16),

            // Opening Balance card
            _buildOpeningBalanceCard(context, ref, _selectedMonth),
            const SizedBox(height: 16),

            // Net balance card
            _buildNetBalanceCard(context, ref, monthRange),
            const SizedBox(height: 16),

            // Income/Expense cards
            Row(
              children: [
                Expanded(child: _buildIncomeCard(context, ref, monthRange)),
                const SizedBox(width: 16),
                Expanded(child: _buildExpenseCard(context, ref, monthRange)),
              ],
            ),
            const SizedBox(height: 16),

            // Borrow/Lend summary
            _buildBorrowLendCard(context, ref),
            const SizedBox(height: 16),

            // Current/Closing Balance card
            _buildClosingBalanceCard(context, ref, _selectedMonth),
            const SizedBox(height: 24),

            // Quick actions
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, DateTime date) {
    final isCurrentMonth = _isCurrentMonth();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
            ),
            InkWell(
              onTap: _showMonthPicker,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${app_date_utils.DateUtils.formatDateLong(date).split(' ')[0]} ${date.year}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down, size: 24),
                  ],
                ),
              ),
            ),
            // Hide next month button if current month
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: isCurrentMonth ? null : _nextMonth,
              color: isCurrentMonth ? Colors.grey[300] : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMonthPicker() async {
    final now = DateTime.now();
    int selectedYear = _selectedMonth.year;
    int selectedMonth = _selectedMonth.month;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Month'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Year selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() {
                              selectedYear--;
                              // If moving away from current year and month was limited by current month,
                              // reset to December (no restrictions in past years)
                              if (selectedYear < now.year &&
                                  selectedMonth > 12) {
                                selectedMonth = 12;
                              }
                            });
                          },
                        ),
                        Text(
                          selectedYear.toString(),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: selectedYear < now.year
                              ? () {
                                  setState(() {
                                    selectedYear++;
                                    // If moving to current year and selected month is in future, reset to current month
                                    if (selectedYear == now.year &&
                                        selectedMonth > now.month) {
                                      selectedMonth = now.month;
                                    }
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Month grid
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final isSelected =
                            month == selectedMonth; // Remove year check
                        final isFuture =
                            selectedYear == now.year && month > now.month;
                        final monthName = _getMonthName(month);

                        return InkWell(
                          onTap: isFuture
                              ? null
                              : () {
                                  setState(() => selectedMonth = month);
                                },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : isFuture
                                  ? Colors.grey[200]
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                monthName,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : isFuture
                                      ? Colors.grey[400]
                                      : Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    this.setState(() {
                      _selectedMonth = DateTime(selectedYear, selectedMonth);
                    });
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildNetBalanceCard(
    BuildContext context,
    WidgetRef ref,
    DateRange range,
  ) {
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white70),
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
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This Month',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  );
                },
                loading: () =>
                    const CircularProgressIndicator(color: Colors.white),
                error: (_, __) =>
                    const Text('Error', style: TextStyle(color: Colors.white)),
              ),
              loading: () =>
                  const CircularProgressIndicator(color: Colors.white),
              error: (_, __) =>
                  const Text('Error', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCard(
    BuildContext context,
    WidgetRef ref,
    DateRange range,
  ) {
    final totalIncomeAsync = ref.watch(totalIncomeProvider(range));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.arrow_downward,
                  color: AppTheme.incomeColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Income', style: Theme.of(context).textTheme.titleSmall),
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

  Widget _buildExpenseCard(
    BuildContext context,
    WidgetRef ref,
    DateRange range,
  ) {
    final totalExpensesAsync = ref.watch(totalExpensesProvider(range));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.arrow_upward,
                  color: AppTheme.expenseColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Expenses', style: Theme.of(context).textTheme.titleSmall),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.borrowedColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        loading: () =>
                            const CircularProgressIndicator(strokeWidth: 2),
                        error: (_, __) => const Text('Error'),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: AppTheme.dividerColor),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.lentColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        loading: () =>
                            const CircularProgressIndicator(strokeWidth: 2),
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

  Widget _buildOpeningBalanceCard(
    BuildContext context,
    WidgetRef ref,
    DateTime month,
  ) {
    final openingBalanceAsync = ref.watch(
      openingBalanceProvider((month.month, month.year)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Opening Balance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: () =>
                      _showSetOpeningBalanceDialog(context, ref, month),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Set'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            openingBalanceAsync.when(
              data: (amount) => Text(
                CurrencyFormatter.format(amount),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              loading: () => const CircularProgressIndicator(strokeWidth: 2),
              error: (_, __) => const Text('Error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosingBalanceCard(
    BuildContext context,
    WidgetRef ref,
    DateTime month,
  ) {
    final closingBalanceAsync = ref.watch(
      closingBalanceProvider((month.month, month.year)),
    );
    final isCurrentMonth = _isCurrentMonth();

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCurrentMonth ? 'Current Balance' : 'Closing Balance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            closingBalanceAsync.when(
              data: (amount) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.format(amount),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: amount >= 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCurrentMonth
                        ? 'Money you have now'
                        : 'Balance at end of month',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(strokeWidth: 2),
              error: (_, __) => const Text('Error'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetOpeningBalanceDialog(
    BuildContext context,
    WidgetRef ref,
    DateTime month,
  ) async {
    final currentBalance = await ref.read(
      openingBalanceProvider((month.month, month.year)).future,
    );
    final controller = TextEditingController(
      text: currentBalance > 0 ? currentBalance.toStringAsFixed(0) : '',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Set Opening Balance - ${_getMonthName(month.month)} ${month.year}',
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '৳ ',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount >= 0) {
                Navigator.pop(context, amount);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await ref
            .read(openingBalanceNotifierProvider.notifier)
            .setOpeningBalance(month.month, month.year, result);
        // Refresh providers
        ref.invalidate(openingBalanceProvider((month.month, month.year)));
        ref.invalidate(closingBalanceProvider((month.month, month.year)));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening balance saved')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
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
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddExpenseScreen(),
                    ),
                  );
                  // Refresh dashboard if something was added
                  if (result == true) {
                    refresh();
                  }
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
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddIncomeScreen(),
                    ),
                  );
                  // Refresh dashboard if something was added
                  if (result == true) {
                    refresh();
                  }
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
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
