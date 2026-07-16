import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class IntakePdfGenerator {
  static Future<void> generateAndPrintReport({
    required String patientName,
    required String patientPhone,
    required Map<String, dynamic> intakeForm,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final basicInfo = intakeForm['basic_info'] as Map<String, dynamic>? ?? {};
    final referralInfo = intakeForm['referral_info'] as Map<String, dynamic>? ?? {};
    final medicalHistory = intakeForm['medical_history'] as Map<String, dynamic>? ?? {};
    final lifestyle = intakeForm['lifestyle'] as Map<String, dynamic>? ?? {};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return [
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
                      'Patient Intake Form & Clinical Assessment',
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

            // Section 1: Basic & Referral Info
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('PATIENT INFORMATION'),
                      _buildInfoRow('Name', patientName),
                      _buildInfoRow('Age/Gender', '${basicInfo['age'] ?? 'N/A'} / ${basicInfo['gender'] ?? 'N/A'}'),
                      _buildInfoRow('Phone', patientPhone),
                      _buildInfoRow('Email', basicInfo['email'] ?? 'N/A'),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('ADDITIONAL DETAILS'),
                      _buildInfoRow('Occupation', basicInfo['occupation'] ?? 'N/A'),
                      _buildInfoRow('Emergency Contact', '${basicInfo['emergency_contact_name'] ?? 'N/A'} (${basicInfo['emergency_contact_number'] ?? 'N/A'})'),
                      _buildInfoRow('Referral Source', referralInfo['referral_source'] ?? 'N/A'),
                      if (referralInfo['referring_doctor'] != null && referralInfo['referring_doctor'].toString().isNotEmpty)
                        _buildInfoRow('Referring Doctor', referralInfo['referring_doctor']),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            _buildInfoRow('Address', basicInfo['address'] ?? 'N/A'),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // Section 2: Clinical Details
            _buildSectionTitle('CLINICAL COMPLAINT'),
            _buildReportBlock('Primary Complaint', intakeForm['primary_complaint']?.toString() ?? 'N/A'),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _buildReportBlock('Problem Duration', intakeForm['problem_duration']?.toString() ?? 'N/A')),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildReportBlock('Onset', intakeForm['onset']?.toString() ?? 'N/A')),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildReportBlock('Pain Scale', '${intakeForm['pain_scale'] ?? 0} / 10')),
              ],
            ),
            
            _buildReportBlock('Symptoms', (intakeForm['symptoms'] as List<dynamic>?)?.join(', ') ?? 'None'),
            _buildReportBlock('Functional Limitations', (intakeForm['functional_limitation'] as List<dynamic>?)?.join(', ') ?? 'None'),
            _buildReportBlock('Patient Goals', (intakeForm['patient_goal'] as List<dynamic>?)?.join(', ') ?? 'None'),
            
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // Section 3: History
            _buildSectionTitle('MEDICAL HISTORY & LIFESTYLE'),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Conditions', medicalHistory.entries.where((e) => e.value == true && e.key != 'surgery_details').map((e) => e.key).join(', ').isEmpty ? 'None' : medicalHistory.entries.where((e) => e.value == true && e.key != 'surgery_details').map((e) => e.key).join(', ')),
                      if (medicalHistory['Previous Surgery'] == true)
                         _buildInfoRow('Surgery Details', medicalHistory['surgery_details']?.toString() ?? 'N/A'),
                      _buildInfoRow('Medications', intakeForm['medication']?.toString().isEmpty ?? true ? 'None' : intakeForm['medication']),
                      _buildInfoRow('Falls History (6m)', intakeForm['falls_history'] == true ? 'Yes' : 'No'),
                      _buildInfoRow('Assistive Device', intakeForm['assistive_device']?.toString() ?? 'None'),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Smoking', lifestyle['smoking'] == true ? 'Yes' : 'No'),
                      _buildInfoRow('Alcohol', lifestyle['alcohol'] == true ? 'Yes' : 'No'),
                      _buildInfoRow('Physical Activity', lifestyle['physical_activity']?.toString() ?? 'N/A'),
                      _buildInfoRow('Sleep Quality', lifestyle['sleep_quality']?.toString() ?? 'N/A'),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 40),
            pw.Divider(color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Form Submitted & Consented on: ${DateFormat('dd MMM yyyy').format(DateTime.parse(intakeForm['created_at'] ?? DateTime.now().toIso8601String()))}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Patient Signature (Digital)',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Intake_Form_${patientName.replaceAll(' ', '_')}.pdf',
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
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
             child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
          )
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
