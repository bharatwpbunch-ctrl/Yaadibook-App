import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/report_models.dart';

/// Handles safe CSV & PDF generation and sharing for Business Reports.
class ReportExportService {
  static final DateFormat _dateFmt = DateFormat('dd MMM yyyy');
  static final DateFormat _tsFmt = DateFormat('dd MMM yyyy, hh:mm a');

  /// Neutralizes CSV/Excel formula injection (OWASP CSV Injection mitigation)
  /// by prefixing any leading formula trigger character (`=`, `+`, `-`, `@`, tab, CR)
  /// with a single apostrophe (`'`).
  static String sanitizeCsvCell(Object? value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.isEmpty) return '';
    final first = str[0];
    if (first == '=' ||
        first == '+' ||
        first == '-' ||
        first == '@' ||
        first == '\t' ||
        first == '\r') {
      return "'$str";
    }
    return str;
  }

  /// Builds a sanitized CSV string for the current [BusinessReportData].
  static String buildSummaryAndServicesCsv(BusinessReportData report) {
    final rows = <List<dynamic>>[
      ['Yaadibook Business Report'],
      ['Business', sanitizeCsvCell(report.businessName)],
      ['Contact', sanitizeCsvCell(report.businessPhone)],
      [
        'Period',
        '${_dateFmt.format(report.startDate)} - ${_dateFmt.format(report.endDate)}',
      ],
      ['Generated At', _tsFmt.format(report.generatedAt)],
      [],
      ['Section', 'Metric', 'Value'],
      ['Customers', 'Total Active Customers', report.customers.totalActive],
      ['Customers', 'New Customers Added', report.customers.newInPeriod],
      ['Customers', 'Repeat Customers', report.customers.repeatCustomers],
      [
        'Customers',
        'Customers With Active AMC',
        report.customers.withActiveAmc,
      ],
      [
        'Services',
        'Active Services in Period',
        report.services.totalActiveCount,
      ],
      ['Services', 'Completed Services', report.services.completedCount],
      [
        'Services',
        'Pending / In-Progress Services',
        report.services.pendingCount,
      ],
      [
        'Services',
        'Cancelled Services (Excluded from Amounts)',
        report.services.cancelledCount,
      ],
      [
        'Amounts (INR)',
        'Total Recorded Service Amounts',
        report.services.recordedAmountInr.toStringAsFixed(2),
      ],
      [
        'Amounts (INR)',
        'Collected (Paid) Amounts',
        report.services.paidAmountInr.toStringAsFixed(2),
      ],
      [
        'Amounts (INR)',
        'Pending Collection Amounts',
        report.services.pendingAmountInr.toStringAsFixed(2),
      ],
      [
        'Maintenance',
        'Scheduled Visits in Period',
        report.maintenance.totalInPeriod,
      ],
      ['Maintenance', 'Completed Visits', report.maintenance.completedCount],
      ['Maintenance', 'Overdue Visits', report.maintenance.overdueCount],
      ['AMC', 'Active Contracts', report.amc.activeCount],
      ['AMC', 'Expiring Within 30 Days', report.amc.expiringWithin30Days],
      ['AMC', 'Expired Contracts', report.amc.expiredCount],
      [
        'AMC',
        'Portfolio Contract Value (INR)',
        report.amc.portfolioContractValueInr.toStringAsFixed(2),
      ],
      ['Follow-ups', 'Completed Reminders', report.followups.completedCount],
      ['Follow-ups', 'Pending Reminders', report.followups.pendingCount],
      ['Follow-ups', 'Overdue Reminders', report.followups.overdueCount],
      [],
      ['Service Records Detail'],
      [
        'Date',
        'Customer',
        'Title',
        'Type',
        'Status',
        'Payment Status',
        'Recorded Amount (INR)',
      ],
      ...report.services.entries.map(
        (s) => [
          _dateFmt.format(s.serviceDate),
          sanitizeCsvCell(s.customer?.fullName ?? 'Customer'),
          sanitizeCsvCell(s.title),
          sanitizeCsvCell(s.serviceType),
          sanitizeCsvCell(s.status),
          sanitizeCsvCell(s.paymentStatus ?? 'unpaid'),
          (s.totalAmount ?? s.serviceAmount ?? 0).toStringAsFixed(2),
        ],
      ),
    ];

    return csv.encode(rows);
  }

  /// Generates a clean PDF report byte array formatted cleanly with INR amounts.
  static Future<Uint8List> buildPdfBytes(BusinessReportData report) async {
    final doc = pw.Document(
      title: '${report.businessName} - Business Report',
      author: 'Yaadibook',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    report.businessName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal800,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Phone: ${report.businessPhone}  |  Timezone: ${report.timezone}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Business Activity Report',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${_dateFmt.format(report.startDate)} - ${_dateFmt.format(report.endDate)}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${_tsFmt.format(report.generatedAt)}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(height: 20, color: PdfColors.grey300),
          pw.Text(
            'Executive Summary',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: ['Category', 'Metric', 'Value'],
            data: [
              [
                'Customers',
                'Total Active / New Added',
                '${report.customers.totalActive} / +${report.customers.newInPeriod}',
              ],
              [
                'Customers',
                'Repeat / Active AMC Holders',
                '${report.customers.repeatCustomers} / ${report.customers.withActiveAmc}',
              ],
              [
                'Services',
                'Completed / Pending / Cancelled',
                '${report.services.completedCount} / ${report.services.pendingCount} / ${report.services.cancelledCount}',
              ],
              [
                'Amounts (INR)',
                'Total Recorded (Excl. Cancelled)',
                'INR ${report.services.recordedAmountInr.toStringAsFixed(2)}',
              ],
              [
                'Amounts (INR)',
                'Collected (Paid) vs Pending',
                'INR ${report.services.paidAmountInr.toStringAsFixed(2)} / INR ${report.services.pendingAmountInr.toStringAsFixed(2)}',
              ],
              [
                'Maintenance',
                'Completed / Upcoming / Overdue',
                '${report.maintenance.completedCount} / ${report.maintenance.upcomingCount} / ${report.maintenance.overdueCount}',
              ],
              [
                'AMC',
                'Active / Expiring 30d / Expired',
                '${report.amc.activeCount} / ${report.amc.expiringWithin30Days} / ${report.amc.expiredCount}',
              ],
              [
                'AMC Value',
                'Active & Renewed Contract Value',
                'INR ${report.amc.portfolioContractValueInr.toStringAsFixed(2)}',
              ],
              [
                'Follow-ups',
                'Completed / Pending / Overdue',
                '${report.followups.completedCount} / ${report.followups.pendingCount} / ${report.followups.overdueCount}',
              ],
            ],
          ),
          if (report.services.entries.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              'Service Records (${report.services.entries.length})',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 8.5,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headers: [
                'Date',
                'Customer',
                'Title',
                'Status',
                'Payment',
                'Amount',
              ],
              data: report.services.entries.take(60).map((s) {
                final amt = s.totalAmount ?? s.serviceAmount ?? 0;
                return [
                  _dateFmt.format(s.serviceDate),
                  s.customer?.fullName ?? 'Customer',
                  s.title,
                  s.status,
                  s.paymentStatus ?? 'unpaid',
                  'INR ${amt.toStringAsFixed(2)}',
                ];
              }).toList(),
            ),
          ],
          pw.SizedBox(height: 14),
          pw.Text(
            'Note: Recorded service and AMC contract amounts reflect operational entries in Yaadibook and do not constitute formal GST tax invoices.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<void> sharePdfReport(BusinessReportData report) async {
    final bytes = await buildPdfBytes(report);
    final fileName =
        'yaadibook_report_${report.startDate.toIso8601String().split('T').first}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<void> shareCsvReport(BusinessReportData report) async {
    final csvString = buildSummaryAndServicesCsv(report);
    final bytes = Uint8List.fromList(utf8.encode(csvString));
    final fileName =
        'yaadibook_report_${report.startDate.toIso8601String().split('T').first}.csv';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv', name: fileName)],
        subject: '${report.businessName} Business Report',
      ),
    );
  }
}
