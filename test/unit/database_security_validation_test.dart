import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Database Schema & Security Migrations Verification', () {
    const migrationDir = 'supabase/migrations';

    test('All 5 ordered migration files exist', () {
      final migrations = [
        '20261104170001_core_schema.sql',
        '20261104170002_crm_and_services.sql',
        '20261104170003_maintenance_and_amc.sql',
        '20261104170004_reminders_and_communication.sql',
        '20261104170005_storage_and_security.sql',
      ];

      for (final migration in migrations) {
        final file = File('$migrationDir/$migration');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Migration $migration must exist',
        );
      }
    });

    test('Row Level Security is explicitly enabled on all 15 core tables', () {
      final expectedTables = [
        'profiles',
        'businesses',
        'customers',
        'customer_addresses',
        'equipment',
        'service_entries',
        'maintenance_plans',
        'maintenance_occurrences',
        'amc_contracts',
        'amc_reminder_schedules',
        'reminders',
        'communication_logs',
        'notification_preferences',
        'business_settings',
        'audit_logs',
      ];

      final migrationFiles = Directory(migrationDir)
          .listSync()
          .whereType<File>()
          .map((f) => f.readAsStringSync())
          .join('\n');

      for (final table in expectedTables) {
        final rlsStatement =
            'ALTER TABLE public.$table ENABLE ROW LEVEL SECURITY;';
        expect(
          migrationFiles.contains(rlsStatement),
          isTrue,
          reason: 'Table $table must have RLS enabled via "$rlsStatement"',
        );
      }
    });

    test('Tenant isolation helper functions are defined and secure', () {
      final coreMigration = File(
        '$migrationDir/20261104170001_core_schema.sql',
      ).readAsStringSync();

      expect(
        coreMigration.contains('FUNCTION public.is_business_owner'),
        isTrue,
      );
      expect(coreMigration.contains('SECURITY DEFINER'), isTrue);
      expect(coreMigration.contains('SET search_path = public'), isTrue);
      expect(
        coreMigration.contains('FUNCTION public.get_my_business_id'),
        isTrue,
      );
    });

    test('Crucial business constraints and uniqueness rules are present', () {
      final m1 = File(
        '$migrationDir/20261104170001_core_schema.sql',
      ).readAsStringSync();
      final m2 = File(
        '$migrationDir/20261104170002_crm_and_services.sql',
      ).readAsStringSync();
      final m3 = File(
        '$migrationDir/20261104170003_maintenance_and_amc.sql',
      ).readAsStringSync();

      // One owner = One business in MVP
      expect(m1.contains('owner_user_id UUID NOT NULL UNIQUE'), isTrue);

      // Composite foreign key on customer_addresses
      expect(m2.contains('fk_customer_addresses_customer'), isTrue);

      // Non-negative monetary amounts
      expect(m2.contains('service_amount >= 0'), isTrue);
      expect(m3.contains('contract_amount >= 0'), isTrue);

      // AMC date validation
      expect(
        m3.contains('chk_amc_contract_dates CHECK (end_date >= start_date)'),
        isTrue,
      );

      // Prevent duplicate occurrences
      expect(
        m3.contains('uq_plan_due_date UNIQUE (maintenance_plan_id, due_date)'),
        isTrue,
      );

      // Prevent duplicate AMC reminder offsets
      expect(
        m3.contains(
          'uq_amc_contract_offset UNIQUE (amc_contract_id, days_before_expiry)',
        ),
        isTrue,
      );
    });

    test('Storage buckets and path isolation policies are configured', () {
      final storageMigration = File(
        '$migrationDir/20261104170005_storage_and_security.sql',
      ).readAsStringSync();

      expect(storageMigration.contains('business-assets'), isTrue);
      expect(storageMigration.contains('customer-attachments'), isTrue);
      expect(storageMigration.contains('service-attachments'), isTrue);
      expect(storageMigration.contains('amc-documents'), isTrue);
      expect(storageMigration.contains('public.is_business_owner'), isTrue);
      expect(
        storageMigration.contains('(storage.foldername(name))[1]'),
        isTrue,
      );
    });

    test('Seed file exists with realistic non-real data', () {
      final seedFile = File('supabase/seed.sql');
      expect(seedFile.existsSync(), isTrue);

      final content = seedFile.readAsStringSync();
      expect(content.contains('Maruti AC & CCTV Services'), isTrue);
      expect(content.contains('Kailash Electronics'), isTrue);
      expect(content.contains('testowner@yaadibook.app'), isTrue);
    });
  });
}
