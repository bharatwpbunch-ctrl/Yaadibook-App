import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/core/errors/app_exception.dart';
import 'package:yaadibook/shared/models/models.dart';
import 'package:yaadibook/shared/repositories/repositories.dart';

void main() {
  group('Backend Repositories Foundation', () {
    test('SupabaseAuthRepository gracefully handles null/offline client', () {
      final authRepo = SupabaseAuthRepository(null);

      expect(authRepo.currentUser, isNull);
      expect(authRepo.currentSession, isNull);

      // Throws AppAuthException when trying to execute operations without client
      expect(
        () => authRepo.signInWithOtp(phone: '+919825012345'),
        throwsA(isA<AppAuthException>()),
      );
    });

    test(
      'SupabaseBusinessRepository gracefully handles null/offline client',
      () {
        final businessRepo = SupabaseBusinessRepository(null);

        expect(
          () => businessRepo.getMyBusiness(),
          throwsA(isA<AppStorageException>()),
        );

        expect(
          () => businessRepo.createBusinessWorkspace(
            businessName: 'Test Business',
            businessCategory: 'AC',
            phone: '+919825012345',
            addressLine1: 'Test Address',
            city: 'Ahmedabad',
            postalCode: '380009',
          ),
          throwsA(isA<AppStorageException>()),
        );
      },
    );

    test('SupabaseCustomerRepository guards against uninitialized client', () {
      final customerRepo = SupabaseCustomerRepository(null);

      expect(
        () => customerRepo.getCustomers(),
        throwsA(isA<AppStorageException>()),
      );

      expect(
        () => customerRepo.createCustomer(
          businessId: 'biz-1',
          fullName: 'Test Customer',
          primaryPhone: '+919825012345',
        ),
        throwsA(isA<AppStorageException>()),
      );
    });

    test('SupabaseServiceRepository guards against uninitialized client', () {
      final serviceRepo = SupabaseServiceRepository(null);

      expect(
        () => serviceRepo.getServiceEntries(),
        throwsA(isA<AppStorageException>()),
      );

      final entry = ServiceEntry(
        id: 'srv-1',
        businessId: 'biz-1',
        customerId: 'cust-1',
        serviceType: 'repair',
        title: 'Repair Task',
        serviceDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => serviceRepo.createServiceEntry(entry),
        throwsA(isA<AppStorageException>()),
      );
    });

    test('SupabaseReminderRepository guards against uninitialized client', () {
      final reminderRepo = SupabaseReminderRepository(null);

      expect(
        () => reminderRepo.getReminders(),
        throwsA(isA<AppStorageException>()),
      );

      expect(
        () => reminderRepo.markCompleted('rem-1'),
        throwsA(isA<AppStorageException>()),
      );
    });
  });
}
