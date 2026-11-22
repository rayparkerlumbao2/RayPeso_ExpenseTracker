import 'package:intl/intl.dart';

class AppFormatters {
  static String formatCurrency(
    double amount, {
    String currencySymbol = '₱',
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat.yMMMM().format(date);
  }

  static String formatMonthShort(DateTime date) {
    return DateFormat.MMM().format(date);
  }

  static String formatFullDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diffDays = target.difference(today).inDays;

    if (diffDays == 0) {
      return 'Today';
    } else if (diffDays == -1) {
      return 'Yesterday';
    } else if (diffDays == 1) {
      return 'Tomorrow';
    } else if (target.year == now.year) {
      return DateFormat('EEE, MMM d').format(date);
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  static String formatTime(DateTime date) {
    return DateFormat.jm().format(date);
  }

  static String formatPercentage(double ratio) {
    final pct = (ratio * 100);
    return '${pct.toStringAsFixed(1)}%';
  }
}
