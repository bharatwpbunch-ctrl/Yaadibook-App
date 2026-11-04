import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    final testDate = DateTime(2026, 11, 4, 16, 30);

    test('formatShort outputs standard day-month-year', () {
      final formatted = DateFormatter.formatShort(testDate);
      expect(formatted, contains('2026'));
      expect(formatted, contains('Nov'));
      expect(formatted, contains('04'));
    });

    test('formatDateTime outputs date and time', () {
      final formatted = DateFormatter.formatDateTime(testDate);
      expect(formatted, contains('04 Nov 2026'));
      expect(formatted, contains('04:30'));
    });

    test('formatTime outputs 12-hour formatted time', () {
      final formatted = DateFormatter.formatTime(testDate);
      expect(formatted, '04:30 PM');
    });

    test('formatMonthYear outputs full month name and year', () {
      final formatted = DateFormatter.formatMonthYear(testDate);
      expect(formatted, 'November 2026');
    });
  });
}
