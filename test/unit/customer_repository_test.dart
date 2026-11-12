import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/core/services/communication_service.dart';
import 'package:yaadibook/features/customers/models/customer_activity_item.dart';
import 'package:yaadibook/shared/models/customer.dart';
import 'package:yaadibook/shared/models/customer_address.dart';

void main() {
  group('CommunicationService Phone Normalization & Formatting Tests', () {
    test('normalizes 10-digit raw number', () {
      expect(
        CommunicationService.normalizePhoneNumber('9825012345'),
        '9825012345',
      );
    });

    test('normalizes +91 country code prefix with spaces and dashes', () {
      expect(
        CommunicationService.normalizePhoneNumber('+91 98250-12345'),
        '9825012345',
      );
      expect(
        CommunicationService.normalizePhoneNumber('+919825012345'),
        '9825012345',
      );
    });

    test('normalizes leading 0 (trunk prefix)', () {
      expect(
        CommunicationService.normalizePhoneNumber('09825012345'),
        '9825012345',
      );
    });

    test('normalizes leading 91 without plus when 12 digits total', () {
      expect(
        CommunicationService.normalizePhoneNumber('919825012345'),
        '9825012345',
      );
    });

    test('formats valid 10-digit phone for WhatsApp with 91 prefix', () {
      expect(
        CommunicationService.formatForWhatsApp('9825012345'),
        '919825012345',
      );
      expect(
        CommunicationService.formatForWhatsApp('+91 98250 12345'),
        '919825012345',
      );
    });
  });

  group('Customer & CustomerAddress Model Tests', () {
    test('computes initials correctly for single and multi-word names', () {
      final c1 = Customer(
        id: 'cust-1',
        businessId: 'biz-1',
        fullName: 'Ramesh Patel',
        primaryPhone: '9825012345',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(c1.initials, 'RP');

      final c2 = Customer(
        id: 'cust-2',
        businessId: 'biz-1',
        fullName: 'Suresh',
        primaryPhone: '9825012346',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(c2.initials, 'S');

      final c3 = Customer(
        id: 'cust-3',
        businessId: 'biz-1',
        fullName: 'Shree Krishna Traders Pvt Ltd',
        primaryPhone: '9825012347',
        customerType: 'business',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(c3.initials, 'SK');
      expect(c3.isBusiness, isTrue);
    });

    test('formats address cleanly skipping empty fields', () {
      final addr = CustomerAddress(
        id: 'addr-1',
        businessId: 'biz-1',
        customerId: 'cust-1',
        addressLine1: 'Shop 12, Galaxy Complex',
        area: 'Satellite',
        city: 'Ahmedabad',
        state: 'Gujarat',
        postalCode: '380015',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        addr.formattedAddress,
        'Shop 12, Galaxy Complex, Satellite, Ahmedabad, Gujarat, 380015',
      );
    });

    test(
      'Customer model incorporates primary address and location summary',
      () {
        final addr = CustomerAddress(
          id: 'addr-1',
          businessId: 'biz-1',
          customerId: 'cust-1',
          addressLine1: 'Shop 12',
          area: 'Satellite',
          city: 'Ahmedabad',
          state: 'Gujarat',
          postalCode: '380015',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final customer = Customer(
          id: 'cust-1',
          businessId: 'biz-1',
          fullName: 'Mukesh Ambani',
          primaryPhone: '9825099999',
          addresses: [addr],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(customer.primaryAddress, isNotNull);
        expect(customer.area, 'Satellite');
        expect(customer.city, 'Ahmedabad');
        expect(customer.locationSummary, 'Satellite, Ahmedabad');
      },
    );

    test(
      'Customer copyWith preserves or updates customerType and archive status',
      () {
        final c = Customer(
          id: 'cust-1',
          businessId: 'biz-1',
          fullName: 'Pooja Shah',
          primaryPhone: '9825000000',
          customerType: 'individual',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(c.isArchived, isFalse);

        final archived = c.copyWith(archivedAt: DateTime.now());
        expect(archived.isArchived, isTrue);

        final businessType = c.copyWith(customerType: 'business');
        expect(businessType.isBusiness, isTrue);
      },
    );
  });

  group('CustomerActivityItem Tests', () {
    test(
      'instantiates activity types and preserves chronological timestamps',
      () {
        final t1 = DateTime(2026, 11, 1, 10, 0);
        final t2 = DateTime(2026, 11, 2, 14, 30);

        final item1 = CustomerActivityItem(
          id: 'act-1',
          type: CustomerActivityType.created,
          title: 'Customer Added',
          description: 'Customer profile was created',
          timestamp: t1,
        );

        final item2 = CustomerActivityItem(
          id: 'act-2',
          type: CustomerActivityType.call,
          title: 'Phone Call',
          description: 'Call initiated to 9825012345',
          timestamp: t2,
        );

        expect(item1.subtitle, 'Customer profile was created');
        expect(item2.type, CustomerActivityType.call);
        expect(item2.timestamp.isAfter(item1.timestamp), isTrue);
      },
    );
  });
}
