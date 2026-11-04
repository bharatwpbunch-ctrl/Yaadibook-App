import 'package:intl/intl.dart';

/// Formatter for dates and timestamps supporting localized output.
class DateFormatter {
  DateFormatter._();

  /// Formats a date into a standard short readable date (e.g. "04 Nov 2026").
  static String formatShort(DateTime date, {String? locale}) {
    try {
      return DateFormat('dd MMM yyyy', locale).format(date);
    } catch (_) {
      return DateFormat('dd MMM yyyy', 'en').format(date);
    }
  }

  /// Formats a date with time (e.g. "04 Nov 2026, 04:30 PM").
  static String formatDateTime(DateTime date, {String? locale}) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a', locale).format(date);
    } catch (_) {
      return DateFormat('dd MMM yyyy, hh:mm a', 'en').format(date);
    }
  }

  /// Formats time only (e.g. "04:30 PM").
  static String formatTime(DateTime date, {String? locale}) {
    try {
      return DateFormat('hh:mm a', locale).format(date);
    } catch (_) {
      return DateFormat('hh:mm a', 'en').format(date);
    }
  }

  /// Formats date for month and year headers (e.g. "November 2026").
  static String formatMonthYear(DateTime date, {String? locale}) {
    try {
      return DateFormat('MMMM yyyy', locale).format(date);
    } catch (_) {
      return DateFormat('MMMM yyyy', 'en').format(date);
    }
  }
}
