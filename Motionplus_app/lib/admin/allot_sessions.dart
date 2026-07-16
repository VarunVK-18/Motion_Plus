import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../shared/specialization_colors.dart';

class AllotSessionsPage extends StatefulWidget {
  const AllotSessionsPage({super.key});

  @override
  State<AllotSessionsPage> createState() => _AllotSessionsPageState();
}

class _AllotSessionsPageState extends State<AllotSessionsPage> {
  final _supabase = Supabase.instance.client;
  int _clinicCount = 0;
  int _onlineCount = 0;
  String? _adminClinicId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminClinicId();
  }

  Future<void> _fetchAdminClinicId() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await _supabase.from('profiles').select('clinic_id').eq('id', user.id).single();
        if (mounted) {
          setState(() {
            _adminClinicId = data['clinic_id'];
            _isLoading = false;
          });
          if (_adminClinicId != null) {
            _setupCountStream();
          }
        }
      } catch (e) {
        debugPrint('Error fetching admin clinic: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupCountStream() {
    if (_adminClinicId == null) return;
    _supabase.from('sessions').stream(primaryKey: ['id']).eq('clinic_id', _adminClinicId!).listen((data) {
      if (mounted) {
        setState(() {
          _clinicCount = data.where((s) => s['status'] == 'pending').length;
          _onlineCount = data.where((s) => s['status'] == 'requested').length;
        });
      }
    });
  }

  static const Color primaryGreen = Color(0xFF2D6A4F);
  static const Color softSage = Color(0xFFF0FAF7);
  static const Color honeyAmber = Color(0xFFB45309);
  static const Color softAmber = Color(0xFFFFFBEB);
  static const Color slate = Color(0xFF475569);

  Future<void> _allotTherapist(String sessionId, String specialization) async {
    if (_adminClinicId == null) return;
    final therapists = await _supabase
        .from('profiles')
        .select()
        .eq('role', 'therapist_assistant')
        .eq('clinic_id', _adminClinicId!)
        .eq('specialization', specialization.toLowerCase());

    if (therapists.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No $specialization Specialists Available'),
            backgroundColor: honeyAmber,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
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
              const SizedBox(height: 32),
              Text(
                'Assign Specialist',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                'Available ${specialization.toUpperCase()} assistants',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: slate,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: therapists.length,
                  itemBuilder: (context, index) {
                    final t = therapists[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: primaryGreen.withOpacity(0.1),
                          child: Text(
                            (t['full_name'] ?? 'T')[0].toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: primaryGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(
                          t['full_name'] ?? 'Therapist',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          'Available Now',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.add_task_rounded,
                          color: primaryGreen,
                          size: 20,
                        ),
                        onTap: () async {
                          Navigator.pop(context); // Close therapist list
                          _showSchedulingDialog(sessionId, t);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showSchedulingDialog(String sessionId, Map<String, dynamic> therapist) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    int sessionCount = 10;
    bool isConfirming = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(
            32,
            24,
            32,
            MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                'Schedule Treatment',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                'Assigning to ${therapist['full_name']}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              // Date and Time Row
              Row(
                children: [
                  Expanded(
                    child: _buildPickerTile(
                      label: 'START DATE',
                      value: DateFormat('MMM d, yyyy').format(selectedDate),
                      icon: Icons.calendar_today_rounded,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF2D6A4F),
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Color(0xFF1E293B),
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
                          setModalState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPickerTile(
                      label: 'START TIME',
                      value: selectedTime.format(context),
                      icon: Icons.access_time_rounded,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setModalState(() => selectedTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'TOTAL SESSIONS',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: sessionCount.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      activeColor: primaryGreen,
                      inactiveColor: const Color(0xFFF1F5F9),
                      onChanged: (v) =>
                          setModalState(() => sessionCount = v.toInt()),
                    ),
                  ),
                  Container(
                    width: 50,
                    alignment: Alignment.center,
                    child: Text(
                      '$sessionCount',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isConfirming
                      ? null
                      : () async {
                          setModalState(() => isConfirming = true);
                          try {
                            debugPrint(
                              'Attempting to update session $sessionId',
                            );
                            await _supabase
                                .from('sessions')
                                .update({
                                  'therapist_id': therapist['id'],
                                  'status': 'assigned',
                                  'scheduled_date': selectedDate
                                      .toIso8601String(),
                                  'scheduled_time': selectedTime.format(
                                    context,
                                  ),
                                  'session_count': sessionCount,
                                })
                                .eq('id', sessionId);

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Staff & Schedule Successfully Allotted!',
                                  ),
                                  backgroundColor: primaryGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              setState(() {});
                            }
                          } catch (e) {
                            debugPrint('Allotment Error: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: const Color(0xFFBE123C),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setModalState(() => isConfirming = false);
                            }
                          }
                        },
                  child: isConfirming
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'CONFIRM ALLOTMENT',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF94A3B8),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 0, // Hidden as we use the TabBar below
          bottom: TabBar(
            indicatorColor: primaryGreen,
            indicatorWeight: 3,
            labelColor: primaryGreen,
            unselectedLabelColor: slate,
            labelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            tabs: [
              Tab(text: 'CLINIC QUEUE ($_clinicCount)'),
              Tab(text: 'ONLINE APPOINTMENTS ($_onlineCount)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSessionList(context, 'pending'),
            _buildSessionList(context, 'requested'),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(BuildContext context, String statusFilter) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryGreen));
    }
    if (_adminClinicId == null) {
      return Center(
        child: Text(
          'No clinic assigned to this admin.',
          style: GoogleFonts.outfit(color: slate, fontSize: 16),
        ),
      );
    }
    return FutureBuilder(
      future: _supabase
          .from('sessions')
          .select('*, profiles!sessions_patient_id_fkey(full_name, phone)')
          .eq('status', statusFilter)
          .eq('clinic_id', _adminClinicId!)
          .order('created_at'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryGreen),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Sync Error: ${snapshot.error}',
              style: GoogleFonts.outfit(),
            ),
          );
        }

        final sessions = snapshot.data as List<dynamic>;

        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: softSage,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusFilter == 'pending'
                        ? Icons.verified_rounded
                        : Icons.calendar_today_rounded,
                    size: 48,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  statusFilter == 'pending'
                      ? 'Queue Cleared'
                      : 'No New Bookings',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  statusFilter == 'pending'
                      ? 'All clinic requests have been allotted.'
                      : 'No online appointment requests found.',
                  style: GoogleFonts.outfit(
                    color: slate,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final patientName = session['profiles'] != null
                ? session['profiles']['full_name']
                : 'Guest Patient';
            final patientPhone = session['profiles'] != null
                ? session['profiles']['phone']
                : null;
            final date = DateTime.parse(session['created_at']).toLocal();

            // For requested sessions, show the preferred date
            String scheduledInfo = '';
            if (statusFilter == 'requested') {
              if (session['scheduled_date'] != null &&
                  session['scheduled_time'] != null) {
                final sDate = DateTime.parse(session['scheduled_date']);
                scheduledInfo =
                    'Booked: ${DateFormat('MMM d').format(sDate)} at ${session['scheduled_time']}';
              } else {
                scheduledInfo =
                    'Requested: ${DateFormat('MMM d, hh:mm a').format(date)}';
              }
            } else {
              scheduledInfo = DateFormat('hh:mm a').format(date);
            }

            final spec = session['specialization_required']
                .toString()
                .toUpperCase();

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      color: const Color(0xFFF8FAFC),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statusBadge(spec),
                          Row(
                            children: [
                              Icon(
                                statusFilter == 'requested'
                                    ? Icons.calendar_today_rounded
                                    : Icons.access_time_rounded,
                                size: 12,
                                color: statusFilter == 'requested'
                                    ? const Color(0xFF3E84DC)
                                    : slate,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                scheduledInfo,
                                style: GoogleFonts.outfit(
                                  color: statusFilter == 'requested'
                                      ? const Color(0xFF3E84DC)
                                      : slate,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: softSage,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: primaryGreen,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      statusFilter == 'requested'
                                          ? 'Patient Booking'
                                          : 'Clinic Request',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: statusFilter == 'requested'
                                            ? const Color(0xFF3E84DC)
                                            : honeyAmber,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      patientName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    if (session['location'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_rounded,
                                              size: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              session['location']
                                                  .toString()
                                                  .toUpperCase(),
                                              style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF64748B),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (patientPhone != null)
                                IconButton(
                                  onPressed: () => _makeCall(patientPhone),
                                  icon: const Icon(Icons.phone_in_talk_rounded),
                                  color: const Color(0xFF10B981),
                                  iconSize: 20,
                                  tooltip: 'Call Patient',
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SERVICE FEE (EDITABLE)',
                                      style: GoogleFonts.outfit(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: slate,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => _showEditFeeDialog(
                                        session['id'],
                                        session['fee_charged'].toString(),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '₹${session['fee_charged']}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: primaryGreen,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.edit_rounded,
                                            size: 12,
                                            color: primaryGreen,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _allotTherapist(
                                  session['id'],
                                  session['specialization_required'],
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    40,
                                    49,
                                    70,
                                  ),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'ALLOT THERAPIST',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const HugeIcon(
                                      icon: HugeIcons.strokeRoundedUserSquare,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _showEditFeeDialog(String sessionId, String currentFee) {
    final controller = TextEditingController(text: currentFee);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Service Fee',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '₹ ',
            labelText: 'New Fee',
            labelStyle: GoogleFonts.outfit(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.outfit(color: slate)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newFee = double.tryParse(controller.text);
              if (newFee != null) {
                await _supabase
                    .from('sessions')
                    .update({'fee_charged': newFee})
                    .eq('id', sessionId);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            child: Text(
              'UPDATE',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: SpecializationColors.getDecoration(label),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: SpecializationColors.getTextColor(label),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
