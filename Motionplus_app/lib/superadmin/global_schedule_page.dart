import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/api_service.dart';

class GlobalSchedulePage extends StatefulWidget {
  const GlobalSchedulePage({super.key});

  @override
  State<GlobalSchedulePage> createState() => _GlobalSchedulePageState();
}

class _GlobalSchedulePageState extends State<GlobalSchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late Future<List<dynamic>> _allSessionsFuture;
  late Future<List<dynamic>> _requestedFuture;
  late Future<List<dynamic>> _assignedFuture;
  late Future<List<dynamic>> _completedFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _loadData();
  }

  void _loadData() {
    _allSessionsFuture = _getSessions(null);
    _requestedFuture = _getSessions('pending');
    _assignedFuture = _getSessions('assigned');
    _completedFuture = _getSessions('completed');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _getSessions(String? status) async {
    try {
      String url = '/sessions';
      if (status != null) {
        url += '?status=\$status';
      }
      final data = await ApiService.get(url, includeAuth: true);
      return data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Network Schedules',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadData();
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.5),
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'All Sessions'),
            Tab(text: 'Requested'),
            Tab(text: 'Assigned'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionList(_allSessionsFuture, null),
          _buildSessionList(_requestedFuture, 'pending'),
          _buildSessionList(_assignedFuture, 'assigned'),
          _buildSessionList(_completedFuture, 'completed'),
        ],
      ),
    );
  }

  Widget _buildSessionList(
    Future<List<dynamic>> future,
    String? filterStatus,
  ) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, size: 48, color: Colors.redAccent.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'Schedules Unavailable',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.redAccent),
                ),
                Text(
                  'Please check your network connection',
                  style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) return _buildEmptyState(filterStatus);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) =>
              _buildAppointmentCard(sessions[index] as Map<String, dynamic>),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> session) {
    final status = (session['status'] ?? 'pending').toString().toLowerCase();
    DateTime? scheduledTime;
    try {
      if (session['scheduled_at'] != null) {
        scheduledTime = DateTime.parse(session['scheduled_at']).toLocal();
      }
    } catch (e) {
      debugPrint('Date parsing error: \$e');
    }

    Color statusColor = Colors.orange;
    if (status == 'completed') statusColor = Colors.green;
    if (status == 'assigned') statusColor = Colors.blue;

    final patientObj = session['patient_id'];
    final therapistObj = session['therapist_id'];
    
    final patientName = patientObj != null && patientObj is Map ? patientObj['full_name'] : 'Unknown';
    final patientPhone = patientObj != null && patientObj is Map ? patientObj['email'] : 'No Contact';

    final therapistName = therapistObj != null && therapistObj is Map ? therapistObj['full_name'] : 'Unassigned';
    final therapistPhone = therapistObj != null && therapistObj is Map ? therapistObj['email'] : 'No Contact';


    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar03,
                      size: 18,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      scheduledTime != null
                          ? DateFormat(
                              'EEE, MMM d • hh:mm a',
                            ).format(scheduledTime)
                          : 'Not scheduled',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildPersonInfo(
                  'PATIENT',
                  patientName,
                  patientPhone,
                  HugeIcons.strokeRoundedUser,
                  Colors.teal,
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 16,
                ),
                const SizedBox(width: 12),
                _buildPersonInfo(
                  'THERAPIST',
                  therapistName,
                  therapistPhone,
                  HugeIcons.strokeRoundedDoctor01,
                  Colors.indigo,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainer
                  : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedClock01,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '45 Mins',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  "Charge: ₹${(session['fee_charged'] ?? 0).toString()}",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonInfo(
    String label,
    String? name,
    String? phone,
    dynamic icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF94A3B8),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              HugeIcon(icon: icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name ?? 'Unassigned',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            phone ?? 'No phone',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String? filterStatus) {
    String message = 'No active sessions found';
    if (filterStatus == 'pending') message = 'No new requests yet';
    if (filterStatus == 'assigned') message = 'No assigned sessions yet';
    if (filterStatus == 'completed') message = 'No completed sessions yet';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 64,
            color: Colors.blue.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
