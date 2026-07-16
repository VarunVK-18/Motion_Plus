import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TherapistDetailsPage extends StatefulWidget {
  final String therapistId;
  final String therapistName;

  const TherapistDetailsPage({
    super.key,
    required this.therapistId,
    required this.therapistName,
  });

  static const Color primaryBlue = Color(0xFF3E84DC);
  static const Color forestGreen = Color(0xFF2D6A4F);
  static const Color slate = Color(0xFF475569);
  static const Color darkSlate = Color(0xFF0F172A);

  @override
  State<TherapistDetailsPage> createState() => _TherapistDetailsPageState();
}

class _TherapistDetailsPageState extends State<TherapistDetailsPage> {
  late Future<Map<String, dynamic>> _dataFuture;
  String selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    // Fetch profile
    final profile = await ApiService.get('/profiles/${widget.therapistId}', includeAuth: true);

    // Fetch sessions
    final sessions = await ApiService.get('/sessions?therapist_id=${widget.therapistId}&_sort=created_at:desc', includeAuth: true) as List;

    return {
      'profile': profile,
      'sessions': sessions,
    };
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: TherapistDetailsPage.primaryBlue));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.outfit()));
              }

              final profile = snapshot.data!['profile'] as Map<String, dynamic>? ?? {};
              final allSessions = snapshot.data!['sessions'] as List<dynamic>;

              // Filter sessions in memory
              final filteredSessions = allSessions.where((s) {
                if (selectedStatus != 'ALL' && s['status'].toString().toUpperCase() != selectedStatus) return false;
                return true;
              }).toList();

              return Column(
                children: [
                  _buildHeader(context, profile, allSessions.length),
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: TherapistDetailsPage.primaryBlue,
                      unselectedLabelColor: TherapistDetailsPage.slate,
                      indicatorColor: TherapistDetailsPage.primaryBlue,
                      labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                      tabs: const [
                        Tab(text: 'PERSONAL DETAILS'),
                        Tab(text: 'SESSIONS'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildPersonalDetailsTab(profile),
                        Column(
                          children: [
                            _buildFilterSection(),
                            Expanded(
                              child: filteredSessions.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      itemCount: filteredSessions.length,
                                      itemBuilder: (context, index) => _buildSessionCard(context, filteredSessions[index]),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> profile, int sessionCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, size: 20, color: TherapistDetailsPage.darkSlate),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.therapistName,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: TherapistDetailsPage.darkSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      (profile['role'] ?? 'Therapist').toString().toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TherapistDetailsPage.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSummaryPill('Total Sessions', sessionCount.toString(), Icons.assignment_rounded, const Color(0xFFF1F5F9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill(String label, String value, IconData icon, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: TherapistDetailsPage.slate),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: TherapistDetailsPage.slate,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: TherapistDetailsPage.darkSlate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsTab(Map<String, dynamic> profile) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('CONTACT INFO'),
          _detailRow('Email', profile['email']?.toString() ?? 'N/A'),
          _detailRow('Phone', profile['phone']?.toString() ?? 'N/A'),
          
          const SizedBox(height: 24),
          _buildSectionHeader('CLINIC DETAILS'),
          _detailRow('Branch', profile['clinic_id']?['name']?.toString() ?? 'Unassigned'),
          _detailRow('Registered On', _formatDate(profile['created_at']?.toString())),
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
          color: TherapistDetailsPage.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: TherapistDetailsPage.primaryBlue,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TherapistDetailsPage.slate,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: TherapistDetailsPage.darkSlate,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _filterChip('ALL'),
            const SizedBox(width: 8),
            _filterChip('ASSIGNED'),
            const SizedBox(width: 8),
            _filterChip('ONGOING'),
            const SizedBox(width: 8),
            _filterChip('COMPLETED'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String status) {
    final isSelected = selectedStatus == status;
    return GestureDetector(
      onTap: () => setState(() => selectedStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? TherapistDetailsPage.darkSlate : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? TherapistDetailsPage.darkSlate
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: TherapistDetailsPage.darkSlate.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          status,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: isSelected ? Colors.white : TherapistDetailsPage.slate,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, Map<String, dynamic> session) {
    final status = session['status']?.toString().toLowerCase() ?? 'unknown';
    Color color = TherapistDetailsPage.slate;
    if (status == 'completed') color = TherapistDetailsPage.forestGreen;
    if (status == 'assigned') color = TherapistDetailsPage.primaryBlue;
    if (status == 'ongoing') color = Colors.orange;

    final patientName = session['patient_id']?['full_name'] ?? 'Unknown Patient';
    final patientPhone = session['patient_id']?['phone'] ?? 'No Phone';
    final date = _formatDate(session['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              Text(
                date,
                style: GoogleFonts.outfit(
                  color: TherapistDetailsPage.slate,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            patientName,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: TherapistDetailsPage.darkSlate,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone_rounded, size: 14, color: TherapistDetailsPage.slate),
              const SizedBox(width: 4),
              Text(
                patientPhone,
                style: GoogleFonts.outfit(
                  color: TherapistDetailsPage.slate,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 48,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 14),
          Text(
            'No History Found',
            style: GoogleFonts.outfit(
              color: TherapistDetailsPage.darkSlate,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return 'Invalid Date';
    }
  }
}
