import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/shared/models/models.dart';

void main() {
  group('Domain Models Validation', () {
    test('Customer model serializes and deserializes cleanly', () {
      final now = DateTime.now();
      final customer = Customer(
        id: 'cust-1',
        businessId: 'biz-1',
        fullName: 'Kailash Electronics',
        primaryPhone: '+919825012345',
        alternatePhone: '+917926401234',
        email: 'kailash@example.com',
        notes: 'Corporate client',
        source: 'Referral',
        createdAt: now,
        updatedAt: now,
      );

      final json = customer.toJson();
      final deserialized = Customer.fromJson(json);

      expect(deserialized.id, 'cust-1');
      expect(deserialized.businessId, 'biz-1');
      expect(deserialized.fullName, 'Kailash Electronics');
      expect(deserialized.primaryPhone, '+919825012345');
      expect(deserialized.isArchived, isFalse);
    });

    test('Customer archive state is correctly determined', () {
      final now = DateTime.now();
      final archivedCustomer = Customer(
        id: 'cust-2',
        businessId: 'biz-1',
        fullName: 'Archived Client',
        primaryPhone: '+919825099999',
        archivedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(archivedCustomer.isArchived, isTrue);
    });

    test(
      'ServiceEntry can exist without equipment (Equipment tracking optional)',
      () {
        final now = DateTime.now();
        final serviceEntry = ServiceEntry(
          id: 'srv-1',
          businessId: 'biz-1',
          customerId: 'cust-1',
          equipmentId: null, // Service without equipment
          serviceType: 'repair',
          title: 'AC Gas Refill',
          serviceDate: now,
          status: 'completed',
          serviceAmount: 1450.00,
          paymentStatus: 'paid',
          createdAt: now,
          updatedAt: now,
        );

        expect(serviceEntry.equipmentId, isNull);
        expect(serviceEntry.serviceAmount, 1450.00);

        final json = serviceEntry.toJson();
        expect(json['equipment_id'], isNull);

        final deserialized = ServiceEntry.fromJson(json);
        expect(deserialized.equipmentId, isNull);
      },
    );

    test('AmcContract serializes dates and amounts accurately', () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2027, 1, 1);
      final now = DateTime.now();

      final amc = AmcContract(
        id: 'amc-1',
        businessId: 'biz-1',
        customerId: 'cust-1',
        contractTitle: 'Annual Security AMC',
        startDate: start,
        endDate: end,
        contractAmount: 12500.00,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      expect(amc.contractAmount, 12500.00);
      expect(amc.endDate.isAfter(amc.startDate), isTrue);

      final json = amc.toJson();
      final deserialized = AmcContract.fromJson(json);

      expect(deserialized.contractTitle, 'Annual Security AMC');
      expect(deserialized.contractAmount, 12500.00);
    });

    test(
      'Reminder can exist without a customer (General Business Reminder)',
      () {
        final now = DateTime.now();
        final reminder = Reminder(
          id: 'rem-1',
          businessId: 'biz-1',
          customerId: null, // General reminder
          title: 'Renew GST Registration',
          reminderType: 'general',
          dueAt: now.add(const Duration(days: 5)),
          status: 'scheduled',
          createdAt: now,
          updatedAt: now,
        );

        expect(reminder.customerId, isNull);
        expect(reminder.isCompleted, isFalse);

        final json = reminder.toJson();
        final deserialized = Reminder.fromJson(json);
        expect(deserialized.customerId, isNull);
        expect(deserialized.title, 'Renew GST Registration');
      },
    );

    test('Business model preserves default settings and timezone', () {
      final now = DateTime.now();
      final business = Business(
        id: 'biz-1',
        ownerUserId: 'user-1',
        businessName: 'Maruti Services',
        businessCategory: 'CCTV & AC',
        phone: '+919825012345',
        addressLine1: 'CG Road',
        city: 'Ahmedabad',
        postalCode: '380009',
        currencyCode: 'INR',
        timezone: 'Asia/Kolkata',
        preferredLanguage: 'gu',
        createdAt: now,
        updatedAt: now,
      );

      expect(business.currencyCode, 'INR');
      expect(business.timezone, 'Asia/Kolkata');
      expect(business.preferredLanguage, 'gu');
      expect(business.state, 'Gujarat');
    });
  });
}
