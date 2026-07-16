import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfReportGenerator {
  static Future<void> generateAndPrintReport({
    required String patientName,
    required String patientPhone,
    required String appointmentDate,
    required String staffName,
    required String serviceFee,
    required String specialization,
    required Map<String, dynamic> session,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'OLIVEO CONNECT',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'PhysioTracker Clinical Management System',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 20),

              // Patient & Appointment Details
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('PATIENT INFORMATION'),
                        _buildInfoRow('Name', patientName),
                        _buildInfoRow('Phone', patientPhone),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('APPOINTMENT DETAILS'),
                        _buildInfoRow('Date/Time', appointmentDate),
                        _buildInfoRow('Specialization', specialization),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('STAFF & BILLING'),
                        _buildInfoRow('Staff Name', staffName),
                        _buildInfoRow('Service Fee', serviceFee),
                      ],
                    ),
                  ),
                  pw.Expanded(child: pw.Container()),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              // Clinical Details
              _buildSectionTitle('CLINICAL FINDINGS & SUMMARY'),
              _buildReportBlock(
                'Session Summary',
                session['session_summary'] ?? 'N/A',
              ),
              _buildReportBlock(
                'Exercises Performed',
                session['exercises_performed'] ?? 'N/A',
              ),
              _buildReportBlock(
                'Pain / Fatigue Level',
                (session['pain_fatigue_level'] != null)
                    ? '${session['pain_fatigue_level']}/10'
                    : 'N/A',
              ),
              _buildReportBlock(
                'Therapist Observations',
                session['therapist_observation'] ?? 'N/A',
              ),
              _buildReportBlock(
                'Homework / Recommendations',
                '${session['homework_given'] ?? 'None'}\n${session['session_recommendation'] ?? ''}',
              ),

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Authorized Clinical Signature',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Clinical_Report_${patientName.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildReportBlock(String title, String content) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(content, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
