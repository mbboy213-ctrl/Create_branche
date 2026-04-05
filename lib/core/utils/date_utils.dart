import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatTimestamp(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
  }

  static String formatShortDate(DateTime dt) {
    return DateFormat('MM/dd/yyyy').format(dt);
  }

  static String formatMonthYear(DateTime dt) {
    return DateFormat('MMM yyyy').format(dt);
  }

  static String formatTime(DateTime dt) {
    return DateFormat('HH:mm:ss').format(dt);
  }

  static DateTime startOfMonth(DateTime dt) {
    return DateTime(dt.year, dt.month, 1);
  }

  static DateTime endOfMonth(DateTime dt) {
    return DateTime(dt.year, dt.month + 1, 0, 23, 59, 59);
  }

  static DateTime startOfYear(DateTime dt) {
    return DateTime(dt.year, 1, 1);
  }

  static DateTime endOfYear(DateTime dt) {
    return DateTime(dt.year, 12, 31, 23, 59, 59);
  }

  static List<String> getLast12Months() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final month = DateTime(now.year, now.month - i, 1);
      return DateFormat('MMM yyyy').format(month);
    }).reversed.toList();
  }

  static List<String> getLast5Years() {
    final now = DateTime.now();
    return List.generate(5, (i) => (now.year - 4 + i).toString());
  }
}
