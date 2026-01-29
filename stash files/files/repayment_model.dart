import 'package:uuid/uuid.dart';

/// Represents a single repayment installment for a BorrowLend transaction
/// 
/// Multiple repayments can be linked to one BorrowLendModel via borrowLendId.
/// This enables tracking partial payments over time.
class RepaymentModel {
  final String id;
  final String borrowLendId;  // Foreign key to BorrowLendModel
  final double amount;
  final DateTime date;  // Date of this specific repayment
  final String? notes;
  final DateTime createdAt;

  const RepaymentModel({
    required this.id,
    required this.borrowLendId,
    required this.amount,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  /// Factory constructor for creating new repayments
  factory RepaymentModel.create({
    required String borrowLendId,
    required double amount,
    required DateTime date,
    String? notes,
  }) {
    return RepaymentModel(
      id: const Uuid().v4(),
      borrowLendId: borrowLendId,
      amount: amount,
      date: date,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: DateTime.now(),
    );
  }

  /// Convert from SQLite Map
  factory RepaymentModel.fromMap(Map<String, dynamic> map) {
    return RepaymentModel(
      id: map['id'] as String,
      borrowLendId: map['borrow_lend_id'] as String,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'borrow_lend_id': borrowLendId,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with optional field updates
  RepaymentModel copyWith({
    String? id,
    String? borrowLendId,
    double? amount,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return RepaymentModel(
      id: id ?? this.id,
      borrowLendId: borrowLendId ?? this.borrowLendId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Validation
  String? validate() {
    if (amount <= 0) {
      return 'Repayment amount must be greater than zero';
    }
    if (borrowLendId.trim().isEmpty) {
      return 'Must be linked to a borrow/lend transaction';
    }
    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return 'Date cannot be in the future';
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepaymentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RepaymentModel(id: $id, borrowLendId: $borrowLendId, '
        'amount: $amount, date: $date)';
  }
}
