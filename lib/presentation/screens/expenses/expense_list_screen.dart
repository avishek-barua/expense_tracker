import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/expense_card.dart';
import 'add_expense_screen.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../core/constants/app_constants.dart';

/// Expense list screen with full CRUD functionality
class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Load expenses when screen first opens
    Future.microtask(() {
      ref.read(expenseProvider.notifier).loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(expenseProvider.notifier)
              .loadExpenses(
                startDate: _startDate,
                endDate: _endDate,
                category: _selectedCategory,
              );
        },
        child: expensesAsync.when(
          data: (expenses) {
            if (expenses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No expenses yet',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add your first expense',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return ExpenseCard(
                  expense: expense,
                  onTap: () => _navigateToEditExpense(expense.id),
                  onDelete: () => _confirmDelete(expense.id),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${error.toString()}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(expenseProvider.notifier).loadExpenses();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expense_fab',
        onPressed: _navigateToAddExpense,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );

    if (result == true && mounted) {
      // Refresh list after adding
      ref
          .read(expenseProvider.notifier)
          .loadExpenses(
            startDate: _startDate,
            endDate: _endDate,
            category: _selectedCategory,
          );
    }
  }

  void _navigateToEditExpense(String expenseId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(expenseId: expenseId),
      ),
    );

    if (result == true && mounted) {
      // Refresh list after editing
      ref
          .read(expenseProvider.notifier)
          .loadExpenses(
            startDate: _startDate,
            endDate: _endDate,
            category: _selectedCategory,
          );
    }
  }

  void _confirmDelete(String expenseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(expenseProvider.notifier)
                    .deleteExpense(expenseId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Expenses'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date Range Section
                Text(
                  'Date Range',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),

                // Quick date presets
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Today'),
                      selected: _isDateRangeToday(),
                      onSelected: (_) {
                        setDialogState(() {
                          final now = DateTime.now();
                          _startDate = app_date_utils.DateUtils.startOfDay(now);
                          _endDate = app_date_utils.DateUtils.endOfDay(now);
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('This Week'),
                      selected: _isDateRangeThisWeek(),
                      onSelected: (_) {
                        setDialogState(() {
                          final now = DateTime.now();
                          _startDate = app_date_utils.DateUtils.startOfWeek(
                            now,
                          );
                          _endDate = app_date_utils.DateUtils.endOfWeek(now);
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('This Month'),
                      selected: _isDateRangeThisMonth(),
                      onSelected: (_) {
                        setDialogState(() {
                          final now = DateTime.now();
                          _startDate = app_date_utils.DateUtils.startOfMonth(
                            now,
                          );
                          _endDate = app_date_utils.DateUtils.endOfMonth(now);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Custom date range
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _startDate == null
                              ? 'Start Date'
                              : app_date_utils.DateUtils.formatDate(
                                  _startDate!,
                                ),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => _startDate = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _endDate == null
                              ? 'End Date'
                              : app_date_utils.DateUtils.formatDate(_endDate!),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => _endDate = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...AppConstants.expenseCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() => _selectedCategory = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _startDate = null;
                  _endDate = null;
                });
                Navigator.pop(context);
                ref.read(expenseProvider.notifier).loadExpenses();
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref
                    .read(expenseProvider.notifier)
                    .loadExpenses(
                      startDate: _startDate,
                      endDate: _endDate,
                      category: _selectedCategory,
                    );
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDateRangeToday() {
    if (_startDate == null || _endDate == null) return false;
    final now = DateTime.now();
    return app_date_utils.DateUtils.isSameDay(_startDate!, now) &&
        app_date_utils.DateUtils.isSameDay(_endDate!, now);
  }

  bool _isDateRangeThisWeek() {
    if (_startDate == null || _endDate == null) return false;
    final now = DateTime.now();
    final weekStart = app_date_utils.DateUtils.startOfWeek(now);
    final weekEnd = app_date_utils.DateUtils.endOfWeek(now);
    return app_date_utils.DateUtils.isSameDay(_startDate!, weekStart) &&
        app_date_utils.DateUtils.isSameDay(_endDate!, weekEnd);
  }

  bool _isDateRangeThisMonth() {
    if (_startDate == null || _endDate == null) return false;
    final now = DateTime.now();
    final monthStart = app_date_utils.DateUtils.startOfMonth(now);
    final monthEnd = app_date_utils.DateUtils.endOfMonth(now);
    return app_date_utils.DateUtils.isSameDay(_startDate!, monthStart) &&
        app_date_utils.DateUtils.isSameDay(_endDate!, monthEnd);
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String query = '';
        return AlertDialog(
          title: const Text('Search Expenses'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter description or category',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => query = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (query.isNotEmpty) {
                  ref.read(expenseProvider.notifier).searchExpenses(query);
                }
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
}
