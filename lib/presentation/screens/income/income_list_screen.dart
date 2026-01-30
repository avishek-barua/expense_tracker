import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/income_provider.dart';
import '../../widgets/income_card.dart';
import 'add_income_screen.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;

/// Income list screen with full CRUD functionality
class IncomeListScreen extends ConsumerStatefulWidget {
  const IncomeListScreen({super.key});

  @override
  ConsumerState<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends ConsumerState<IncomeListScreen> {
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Load income when screen first opens
    Future.microtask(() {
      ref.read(incomeProvider.notifier).loadIncome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final incomeAsync = ref.watch(incomeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
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
              .read(incomeProvider.notifier)
              .loadIncome(
                startDate: _startDate,
                endDate: _endDate,
                category: _selectedCategory,
              );
        },
        child: incomeAsync.when(
          data: (incomeList) {
            if (incomeList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No income yet',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add your first income',
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
              itemCount: incomeList.length,
              itemBuilder: (context, index) {
                final income = incomeList[index];
                return IncomeCard(
                  income: income,
                  onTap: () => _navigateToEditIncome(income.id),
                  onDelete: () => _confirmDelete(income.id),
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
                    ref.read(incomeProvider.notifier).loadIncome();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'income_fab',
        onPressed: _navigateToAddIncome,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddIncome() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddIncomeScreen()),
    );

    if (result == true && mounted) {
      ref
          .read(incomeProvider.notifier)
          .loadIncome(
            startDate: _startDate,
            endDate: _endDate,
            category: _selectedCategory,
          );
    }
  }

  void _navigateToEditIncome(String incomeId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddIncomeScreen(incomeId: incomeId),
      ),
    );

    if (result == true && mounted) {
      ref
          .read(incomeProvider.notifier)
          .loadIncome(
            startDate: _startDate,
            endDate: _endDate,
            category: _selectedCategory,
          );
    }
  }

  void _confirmDelete(String incomeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income'),
        content: const Text('Are you sure you want to delete this income?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(incomeProvider.notifier).deleteIncome(incomeId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Income deleted')),
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
      builder: (context) => AlertDialog(
        title: const Text('Filter Income'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text('Filter options coming soon')],
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
              ref.read(incomeProvider.notifier).loadIncome();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String query = '';
        return AlertDialog(
          title: const Text('Search Income'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter description or source',
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
                  ref.read(incomeProvider.notifier).searchIncome(query);
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
