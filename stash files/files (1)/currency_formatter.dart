import 'package:intl/intl.dart';

/// Supported currencies
enum Currency {
  bdt('BDT', '৳', 'en_BD'),
  usd('USD', '\$', 'en_US'),
  eur('EUR', '€', 'de_DE');

  const Currency(this.code, this.symbol, this.locale);
  
  final String code;
  final String symbol;
  final String locale;
}

/// Currency formatting utility
/// 
/// Handles formatting numbers as currency strings with proper symbols and locales.
class CurrencyFormatter {
  // Default currency (can be changed by user later)
  static Currency _defaultCurrency = Currency.bdt;

  /// Get current default currency
  static Currency get defaultCurrency => _defaultCurrency;

  /// Set default currency
  static void setDefaultCurrency(Currency currency) {
    _defaultCurrency = currency;
  }

  /// Format amount with default currency
  static String format(double amount, {bool compact = false}) {
    return formatWithCurrency(amount, _defaultCurrency, compact: compact);
  }

  /// Format amount with specific currency
  static String formatWithCurrency(
    double amount,
    Currency currency, {
    bool compact = false,
  }) {
    if (compact) {
      return _formatCompact(amount, currency);
    }

    final formatter = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    return formatter.format(amount);
  }

  /// Format large numbers compactly (e.g., 1.5K, 2.3M)
  static String _formatCompact(double amount, Currency currency) {
    if (amount.abs() < 1000) {
      return formatWithCurrency(amount, currency);
    }

    String suffix;
    double divisor;

    if (amount.abs() >= 1000000000) {
      suffix = 'B';
      divisor = 1000000000;
    } else if (amount.abs() >= 1000000) {
      suffix = 'M';
      divisor = 1000000;
    } else {
      suffix = 'K';
      divisor = 1000;
    }

    final compactValue = amount / divisor;
    return '${currency.symbol}${compactValue.toStringAsFixed(1)}$suffix';
  }

  /// Parse currency string back to double
  /// Example: "৳1,234.56" -> 1234.56
  static double? parse(String currencyString) {
    try {
      // Remove currency symbols and whitespace
      String cleaned = currencyString
          .replaceAll(RegExp(r'[৳\$€,\s]'), '')
          .trim();
      
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }

  /// Format without symbol (just the number)
  static String formatNumberOnly(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }

  /// Check if amount is positive/negative and format with color indication
  static String formatWithSign(double amount) {
    final formatted = format(amount.abs());
    if (amount > 0) {
      return '+$formatted';
    } else if (amount < 0) {
      return '-$formatted';
    }
    return formatted;
  }
}
