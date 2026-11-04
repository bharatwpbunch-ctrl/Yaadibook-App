import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats standard INR amounts with Indian numbering system', () {
      expect(CurrencyFormatter.format(0), '₹0');
      expect(CurrencyFormatter.format(999), '₹999');
      expect(CurrencyFormatter.format(1250), '₹1,250');
      expect(CurrencyFormatter.format(25000), '₹25,000');
      expect(CurrencyFormatter.format(150000), '₹1,50,000');
      expect(CurrencyFormatter.format(10000000), '₹1,00,00,000');
    });

    test('formats decimals when showDecimals is true', () {
      expect(
        CurrencyFormatter.format(1250.50, showDecimals: true),
        '₹1,250.50',
      );
    });

    test('formats compact amounts correctly', () {
      expect(CurrencyFormatter.formatCompact(500), '₹500');
      expect(CurrencyFormatter.formatCompact(1500), '₹1.5k');
      expect(CurrencyFormatter.formatCompact(250000), '₹2.5L');
      expect(CurrencyFormatter.formatCompact(10000000), '₹1 Cr');
    });
  });
}
