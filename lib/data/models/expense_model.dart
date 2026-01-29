import 'package:uuid/uuid.dart';

/// Represents a single expense entry
/// 
/// This model is immutable - use copyWith() to create modified copies.
/// All monetary amounts are stored as double (SQLite REAL type).
class ExpenseModel {
  final String id;
  final double amount;
  final String? category;  // Nullable: not all expenses need categorization
  final String description;
  final DateTime date;  // User-chosen date (may differ from createdAt)
  final DateTime createdAt;  // Actual timestamp of creation
  final DateTime? updatedAt;  // Null if never updated

  const ExpenseModel({
    required this.id,
    required this.amount,
    this.category,
    required this.description,
    required this.date,
    required this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor for creating new expenses
  /// Auto-generates ID and timestamps
  factory ExpenseModel.create({
    required double amount,
    String? category,
    required String description,
    required DateTime date,
  }) {
    final now = DateTime.now();
    return ExpenseModel(
      id: const Uuid().v4(),
      amount: amount,
      category: category?.trim().isEmpty == true ? null : category?.trim(),
      description: description.trim(),
      date: date,
      createdAt: now,
      updatedAt: null,
    );
  }

  /// Convert from SQLite Map to ExpenseModel
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String,
      amount: map['amount'] as double,
      category: map['category'] as String?,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert to SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with optional field updates
  ExpenseModel copyWith({
    String? id,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validation: Check if expense is valid before saving
  /// Returns error message or null if valid
  String? validate() {
    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }
    if (description.trim().isEmpty) {
      return 'Description cannot be empty';
    }
    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return 'Date cannot be in the future';
    }
    return null;  // Valid
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ExpenseModel(id: $id, amount: $amount, category: $category, '
        'description: $description, date: $date)';
  }
}