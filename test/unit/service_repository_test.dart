import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/shared/models/equipment.dart';
import 'package:yaadibook/shared/models/service_activity.dart';
import 'package:yaadibook/shared/models/service_attachment.dart';
import 'package:yaadibook/shared/models/service_entry.dart';
import 'package:yaadibook/shared/repositories/service_repository.dart';

void main() {
  group('ServiceEntry Entity & Amount Calculation Tests', () {
    test(
      'computedTotal calculates base + additional - discount accurately',
      () {
        final entry = ServiceEntry(
          id: 'srv-1',
          businessId: 'biz-1',
          customerId: 'cust-1',
          serviceType: 'repair',
          title: 'AC Gas Refill',
          serviceDate: DateTime(2026, 11, 5),
          status: 'pending',
          serviceAmount: 1500.0,
          additionalCharges: 300.0,
          discountAmount: 200.0,
          createdAt: DateTime(2026, 11, 5),
          updatedAt: DateTime(2026, 11, 5),
        );

        expect(entry.computedTotal, equals(1600.0));
        expect(entry.serviceTypeDisplay, equals('Repair'));
        expect(entry.isPending, isTrue);
        expect(entry.isInProgress, isFalse);
        expect(entry.isCompleted, isFalse);
        expect(entry.isCancelled, isFalse);
      },
    );

    test('computedTotal clamps to 0 if discount exceeds charges', () {
      final entry = ServiceEntry(
        id: 'srv-2',
        businessId: 'biz-1',
        customerId: 'cust-1',
        serviceType: 'installation',
        title: 'Complimentary Checkup',
        serviceDate: DateTime(2026, 11, 5),
        status: 'in_progress',
        serviceAmount: 500.0,
        additionalCharges: 0.0,
        discountAmount: 800.0,
        createdAt: DateTime(2026, 11, 5),
        updatedAt: DateTime(2026, 11, 5),
      );

      expect(entry.computedTotal, equals(0.0));
      expect(entry.isInProgress, isTrue);
    });

    test('explicit totalAmount overrides computedTotal if set', () {
      final entry = ServiceEntry(
        id: 'srv-3',
        businessId: 'biz-1',
        customerId: 'cust-1',
        serviceType: 'maintenance',
        title: 'RO Filter Replacement',
        serviceDate: DateTime(2026, 11, 5),
        status: 'completed',
        serviceAmount: 1000.0,
        additionalCharges: 250.0,
        discountAmount: 100.0,
        totalAmount: 1150.0,
        createdAt: DateTime(2026, 11, 5),
        updatedAt: DateTime(2026, 11, 5),
      );

      expect(entry.computedTotal, equals(1150.0));
      expect(entry.isCompleted, isTrue);
    });

    test('serviceTypeDisplay maps all types cleanly', () {
      const types = {
        'installation': 'Installation',
        'repair': 'Repair',
        'maintenance': 'Maintenance',
        'inspection': 'Inspection',
        'general': 'General Service',
        'other': 'Other',
        'unknown_custom': 'Other',
      };

      for (final entry in types.entries) {
        final s = ServiceEntry(
          id: 'test',
          businessId: 'biz',
          customerId: 'cust',
          serviceType: entry.key,
          title: 'Test',
          serviceDate: DateTime(2026, 11, 5),
          status: 'pending',
          createdAt: DateTime(2026, 11, 5),
          updatedAt: DateTime(2026, 11, 5),
        );
        expect(s.serviceTypeDisplay, equals(entry.value));
      }
    });

    test('ServiceEntry serialization and deserialization roundtrip', () {
      final json = {
        'id': 'srv-100',
        'business_id': 'biz-100',
        'customer_id': 'cust-100',
        'customer_address_id': 'addr-100',
        'equipment_id': 'eq-100',
        'service_number': 'YB-SRV-000042',
        'service_type': 'repair',
        'title': 'CCTV Camera Replacement',
        'description': 'Main camera not showing feed',
        'work_performed': 'Replaced power adapter and connector',
        'service_date': '2026-11-05T00:00:00.000',
        'status': 'completed',
        'service_amount': 2500.0,
        'additional_charges': 450.0,
        'discount_amount': 150.0,
        'total_amount': 2800.0,
        'payment_status': 'paid',
        'notes': 'Customer paid via UPI',
        'completed_at': '2026-11-05T14:30:00.000',
        'created_at': '2026-11-05T10:00:00.000',
        'updated_at': '2026-11-05T14:30:00.000',
      };

      final entry = ServiceEntry.fromJson(json);

      expect(entry.id, equals('srv-100'));
      expect(entry.serviceNumber, equals('YB-SRV-000042'));
      expect(entry.serviceAmount, equals(2500.0));
      expect(entry.additionalCharges, equals(450.0));
      expect(entry.discountAmount, equals(150.0));
      expect(entry.totalAmount, equals(2800.0));
      expect(entry.status, equals('completed'));
      expect(entry.isCompleted, isTrue);

      final outJson = entry.toJson();
      expect(outJson['service_number'], equals('YB-SRV-000042'));
      expect(outJson['total_amount'], equals(2800.0));
      expect(
        outJson['work_performed'],
        equals('Replaced power adapter and connector'),
      );
    });
  });

  group('ServiceAttachment & Activity Model Tests', () {
    test('ServiceAttachment detects image and pdf types correctly', () {
      final imgAtt = ServiceAttachment(
        id: 'att-1',
        businessId: 'biz-1',
        serviceId: 'srv-1',
        filePath: 'biz-1/srv-1/photo.jpg',
        fileName: 'repair_site_before.jpg',
        fileSize: 1048576, // 1 MB
        mimeType: 'image/jpeg',
        createdAt: DateTime(2026, 11, 5),
      );

      expect(imgAtt.isImage, isTrue);
      expect(imgAtt.isPdf, isFalse);
      expect(imgAtt.formattedFileSize, equals('1.0 MB'));

      final pdfAtt = ServiceAttachment(
        id: 'att-2',
        businessId: 'biz-1',
        serviceId: 'srv-1',
        filePath: 'biz-1/srv-1/invoice.pdf',
        fileName: 'vendor_invoice.pdf',
        fileSize: 51200, // 50 KB
        mimeType: 'application/pdf',
        createdAt: DateTime(2026, 11, 5),
      );

      expect(pdfAtt.isImage, isFalse);
      expect(pdfAtt.isPdf, isTrue);
      expect(pdfAtt.formattedFileSize, equals('50.0 KB'));
    });

    test(
      'ServiceActivity deserialization parses timeline action and metadata',
      () {
        final json = {
          'id': 'act-1',
          'business_id': 'biz-1',
          'service_id': 'srv-1',
          'activity_type': 'status_changed',
          'title': 'Status changed from Pending to In Progress',
          'description': 'Started technician diagnostic visit',
          'old_status': 'pending',
          'new_status': 'in_progress',
          'metadata': {'updated_by': 'owner'},
          'created_at': '2026-11-05T11:00:00.000',
        };

        final activity = ServiceActivity.fromJson(json);

        expect(activity.id, equals('act-1'));
        expect(activity.activityType, equals('status_changed'));
        expect(activity.oldStatus, equals('pending'));
        expect(activity.newStatus, equals('in_progress'));
        expect(activity.title, contains('In Progress'));
      },
    );

    test('Equipment displayName combines model and serial correctly', () {
      final eq = Equipment(
        id: 'eq-1',
        businessId: 'biz-1',
        customerId: 'cust-1',
        equipmentName: 'Air Conditioner',
        category: 'Split AC 1.5T',
        brand: 'Daikin',
        modelNumber: 'FTKF50',
        serialNumber: 'SN-987654',
        createdAt: DateTime(2026, 11, 5),
        updatedAt: DateTime(2026, 11, 5),
      );

      expect(eq.displayName, equals('Air Conditioner (Daikin FTKF50)'));
    });

    test('ServiceSummaryCounts defaults to 0 counts', () {
      const counts = ServiceSummaryCounts();
      expect(counts.totalServices, equals(0));
      expect(counts.pending, equals(0));
      expect(counts.inProgress, equals(0));
      expect(counts.completed, equals(0));
      expect(counts.cancelled, equals(0));
    });
  });
}
