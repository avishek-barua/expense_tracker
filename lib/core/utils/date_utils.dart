import 'package:intl/intl.dart';

/// Date formatting and manipulation utilities
class DateUtils {
  /// Format date as "Jan 27, 2025"
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Format date as "27/01/2025"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format date as "January 27, 2025"
  static String formatDateLong(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  /// Format as "Today", "Yesterday", or date
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference == -1) {
      return 'Tomorrow';
    } else if (difference > 1 && difference <= 7) {
      return '$difference days ago';
    } else if (difference < -1 && difference >= -7) {
      return 'In ${-difference} days';
    } else {
      return formatDate(date);
    }
  }

  /// Format time as "2:30 PM"
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Format date and time as "Jan 27, 2025 at 2:30 PM"
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at ${formatTime(dateTime)}';
  }

  /// Get start of day (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day (23:59:59.999)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of current month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of current month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  /// Get start of current week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return startOfDay(monday);
  }

  /// Get end of current week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final sunday = date.add(Duration(days: 7 - date.weekday));
    return endOfDay(sunday);
  }

  /// Get start of current year
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Get end of current year
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59, 999);
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Check if date is in current month
  static bool isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Get month name
  static String getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2000, month));
  }

  /// Get days in month
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Calculate days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    final fromDate = startOfDay(from);
    final toDate = startOfDay(to);
    return toDate.difference(fromDate).inDays;
  }

  /// Get date range description
  static String describeDateRange(DateTime start, DateTime end) {
    if (isSameDay(start, end)) {
      return formatDate(start);
    }

    final now = DateTime.now();
    final startOfThisMonth = startOfMonth(now);
    final endOfThisMonth = endOfMonth(now);

    if (isSameDay(start, startOfThisMonth) && 
        isSameDay(end, endOfThisMonth)) {
      return 'This Month';
    }

    final startOfThisWeek = startOfWeek(now);
    final endOfThisWeek = endOfWeek(now);

    if (isSameDay(start, startOfThisWeek) && 
        isSameDay(end, endOfThisWeek)) {
      return 'This Week';
    }

    return '${formatDate(start)} - ${formatDate(end)}';
  }
}