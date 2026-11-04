import 'package:intl/intl.dart';

/// Formatter for Indian Rupee (INR) currency values.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats a numeric amount to INR representation (e.g. ₹1,250 or ₹2,50,000).
  ///
  /// Uses Indian number formatting system (thousands, then lakhs and crores).
  static String format(
    num amount, {
    bool showDecimals = false,
    String symbol = '₹',
  }) {
    try {
      final pattern = showDecimals ? '##,##,##0.00' : '##,##,##0';
      final formatter = NumberFormat(pattern, 'en_IN');
      final formattedNumber = formatter.format(amount);
      return '$symbol$formattedNumber';
    } catch (_) {
      // Fallback format
      return '$symbol$amount';
    }
  }

  /// Compact formatting for overview badges or stat cards (e.g. ₹2.5L, ₹15K).
  static String formatCompact(num amount, {String symbol = '₹'}) {
    if (amount >= 10000000) {
      final cr = amount / 10000000;
      return '$symbol${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 1)} Cr';
    } else if (amount >= 100000) {
      final lakh = amount / 100000;
      return '$symbol${lakh.toStringAsFixed(lakh.truncateToDouble() == lakh ? 0 : 1)}L';
    } else if (amount >= 1000) {
      final k = amount / 1000;
      return '$symbol${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k';
    }
    return format(amount, symbol: symbol);
  }
}
