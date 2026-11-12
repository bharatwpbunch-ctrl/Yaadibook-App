import 'package:intl/intl.dart';

/// Formatter for dates and timestamps supporting localized output.
class DateFormatter {
  DateFormatter._();

  /// Formats a full expanded date (e.g. "Wednesday, 04 November 2026").
  static String formatLong(DateTime date, {String? locale}) {
    try {
      return DateFormat('EEEE, dd MMMM yyyy', locale).format(date);
    } catch (_) {
      return DateFormat('EEEE, dd MMMM yyyy', 'en').format(date);
    }
  }

  /// Formats a date into a standard short readable date (e.g. "04 Nov 2026").
  static String formatShort(DateTime date, {String? locale}) {
    try {
      return DateFormat('dd MMM yyyy', locale).format(date);
    } catch (_) {
      return DateFormat('dd MMM yyyy', 'en').format(date);
    }
  }

  /// Convenience alias for formatShort.
  static String formatDate(DateTime date, {String? locale}) =>
      formatShort(date, locale: locale);

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

  /// Formats relative time (e.g. "Just now", "5m ago", "2h ago", "Yesterday", "04 Nov 2026").
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatShort(date);
    }
  }
}
