/// Model for monthly opening balance
class OpeningBalanceModel {
  final String id;
  final int month;
  final int year;
  final double amount;
  final DateTime createdAt;

  OpeningBalanceModel({
    required this.id,
    required this.month,
    required this.year,
    required this.amount,
    required this.createdAt,
  });

  // Validation
  String? validate() {
    if (month < 1 || month > 12) {
      return 'Month must be between 1 and 12';
    }
    if (year < 2000 || year > 2100) {
      return 'Year must be between 2000 and 2100';
    }
    if (amount < 0) {
      return 'Amount cannot be negative';
    }
    return null;
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create from Map
  factory OpeningBalanceModel.fromMap(Map<String, dynamic> map) {
    return OpeningBalanceModel(
      id: map['id'] as String,
      month: map['month'] as int,
      year: map['year'] as int,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // CopyWith for updates
  OpeningBalanceModel copyWith({
    String? id,
    int? month,
    int? year,
    double? amount,
    DateTime? createdAt,
  }) {
    return OpeningBalanceModel(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'OpeningBalanceModel(id: $id, month: $month, year: $year, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OpeningBalanceModel &&
        other.id == id &&
        other.month == month &&
        other.year == year &&
        other.amount == amount;
  }

  @override
  int get hashCode {
    return id.hashCode ^ month.hashCode ^ year.hashCode ^ amount.hashCode;
  }
}
