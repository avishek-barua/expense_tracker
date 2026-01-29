/// Application-wide constants
class AppConstants {
  // App info
  static const String appName = 'Expense Tracker';
  static const String appVersion = '1.0.0';
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // Border radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  
  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Date formats
  static const String dateFormatShort = 'dd/MM/yyyy';
  static const String dateFormatLong = 'MMMM d, y';
  static const String timeFormat = 'h:mm a';
  
  // Validation
  static const double minAmount = 0.01;
  static const double maxAmount = 999999999.99;
  static const int maxDescriptionLength = 200;
  static const int maxNotesLength = 500;
  
  // Pagination
  static const int defaultPageSize = 50;
  
  // Category suggestions (can be user-editable later)
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Travel',
    'Other',
  ];
  
  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Gift',
    'Other',
  ];
}