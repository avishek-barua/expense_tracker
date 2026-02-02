import 'package:uuid/uuid.dart';

/// Represents money received (salary, gifts, freelance, etc.)
/// 
/// This is separate from expenses and borrow/lend transactions.
/// Refunds and loan repayments are NOT income—they're tracked separately.
class IncomeModel {
  final String id;
  final double amount;
  final String source;  // Freeform: "January Salary", "Birthday Gift", etc.
  final String? category;  // Optional: "Salary", "Gift", "Freelance", "Other"
  final String description;
  final DateTime date;  // User-chosen date (may differ from createdAt)
  final DateTime createdAt;  // Actual timestamp of creation
  final DateTime? updatedAt;  // Null if never updated

  const IncomeModel({
    required this.id,
    required this.amount,
    required this.source,
    this.category,
    required this.description,
    required this.date,
    required this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor for creating new income entries
  /// Auto-generates ID and timestamps
  factory IncomeModel.create({
    required double amount,
    required String source,
    String? category,
    required String description,
    required DateTime date,
  }) {
    final now = DateTime.now();
    return IncomeModel(
      id: const Uuid().v4(),
      amount: amount,
      source: source.trim(),
      category: category?.trim().isEmpty == true ? null : category?.trim(),
      description: description.trim(),
      date: date,
      createdAt: now,
      updatedAt: null,
    );
  }

  /// Convert from SQLite Map to IncomeModel
  factory IncomeModel.fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      id: map['id'] as String,
      amount: map['amount'] as double,
      source: map['source'] as String,
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
      'source': source,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with optional field updates
  IncomeModel copyWith({
    String? id,
    double? amount,
    String? source,
    String? category,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncomeModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validation: Check if income is valid before saving
  /// Returns error message or null if valid
  String? validate() {
    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }
    if (source.trim().isEmpty) {
      return 'Source cannot be empty';
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
    return other is IncomeModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'IncomeModel(id: $id, amount: $amount, source: $source, '
        'category: $category, description: $description, date: $date)';
  }
}
