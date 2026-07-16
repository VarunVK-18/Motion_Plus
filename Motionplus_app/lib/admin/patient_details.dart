import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pdf_report_generator.dart';
import 'intake_pdf_generator.dart';

class PatientDetailsPage extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientDetailsPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  static const Color primaryBlue = Color(0xFF3E84DC);
  static const Color forestGreen = Color(0xFF2D6A4F);
  static const Color slate = Color(0xFF475569);
  static const Color darkSlate = Color(0xFF0F172A);

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  String selectedStatus = 'ALL';
  DateTime? selectedDate;
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final sessions = await ApiService.get('/sessions?patient_id=${widget.patientId}&_sort=created_at:desc', includeAuth: true) as List;

    final intakeForms = await ApiService.get('/patient_intake_forms?patient_id=${widget.patientId}', includeAuth: true) as List;
    final intakeForm = intakeForms.isNotEmpty ? intakeForms.first : null;

    return {
      'sessions': sessions,
      'intakeForm': intakeForm,
    };
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFF8FAFC),
              body: Center(child: CircularProgressIndicator(color: PatientDetailsPage.primaryBlue)),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.outfit())),
            );
          }

              final allSessions = snapshot.data!['sessions'] as List<dynamic>;
              final intakeForm = snapshot.data!['intakeForm'] as Map<String, dynamic>?;

              // 1. Filter sessions in memory
              final filteredSessions = allSessions.where((s) {
                if (selectedStatus != 'ALL' && s['status'].toString().toUpperCase() != selectedStatus) return false;
                if (selectedDate != null) {
                  final sessionDate = DateTime.parse(s['created_at']).toLocal();
                  if (sessionDate.year != selectedDate!.year || sessionDate.month != selectedDate!.month || sessionDate.day != selectedDate!.day) return false;
                }
                return true;
              }).toList();

              // 2. Calculate totals
              double totalPaid = 0;
              for (var s in allSessions) {
                if (s['status'] == 'completed') totalPaid += (s['fee_charged'] ?? 0).toDouble();
              }

              return Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                floatingActionButton: intakeForm != null 
                    ? FloatingActionButton(
                        onPressed: () {
                          final patientPhone = (intakeForm['basic_info']?['phone']?.toString()) ?? 'N/A';
                          IntakePdfGenerator.generateAndPrintReport(
                            patientName: widget.patientName,
                            patientPhone: patientPhone,
                            intakeForm: intakeForm,
                          );
                        },
                        backgroundColor: PatientDetailsPage.primaryBlue,
                        elevation: 4,
                        shape: const CircleBorder(),
                        child: const Icon(Icons.download_rounded, color: Colors.white),
                      )
                    : null,
                body: SafeArea(
                  child: Column(
                    children: [
                      _buildCustomHeader(context, allSessions.length, totalPaid),
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: PatientDetailsPage.primaryBlue,
                      unselectedLabelColor: PatientDetailsPage.slate,
                      indicatorColor: PatientDetailsPage.primaryBlue,
                      dividerColor: Colors.transparent,
                      labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                      tabs: const [
                        Tab(text: 'PATIENT DETAILS'),
                        Tab(text: 'SESSIONS'),
                        Tab(text: 'MORNING CHECK-INS'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Intake Form Tab
                        _buildIntakeFormTab(intakeForm),
                        // Sessions Tab
                        Column(
                          children: [
                            _buildFilterSection(),
                            Expanded(
                              child: filteredSessions.isEmpty
                                  ? _buildEmptyState(isFiltered: allSessions.isNotEmpty)
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      itemCount: filteredSessions.length,
                                      itemBuilder: (context, index) => _buildSessionCard(context, filteredSessions[index]),
                                    ),
                            ),
                          ],
                        ),
                        // Morning Check-Ins Tab
                        _buildMorningCheckInsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntakeFormTab(Map<String, dynamic>? intakeForm) {
    if (intakeForm == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_late_rounded, size: 48, color: PatientDetailsPage.slate),
            const SizedBox(height: 16),
            Text('No intake form found.', style: GoogleFonts.outfit(fontSize: 16, color: PatientDetailsPage.slate)),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('BASIC INFO'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _reportSection('Full Name', intakeForm['basic_info']?['full_name']?.toString() ?? 'N/A')),
                      const SizedBox(width: 12),
                      Expanded(child: _reportSection('Age & Gender', '${intakeForm['basic_info']?['age']?.toString() ?? 'N/A'}, ${intakeForm['basic_info']?['gender']?.toString() ?? 'N/A'}')),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _reportSection('Phone', intakeForm['basic_info']?['phone']?.toString() ?? 'N/A')),
                      const SizedBox(width: 12),
                      Expanded(child: _reportSection('Email', intakeForm['basic_info']?['email']?.toString() ?? 'N/A')),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _reportSection('Address', intakeForm['basic_info']?['address']?.toString() ?? 'N/A')),
                      const SizedBox(width: 12),
                      Expanded(child: _reportSection('Occupation', intakeForm['basic_info']?['occupation']?.toString() ?? 'N/A')),
                    ],
                  ),
                  _reportSection('Emergency Contact', intakeForm['basic_info']?['emergency_contact_number']?.toString() ?? 'N/A'),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader('CLINICAL DETAILS'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _reportSection('Primary Complaint', intakeForm['primary_complaint']?.toString() ?? 'N/A')),
                      const SizedBox(width: 12),
                      Expanded(child: _reportSection('Problem Duration', intakeForm['problem_duration']?.toString() ?? 'N/A')),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _reportSection('Onset', intakeForm['onset']?.toString() ?? 'N/A')),
                      const SizedBox(width: 12),
                      Expanded(child: _reportSection('Pain Scale', '${intakeForm['pain_scale'] ?? 0} / 10')),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _reportSection('Severity', intakeForm['severity']?.toString() ?? 'N/A')),
                      const SizedBox(width: 12),
                      Expanded(child: _reportSection('Symptoms', (intakeForm['symptoms'] as List<dynamic>?)?.join(', ') ?? 'None')),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _reportSection('Limitations', (intakeForm['functional_limitation'] as List<dynamic>?)?.join(', ') ?? 'None')),
                      const SizedBox(width: 12),
                      Expanded(child: _reportSection('Goals', (intakeForm['patient_goal'] as List<dynamic>?)?.join(', ') ?? 'None')),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader('MEDICAL HISTORY'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _reportSection('Conditions', _formatMapToString(intakeForm['medical_history'] as Map<String, dynamic>?))),
                      const SizedBox(width: 12),
                      Expanded(child: _reportSection('Medication', intakeForm['medication']?.toString() ?? 'None')),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _reportSection('Falls History', intakeForm['falls_history'] == true ? 'Yes' : 'No')),
                      const SizedBox(width: 12),
                      Expanded(child: _reportSection('Assistive Device', intakeForm['assistive_device']?.toString() ?? 'None')),
                    ],
                  ),

                  const SizedBox(height: 16),
                  _buildSectionHeader('LIFESTYLE & OTHERS'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _reportSection('Smoking', intakeForm['lifestyle']?['smoking']?.toString() ?? 'N/A')),
                      const SizedBox(width: 12),
                      Expanded(child: _reportSection('Alcohol', intakeForm['lifestyle']?['alcohol']?.toString() ?? 'N/A')),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _reportSection('Physical Activity', intakeForm['lifestyle']?['physical_activity']?.toString() ?? 'N/A')),
                      const SizedBox(width: 12),
                      Expanded(child: _reportSection('Sleep Quality', intakeForm['lifestyle']?['sleep_quality']?.toString() ?? 'N/A')),
                    ],
                  ),
                  _reportSection('Home Exercise Compliance', intakeForm['home_exercise_compliance']?.toString() ?? 'N/A'),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader('REFERRAL INFO'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _reportSection('Source', intakeForm['referral_info']?['referral_source']?.toString() ?? 'N/A')),
                      const SizedBox(width: 12),
                      Expanded(child: _reportSection('Referring Doctor', intakeForm['referral_info']?['referring_doctor']?.toString() ?? 'N/A')),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: PatientDetailsPage.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: PatientDetailsPage.primaryBlue,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  String _formatMapToString(Map<String, dynamic>? map) {
    if (map == null) return 'None';
    List<String> trueKeys = [];
    map.forEach((key, value) {
      if (value == true) {
        trueKeys.add(key);
      } else if (key == 'surgery_details' && value != null && value.toString().isNotEmpty) {
        trueKeys.add('Surgery: $value');
      }
    });
    return trueKeys.isEmpty ? 'None' : trueKeys.join(', ');
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _statusChip('ALL'),
                      _statusChip('ASSIGNED'),
                      _statusChip('IN_PROGRESS', label: 'LIVE'),
                      _statusChip('COMPLETED'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildDatePicker(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, {String? label}) {
    final isSelected = selectedStatus == status;
    return GestureDetector(
      onTap: () => setState(() => selectedStatus = status),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? PatientDetailsPage.darkSlate : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? PatientDetailsPage.darkSlate
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: PatientDetailsPage.darkSlate.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label ?? status,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : PatientDetailsPage.slate,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        if (selectedDate != null) {
          setState(() => selectedDate = null);
          return;
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: PatientDetailsPage.primaryBlue,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: PatientDetailsPage.darkSlate,
                ),
                appBarTheme: const AppBarTheme(
                  systemOverlayStyle: SystemUiOverlayStyle.dark,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selectedDate != null
              ? PatientDetailsPage.primaryBlue.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedDate != null
                ? PatientDetailsPage.primaryBlue
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selectedDate != null
                  ? Icons.calendar_today_rounded
                  : Icons.calendar_month_rounded,
              size: 16,
              color: selectedDate != null
                  ? PatientDetailsPage.primaryBlue
                  : PatientDetailsPage.slate,
            ),
            if (selectedDate != null) ...[
              const SizedBox(width: 8),
              Text(
                DateFormat('MMM d').format(selectedDate!),
                style: GoogleFonts.outfit(
                  color: PatientDetailsPage.primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.close_rounded,
                size: 12,
                color: PatientDetailsPage.primaryBlue,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context, int count, double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: PatientDetailsPage.darkSlate,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PATIENT CASE FILE',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: PatientDetailsPage.primaryBlue,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      widget.patientName,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: PatientDetailsPage.darkSlate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _summaryBox(
                'RECOVERY SESSIONS',
                count.toString(),
                PatientDetailsPage.primaryBlue,
              ),
              const SizedBox(width: 14),
              _summaryBox(
                'TOTAL PAID',
                '₹${total.toStringAsFixed(0)}',
                PatientDetailsPage.forestGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: PatientDetailsPage.darkSlate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, Map<String, dynamic> session) {
    final status = session['status'] ?? 'pending';
    final date = DateTime.parse(session['created_at']).toLocal();
    final therapistName = (session['therapist_id'] != null)
        ? session['therapist_id']['full_name']
        : 'System Assigned';
    final patientPhone = (session['patient_id'] != null)
        ? session['patient_id']['phone']
        : 'N/A';
    final spec = session['specialization_required'].toString().toUpperCase();

    return GestureDetector(
      onTap: status == 'completed'
          ? () => _showSessionReport(context, session)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: const Color(0xFFF8FAFC),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      spec,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        color: PatientDetailsPage.primaryBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                    _statusBadge(status),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow(
                      Icons.calendar_today_rounded,
                      'Appointment',
                      DateFormat('dd MMM yyyy, hh:mm a').format(date),
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      Icons.medical_information_rounded,
                      'Clinical Staff',
                      therapistName,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      Icons.payments_rounded,
                      'Service Fee',
                      '₹${session['fee_charged']}',
                    ),
                    if (status == 'completed') ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showSessionReport(context, session),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: PatientDetailsPage.forestGreen
                                      .withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'VIEW CLINICAL REPORT',
                                    style: GoogleFonts.outfit(
                                      color: PatientDetailsPage.forestGreen,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () =>
                                PdfReportGenerator.generateAndPrintReport(
                                  patientName: widget.patientName,
                                  patientPhone: patientPhone,
                                  appointmentDate: DateFormat(
                                    'dd MMM yyyy, hh:mm a',
                                  ).format(date),
                                  staffName: therapistName,
                                  serviceFee: '₹${session['fee_charged']}',
                                  specialization: spec,
                                  session: session,
                                ),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: PatientDetailsPage.primaryBlue
                                    .withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.print_rounded,
                                color: PatientDetailsPage.primaryBlue,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionReport(BuildContext context, Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CLINICAL REPORT',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: PatientDetailsPage.darkSlate,
                    letterSpacing: 0.5,
                  ),
                ),
                _statusBadge('COMPLETED'),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _reportSection(
                      'SESSION SUMMARY',
                      session['session_summary'] ?? 'No summary provided',
                    ),
                    _reportSection(
                      'EXERCISES PERFORMED',
                      session['exercises_performed'] ?? 'None recorded',
                    ),
                    _reportSection(
                      'PAIN / FATIGUE LEVEL',
                      (session['pain_fatigue_level'] != null)
                          ? '${session['pain_fatigue_level']}/10'
                          : 'Not recorded',
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),

                    // Styled Patient Feedback Section
                    _feedbackSection(session['patient_feedback']),

                    _reportSection(
                      'THERAPIST OBSERVATION',
                      session['therapist_observation'] ?? 'No observations',
                    ),
                    _reportSection(
                      'PATIENT RESPONSE (CLINICAL)',
                      session['patient_response'] ?? 'Not recorded',
                    ),
                    _reportSection(
                      'HOMEWORK GIVEN',
                      session['homework_given'] ?? 'None',
                    ),
                    _reportSection(
                      'RECOMMENDATIONS',
                      session['session_recommendation'] ?? 'None',
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PatientDetailsPage.darkSlate,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'CLOSE REPORT',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportSection(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: PatientDetailsPage.slate,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: PatientDetailsPage.darkSlate,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedbackSection(dynamic response) {
    final hasFeedback =
        response != null && response.toString().trim().isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasFeedback ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasFeedback
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PATIENT FEEDBACK',
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: hasFeedback
                  ? const Color(0xFF166534)
                  : PatientDetailsPage.slate,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasFeedback
                ? response.toString()
                : 'No patient feedback submitted yet.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: hasFeedback
                  ? const Color(0xFF166534)
                  : PatientDetailsPage.slate,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = PatientDetailsPage.slate;
    if (status == 'completed') color = PatientDetailsPage.forestGreen;
    if (status == 'in_progress') color = const Color(0xFFBE123C);
    if (status == 'assigned') color = PatientDetailsPage.primaryBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 12, color: PatientDetailsPage.slate),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: PatientDetailsPage.slate,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: PatientDetailsPage.darkSlate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState({bool isFiltered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_list_off_rounded : Icons.history_rounded,
            size: 48,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 14),
          Text(
            isFiltered ? 'No matches found' : 'No History Found',
            style: GoogleFonts.outfit(
              color: PatientDetailsPage.darkSlate,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          if (isFiltered)
            TextButton(
              onPressed: () => setState(() {
                selectedStatus = 'ALL';
                selectedDate = null;
              }),
              child: Text(
                'Clear all filters',
                style: GoogleFonts.outfit(
                  color: PatientDetailsPage.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMorningCheckInsTab() {
    return FutureBuilder(
      future: ApiService.get('/morning_checkins?patient_id=${widget.patientId}&_sort=created_at:desc', includeAuth: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: PatientDetailsPage.primaryBlue));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading check-ins', style: GoogleFonts.outfit()));
        }
        final checkins = (snapshot.data as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (checkins.isEmpty) {
          return Center(
            child: Text('No Morning Check-Ins recorded yet.',
                style: GoogleFonts.outfit(color: PatientDetailsPage.slate)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: checkins.length,
          itemBuilder: (context, index) {
            final checkin = checkins[index];
            final date = DateTime.parse(checkin['created_at']).toLocal();
            final dateStr = DateFormat('MMM d, yyyy - h:mm a').format(date);
            
            final score = checkin['readiness_score'] ?? 0;
            final compliance = checkin['compliance_score'] ?? 0;
            final smartNotes = (checkin['smart_notifications'] as List<dynamic>?) ?? [];
            final symptoms = (checkin['symptoms'] as List<dynamic>?) ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateStr, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: PatientDetailsPage.darkSlate)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: score >= 80 ? PatientDetailsPage.forestGreen.withOpacity(0.1) : (score >= 50 ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Readiness: $score%',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: score >= 80 ? PatientDetailsPage.forestGreen : (score >= 50 ? Colors.orange : Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (smartNotes.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                                const SizedBox(width: 8),
                                Text('Smart Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.red, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...smartNotes.map((note) => Text('• $note', style: GoogleFonts.outfit(fontSize: 12, color: Colors.red.shade900))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(child: _reportSection('Overall Day', checkin['overall_day']?.toString() ?? 'N/A')),
                        Expanded(child: _reportSection('Energy', checkin['energy_level']?.toString() ?? 'N/A')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _reportSection('Sleep', checkin['sleep_quality']?.toString() ?? 'N/A')),
                        Expanded(child: _reportSection('Mood', checkin['mood']?.toString() ?? 'N/A')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _reportSection('Pain/Discomfort', checkin['pain_discomfort']?.toString() ?? 'N/A')),
                        Expanded(child: _reportSection('Compliance', '$compliance%')),
                      ],
                    ),
                    if (symptoms.isNotEmpty)
                      _reportSection('Symptoms', symptoms.join(', ')),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }
}
