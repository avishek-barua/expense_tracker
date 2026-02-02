import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/data/datasources/local_database.dart';
import 'package:expense_tracker/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/domain/repositories/income_repository.dart';
import 'package:expense_tracker/domain/repositories/borrow_lend_repository.dart';
import 'package:expense_tracker/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/data/repositories/income_repository_impl.dart';
import 'package:expense_tracker/data/repositories/borrow_lend_repository_impl.dart';

/// Database instance provider (singleton)
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase.instance;
});

/// Expense repository provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final database = ref.watch(localDatabaseProvider);
  return ExpenseRepositoryImpl(database);
});

/// Income repository provider
final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  final database = ref.watch(localDatabaseProvider);
  return IncomeRepositoryImpl(database);
});

/// Borrow/Lend repository provider
final borrowLendRepositoryProvider = Provider<BorrowLendRepository>((ref) {
  final database = ref.watch(localDatabaseProvider);
  return BorrowLendRepositoryImpl(database);
});
