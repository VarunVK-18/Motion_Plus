import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../selection_page.dart';
import '../shared/chat_page.dart';
import '../patients/patient_profile_page.dart';
import '../shared/specialization_colors.dart';
import '../services/audit_logger.dart';
import 'package:hugeicons/hugeicons.dart';

class TherapistDashboard extends StatefulWidget {
  const TherapistDashboard({super.key});

  @override
  State<TherapistDashboard> createState() => _TherapistDashboardState();
}

class _TherapistDashboardState extends State<TherapistDashboard> {
  Map<String, dynamic>? _currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentStatus = 'Available'; // Default status

  @override
  void initState() {
    ApiService.get('/profiles/me', includeAuth: true).then((user) {
      setState(() {
        _currentUser = user as Map<String, dynamic>;
      });
    });
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    final user = _currentUser;
    if (user != null) {
      final data = await ApiService.get('/profiles/me', includeAuth: true);
      if (data['clinical_status'] != null) {
        if (mounted) {
          setState(() {
            _currentStatus = data['clinical_status'];
          });
        }
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final user = _currentUser;
    if (user != null) {
      try {
        await ApiService.put('/profiles/' + user['id'].toString(), {'clinical_status': newStatus}, includeAuth: true);
        if (mounted) {
          setState(() {
            _currentStatus = newStatus;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Clinical Status: $newStatus'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error updating status: $e');
      }
    }
  }

  Future<void> _showLogoutConfirm() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Sign Out?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to log out of your clinical portal?',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'LOGOUT',
              style: GoogleFonts.outfit(
                color: const Color(0xFFBE123C),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await ApiService.clearToken();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SelectionPage()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _startSession(String sessionId, int minutes) async {
    try {
      final data = await ApiService.put('/sessions/' + sessionId.trim(), {
            'status': 'in_progress',
            'started_at': DateTime.now().toUtc().toIso8601String(),
            'allotted_time': minutes,
          }, includeAuth: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session Started! (Status: ${data['status']})'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to Start Session: $e'),
            backgroundColor: const Color(0xFFBE123C),
          ),
        );
      }
    }
  }

  Future<void> _completeSession(
    String sessionId,
    Map<String, dynamic> reportData,
    int currentCount,
    int totalCount,
  ) async {
    debugPrint("Attempting to complete session visit: $sessionId");
    try {
      final isFinalSession = (currentCount + 1) >= totalCount;

      await ApiService.put('/sessions/' + sessionId.trim(), {
            'status': isFinalSession ? 'completed' : 'assigned',
            'completed_count': currentCount + 1,
            'completed_at': isFinalSession
                ? DateTime.now().toUtc().toIso8601String()
                : null,
            'session_summary': reportData['session_summary'],
            'exercises_performed': reportData['exercises_performed'],
            'pain_fatigue_level': reportData['pain_fatigue_level'],
            'patient_response': reportData['patient_response'],
            'therapist_observation': reportData['therapist_observation'],
            'homework_given': reportData['homework_given'],
            'session_recommendation': reportData['session_recommendation'],
          }, includeAuth: true);

      await AuditLogger.logEvent(
        action: 'COMPLETE_SESSION',
        reason: 'Completed session $sessionId',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFinalSession
                  ? 'Assignment Fully Completed!'
                  : 'Visit ${currentCount + 1} Logged Successfully!',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      debugPrint("Completion Error for $sessionId: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to Log Visit: $e'),
            backgroundColor: const Color(0xFFBE123C),
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    final userId = user?['id'] ?? '';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildDrawer(user, userId),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedMenu01,
                        color: Color(0xFF0F172A),
                        size: 24,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        'THERAPIST ACCESS',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3E84DC),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'MY ASSIGNMENTS',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showLogoutConfirm,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFBE123C),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Smart Alerts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: FutureBuilder<dynamic>(
                future: ApiService.get('/smart_alerts?is_read=false', includeAuth: true),
                builder: (context, snapshot) {
                  final alerts = snapshot.data ?? [];
                  if (alerts.isEmpty) return const SizedBox.shrink();

                  return Column(
                    children: alerts.map((alert) {
                      final isPlateau = alert['alert_type'] == 'plateau';
                      final color = isPlateau ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(isPlateau ? Icons.trending_flat_rounded : Icons.warning_rounded, color: color, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                alert['message'],
                                style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: color, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                await ApiService.put('/smart_alerts/' + alert['id'].toString(), {'is_read': true}, includeAuth: true);
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            // Status Selector Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E84DC).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedUserAccount,
                        color: Color(0xFF3E84DC),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'THERAPIST STATUS',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _statusChip(
                                  'Available',
                                  const Color(0xFF10B981),
                                ),
                                const SizedBox(width: 8),
                                _statusChip(
                                  'On Therapy',
                                  const Color(0xFF3E84DC),
                                ),
                                const SizedBox(width: 8),
                                _statusChip('Offline', const Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: FutureBuilder<dynamic>(
                future: ApiService.get('/sessions?therapist_id=$userId', includeAuth: true),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 48,
                            color: Colors.redAccent.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Schedules Offline',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: Colors.redAccent,
                            ),
                          ),
                          Text(
                            'Reconnect to see assigned patients',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3E84DC),
                      ),
                    );
                  }

                  final allSessions = snapshot.data ?? [];
                  final activeSessions = allSessions
                      .where(
                        (s) =>
                            s['status'] == 'assigned' ||
                            s['status'] == 'in_progress',
                      )
                      .toList();

                  if (activeSessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.assignment_turned_in_rounded,
                              size: 40,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'All caught up!',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No pending clinical assignments at the moment.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    physics: const BouncingScrollPhysics(),
                    itemCount: activeSessions.length,
                    itemBuilder: (context, index) {
                      final session = activeSessions[index];
                      return _SessionCard(
                        key: ValueKey(session['id']),
                        session: session,
                        onStart: (mins) =>
                            _startSession(session['id'].toString(), mins),
                        onComplete: (reportData) => _completeSession(
                          session['id'].toString(),
                          reportData,
                          session['completed_count'] ?? 0,
                          session['session_count'] ?? 1,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(Map<String, dynamic>? user, String userId) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3E84DC), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: FutureBuilder(
              future: ApiService.get('/profiles/' + userId.toString(), includeAuth: true),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                final name =
                    profile?['full_name']?.toString().toUpperCase() ??
                    user?['email']?.split('@')[0].toUpperCase() ??
                    'STAFF';
                final spec = profile?['specialization']?.toString() ?? 'N/A';
                final phone = profile?['phone']?.toString() ?? 'N/A';

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person_rounded,
                          size: 32,
                          color: Color(0xFF3E84DC),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              spec.toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.alternate_email_rounded,
                                size: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  user?['email'] ?? 'No Email',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_android_rounded,
                                size: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                phone,
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
          const SizedBox(height: 20),
          _drawerItem(
            Icons.grid_view_rounded,
            'Overview',
            () => Navigator.pop(context),
          ),
          _drawerItem(Icons.history_rounded, 'My Treatment Logs', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    _TherapistHistoryPage(therapistId: userId),
              ),
            );
          }),
          const Spacer(),
          const Divider(indent: 24, endIndent: 24, color: Color(0xFFF1F5F9)),
          _drawerItem(
            Icons.logout_rounded,
            'Sign Out',
            _showLogoutConfirm,
            isRed: true,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isRed = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isRed ? const Color(0xFFBE123C) : const Color(0xFF64748B),
        size: 20,
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: isRed ? const Color(0xFFBE123C) : const Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
      visualDensity: const VisualDensity(vertical: -1),
    );
  }

  Widget _statusChip(String label, Color color) {
    final isSelected = _currentStatus == label;
    return GestureDetector(
      onTap: () => _updateStatus(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: isSelected ? Colors.white : color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatefulWidget {
  final Map<String, dynamic> session;
  final Function(int) onStart;
  final Future<void> Function(Map<String, dynamic>) onComplete;
  const _SessionCard({
    super.key,
    required this.session,
    required this.onStart,
    required this.onComplete,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  Timer? _timer;
  String _timeLeft = "00:00:00";

  @override
  void initState() {
    super.initState();
    if (widget.session['status'] == 'in_progress' &&
        widget.session['started_at'] != null) {
      _startCountdown();
    }
  }

  @override
  void didUpdateWidget(_SessionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isNowInProgress = widget.session['status'] == 'in_progress';
    final wasInProgress = oldWidget.session['status'] == 'in_progress';
    final hasStartTime = widget.session['started_at'] != null;

    if (isNowInProgress &&
        (!wasInProgress || (_timer == null && hasStartTime))) {
      _timer?.cancel();
      _startCountdown();
    } else if (!isNowInProgress) {
      _timer?.cancel();
      _timer = null;
    }

    if (isNowInProgress && !hasStartTime && wasInProgress) {
      debugPrint("Waiting for timestamp for ${widget.session['id']}...");
    }
  }

  void _startCountdown() {
    try {
      final startedAt = widget.session['started_at'];
      if (startedAt == null) return; // Wait for the timestamp to arrive

      final startTime = DateTime.parse(startedAt.toString()).toLocal();
      final allotted = widget.session['allotted_time'] ?? 45;
      final endTime = startTime.add(
        Duration(minutes: int.parse(allotted.toString())),
      );

      // Initial calculation to prevent flicker
      final initialDiff = endTime.difference(DateTime.now());
      if (mounted) {
        setState(() {
          _timeLeft = _format(initialDiff);
        });
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        final diff = endTime.difference(DateTime.now());
        if (diff.isNegative) {
          timer.cancel();
          _showSessionReportForm();
        } else {
          setState(() => _timeLeft = _format(diff));
        }
      });

      debugPrint("Timer started for ${widget.session['id']}");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Timer Logic Error: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, "0");
    return "${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  bool _isCompleting = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _showSessionReportForm() async {
    final summaryController = TextEditingController();
    final exercisesController = TextEditingController();
    final responseController = TextEditingController();
    final observationController = TextEditingController();
    final homeworkController = TextEditingController();
    final recommendationController = TextEditingController();
    double painLevel = 3.0;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
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
                    'SESSION REPORT',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  _statusBadge('COMPLETING', const Color(0xFF10B981)),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _reportTextField(
                        'SESSION SUMMARY',
                        'How did the session go?',
                        summaryController,
                        maxLines: 3,
                      ),
                      _reportTextField(
                        'EXERCISES PERFORMED',
                        'List the exercises completed',
                        exercisesController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'PAIN / FATIGUE LEVEL',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF475569),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFF3E84DC),
                                inactiveTrackColor: const Color(0xFFF1F5F9),
                                thumbColor: const Color(0xFF3E84DC),
                                overlayColor: const Color(
                                  0xFF3E84DC,
                                ).withOpacity(0.1),
                                valueIndicatorColor: const Color(0xFF0F172A),
                                valueIndicatorTextStyle: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: Slider(
                                value: painLevel,
                                min: 0,
                                max: 10,
                                divisions: 10,
                                label: painLevel.round().toString(),
                                onChanged: (val) =>
                                    setModalState(() => painLevel = val),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${painLevel.round()}/10',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      _reportTextField(
                        'PATIENT RESPONSE',
                        'How did the patient feel/react?',
                        responseController,
                      ),
                      _reportTextField(
                        'THERAPIST OBSERVATION',
                        'Clinical notes and observations',
                        observationController,
                        maxLines: 3,
                      ),
                      _reportTextField(
                        'HOMEWORK GIVEN',
                        'Tasks for the patient until next time',
                        homeworkController,
                      ),
                      _reportTextField(
                        'NEXT SESSION RECOMMENDATION',
                        'Adjustments or focus for next time',
                        recommendationController,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'session_summary': summaryController.text,
                      'exercises_performed': exercisesController.text,
                      'pain_fatigue_level': painLevel.round().toString(),
                      'patient_response': responseController.text,
                      'therapist_observation': observationController.text,
                      'homework_given': homeworkController.text,
                      'session_recommendation': recommendationController.text,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'SUBMIT & COMPLETE',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) _handleComplete(result);
  }

  Widget _reportTextField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF475569),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                color: const Color(0xFFCBD5E1),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3E84DC)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleComplete(Map<String, dynamic> reportData) async {
    setState(() => _isCompleting = true);
    _timer?.cancel();
    try {
      await widget.onComplete(reportData);
    } catch (e) {
      if (mounted) {
        // Restart timer if it failed
        if (widget.session['status'] == 'in_progress') _startCountdown();
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete Assignment?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to remove "$name" from the patient\'s list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'DELETE',
              style: GoogleFonts.outfit(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.delete('/prescribed_exercises/' + id.toString(), includeAuth: true);
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    // Remove all non-numeric characters except the plus sign
    final String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri.parse('tel:$cleanPhone');

    try {
      // Try launching with external application mode first (opens dialer directly)
      final success = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!success) {
        // Fallback to platform default if external app fails
        await launchUrl(launchUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Could not launch $launchUri: $e');
      // Final attempt with plain launchUrl
      try {
        await launchUrl(launchUri);
      } catch (_) {}
    }
  }

  void _showSkipReason(BuildContext context, String name, String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Text(
          'Not Completed Detail',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3E84DC),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Reason for not completing:',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reason,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF1E293B),
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CLOSE',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3E84DC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFF94A3B8),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, size: 12, color: const Color(0xFF3E84DC)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAssignmentDialog(BuildContext context, String patientId) {
    final exercises = [
      {'name': 'Squats', 'part': 'Legs', 'type': 'Reps'},
      {'name': 'Push-ups', 'part': 'Chest', 'type': 'Reps'},
      {'name': 'Plank', 'part': 'Abs', 'type': 'Hold'},
      {'name': 'Bicep Curls', 'part': 'Arms', 'type': 'Reps'},
      {'name': 'Wrist Curls', 'part': 'Forearms', 'type': 'Reps'},
      {'name': 'Shoulder Press', 'part': 'Shoulder', 'type': 'Reps'},
      {'name': 'Leg Press', 'part': 'Legs', 'type': 'Reps'},
      {'name': 'Mountain Climbers', 'part': 'Abs', 'type': 'Hold'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
            Text(
              'Prescribe Workouts',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select exercises to assign to this patient',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final ex = exercises[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3E84DC).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          ex['type'] == 'Hold'
                              ? Icons.timer_rounded
                              : Icons.fitness_center_rounded,
                          color: const Color(0xFF3E84DC),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        ex['name']!,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        ex['part']!,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _assignExercise(patientId, ex),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF10B981),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFF10B981)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'ASSIGN',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
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

  Future<void> _assignExercise(String patientId, Map<String, String> ex) async {
    try {
      final therapistData = await ApiService.get('/profiles/me', includeAuth: true);
      final therapistId = therapistData['id'];

      await ApiService.post('/prescribed_exercises', {
        'patient_id': patientId,
        'therapist_id': therapistId,
        'exercise_name': ex['name'],
        'body_part': ex['part'],
        'is_hold_based': ex['type'] == 'Hold',
        'target_sets': 3,
        'target_reps': ex['type'] == 'Hold' ? 0 : 12,
        'hold_duration': ex['type'] == 'Hold' ? 30 : 0,
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }, includeAuth: true);

      await AuditLogger.logEvent(
        action: 'PRESCRIBE_EXERCISE',
        targetId: patientId,
        reason: 'Assigned ${ex['name']}',
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Assignment Successful',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${ex['name']} has been prescribed to the patient.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'DONE',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            title: Text(
              'Assignment Failed',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFBE123C),
              ),
            ),
            content: Text(
              'Could not assign ${ex['name']}: $e',
              style: GoogleFonts.outfit(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFBE123C),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildContactAction({
    required dynamic icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: HugeIcon(icon: icon, size: 16, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final spec = session['specialization_required'].toString().toUpperCase();
    final status = session['status'];
    final isInProgress = status == 'in_progress';
    final accentColor = const Color(0xFF3E84DC); // Simplified for demo

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _typeBadge(spec),
                Row(
                  children: [
                    if (isInProgress)
                      _statusBadge('LIVE SESSION', const Color(0xFFBE123C))
                    else
                      _statusBadge('ASSIGNED', const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E84DC).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'VISIT ${(session['completed_count'] ?? 0) + 1}/${session['session_count'] ?? 1}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF3E84DC),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PATIENT NAME',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'CONTACT',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FutureBuilder(
                  future: ApiService.get('/profiles/' + session['patient_id'].toString(), includeAuth: true),
                  builder: (context, snap) {
                    final name = snap.hasData
                        ? snap.data!['full_name']
                        : 'Loading...';
                    final phone = snap.hasData ? snap.data!['phone'] : '...';
                    return Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PatientProfilePage(
                                    email: name, // We don't have email in this snap, use name as fallback
                                    patientId: session['patient_id'],
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              name,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF3E84DC),
                              ),
                            ),
                          ),
                        ),
                        if (snap.hasData)
                          Row(
                            children: [
                              _buildContactAction(
                                icon: HugeIcons.strokeRoundedChat01,
                                color: const Color(0xFF3E84DC),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatPage(
                                        sessionId: session['id'],
                                        receiverId: session['patient_id'],
                                        receiverName: name,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Schedule Info Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _scheduleItem(
                        icon: Icons.calendar_today_rounded,
                        label: 'DATE',
                        value: session['scheduled_date'] != null
                            ? DateFormat('MMM d, yyyy').format(
                                DateTime.parse(session['scheduled_date']),
                              )
                            : 'TBD',
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _scheduleItem(
                        icon: Icons.access_time_rounded,
                        label: isInProgress ? 'REMAINING' : 'TIME',
                        value: isInProgress
                            ? _timeLeft
                            : (session['scheduled_time']?.toString() ?? 'TBD'),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _scheduleItem(
                        icon: Icons.repeat_rounded,
                        label: 'PROGRESS',
                        value:
                            '${session['completed_count'] ?? 0}/${session['session_count'] ?? 1} DONE',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (session['session_count'] ?? 1) > 0
                          ? (session['completed_count'] ?? 0) /
                                (session['session_count'] ?? 1)
                          : 0,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Prescribed Workouts Status Section
                Text(
                  'ASSIGNED WORKOUTS STATUS',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<dynamic>(
                  future: ApiService.get('/prescribed_exercises?patient_id=${session['patient_id']}', includeAuth: true),
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data!.isEmpty) {
                      return Text(
                        'No workouts assigned yet.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                    final items = snap.data!
                        .where(
                          (ex) => ex['therapist_id'] == session['therapist_id'],
                        )
                        .toList();

                    if (items.isEmpty) {
                      return Text(
                        'No workouts assigned by you.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                    return Column(
                      children: items.map((ex) {
                        final status = ex['status'] ?? 'pending';
                        final name = ex['exercise_name'] ?? 'Unknown';
                        Color statusColor;
                        String statusLabel;

                        if (status == 'completed') {
                          statusColor = const Color(0xFF10B981);
                          statusLabel = 'COMPLETED';
                        } else if (status == 'skipped') {
                          statusColor = const Color(0xFFBE123C);
                          statusLabel = 'NOT COMPLETED';
                        } else {
                          statusColor = const Color(0xFFF59E0B);
                          statusLabel = 'PENDING';
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              GestureDetector(
                                onTap: status == 'skipped'
                                    ? () => _showSkipReason(
                                        context,
                                        name,
                                        ex['skip_reason'] ??
                                            'No reason provided',
                                      )
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        statusLabel,
                                        style: GoogleFonts.outfit(
                                          color: statusColor,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      if (status == 'skipped') ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 10,
                                          color: statusColor,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    _confirmDelete(context, ex['id'], name),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => _showAssignmentDialog(
                            context,
                            session['patient_id'],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: const Color.fromARGB(
                              255,
                              255,
                              254,
                              254,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'ASSIGN WORKOUTS',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isCompleting
                              ? null
                              : (isInProgress
                                    ? _showSessionReportForm
                                    : () => _showPicker()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInProgress
                                ? const Color(0xFFBE123C)
                                : const Color(0xFF3E84DC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isCompleting
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color.fromARGB(255, 7, 7, 66),
                                  ),
                                )
                              : Text(
                                  isInProgress
                                      ? 'COMPLETE VISIT #${(session['completed_count'] ?? 0) + 1}'
                                      : 'START SESSION',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SESSION DURATION',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _timeBtn(45, '45 MINS'),
                const SizedBox(width: 12),
                _timeBtn(90, '90 MINS'),
                const SizedBox(width: 12),
                _timeBtn(135, '135 MINS'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showCustom();
                },
                child: Text(
                  'ENTER CUSTOM DURATION',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF3E84DC),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeBtn(int m, String l) => Expanded(
    child: OutlinedButton(
      onPressed: () {
        Navigator.pop(context);
        widget.onStart(m);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: const BorderSide(color: Color(0xFFF1F5F9), width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        l,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: const Color(0xFF1E293B),
        ),
      ),
    ),
  );

  void _showCustom() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Custom Duration',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter minutes',
            hintStyle: GoogleFonts.outfit(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(
                color: const Color(0xFFBE123C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              widget.onStart(int.tryParse(c.text) ?? 45);
              Navigator.pop(context);
            },
            child: Text(
              'START',
              style: GoogleFonts.outfit(
                color: const Color(0xFF3E84DC),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(String s) {
    if (s == 'ORTHO') return const Color(0xFFB45309);
    if (s == 'NEURO') return const Color(0xFF2D6A4F);
    if (s == 'CARDIO') return const Color(0xFFBE123C);
    return const Color(0xFF3E84DC);
  }

  Widget _typeBadge(String type) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: SpecializationColors.getDecoration(type),
    child: Text(
      type,
      style: GoogleFonts.outfit(
        color: SpecializationColors.getTextColor(type),
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    ),
  );
  Widget _statusBadge(String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: c.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          l,
          style: GoogleFonts.outfit(
            color: c,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

class _TherapistHistoryPage extends StatelessWidget {
  final String therapistId;
  const _TherapistHistoryPage({required this.therapistId});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF1E293B),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'TREATMENT LOGS',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<dynamic>(
                future: ApiService.get('/sessions?therapist_id=$therapistId', includeAuth: true),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3E84DC),
                      ),
                    );
                  }
                  final history = snapshot.data!
                      .where((s) => s['status'] == 'completed')
                      .toList();
                  if (history.isEmpty) {
                    return Center(
                      child: Text(
                        'No completed sessions found.',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final s = history[index];
                      final dateStr =
                          s['completed_at'] ??
                          s['created_at'] ??
                          DateTime.now().toIso8601String();
                      final date = DateTime.parse(dateStr.toString()).toLocal();
                      return GestureDetector(
                        onTap: () => _showSessionDetails(context, s),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0FDF4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF10B981),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FutureBuilder(
                                      future: ApiService.get('/profiles/' + s['patient_id'].toString(), includeAuth: true),
                                      builder: (context, p) => Text(
                                        p.hasData
                                            ? p.data!['full_name']
                                            : '...',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat(
                                        'MMM d • hh:mm a',
                                      ).format(date),
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${s['allotted_time'] ?? 45}m',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF3E84DC),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'SESSION',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFCBD5E1),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionDetails(BuildContext context, Map<String, dynamic> s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SESSION DETAILS',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- THERAPIST REPORT SECTION ---
                    _sectionTitle('CLINICAL REPORT (MY LOGS)'),
                    _infoTile('Summary', s['session_summary'] ?? 'N/A'),
                    _infoTile('Exercises', s['exercises_performed'] ?? 'N/A'),
                    _infoTile(
                      'Observation',
                      s['therapist_observation'] ?? 'N/A',
                    ),
                    _infoTile(
                      'Recommendation',
                      s['session_recommendation'] ?? 'N/A',
                    ),

                    const SizedBox(height: 32),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 32),

                    // --- PATIENT FEEDBACK SECTION ---
                    _sectionTitle('PATIENT\'S PERSPECTIVE'),
                    if (s['patient_feedback'] == null ||
                        s['patient_feedback'].toString().trim().isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Patient hasn\'t provided feedback for this session yet.',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: Text(
                          s['patient_feedback'].toString(),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF166534),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF3E84DC),
        letterSpacing: 1,
      ),
    ),
  );

  Widget _infoTile(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    ),
  );

  Widget _statBox(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}
