import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../selection_page.dart';
import '../notifications/notification_service.dart';
import '../shared/chat_page.dart';
import '../shared/specialization_colors.dart';
import 'steps_tracker_page.dart';
import 'heart_rate_page.dart';
import 'exercise_tracker_page.dart';
import 'reminders_page.dart';
import 'patientanalytics.dart';
import 'package:hugeicons/hugeicons.dart' as hi;
import 'package:dropdown_button2/dropdown_button2.dart';
import '../widgets/connectivity_banner.dart';
import 'patient_profile_page.dart';
import 'blood_pressure_page.dart';
import 'sleep_monitoring_page.dart';
import 'oxygen_level_page.dart';
import '../services/profile_image_service.dart';
import 'ai_assistant_view.dart';
import 'patient_intake_form.dart';
import 'morningform.dart';
import 'caregiver_dashboard.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final _supabase = Supabase.instance.client;
  final bool _isExpanded = false;
  final Set<String> _notifiedSessions = {};
  int _selectedIndex = 0;
  String _filterType = 'Most Recent';

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING,';
    if (hour < 17) return 'GOOD AFTERNOON,';
    if (hour < 21) return 'GOOD EVENING,';
    return 'GOOD NIGHT,';
  }

  DateTimeRange? _customDateRange;

  // Removed Bluetooth State variables

  // Real Vitals Data
  int _todaySteps = 0;
  int _stepGoal = 10000;
  int _lastBpm = 72;
  int _pendingReminders = 3;
  late Stream<List<Map<String, dynamic>>> _sessionsStream;
  List<String> _selectedCards = [
    'Steps',
    'Heart Rate',
    'Exercise Tracker',
    'Reminders',
  ];

  @override
  void initState() {
    super.initState();
    _checkIntakeForm();
    _loadVitals();
    _initSessionsStream();
    ProfileImageService().loadProfileImage();
  }

  Future<void> _checkIntakeForm() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final response = await _supabase
          .from('patient_intake_forms')
          .select('id')
          .eq('patient_id', user.id)
          .maybeSingle();

      if (response == null && mounted) {
        // No intake form found, redirect to Intake Form Screen
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientIntakeFormScreen()),
        );
      }
    } catch (e) {
      // Ignored: possibly table doesn't exist yet, or network error
      debugPrint('Error checking intake form: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }



  void _initSessionsStream() {
    final user = _supabase.auth.currentUser;
    final patientId = user?.id ?? '';
    _sessionsStream = _supabase
        .from('sessions')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('created_at');
  }

  Future<void> _loadVitals() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastSavedDate = prefs.getString('last_step_date');

    setState(() {
      _stepGoal = prefs.getInt('step_goal') ?? 10000;
      _lastBpm = prefs.getInt('last_known_bpm') ?? 72;
      _pendingReminders = prefs.getInt('pending_reminders') ?? 3;

      if (lastSavedDate == today) {
        _todaySteps = prefs.getInt('last_known_steps') ?? 0;
      } else {
        _todaySteps = 0;
      }

      _selectedCards =
          prefs.getStringList('dashboard_cards') ??
          ['Steps', 'Heart Rate', 'Exercise Tracker', 'Reminders'];
    });
  }

  // ... (rest of the state methods)

  // Elite Palette
  static const Color primaryBlue = Color(0xFF3E84DC);
  static const Color forestGreen = Color(0xFF2D6A4F);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color softSlate = Color(0xFF64748B);

  bool _morningFormTriggered = false;

  Future<void> _checkMorningFormTrigger(List<dynamic> allSessions) async {
    if (_morningFormTriggered) return;
    
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final now = DateTime.now();
    bool shouldShowForm = false;
    String? formSessionId;

    for (var s in allSessions) {
      final sessionId = s['id'].toString();
      final currentCompletedCount = s['completed_count'] ?? 0;
      
      final storedCount = prefs.getInt('session_count_$sessionId') ?? 0;

      // If count increased, record the date it happened
      if (currentCompletedCount > storedCount) {
        prefs.setInt('session_count_$sessionId', currentCompletedCount);
        prefs.setString('session_last_increment_date_$sessionId', todayStr);
      }

      // For testing and reliability: If they have any completed visits,
      // and they haven't filled a morning form today, show it.
      if (currentCompletedCount > 0) {
        final lastMorningFormDateStr = prefs.getString('last_morning_form_date');
        
        // Show if not filled today
        if (lastMorningFormDateStr != todayStr) {
          shouldShowForm = true;
          formSessionId = sessionId;
          break; // Show for at least one session
        }
      }
    }

    if (shouldShowForm && formSessionId != null && mounted) {
      _morningFormTriggered = true;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MorningFormScreen(sessionId: formSessionId!),
        ),
      );
      
      if (result == true) {
        prefs.setString('last_morning_form_date', todayStr);
        // Clear the trigger so it doesn't fire again for this specific increment
        prefs.remove('session_last_increment_date_$formSessionId');
      }
      _morningFormTriggered = false;
    }
  }

  void _showCompletionNotification(String therapistName, String sessionId) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: forestGreen,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: forestGreen.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TREATMENT COMPLETED',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Session with $therapistName is complete.',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  _showFeedbackDialog(sessionId);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'GIVE FEEDBACK',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final patientId = user?.id ?? '';
    final email = user?.email ?? 'User';

    return ConnectivityBanner(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          bottomNavigationBar: _buildBottomNav(),
          body: Column(
            children: [
              _buildHeader(context, email),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _sessionsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return _buildLoadingState();
                    }

                    final allSessions = snapshot.data ?? [];

                    // Notification Logic
                    for (var s in allSessions) {
                      if (s['status'] == 'completed' &&
                          !_notifiedSessions.contains(s['id'])) {
                        _notifiedSessions.add(s['id']);
                        final completedAt = s['completed_at'] != null
                            ? DateTime.parse(s['completed_at'])
                            : null;
                        if (completedAt != null &&
                            DateTime.now()
                                    .difference(completedAt.toLocal())
                                    .inMinutes <
                                5) {
                          Future.microtask(() async {
                            final tSnap = await _supabase
                                .from('profiles')
                                .select('full_name')
                                .eq('id', s['therapist_id'])
                                .single();
                            final tName = tSnap['full_name'];

                            NotificationService.showNotification(
                              id: s['id'].hashCode,
                              title: 'Treatment Completed',
                              body: 'Your session with $tName is now complete.',
                            );
                            _showCompletionNotification(
                              tName,
                              s['id'].toString(),
                            );
                          });
                        }
                      }
                    }

                    // Morning Form Logic
                    Future.microtask(() => _checkMorningFormTrigger(allSessions));

                    final assigned = allSessions
                        .where(
                          (s) =>
                              s['status'] == 'assigned' ||
                              s['status'] == 'in_progress',
                        )
                        .toList();
                    final completed = allSessions
                        .where((s) => s['status'] == 'completed')
                        .toList();

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      layoutBuilder:
                          (
                            Widget? currentChild,
                            List<Widget> previousChildren,
                          ) {
                            return Stack(
                              alignment: Alignment.topCenter,
                              children: [...previousChildren, ?currentChild],
                            );
                          },
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.05),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                      child: _selectedIndex == 0
                          ? _buildHomeView(allSessions, patientId)
                          : _selectedIndex == 1
                          ? const PatientAnalyticsPage()
                          : _selectedIndex == 2
                          ? _buildAIAssistantView()
                          : _selectedIndex == 3
                          ? _buildUpcomingView(assigned)
                          : _buildHistoryView(_applyFilters(completed)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: forestGreen,
        unselectedItemColor: softSlate,
        selectedLabelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: hi.HugeIcon(
              icon: hi.HugeIcons.strokeRoundedHome07,
              color: softSlate,
              size: 24,
            ),
            activeIcon: hi.HugeIcon(
              icon: hi.HugeIcons.strokeRoundedHome07,
              color: forestGreen,
              size: 24,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: hi.HugeIcon(
              icon: hi.HugeIcons.strokeRoundedAnalytics01,
              color: softSlate,
              size: 24,
            ),
            activeIcon: hi.HugeIcon(
              icon: hi.HugeIcons.strokeRoundedAnalytics01,
              color: forestGreen,
              size: 24,
            ),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: hi.HugeIcon(
              icon: hi.HugeIcons.strokeRoundedAiVoiceGenerator,
              color: softSlate,
              size: 24,
            ),
            activeIcon: hi.HugeIcon(
              icon: hi.HugeIcons.strokeRoundedAiVoiceGenerator,
              color: forestGreen,
              size: 24,
            ),
            label: 'AI Assistant',
          ),
          BottomNavigationBarItem(
            icon: hi.HugeIcon(
              icon: hi.HugeIcons.strokeRoundedCalendar02,
              color: softSlate,
              size: 24,
            ),
            activeIcon: hi.HugeIcon(
              icon: hi.HugeIcons.strokeRoundedCalendar02,
              color: forestGreen,
              size: 24,
            ),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: hi.HugeIcon(
              icon: hi.HugeIcons.strokeRoundedClock01,
              color: softSlate,
              size: 24,
            ),
            activeIcon: hi.HugeIcon(
              icon: hi.HugeIcons.strokeRoundedClock01,
              color: forestGreen,
              size: 24,
            ),
            label: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildAIAssistantView() {
    return const AIAssistantView(showAppBar: false);
  }

  Widget _buildHomeView(List<Map<String, dynamic>> allSessions, String patientId) {
    int completedCount = 0;
    int totalSessions = 0;

    for (var s in allSessions) {
      completedCount += (s['completed_count'] ?? 0) as int;
      totalSessions += (s['session_count'] ?? 0) as int;
    }

    final upcomingSession = allSessions.firstWhere(
      (s) => s['status'] == 'assigned' || s['status'] == 'in_progress',
      orElse: () => {},
    );

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        await _loadVitals();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dashboard refreshed successfully!'),
              backgroundColor: forestGreen,
            ),
          );
        }
      },
      color: forestGreen,
      child: SingleChildScrollView(
        key: const PageStorageKey('home'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Vitals Grid Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSectionTitle('VITALS OVERVIEW'),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const hi.HugeIcon(
                    icon:
                        hi.HugeIcons.strokeRoundedAlignVerticalDistributeCenter,
                    color: Color.fromARGB(255, 137, 141, 147),
                    size: 24,
                  ),
                  onPressed: _showCustomizeDashboardModal,
                  tooltip: 'Customize Dashboard',
                ),
              ],
            ),
            const SizedBox(height: 0.5),
            // Vitals Grid
            GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio:
                  1.25, // Adjusted from 1.4 to fix bottom overflow error
              children: _selectedCards
                  .map((cardName) => _buildSelectedCard(cardName))
                  .toList(),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('TREATMENT PROGRESS'),
            const SizedBox(height: 8),
            // Progress Card
            GestureDetector(
              onTap: () => _showSessionBreakdown(allSessions),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: forestGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_graph_rounded,
                            color: forestGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Treatment Consistency',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: darkSlate,
                                ),
                              ),
                              Text(
                                'You\'ve completed $completedCount of $totalSessions sessions (${totalSessions - completedCount} remaining)',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: softSlate,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: softSlate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: totalSessions > 0
                            ? completedCount / totalSessions
                            : 0,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: forestGreen,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildCaregiverDashboardCard(),
            const SizedBox(height: 32),

            _buildSectionTitle('ACHIEVEMENTS & BADGES'),
            const SizedBox(height: 12),
            _buildAchievementsSection(patientId),
            const SizedBox(height: 32),

            // Book Appointment Card
            _buildBookingCallToAction(),
            const SizedBox(height: 24),
            if (upcomingSession.isNotEmpty) ...[
              _buildSectionTitle('NEXT SESSION'),
              const SizedBox(height: 12),
              _PatientSessionCard(session: upcomingSession),
            ] else
              _buildEmptyState(
                icon: Icons.notifications_none_rounded,
                message: 'No pending activities for today.',
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCard(String cardName) {
    switch (cardName) {
      case 'Steps':
        return _buildVitalCard(
          label: 'Steps',
          value: _todaySteps.toString(),
          subLabel: 'Goal: ${_stepGoal ~/ 1000}k',
          imagePath: 'assets/steps_calculation.png',
          color: const Color(0xFFF97316),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StepsTrackerPage()),
          ).then((_) => _loadVitals()),
        );
      case 'Heart Rate':
        return _buildVitalCard(
          label: 'Heart Rate',
          value: '$_lastBpm bpm',
          subLabel: 'Normal',
          imagePath: 'assets/heart_measure.png',
          color: const Color(0xFFEF4444),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HeartRatePage()),
          ).then((_) => _loadVitals()),
        );
      case 'Exercise Tracker':
        return _buildVitalCard(
          label: 'Exercise Tracker',
          value: '80%',
          subLabel: 'Weekly Goal',
          imagePath: 'assets/exercise.png',
          color: const Color(0xFF2D6A4F),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExerciseTrackerPage(),
            ),
          ).then((_) => _loadVitals()),
        );
      case 'Reminders':
        return _buildVitalCard(
          label: 'Reminders',
          value: '$_pendingReminders Pending',
          subLabel: 'Water & Meds',
          imagePath: 'assets/remainder.png',
          color: const Color(0xFF0D9488),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RemindersPage()),
          ).then((_) => _loadVitals()),
        );
      case 'Blood Pressure':
        return _buildVitalCard(
          label: 'Blood Pressure',
          value: '120/80',
          subLabel: 'mmHg',
          iconData: Icons.favorite_outline_rounded,
          color: const Color(0xFFE11D48),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BloodPressurePage()),
          ),
        );
      case 'Sleep Monitoring':
        return _buildVitalCard(
          label: 'Sleep Monitoring',
          value: '7h 30m',
          subLabel: 'Good Quality',
          iconData: Icons.nights_stay_outlined,
          color: const Color(0xFF6366F1),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SleepMonitoringPage(),
            ),
          ),
        );
      case 'Oxygen Level':
        return _buildVitalCard(
          label: 'Oxygen Level',
          value: '98%',
          subLabel: 'Healthy SpO2',
          iconData: Icons.water_drop_outlined,
          color: const Color(0xFF0EA5E9),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OxygenLevelPage()),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showCustomizeDashboardModal() {
    final availableCards = [
      'Steps',
      'Heart Rate',
      'Exercise Tracker',
      'Reminders',
      'Blood Pressure',
      'Sleep Monitoring',
      'Oxygen Level',
    ];
    List<String> tempSelected = List.from(_selectedCards);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customize Dashboard',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: darkSlate,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: softSlate),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select exactly 4 metrics to display on your dashboard.',
                    style: GoogleFonts.outfit(color: softSlate, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: availableCards.map((card) {
                      final isSelected = tempSelected.contains(card);
                      return ChoiceChip(
                        label: Text(card),
                        selected: isSelected,
                        selectedColor: primaryBlue.withOpacity(0.1),
                        labelStyle: GoogleFonts.outfit(
                          color: isSelected ? primaryBlue : softSlate,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              if (tempSelected.length < 4) {
                                tempSelected.add(card);
                              }
                            } else {
                              tempSelected.remove(card);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: tempSelected.length == 4
                          ? () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setStringList(
                                'dashboard_cards',
                                tempSelected,
                              );
                              setState(() => _selectedCards = tempSelected);
                              if (mounted) Navigator.pop(context);
                            }
                          : null,
                      child: Text(
                        'SAVE PREFERENCES',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVitalCard({
    required String label,
    required String value,
    required String subLabel,
    String? imagePath,
    IconData? iconData,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (imagePath != null)
                  Image.asset(imagePath, width: 22, height: 22)
                else if (iconData != null)
                  Icon(iconData, color: color, size: 22)
                else
                  const SizedBox(width: 22, height: 22),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: softSlate.withOpacity(0.5),
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: darkSlate,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          color: softSlate,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '\u2022 $subLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w400,
                          fontSize: 10,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingView(List<Map<String, dynamic>> assigned) {
    if (assigned.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today_rounded,
        message: 'No Upcoming Sessions Scheduled Yet!',
      );
    }

    final sortedAssigned = List<Map<String, dynamic>>.from(assigned)
      ..sort((a, b) {
        final aLive = a['status'] == 'in_progress';
        final bLive = b['status'] == 'in_progress';
        if (aLive && !bLive) return -1;
        if (!aLive && bLive) return 1;
        return 0;
      });

    return SingleChildScrollView(
      key: const PageStorageKey('upcoming'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Column(
            children: sortedAssigned
                .map((s) => _PatientSessionCard(session: s))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView(List<Map<String, dynamic>> filteredCompleted) {
    return SingleChildScrollView(
      key: const PageStorageKey('history'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('TREATMENT HISTORY'),
                  GestureDetector(
                    onTap: _showFilterOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.filter_list_rounded,
                            size: 14,
                            color: Color(0xFF2D9CDB),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _filterType.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2D9CDB),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filteredCompleted.isEmpty)
                _buildEmptyState(
                  icon: Icons.history_rounded,
                  message: _filterType == 'Custom'
                      ? 'No sessions in selected range'
                      : 'No past treatment history',
                )
              else
                ...filteredCompleted.map((s) => _buildHistoryCard(s)),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> sessions,
  ) {
    List<Map<String, dynamic>> filtered = List.from(sessions);

    if (_filterType == 'This Month') {
      final now = DateTime.now();
      filtered = filtered.where((s) {
        final dateStr = s['completed_at'] ?? s['created_at'];
        if (dateStr == null) return false;
        final date = DateTime.parse(dateStr.toString()).toLocal();
        return date.month == now.month && date.year == now.year;
      }).toList();
    } else if (_filterType == 'Custom' && _customDateRange != null) {
      filtered = filtered.where((s) {
        final dateStr = s['completed_at'] ?? s['created_at'];
        if (dateStr == null) return false;
        final date = DateTime.parse(dateStr.toString()).toLocal();
        return date.isAfter(
              _customDateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            date.isBefore(_customDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Sorting
    if (_filterType == 'Old to New') {
      filtered.sort((a, b) {
        final da = DateTime.parse(
          (a['completed_at'] ?? a['created_at'] ?? '').toString(),
        );
        final db = DateTime.parse(
          (b['completed_at'] ?? b['created_at'] ?? '').toString(),
        );
        return da.compareTo(db);
      });
    } else {
      // Most Recent (Default)
      filtered.sort((a, b) {
        final da = DateTime.parse(
          (a['completed_at'] ?? a['created_at'] ?? '').toString(),
        );
        final db = DateTime.parse(
          (b['completed_at'] ?? b['created_at'] ?? '').toString(),
        );
        return db.compareTo(da);
      });
    }

    return filtered;
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FILTER HISTORY',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: softSlate,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),
            _buildFilterTile('Most Recent', Icons.access_time_rounded),
            _buildFilterTile('This Month', Icons.calendar_today_rounded),
            _buildFilterTile('Old to New', Icons.sort_rounded),
            _buildFilterTile('Custom', Icons.date_range_rounded),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTile(String title, IconData icon) {
    final isSelected = _filterType == title;
    return GestureDetector(
      onTap: () async {
        if (title == 'Custom') {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: forestGreen,
                    onPrimary: Colors.white,
                    onSurface: darkSlate,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (range != null) {
            setState(() {
              _filterType = title;
              _customDateRange = range;
            });
            if (mounted) Navigator.pop(context);
          }
        } else {
          setState(() {
            _filterType = title;
            _customDateRange = null;
          });
          Navigator.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2D9CDB).withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2D9CDB).withOpacity(0.2)
                : const Color(0xFFF1F5F9),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF2D9CDB) : softSlate,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFF2D9CDB) : darkSlate,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              hi.HugeIcon(
                icon: hi.HugeIcons.strokeRoundedTaskDone02,
                size: 20,
                color: const Color(0xFF2D9CDB),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> s) {
    final dateStr =
        s['completed_at'] ??
        s['created_at'] ??
        DateTime.now().toIso8601String();
    final date = DateTime.parse(dateStr.toString()).toLocal();
    final spec = s['specialization_required'].toString().toUpperCase();
    final amount = s['fee_charged'] ?? 0;

    // Check if patient feedback is already provided
    final String? response = s['patient_feedback']?.toString();
    final bool hasFeedback =
        response != null &&
        response.trim() != 'null' &&
        response.trim() != 'None' &&
        response.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF8FAFC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _typeBadge(spec),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: forestGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'COMPLETED',
                      style: GoogleFonts.outfit(
                        color: forestGreen,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: hi.HugeIcon(
                          icon: hi.HugeIcons.strokeRoundedTaskDone02,
                          color: forestGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd MMMM yyyy').format(date),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: darkSlate,
                              ),
                            ),
                            Text(
                              'at ${DateFormat('hh:mm a').format(date)}',
                              style: GoogleFonts.outfit(
                                color: softSlate,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FutureBuilder(
                              future: _supabase
                                  .from('profiles')
                                  .select('full_name')
                                  .eq('id', s['therapist_id'] ?? '')
                                  .single(),
                              builder: (context, snapshot) {
                                final name = snapshot.hasData
                                    ? snapshot.data!['full_name']
                                    : '...';
                                return Text(
                                  'Therapy by $name',
                                  style: GoogleFonts.outfit(
                                    color: primaryBlue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      if (amount > 0)Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹$amount',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: forestGreen,
                            ),
                          ),
                          Text(
                            'PAID',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFCBD5E1),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!hasFeedback) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showFeedbackDialog(s['id'].toString()),
                        icon: const hi.HugeIcon(
                          icon: hi.HugeIcons.strokeRoundedLicenseDraft,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'GIVE SESSION FEEDBACK',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            65,
                            135,
                            221,
                          ),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: forestGreen.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: forestGreen.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              hi.HugeIcon(
                                icon: hi.HugeIcons.strokeRoundedChatFeedback01,
                                color: forestGreen,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'FEEDBACK SUBMITTED',
                                style: GoogleFonts.outfit(
                                  color: forestGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Your Feedback Has Been Submitted. Thank You For Your Response...',
                            style: GoogleFonts.outfit(
                              color: darkSlate.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFeedbackDialog(String sessionId) async {
    double recoveryLevel = 5.0;
    double painLevel = 3.0;
    String intensity = 'Medium';
    String stress = 'Feels Good';
    final feedbackController = TextEditingController();

    bool isSubmitting = false;

    final result = await showModalBottomSheet<bool>(
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
              Text(
                'SESSION FEEDBACK',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: darkSlate,
                ),
              ),
              Text(
                'How are you feeling after your therapy?',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: softSlate,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Recovery Level
                      _feedbackLabel(
                        'RECOVERY LEVEL (1-10)',
                        recoveryLevel.round().toString(),
                      ),
                      Slider(
                        value: recoveryLevel,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: primaryBlue,
                        inactiveColor: const Color(0xFFF1F5F9),
                        onChanged: isSubmitting
                            ? null
                            : (val) => setModalState(() => recoveryLevel = val),
                      ),
                      const SizedBox(height: 12),

                      // 2. Exercise Intensity
                      _feedbackLabel('EXERCISE INTENSITY', intensity),
                      Row(
                        children: ['Low', 'Medium', 'High'].map((lvl) {
                          bool isSel = intensity == lvl;
                          return Expanded(
                            child: GestureDetector(
                              onTap: isSubmitting
                                  ? null
                                  : () => setModalState(() => intensity = lvl),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? primaryBlue
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSel
                                        ? primaryBlue
                                        : const Color(0xFFF1F5F9),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    lvl.toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      color: isSel ? Colors.white : softSlate,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // 3. Stress Level
                      _feedbackLabel('STRESS LEVEL', stress),
                      Row(
                        children: ['Not feels well', 'Low', 'Feels Good'].map((
                          lvl,
                        ) {
                          bool isSel = stress == lvl;
                          return Expanded(
                            child: GestureDetector(
                              onTap: isSubmitting
                                  ? null
                                  : () => setModalState(() => stress = lvl),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? primaryBlue
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSel
                                        ? primaryBlue
                                        : const Color(0xFFF1F5F9),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    lvl.toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      color: isSel ? Colors.white : softSlate,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // 4. Pain Level
                      _feedbackLabel(
                        'PAIN & SORENESS (1-10)',
                        painLevel.round().toString(),
                      ),
                      Slider(
                        value: painLevel,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: const Color(0xFFEF4444),
                        inactiveColor: const Color(0xFFF1F5F9),
                        onChanged: isSubmitting
                            ? null
                            : (val) => setModalState(() => painLevel = val),
                      ),
                      const SizedBox(height: 12),

                      // 5. Feedback Text
                      _feedbackLabel('ADDITIONAL FEEDBACK', ''),
                      TextField(
                        controller: feedbackController,
                        enabled: !isSubmitting,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Any specific observations or feelings?',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          final formattedFeedback =
                              """
Recovery Level: ${recoveryLevel.round()}/10
Intensity: $intensity
Stress Level: $stress
Pain Level: ${painLevel.round()}/10
Feedback: ${feedbackController.text}
""";

                          try {
                            await _supabase
                                .from('sessions')
                                .update({'patient_feedback': formattedFeedback})
                                .eq('id', sessionId);
                            if (context.mounted) {
                              Navigator.pop(context, true);
                              // Force a rebuild of the parent to show updated status immediately
                              setState(() {});
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            // Error handling could go here
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkSlate,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'SUBMIT FEEDBACK',
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

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback shared with your therapist!'),
            backgroundColor: forestGreen,
          ),
        );
      }
    }
  }

  Widget _feedbackLabel(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: softSlate,
              letterSpacing: 1,
            ),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: primaryBlue,
              ),
            ),
        ],
      ),
    );
  }

  // Logout logic has been moved to patient_profile_page.dart

  void _showSessionBreakdown(List<Map<String, dynamic>> allSessions) {
    String selectedStatusFilter = 'ALL';
    DateTimeRange? selectedFilterRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Filtering logic
          final filtered = allSessions.where((s) {
            final status = s['status'].toString().toUpperCase();
            final dateStr = s['created_at'];
            DateTime? date;
            if (dateStr != null) date = DateTime.parse(dateStr);

            // 1. Status Filter
            if (selectedStatusFilter != 'ALL' &&
                status != selectedStatusFilter) {
              return false;
            }

            // 2. Date Filter
            if (selectedFilterRange != null && date != null) {
              if (date.isBefore(selectedFilterRange!.start) ||
                  date.isAfter(
                    selectedFilterRange!.end.add(const Duration(days: 1)),
                  )) {
                return false;
              }
            }

            return true;
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SESSION BREAKDOWN',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: darkSlate,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Detailed view of your therapy progress',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: softSlate,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: forestGreen,
                                onPrimary: Colors.white,
                                onSurface: darkSlate,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (range != null) {
                          setModalState(() => selectedFilterRange = range);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selectedFilterRange != null
                              ? forestGreen.withOpacity(0.1)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              size: 14,
                              color: selectedFilterRange != null
                                  ? forestGreen
                                  : softSlate,
                            ),
                            if (selectedFilterRange != null) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setModalState(
                                    () => selectedFilterRange = null,
                                  );
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: forestGreen,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children:
                        [
                          'ALL',
                          'COMPLETED',
                          'ASSIGNED',
                          'IN_PROGRESS',
                          'REQUESTED',
                        ].map((status) {
                          final isSelected = selectedStatusFilter == status;
                          return GestureDetector(
                            onTap: () => setModalState(
                              () => selectedStatusFilter = status,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? darkSlate : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? darkSlate
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                status.replaceAll('_', ' '),
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : softSlate,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),

                const SizedBox(height: 24),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: softSlate.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No matching therapy records.',
                                style: GoogleFonts.outfit(
                                  color: softSlate,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (selectedStatusFilter != 'ALL' ||
                                  selectedFilterRange != null)
                                TextButton(
                                  onPressed: () {
                                    setModalState(() {
                                      selectedStatusFilter = 'ALL';
                                      selectedFilterRange = null;
                                    });
                                  },
                                  child: Text(
                                    'Clear Filters',
                                    style: GoogleFonts.outfit(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final s = filtered[index];
                            final type = s['specialization_required']
                                .toString()
                                .toUpperCase();
                            final completed = s['completed_count'] ?? 0;
                            final total = s['session_count'] ?? 0;
                            final remaining = total - completed;
                            final status = s['status'].toString().toUpperCase();
                            final date = s['created_at'] != null
                                ? DateFormat(
                                    'MMM d, yyyy',
                                  ).format(DateTime.parse(s['created_at']))
                                : 'N/A';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFF1F5F9),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _typeBadge(type),
                                      Text(
                                        status.replaceAll('_', ' '),
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: status == 'COMPLETED'
                                              ? forestGreen
                                              : status == 'REQUESTED'
                                              ? const Color(0xFFF59E0B)
                                              : primaryBlue,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 14,
                                        color: softSlate,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Started: $date',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: softSlate,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Sessions Progress',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: darkSlate,
                                        ),
                                      ),
                                      Text(
                                        '$completed / $total ($remaining remaining)',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: forestGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: total > 0 ? completed / total : 0,
                                      backgroundColor: Colors.white,
                                      color: forestGreen,
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String email) {
    final name = email.split('@')[0].toUpperCase();
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(24, topPadding + 12, 24, 8),
      decoration: BoxDecoration(
        color: forestGreen,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: forestGreen.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: [

              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientProfilePage(email: email),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ValueListenableBuilder<String?>(
                    valueListenable: ProfileImageService().profileImagePathNotifier,
                    builder: (context, imagePath, child) {
                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: imagePath != null ? Colors.transparent : Colors.transparent,
                        backgroundImage: imagePath != null ? FileImage(File(imagePath)) : null,
                        child: imagePath == null
                            ? Text(
                                name.isNotEmpty ? name[0] : '?',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: SpecializationColors.getDecoration(type),
      child: Text(
        type,
        style: GoogleFonts.outfit(
          color: SpecializationColors.getTextColor(type),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF94A3B8),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Vitals Grid Skeleton
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: List.generate(
              4,
              (index) => const _SkeletonPulse(borderRadius: 24),
            ),
          ),
          const SizedBox(height: 24),
          const _SkeletonPulse(height: 12, width: 120, borderRadius: 4),
          const SizedBox(height: 12),
          // Progress Card Skeleton
          const _SkeletonPulse(height: 120, borderRadius: 24),
          const SizedBox(height: 24),
          const _SkeletonPulse(height: 12, width: 100, borderRadius: 4),
          const SizedBox(height: 12),
          // Assignment Card Skeleton
          const _SkeletonPulse(height: 180, borderRadius: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyState({IconData? icon, String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.history_rounded,
              size: 40,
              color: const Color(0xFFCBD5E1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'No session history found',
            style: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
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
          borderRadius: BorderRadius.circular(10),
        ),
        child: hi.HugeIcon(icon: icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildCaregiverDashboardCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.family_restroom_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const hi.HugeIcon(
                icon: hi.HugeIcons.strokeRoundedArrowRight02,
                color: Colors.white,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Caregiver Dashboard',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage and monitor caregiving activities.',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CaregiverDashboard(onBookAppointment: _showBookingModal)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F766E),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'OPEN DASHBOARD',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCallToAction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const hi.HugeIcon(
                  icon: hi.HugeIcons.strokeRoundedCalendar01,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const hi.HugeIcon(
                icon: hi.HugeIcons.strokeRoundedArrowRight02,
                color: Colors.white,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Book Professional Session',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select your preferred date and specialization.',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: _showBookingModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F766E),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'BOOK APPOINTMENT',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingModal() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    String selectedSpec = 'ORTHO';
    String? selectedLocationId;
    String? selectedLocationName;
    bool isSubmitting = false;

    final List<String> specializations = [
      'Ortho',
      'Neuro',
      'Pediatrics',
      'Cardio',
      'Psychology',
      'Speech',
      'Sensory Integration',
    ];

    showModalBottomSheet(
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
          padding: const EdgeInsets.all(24),
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
                'BOOK APPOINTMENT',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Specialization Picker
                      _modalLabel('SELECT CATEGORY'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: specializations.map((spec) {
                          bool isSel = selectedSpec == spec;
                          return GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedSpec = spec),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFF3E84DC)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                spec,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isSel
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Location Picker
                      _modalLabel('PREFERRED LOCATION'),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _supabase
                            .from('clinics')
                            .select()
                            .order('name'),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          final clinicList = snapshot.data ?? [];
                          if (clinicList.isEmpty) {
                            return Text(
                              'No clinics available',
                              style: GoogleFonts.outfit(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            );
                          }
                          
                          // Set default selection if none chosen
                          if (selectedLocationId == null && clinicList.isNotEmpty) {
                            selectedLocationId = clinicList[0]['id'];
                            selectedLocationName = clinicList[0]['name'];
                          }
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
                            ),
                            child: DropdownButtonFormField2<String>(
                              valueListenable: ValueNotifier(selectedLocationId),
                              items: clinicList.map((c) {
                                return DropdownItem<String>(
                                  value: c['id'],
                                  child: Text(
                                    c['name'],
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setModalState(() {
                                  selectedLocationId = val;
                                  selectedLocationName = clinicList.firstWhere((c) => c['id'] == val)['name'];
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Select Clinic Location',
                                hintStyle: GoogleFonts.outfit(
                                  color: const Color(0xFFCBD5E1),
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              buttonStyleData: const FormFieldButtonStyleData(
                                padding: EdgeInsets.only(right: 8),
                              ),
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 250,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.white,
                                ),
                              ),
                              iconStyleData: const IconStyleData(
                                icon: Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Date and Time
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _modalLabel('PREFERRED DATE'),
                                GestureDetector(
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 90),
                                      ),
                                      builder: (context, child) {
                                        return Theme(
                                          data: ThemeData.light().copyWith(
                                            colorScheme:
                                                const ColorScheme.light(
                                                  primary: Color(0xFF0F766E),
                                                  onPrimary: Colors.white,
                                                  surface: Colors.white,
                                                  onSurface: Color(0xFF0F172A),
                                                ),
                                            appBarTheme: const AppBarTheme(
                                              systemOverlayStyle:
                                                  SystemUiOverlayStyle.dark,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (d != null) {
                                      setModalState(() => selectedDate = d);
                                    }
                                  },
                                  child: _pickerTile(
                                    DateFormat(
                                      'MMM d, yyyy',
                                    ).format(selectedDate),
                                    Icons.calendar_today_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _modalLabel('PREFERRED TIME'),
                                GestureDetector(
                                  onTap: () async {
                                    final t = await showTimePicker(
                                      context: context,
                                      initialTime: selectedTime,
                                    );
                                    if (t != null) {
                                      setModalState(() => selectedTime = t);
                                    }
                                  },
                                  child: _pickerTile(
                                    selectedTime.format(context),
                                    Icons.access_time_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          try {
                            final userId = _supabase.auth.currentUser!.id;
                            await _supabase.from('sessions').insert({
                              'patient_id': userId,
                              'clinic_id': selectedLocationId,
                              'specialization_required': selectedSpec,
                              'status': 'requested',
                              'created_at': DateTime.now().toIso8601String(),
                              'scheduled_date': selectedDate.toIso8601String(),
                              'scheduled_time': selectedTime.format(context),
                              'fee_charged': 500, // Default fee
                              'location': selectedLocationName ?? 'TBD',
                            });

                            // Assign patient to this clinic
                            if (selectedLocationId != null) {
                              await _supabase.from('profiles').update({
                                'clinic_id': selectedLocationId,
                              }).eq('id', userId);
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Appointment Requested Successfully!',
                                  ),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'CONFIRM BOOKING',
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
  }

  Widget _modalLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF94A3B8),
        letterSpacing: 1,
      ),
    ),
  );

  Widget _pickerTile(String text, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF1F5F9)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF3E84DC)),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    ),
  );

  Widget _buildAchievementsSection(String patientId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('patient_achievements').stream(primaryKey: ['id']).eq('patient_id', patientId).order('unlocked_at'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final badges = snapshot.data ?? [];
        if (badges.isEmpty) {
          return _buildEmptyState(
            icon: Icons.emoji_events_rounded,
            message: 'Complete sessions to unlock your first badge!',
          );
        }
        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      badge['badge_icon'] ?? '🏆',
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge['badge_name'] ?? 'Badge',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: darkSlate,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SkeletonPulse extends StatefulWidget {
  final double? height;
  final double? width;
  final double borderRadius;

  const _SkeletonPulse({this.height, this.width, required this.borderRadius});

  @override
  State<_SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<_SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 0.5),
            ),
          ),
        );
      },
    );
  }
}

class _PatientSessionCard extends StatefulWidget {
  final Map<String, dynamic> session;
  const _PatientSessionCard({required this.session});

  @override
  State<_PatientSessionCard> createState() => _PatientSessionCardState();
}

class _PatientSessionCardState extends State<_PatientSessionCard> {
  Timer? _timer;
  String _timeLeft = "00:00:00";
  final _supabase = Supabase.instance.client;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.session['status'] == 'in_progress' &&
        widget.session['started_at'] != null) {
      _startCountdown();
    }
  }

  @override
  void didUpdateWidget(_PatientSessionCard oldWidget) {
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
  }

  void _startCountdown() {
    try {
      final startedAt = widget.session['started_at'];
      if (startedAt == null) return;

      final startTime = DateTime.parse(startedAt.toString()).toLocal();
      final allotted = widget.session['allotted_time'] ?? 45;
      final endTime = startTime.add(
        Duration(minutes: int.parse(allotted.toString())),
      );

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
          setState(() => _timeLeft = "00:00:00");
        } else {
          setState(() => _timeLeft = _format(diff));
        }
      });
    } catch (e) {
      debugPrint('Timer logic error: $e');
    }
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, "0");
    return "${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _typeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: type == 'ORTHO'
            ? const Color(0xFFB45309).withOpacity(0.1)
            : type == 'NEURO'
            ? const Color(0xFF2D6A4F).withOpacity(0.1)
            : type == 'CARDIO'
            ? const Color(0xFFBE123C).withOpacity(0.1)
            : const Color(0xFF3E84DC).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        style: GoogleFonts.outfit(
          color: type == 'ORTHO'
              ? const Color(0xFFB45309)
              : type == 'NEURO'
              ? const Color(0xFF2D6A4F)
              : type == 'CARDIO'
              ? const Color(0xFFBE123C)
              : const Color(0xFF3E84DC),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
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
        child: hi.HugeIcon(icon: icon, size: 16, color: color),
      ),
    );
  }

  Widget _scheduleInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final spec = session['specialization_required'].toString().toUpperCase();
    final therapistId = session['therapist_id'];
    const Color orangeAccent = Color(0xFFEA580C);
    final bool isInProgress = session['status'] == 'in_progress';

    return FutureBuilder(
      future: _supabase
          .from('profiles')
          .select('full_name, phone, clinical_status')
          .eq('id', therapistId)
          .single(),
      builder: (context, snapshot) {
        final therapistName = snapshot.hasData
            ? snapshot.data!['full_name']
            : 'Assigning...';
        final userEmail =
            _supabase.auth.currentUser?.email?.split('@')[0].toUpperCase() ??
            'YOU';

        return GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: isInProgress
                        ? const Color(0xFFFFF1F2)
                        : const Color(0xFFFFF7ED),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _typeBadge(spec),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isInProgress
                                ? const Color(0xFFBE123C).withOpacity(0.1)
                                : orangeAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isInProgress ? 'LIVE SESSION' : 'UPCOMING',
                            style: GoogleFonts.outfit(
                              color: isInProgress
                                  ? const Color(0xFFBE123C)
                                  : orangeAccent,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4F7),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF6B7280),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          therapistName,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      if (snapshot.hasData)
                                        Row(
                                          children: [
                                            _buildContactAction(
                                              icon: hi
                                                  .HugeIcons
                                                  .strokeRoundedChat01,
                                              color: const Color(0xFF3E84DC),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ChatPage(
                                                          sessionId:
                                                              session['id']
                                                                  .toString(),
                                                          receiverId:
                                                              therapistId,
                                                          receiverName:
                                                              therapistName,
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _isExpanded
                                                    ? Icons
                                                          .keyboard_arrow_up_rounded
                                                    : Icons
                                                          .keyboard_arrow_down_rounded,
                                                size: 16,
                                                color: const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    snapshot.hasData
                                        ? (snapshot.data!['clinical_status'] ??
                                                  'AVAILABLE')
                                              .toString()
                                              .toUpperCase()
                                        : 'PENDING',
                                    style: GoogleFonts.outfit(
                                      color: snapshot.hasData
                                          ? (snapshot.data!['clinical_status'] ==
                                                    'Offline'
                                                ? const Color(0xFF64748B)
                                                : (snapshot.data!['clinical_status'] ==
                                                          'On Therapy'
                                                      ? const Color(0xFF3E84DC)
                                                      : const Color(
                                                          0xFF10B981,
                                                        )))
                                          : const Color(0xFF94A3B8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isExpanded
                              ? Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFF1F5F9),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${userEmail[0].toUpperCase()}${userEmail.substring(1).toLowerCase()}, your ${spec.toLowerCase()} therapy is scheduled with $therapistName.',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF1E293B),
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 12,
                                            children: [
                                              _scheduleInfo(
                                                Icons.calendar_today_rounded,
                                                session['scheduled_date'] !=
                                                        null
                                                    ? DateFormat(
                                                        'MMM d',
                                                      ).format(
                                                        DateTime.parse(
                                                          session['scheduled_date'],
                                                        ),
                                                      )
                                                    : 'TBD',
                                              ),
                                              _scheduleInfo(
                                                Icons.access_time_rounded,
                                                isInProgress
                                                    ? _timeLeft
                                                    : (session['scheduled_time']
                                                              ?.toString() ??
                                                          'TBD'),
                                              ),
                                              _scheduleInfo(
                                                Icons.repeat_rounded,
                                                'VISIT ${(session['completed_count'] ?? 0) + 1}/${session['session_count'] ?? 0}',
                                              ),
                                              if (session['location'] != null)
                                                _scheduleInfo(
                                                  Icons.location_on_rounded,
                                                  session['location']
                                                      .toString(),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
