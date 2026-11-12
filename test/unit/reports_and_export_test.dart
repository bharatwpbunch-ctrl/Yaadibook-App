import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/features/reports/models/report_models.dart';
import 'package:yaadibook/features/reports/services/report_export_service.dart';
import 'package:yaadibook/shared/models/amc_contract.dart';
import 'package:yaadibook/shared/models/customer.dart';
import 'package:yaadibook/shared/models/reminder.dart';
import 'package:yaadibook/shared/models/service_entry.dart';

void main() {
  group('ReportDateRange presets', () {
    test('lastMonth across January rolls back to December safely', () {
      final jan15 = DateTime(2026, 1, 15);
      final range = ReportDateRange.fromPreset(
        ReportDatePreset.lastMonth,
        referenceNow: jan15,
      );
      expect(range.startDate, DateTime(2025, 12, 1));
      expect(range.endDate, DateTime(2025, 12, 31));
    });

    test('thisMonth starts at day 1 and ends at reference day', () {
      final nov12 = DateTime(2026, 11, 12, 14, 30);
      final range = ReportDateRange.fromPreset(
        ReportDatePreset.thisMonth,
        referenceNow: nov12,
      );
      expect(range.startDate, DateTime(2026, 11, 1));
      expect(range.endDate, DateTime(2026, 11, 12));
    });
  });

  group('BusinessReportData calculations', () {
    test(
      'excludes cancelled services from totals and separates paid vs pending',
      () {
        final now = DateTime(2026, 11, 12);
        final customers = [
          Customer(
            id: 'c1',
            businessId: 'b1',
            fullName: 'Ramesh Patel',
            primaryPhone: '+919876543210',
            createdAt: DateTime(2026, 11, 2),
            updatedAt: DateTime(2026, 11, 2),
          ),
          Customer(
            id: 'c2',
            businessId: 'b1',
            fullName: '=CMD|calc',
            primaryPhone: '+919876543211',
            createdAt: DateTime(2026, 9, 1),
            updatedAt: DateTime(2026, 9, 1),
          ),
        ];

        final services = [
          ServiceEntry(
            id: 's1',
            businessId: 'b1',
            customerId: 'c1',
            customer: customers[0],
            serviceType: 'installation',
            title: 'CCTV Camera Setup',
            serviceDate: DateTime(2026, 11, 5),
            status: 'completed',
            serviceAmount: 5000,
            totalAmount: 5000,
            paymentStatus: 'paid',
            createdAt: now,
            updatedAt: now,
          ),
          ServiceEntry(
            id: 's2',
            businessId: 'b1',
            customerId: 'c1',
            customer: customers[0],
            serviceType: 'repair',
            title: 'DVR Replacement',
            serviceDate: DateTime(2026, 11, 8),
            status: 'pending',
            serviceAmount: 2500,
            totalAmount: 2500,
            paymentStatus: 'unpaid',
            createdAt: now,
            updatedAt: now,
          ),
          ServiceEntry(
            id: 's3',
            businessId: 'b1',
            customerId: 'c2',
            customer: customers[1],
            serviceType: 'repair',
            title: '+MaliciousTitle',
            serviceDate: DateTime(2026, 11, 9),
            status: 'cancelled',
            serviceAmount: 9999,
            totalAmount: 9999,
            paymentStatus: 'unpaid',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final amcs = [
          AmcContract(
            id: 'a1',
            businessId: 'b1',
            customerId: 'c1',
            contractTitle: 'Annual CCTV AMC',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime.now().add(const Duration(days: 15)),
            contractAmount: 12000,
            status: 'active',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final reminders = [
          Reminder(
            id: 'r1',
            businessId: 'b1',
            title: 'Payment Call',
            reminderType: 'follow_up',
            dueAt: DateTime(2026, 11, 10),
            status: 'completed',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final report = BusinessReportData.computeFromEntities(
          businessId: 'b1',
          businessName: 'Bharat CCTV Company',
          businessPhone: '+919999999999',
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 30),
          customers: customers,
          services: services,
          amcs: amcs,
          reminders: reminders,
          nowOverride: now,
        );

        expect(report.customers.totalActive, 2);
        expect(report.customers.newInPeriod, 1);
        expect(report.customers.repeatCustomers, 1);
        expect(report.customers.withActiveAmc, 1);
        expect(report.services.totalActiveCount, 2);
        expect(report.services.completedCount, 1);
        expect(report.services.pendingCount, 1);
        expect(report.services.cancelledCount, 1);
        expect(report.services.recordedAmountInr, 7500);
        expect(report.services.paidAmountInr, 5000);
        expect(report.services.pendingAmountInr, 2500);
        expect(report.amc.activeCount, 1);
        expect(report.amc.expiringWithin30Days, 1);
        expect(report.amc.portfolioContractValueInr, 12000);
        expect(report.followups.completedCount, 1);
      },
    );
  });

  group('ReportExportService CSV injection & PDF output', () {
    test('sanitizeCsvCell neutralizes formula triggers', () {
      expect(ReportExportService.sanitizeCsvCell('=1+1'), "'=1+1");
      expect(ReportExportService.sanitizeCsvCell('+SUM(A1)'), "'+SUM(A1)");
      expect(ReportExportService.sanitizeCsvCell('-cmd'), "'-cmd");
      expect(ReportExportService.sanitizeCsvCell('@HYPERLINK'), "'@HYPERLINK");
      expect(ReportExportService.sanitizeCsvCell('\tformula'), "'\tformula");
      expect(ReportExportService.sanitizeCsvCell('Normal Text'), 'Normal Text');
    });

    test(
      'buildSummaryAndServicesCsv escapes unsafe cells and buildPdfBytes returns valid PDF',
      () async {
        final now = DateTime(2026, 11, 12);
        final report = BusinessReportData.computeFromEntities(
          businessId: 'b1',
          businessName: '=EvilBusiness',
          businessPhone: '+919876543210',
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 30),
          customers: const [],
          services: [
            ServiceEntry(
              id: 's1',
              businessId: 'b1',
              customerId: 'c1',
              serviceType: 'repair',
              title: '=IMPORTXML("http://bad")',
              serviceDate: now,
              status: 'completed',
              totalAmount: 1000,
              paymentStatus: 'paid',
              createdAt: now,
              updatedAt: now,
            ),
          ],
          amcs: const [],
          reminders: const [],
          nowOverride: now,
        );

        final csvOut = ReportExportService.buildSummaryAndServicesCsv(report);
        expect(csvOut.contains("'=EvilBusiness"), isTrue);
        expect(csvOut.contains("'=IMPORTXML"), isTrue);

        final pdfBytes = await ReportExportService.buildPdfBytes(report);
        expect(pdfBytes.length, greaterThan(500));
        expect(ascii.decode(pdfBytes.take(5).toList()), '%PDF-');
      },
    );
  });
}
