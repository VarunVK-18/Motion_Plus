import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';

class GlobalSchedulePage extends StatefulWidget {
  const GlobalSchedulePage({super.key});

  @override
  State<GlobalSchedulePage> createState() => _GlobalSchedulePageState();
}

class _GlobalSchedulePageState extends State<GlobalSchedulePage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  late Stream<List<Map<String, dynamic>>> _allSessionsStream;
  late Stream<List<Map<String, dynamic>>> _requestedStream;
  late Stream<List<Map<String, dynamic>>> _assignedStream;
  late Stream<List<Map<String, dynamic>>> _completedStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize streams once
    _allSessionsStream = _getReactiveSessions(null);
    _requestedStream = _getReactiveSessions('pending');
    _assignedStream = _getReactiveSessions('assigned');
    _completedStream = _getReactiveSessions('completed');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _getReactiveSessions(String? status) {
    return _supabase.from('sessions').stream(primaryKey: ['id']).asyncMap((
      _,
    ) async {
      try {
        var query = _supabase
            .from('sessions')
            .select(
              '*, patient:profiles!sessions_patient_id_fkey(full_name, phone), therapist:profiles!sessions_therapist_id_fkey(full_name, phone)',
            );
        if (status != null) {
          query = query.eq('status', status);
        }
        final List<dynamic> data = await query.order('scheduled_time');
        return List<Map<String, dynamic>>.from(data);
      } catch (e) {
        return <Map<String, dynamic>>[];
      }
    });
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
          _buildSessionList(_allSessionsStream, null),
          _buildSessionList(_requestedStream, 'pending'),
          _buildSessionList(_assignedStream, 'assigned'),
          _buildSessionList(_completedStream, 'completed'),
        ],
      ),
    );
  }

  Widget _buildSessionList(
    Stream<List<Map<String, dynamic>>> stream,
    String? filterStatus,
  ) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
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
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) return _buildEmptyState(filterStatus);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) =>
              _buildAppointmentCard(sessions[index]),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> session) {
    final status = (session['status'] ?? 'pending').toString().toLowerCase();
    DateTime? scheduledTime;
    try {
      if (session['scheduled_time'] != null) {
        scheduledTime = DateTime.parse(session['scheduled_time']).toLocal();
      }
    } catch (e) {
      debugPrint('Date parsing error: $e');
    }

    Color statusColor = Colors.orange;
    if (status == 'completed') statusColor = Colors.green;
    if (status == 'assigned') statusColor = Colors.blue;

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
                          : (session['scheduled_time'] ?? 'Not scheduled'),
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
                  session['patient']?['full_name'],
                  session['patient']?['phone'],
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
                  session['therapist']?['full_name'],
                  session['therapist']?['phone'],
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
                      '${session['allotted_time'] ?? session['duration_minutes'] ?? "45"} Mins',
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
                  'Charge: ₹${(session['fee_charged'] ?? session['payment_amount'] ?? "0").toString()}',
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
