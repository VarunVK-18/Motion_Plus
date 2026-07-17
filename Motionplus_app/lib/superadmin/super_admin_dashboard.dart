import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'clinic_management_page.dart';
import 'admin_management_page.dart';
import 'global_analytics_page.dart';
import 'financial_management_page.dart';
import 'platform_settings_page.dart';
import 'global_schedule_page.dart';
import 'global_data_view.dart';
import '../selection_page.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Stream<List<dynamic>> _activityStream;
  final _activityController =
      StreamController<List<dynamic>>.broadcast();
  
  late Future<List<dynamic>> _clinicsFuture;
  late Future<List<dynamic>> _adminsFuture;
  Timer? _refreshTimer;
  StreamSubscription? _themeSubscription;
  bool _isDarkMode = false;
  final ValueNotifier<bool> _isDarkModeNotifier = ValueNotifier(false);
  final ValueNotifier<String> _activityFilterNotifier = ValueNotifier('Today');
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _activityStream = _activityController.stream;
    _fetchRecentActivity();
    _loadData();

    // Refresh the UI every 30 seconds to update relative time labels
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });

    _fetchTheme();
  }

  void _loadData() {
    _clinicsFuture = ApiService.get('/clinics', includeAuth: true).then((res) => res as List<dynamic>);
    _adminsFuture = ApiService.get('/profiles?role=admin', includeAuth: true).then((res) => res as List<dynamic>);
  }

  Future<void> _fetchTheme() async {
    try {
      final data = await ApiService.get('/settings?key=dark_mode_support', includeAuth: true);
      final settings = data as List<dynamic>;
      if (settings.isNotEmpty && mounted) {
        final isDark = settings.first['value'] == 'true';
        _isDarkModeNotifier.value = isDark;
        setState(() {
          _isDarkMode = isDark;
        });
      }
    } catch (e) {
      debugPrint('Theme fetch error: $e');
    }
  }

  Future<void> _fetchRecentActivity() async {
    try {
      DateTime? startDate;
      DateTime? endDate;
      final now = DateTime.now();

      final filter = _activityFilterNotifier.value;

      if (filter == 'Today') {
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
      } else if (filter == 'This Week') {
        startDate = DateTime(now.year, now.month, now.day - now.weekday + 1);
        endDate = now;
      } else if (filter == 'This Month') {
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
      } else if (filter == 'Custom Date Range' && _customDateRange != null) {
        startDate = _customDateRange!.start;
        endDate = _customDateRange!.end.add(const Duration(days: 1));
      }

      final sessionDataRaw = await ApiService.get('/sessions', includeAuth: true);
      final profileDataRaw = await ApiService.get('/profiles', includeAuth: true);
      
      List<dynamic> sessionData = sessionDataRaw as List<dynamic>;
      List<dynamic> profileData = profileDataRaw as List<dynamic>;

      if (startDate != null && endDate != null) {
        sessionData = sessionData.where((s) {
          final d = DateTime.tryParse(s['created_at']?.toString() ?? '');
          if (d == null) return false;
          return d.isAfter(startDate!) && d.isBefore(endDate!);
        }).toList();
        
        profileData = profileData.where((p) {
          final d = DateTime.tryParse(p['created_at']?.toString() ?? '');
          if (d == null) return false;
          return d.isAfter(startDate!) && d.isBefore(endDate!);
        }).toList();
      }

      final mappedSessions = sessionData.map<Map<String, dynamic>>((s) {
        final Map<String, dynamic> session = Map<String, dynamic>.from(s as Map);
        session['patient_name'] = session['patient_id']?['full_name'];
        session['therapist_name'] = session['therapist_id']?['full_name'];
        
        session['activity_time'] = session['completed_at'] ?? session['created_at'];
        session['created_at'] = session['activity_time'];
        return session;
      }).toList();

      final mappedProfiles = profileData.map<Map<String, dynamic>>((p) {
        final Map<String, dynamic> profile = Map<String, dynamic>.from(p as Map);
        return {
          'status': 'registered',
          'patient_name': profile['full_name'] ?? 'Unknown User',
          'therapist_name': 'Role: ${(profile['role'] ?? 'user').toString().toUpperCase()}',
          'activity_time': profile['created_at'],
          'created_at': profile['created_at'],
        };
      }).toList();

      final allActivities = [...mappedSessions, ...mappedProfiles];

      allActivities.sort((a, b) {
        final dateA = DateTime.tryParse(a['activity_time']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['activity_time']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      if (!_activityController.isClosed) {
        _activityController.add(allActivities.take(50).toList());
      }
    } catch (e) {
      debugPrint('Error fetching recent activity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? _getDarkTheme() : _getLightTheme(),
      child: Builder(
        builder: (context) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: _isDarkMode
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              drawer: _buildDrawer(context),
              body: SafeArea(
                child: RefreshIndicator.adaptive(
                  onRefresh: _handleRefresh,
                  color: Theme.of(context).colorScheme.surface,
                  backgroundColor: Theme.of(context).colorScheme.onSurface,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      _buildAppBar(context),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overview',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildStatsRow(context),
                              const SizedBox(height: 32),
                              _buildQuickAccessSection(context),
                              const SizedBox(height: 32),
                              _buildRecentActivitySection(context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await _fetchRecentActivity();
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: 90,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 40, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: Icon(
                Icons.menu_rounded,
                color: Theme.of(context).colorScheme.onSurface,
                size: 26,
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OLIVEO',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Super Admin',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color.fromARGB(255, 222, 213, 132),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildDrawerItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedHospital01,
                    title: 'Clinic Management',
                    onTap: () => _navigateTo(const ClinicManagementPage()),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedUserAdd01,
                    title: 'Admin Access',
                    onTap: () => _navigateTo(const AdminManagementPage()),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedAnalytics03,
                    title: 'Global Analytics',
                    onTap: () => _navigateTo(const GlobalAnalyticsPage()),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedCoins01,
                    title: 'Financial Management',
                    onTap: () => _navigateTo(const FinancialManagementPage()),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedCalendar01,
                    title: 'Clinic Schedules',
                    onTap: () => _navigateTo(const GlobalSchedulePage()),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedUserGroup,
                    title: 'Clinic Management',
                    onTap: () => _navigateTo(const GlobalDataView()),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      color: Theme.of(context).dividerColor.withOpacity(0.05),
                    ),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedSettings01,
                    title: 'Settings',
                    onTap: () => _navigateTo(PlatformSettingsPage(
                      onThemeChanged: (isDark) {
                        _isDarkModeNotifier.value = isDark;
                        setState(() {
                          _isDarkMode = isDark;
                        });
                      },
                    )),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    color: Colors.redAccent,
                    onTap: _signOut,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.security_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'OLIVEO',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'System Administration',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required dynamic icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: _renderIcon(
        icon,
        color ??
            (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF475569)),
        22,
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Color(0xFFCBD5E1),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        FutureBuilder<List<dynamic>>(
          future: _clinicsFuture,
          builder: (context, snapshot) {
            final count = snapshot.data?.length.toString() ?? '...';
            return _buildStatCard(
              context,
              'Clinics',
              count,
              HugeIcons.strokeRoundedHospital01,
              const Color(0xFF3B82F6),
              () => _navigateTo(const ClinicManagementPage()),
            );
          },
        ),
        const SizedBox(width: 16),
        FutureBuilder<List<dynamic>>(
          future: _adminsFuture,
          builder: (context, snapshot) {
            final count = snapshot.data?.length.toString() ?? '...';
            return _buildStatCard(
              context,
              'Admins',
              count,
              HugeIcons.strokeRoundedUserAdd01,
              const Color(0xFF3B82F6),
              () => _navigateTo(const AdminManagementPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    dynamic icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.2)
                    : const Color(0xFF0F172A).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _renderIcon(icon, color, 20),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _navigateTo(const GlobalDataView()),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _renderIcon(
                    HugeIcons.strokeRoundedUserGroup,
                    Colors.white,
                    28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registered Directory',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromARGB(255, 222, 213, 132),
                        ),
                      ),
                      Text(
                        'View All Patients / Therapist',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: Colors.white.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            _buildDateFilterDropdown(context),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.1)
                    : const Color(0xFF0F172A).withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: StreamBuilder<List<dynamic>>(
            stream: _activityStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Error loading activity',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final activities = snapshot.data!;
              if (activities.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'No recent activity found',
                      style: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                    ),
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                  final activity = activities[index];
                  final status =
                      activity['status']?.toString().toLowerCase() ?? 'pending';
                  final patientName =
                      activity['patient_name'] ?? 'Unknown Patient';
                  final therapistName =
                      activity['therapist_name'] ?? 'Unassigned';
                  final createdAtStr = activity['created_at'];
                  final timeAgo = _getRelativeTime(createdAtStr);

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getStatusIcon(status),
                            color: _getStatusColor(status),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          _getActivityTitle(status, patientName),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Therapist: $therapistName',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        trailing: Text(
                          timeAgo,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                      if (index < activities.length - 1)
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor.withOpacity(0.5),
                        ),
                    ],
                  );
                },
              ),
            );
          },
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilterDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          valueListenable: _activityFilterNotifier,
          customButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedFilterVertical,
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
          ),
          items: const [
            DropdownItem(value: 'Today', child: Text('Today')),
            DropdownItem(value: 'This Week', child: Text('This Week')),
            DropdownItem(value: 'This Month', child: Text('This Month')),
            DropdownItem(value: 'Custom Date Range', child: Text('Custom Date Range')),
          ],
          onChanged: (value) async {
            if (value == 'Custom Date Range') {
              final result = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                currentDate: DateTime.now(),
              );
              if (result != null) {
                setState(() {
                  _customDateRange = result;
                });
                _activityFilterNotifier.value = 'Custom Date Range';
                _fetchRecentActivity();
              }
            } else if (value != null) {
              _activityFilterNotifier.value = value;
              _fetchRecentActivity();
            }
          },
          dropdownStyleData: DropdownStyleData(
            width: 180,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).cardColor,
            ),
            offset: const Offset(0, -4),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
        return Colors.purple;
      case 'registered':
        return Colors.teal;
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'assigned':
        return Icons.person_add_rounded;
      case 'in_progress':
        return Icons.play_circle_rounded;
      case 'pending':
        return Icons.new_releases_rounded;
      case 'registered':
        return Icons.person_add_alt_1_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getActivityTitle(String status, String patientName) {
    switch (status) {
      case 'completed':
        return 'Session Completed for $patientName';
      case 'assigned':
        return 'Therapist Assigned to $patientName';
      case 'in_progress':
        return 'Session Started for $patientName';
      case 'pending':
        return 'New Session Requested by $patientName';
      case 'registered':
        return 'New User Registered: $patientName';
      default:
        return 'Activity updated for $patientName';
    }
  }

  Widget _renderIcon(dynamic icon, Color color, double size) {
    if (icon is IconData && icon.fontFamily == 'MaterialIcons') {
      return Icon(icon, color: color, size: size);
    }
    return HugeIcon(icon: icon, color: color, size: size);
  }

  String _getRelativeTime(String? createdAtStr) {
    if (createdAtStr == null) return 'justnow';
    try {
      final createdAt = DateTime.parse(createdAtStr).toLocal();
      final diff = DateTime.now().difference(createdAt);

      if (diff.inSeconds < 60) return 'justnow';
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      }
      if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      }
      if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      }
      return DateFormat('MMM d').format(createdAt);
    } catch (e) {
      return 'justnow';
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _themeSubscription?.cancel();
    
    _activityController.close();
    _isDarkModeNotifier.dispose();
    super.dispose();
  }

  ThemeData _getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF020617),
      cardColor: const Color(0xFF0F172A),
      dividerColor: Colors.white.withOpacity(0.1),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF020617),
        elevation: 0,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        brightness: Brightness.dark,
        surface: const Color(0xFF0F172A),
        onSurface: Colors.white,
      ),
    );
  }

  ThemeData _getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE2E8F0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8FAFC),
        elevation: 0,
      ),
      textTheme: GoogleFonts.outfitTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        brightness: Brightness.light,
        surface: Colors.white,
        onSurface: const Color(0xFF0F172A),
      ),
    );
  }

  void _navigateTo(Widget page) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context); // Close drawer
    }
    
    // We use a PageRouteBuilder to avoid the default MaterialPageRoute transition
    // which inherits the root MaterialApp's light theme canvas color, causing a white flash.
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ValueListenableBuilder<bool>(
            valueListenable: _isDarkModeNotifier,
            builder: (context, isDark, child) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
                child: Theme(
                  data: isDark ? _getDarkTheme() : _getLightTheme(),
                  child: page,
                ),
              );
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Standard slide transition
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _loadData();
        });
      }
    });
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Sign Out?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your super admin portal?',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'LOGOUT',
              style: GoogleFonts.outfit(
                color: const Color(0xFFBE123C),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.clearToken();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SelectionPage()),
          (route) => false,
        );
      }
    }
  }
}
