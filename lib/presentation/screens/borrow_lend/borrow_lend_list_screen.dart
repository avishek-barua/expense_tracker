import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/borrow_lend_provider.dart';
import '../../widgets/borrow_lend_card.dart';
import 'add_borrow_lend_screen.dart';
import 'transaction_detail_screen.dart';
import '../../../data/models/borrow_lend_model.dart';

/// Borrow/Lend list screen with full CRUD functionality
class BorrowLendListScreen extends ConsumerStatefulWidget {
  const BorrowLendListScreen({super.key});

  @override
  ConsumerState<BorrowLendListScreen> createState() =>
      _BorrowLendListScreenState();
}

class _BorrowLendListScreenState extends ConsumerState<BorrowLendListScreen> {
  TransactionType? _selectedType;
  TransactionStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Load transactions when screen first opens
    Future.microtask(() {
      ref.read(borrowLendProvider.notifier).loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(borrowLendProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow & Lend'),
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
              .read(borrowLendProvider.notifier)
              .loadTransactions(type: _selectedType, status: _selectedStatus);
        },
        child: transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add your first transaction',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            // Group by active/settled
            final activeTransactions = transactions
                .where((t) => t.status == TransactionStatus.active)
                .toList();
            final settledTransactions = transactions
                .where((t) => t.status == TransactionStatus.settled)
                .toList();

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (activeTransactions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Active (${activeTransactions.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...activeTransactions.map(
                    (transaction) => BorrowLendCard(
                      transaction: transaction,
                      onTap: () => _navigateToDetail(transaction),
                      onDelete: () => _confirmDelete(transaction.id),
                    ),
                  ),
                ],
                if (settledTransactions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Settled (${settledTransactions.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  ...settledTransactions.map(
                    (transaction) => BorrowLendCard(
                      transaction: transaction,
                      onTap: () => _navigateToDetail(transaction),
                      onDelete: () => _confirmDelete(transaction.id),
                    ),
                  ),
                ],
              ],
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
                    ref.read(borrowLendProvider.notifier).loadTransactions();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'borrow_lend_fab',
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddBorrowLendScreen()),
    );

    if (result == true && mounted) {
      ref
          .read(borrowLendProvider.notifier)
          .loadTransactions(type: _selectedType, status: _selectedStatus);
    }
  }

  void _navigateToDetail(BorrowLendModel transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transaction: transaction),
      ),
    );

    if (result == true && mounted) {
      ref
          .read(borrowLendProvider.notifier)
          .loadTransactions(type: _selectedType, status: _selectedStatus);
    }
  }

  void _confirmDelete(String transactionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure? This will also delete all repayment history.',
        ),
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
                    .read(borrowLendProvider.notifier)
                    .deleteTransaction(transactionId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted')),
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
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<TransactionType?>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(
                  value: TransactionType.borrowed,
                  child: Text('Borrowed'),
                ),
                DropdownMenuItem(
                  value: TransactionType.lent,
                  child: Text('Lent'),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TransactionStatus?>(
              value: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(
                  value: TransactionStatus.active,
                  child: Text('Active'),
                ),
                DropdownMenuItem(
                  value: TransactionStatus.settled,
                  child: Text('Settled'),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedStatus = null;
              });
              Navigator.pop(context);
              ref.read(borrowLendProvider.notifier).loadTransactions();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(borrowLendProvider.notifier)
                  .loadTransactions(
                    type: _selectedType,
                    status: _selectedStatus,
                  );
            },
            child: const Text('Apply'),
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
          title: const Text('Search by Person'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter person name',
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
                  ref.read(borrowLendProvider.notifier).searchByPerson(query);
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
