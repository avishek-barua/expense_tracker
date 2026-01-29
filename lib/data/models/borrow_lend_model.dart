import 'package:uuid/uuid.dart';

/// Type of transaction
enum TransactionType {
  borrowed('borrowed'),  // Money you borrowed from someone
  lent('lent');          // Money you lent to someone

  const TransactionType(this.value);
  final String value;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid transaction type: $value'),
    );
  }
}

/// Status of the transaction
enum TransactionStatus {
  active('active'),      // Money not fully repaid
  settled('settled');    // Fully repaid

  const TransactionStatus(this.value);
  final String value;

  static TransactionStatus fromString(String value) {
    return TransactionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Invalid transaction status: $value'),
    );
  }
}

/// Represents money borrowed from or lent to someone
/// 
/// This model tracks the overall loan. Individual repayments are tracked
/// separately in the RepaymentModel.
class BorrowLendModel {
  final String id;
  final TransactionType type;
  final String personName;
  final double originalAmount;  // Initial loan amount (never changes)
  final double remainingAmount;  // Decreases with each repayment
  final DateTime date;  // Date of the loan
  final TransactionStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BorrowLendModel({
    required this.id,
    required this.type,
    required this.personName,
    required this.originalAmount,
    required this.remainingAmount,
    required this.date,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor for creating new transactions
  factory BorrowLendModel.create({
    required TransactionType type,
    required String personName,
    required double amount,
    required DateTime date,
    String? notes,
  }) {
    final now = DateTime.now();
    return BorrowLendModel(
      id: const Uuid().v4(),
      type: type,
      personName: personName.trim(),
      originalAmount: amount,
      remainingAmount: amount,  // Initially, nothing is repaid
      date: date,
      status: TransactionStatus.active,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: now,
      updatedAt: null,
    );
  }

  /// Convert from SQLite Map
  factory BorrowLendModel.fromMap(Map<String, dynamic> map) {
    return BorrowLendModel(
      id: map['id'] as String,
      type: TransactionType.fromString(map['type'] as String),
      personName: map['person_name'] as String,
      originalAmount: map['original_amount'] as double,
      remainingAmount: map['remaining_amount'] as double,
      date: DateTime.parse(map['date'] as String),
      status: TransactionStatus.fromString(map['status'] as String),
      notes: map['notes'] as String?,
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
      'type': type.value,
      'person_name': personName,
      'original_amount': originalAmount,
      'remaining_amount': remainingAmount,
      'date': date.toIso8601String(),
      'status': status.value,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with optional field updates
  BorrowLendModel copyWith({
    String? id,
    TransactionType? type,
    String? personName,
    double? originalAmount,
    double? remainingAmount,
    DateTime? date,
    TransactionStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BorrowLendModel(
      id: id ?? this.id,
      type: type ?? this.type,
      personName: personName ?? this.personName,
      originalAmount: originalAmount ?? this.originalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Computed: How much has been repaid
  double get totalRepaid => originalAmount - remainingAmount;

  /// Computed: Percentage repaid (0.0 to 1.0)
  double get repaymentProgress => 
      originalAmount > 0 ? totalRepaid / originalAmount : 0.0;

  /// Computed: Is this fully settled?
  bool get isSettled => remainingAmount <= 0.01;  // Using epsilon for float comparison

  /// Apply a repayment to this transaction
  /// Returns updated BorrowLendModel with new remaining amount
  BorrowLendModel applyRepayment(double repaymentAmount) {
    final newRemaining = remainingAmount - repaymentAmount;
    final newStatus = newRemaining <= 0.01 
        ? TransactionStatus.settled 
        : TransactionStatus.active;

    return copyWith(
      remainingAmount: newRemaining.clamp(0.0, originalAmount),
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  /// Validation
  String? validate() {
    if (originalAmount <= 0) {
      return 'Amount must be greater than zero';
    }
    if (personName.trim().isEmpty) {
      return 'Person name cannot be empty';
    }
    if (remainingAmount < 0) {
      return 'Remaining amount cannot be negative';
    }
    if (remainingAmount > originalAmount) {
      return 'Remaining amount cannot exceed original amount';
    }
    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return 'Date cannot be in the future';
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BorrowLendModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BorrowLendModel(id: $id, type: ${type.value}, personName: $personName, '
        'originalAmount: $originalAmount, remainingAmount: $remainingAmount, '
        'status: ${status.value})';
  }
}