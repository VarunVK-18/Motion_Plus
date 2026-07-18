import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PatientAnalyticsPage extends StatefulWidget {
  final String? patientId;
  const PatientAnalyticsPage({super.key, this.patientId});

  @override
  State<PatientAnalyticsPage> createState() => _PatientAnalyticsPageState();
}

class _PatientAnalyticsPageState extends State<PatientAnalyticsPage> {
  String _selectedTab = 'Week'; // 'Day', 'Week', 'Month'
  Map<String, dynamic>? _currentUser;

  // Real Vitals Data
  int _todaySteps = 0;
  int _stepGoal = 10000;
  int _lastBpm = 72;
  int _pendingReminders = 3;
  DateTimeRange? _selectedDateRange;
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadVitals();
    _dataFuture = _loadDataWithBuffer();
  }

  Future<List<dynamic>> _loadDataWithBuffer() async {
    // 300ms buffer to allow the page transition animation to finish smoothly
    await Future.delayed(const Duration(milliseconds: 300));
    
    dynamic user = _currentUser;
    if (user == null) {
      user = await ApiService.get('/profiles/me', includeAuth: true);
      if (mounted) setState(() => _currentUser = user as Map<String, dynamic>);
    }
    
    final targetId = widget.patientId ?? user?['id'];
    if (targetId == null) return [[], []];

    final sessions = await ApiService.get('/sessions?patient_id=$targetId', includeAuth: true);
    final checkins = await ApiService.get('/morning_checkins?patient_id=$targetId', includeAuth: true);

    return [sessions, checkins];
  }

  Future<void> _loadVitals() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastSavedDate = prefs.getString('last_step_date');

    if (mounted) {
      setState(() {
        _stepGoal = prefs.getInt('step_goal') ?? 10000;
        _lastBpm = prefs.getInt('last_known_bpm') ?? 72;
        _pendingReminders = prefs.getInt('pending_reminders') ?? 3;

        if (lastSavedDate == today) {
          _todaySteps = prefs.getInt('last_known_steps') ?? 0;
        } else {
          _todaySteps = 0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(child: Text('User not found or error loading data')),
          );
        }

        final sessionData = snapshot.data![0];
        final checkinData = snapshot.data![1];

        final allSessions = (sessionData as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ?? <Map<String, dynamic>>[];
            
        final allCheckins = (checkinData as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ?? <Map<String, dynamic>>[];

            // Apply Date Range Filter for sessions
            final sessions = _selectedDateRange == null
                ? allSessions
                : allSessions.where((s) {
                    try {
                      final dateStr = s['scheduled_date'] ?? s['created_at'];
                      if (dateStr == null) return false;
                      final date = DateTime.parse(dateStr).toLocal();
                      return date.isAfter(
                            _selectedDateRange!.start.subtract(
                              const Duration(seconds: 1),
                            ),
                          ) &&
                          date.isBefore(
                            _selectedDateRange!.end.add(const Duration(days: 1)),
                          );
                    } catch (e) {
                      return false;
                    }
                  }).toList();

            // Apply Date Range Filter for checkins
            final checkins = _selectedDateRange == null
                ? allCheckins
                : allCheckins.where((c) {
                    try {
                      final dateStr = c['created_at'];
                      if (dateStr == null) return false;
                      final date = DateTime.parse(dateStr).toLocal();
                      return date.isAfter(
                            _selectedDateRange!.start.subtract(
                              const Duration(seconds: 1),
                            ),
                          ) &&
                          date.isBefore(
                            _selectedDateRange!.end.add(const Duration(days: 1)),
                          );
                    } catch (e) {
                      return false;
                    }
                  }).toList();

            final completed = sessions
                .where((s) => s['status'] == 'completed')
                .toList();
            final totalCount = sessions.length;
            final completedCount = completed.length;
            final recoveryPercentage = totalCount > 0
                ? (completedCount / totalCount) * 100
                : 0.0;

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _dataFuture = _loadDataWithBuffer();
                  });
                  await _dataFuture;
                },
                child: SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildTabSelector(),
                        const SizedBox(height: 24),
                        _buildActivityLineChart(sessions),
                        const SizedBox(height: 24),
                        _buildMorningCheckAnalytics(checkins),
                        const SizedBox(height: 24),
                        _buildOverviewCard(recoveryPercentage),
                        const SizedBox(height: 24),
                        _buildRecoveryDonutChart(completedCount, totalCount),
                        const SizedBox(height: 24),
                        _buildWeeklyProgressList(recoveryPercentage, checkins),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ANALYTICS',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF94A3B8),
                letterSpacing: 2,
              ),
            ),
            Text(
              _selectedDateRange != null
                  ? '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}'
                  : 'Health Progress',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _showDateRangePicker,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _selectedDateRange != null
                  ? const Color.fromARGB(255, 13, 16, 53)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDateRange != null
                    ? const Color.fromARGB(255, 13, 16, 53)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar03,
              color: _selectedDateRange != null
                  ? Colors.white
                  : const Color(0xFF0F172A),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F172A), // Dark Slate
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
              secondary: Color(0xFF3B82F6),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            ),
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle.dark,
            ),
            textTheme: GoogleFonts.outfitTextTheme(),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    } else if (picked == null && _selectedDateRange != null) {
      // Option to reset filter
      setState(() {
        _selectedDateRange = null;
      });
    }
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: ['Day', 'Week', 'Month'].map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color.fromARGB(255, 13, 16, 53)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewCard(double recoveryPercent) {
    final double goalProgress = (_todaySteps / _stepGoal * 100).clamp(0, 100);
    String intensity = 'Low';
    Color intensityColor = const Color(0xFF3B82F6);
    if (_lastBpm > 100) {
      intensity = 'High';
      intensityColor = const Color(0xFFEF4444);
    } else if (_lastBpm > 70) {
      intensity = 'Normal';
      intensityColor = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _overviewItem(
                'Daily Goal',
                '${goalProgress.toInt()}%',
                Icons.bolt_rounded,
                const Color(0xFFF59E0B),
              ),
              _overviewItem(
                'Intensity',
                intensity,
                Icons.speed_rounded,
                intensityColor,
              ),
              _overviewItem(
                'Recovery',
                '${recoveryPercent.toInt()}%',
                Icons.favorite_rounded,
                const Color(0xFFF43F5E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewItem(String label, String value, IconData icon, Color color, {bool darkText = false}) {
    final titleColor = darkText ? const Color(0xFF0F172A) : Colors.white;
    final subColor = darkText ? const Color(0xFF64748B) : Colors.white.withValues(alpha: 0.5);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: titleColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: subColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMorningCheckAnalytics(List<Map<String, dynamic>> checkins) {
    if (checkins.isEmpty) return const SizedBox();

    double avgReadiness = 0;
    double avgCompliance = 0;
    for (var c in checkins) {
      avgReadiness += (c['readiness_score'] ?? 0);
      avgCompliance += (c['compliance_score'] ?? 0);
    }
    avgReadiness /= checkins.length;
    avgCompliance /= checkins.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Morning Check-ins Averages',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _overviewItem('Readiness', '${avgReadiness.toStringAsFixed(1)}/100', Icons.monitor_heart_rounded, const Color(0xFF10B981), darkText: true),
              ),
              Expanded(
                child: _overviewItem('Compliance', '${avgCompliance.toStringAsFixed(1)}/100', Icons.verified_user_rounded, const Color(0xFF3B82F6), darkText: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLineChart(List<Map<String, dynamic>> sessions) {
    // Plot actual dates over the last 7 days (index 0 = 6 days ago, index 6 = today)
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final List<int> dailyCounts = List.filled(7, 0);
    
    for (var s in sessions) {
      try {
        final dateStr = s['scheduled_date'] ?? s['created_at'];
        if (dateStr == null) continue;
        final date = DateTime.parse(dateStr).toLocal();
        final startOfDate = DateTime(date.year, date.month, date.day);
        
        final diffDays = startOfToday.difference(startOfDate).inDays;
        if (diffDays >= 0 && diffDays <= 6) {
          final index = 6 - diffDays;
          dailyCounts[index]++;
        }
      } catch (e) {
        debugPrint('Error parsing session date: $e');
      }
    }

    int maxY = dailyCounts.reduce((curr, next) => curr > next ? curr : next);
    if (maxY < 5) maxY = 5;

    final spots = List.generate(7, (i) => FlSpot(i.toDouble(), dailyCounts[i].toDouble()));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity Score',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        if (val % 1 != 0) return const SizedBox();
                        return Text(
                          val.toInt().toString(),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF94A3B8),
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        if (val.toInt() >= 0 && val.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[val.toInt()],
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF94A3B8),
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY.toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryDonutChart(int completed, int total) {
    final double completedPercent = total > 0 ? (completed / total) * 100 : 0;
    final double pendingPercent = total > 0
        ? ((total - completed) / total) * 100
        : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recovery Status',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 45,
                    sections: [
                      PieChartSectionData(
                        color: const Color(0xFF10B981),
                        value: completedPercent > 0 ? completedPercent : 0.01,
                        title: '${completedPercent.toInt()}%',
                        radius: 20,
                        titleStyle: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: const Color(0xFF3B82F6),
                        value: pendingPercent > 0 ? pendingPercent : 0.01,
                        title: '${pendingPercent.toInt()}%',
                        radius: 20,
                        titleStyle: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _chartLegend('Completed', const Color(0xFF10B981)),
                    const SizedBox(height: 12),
                    _chartLegend('Pending', const Color(0xFF3B82F6)),
                    const SizedBox(height: 24),
                    Text(
                      'Consistency is the key to recovery!',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }


  Widget _buildWeeklyProgressList(double recoveryPercent, List<Map<String, dynamic>> checkins) {
    double avgCompliance = 0;
    if (checkins.isNotEmpty) {
      for (var c in checkins) {
        avgCompliance += (c['compliance_score'] ?? 0);
      }
      avgCompliance /= checkins.length;
    } else {
      // Fallback if no morning checkins
      avgCompliance = (recoveryPercent * 0.8).clamp(0, 100);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Milestones',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        _milestoneTile(
          'Recovery Goal',
          recoveryPercent / 100,
          const Color(0xFF10B981),
        ),
        _milestoneTile(
          'Step Goal Progress',
          (_todaySteps / _stepGoal).clamp(0.0, 1.0),
          const Color(0xFFF97316),
        ),
        _milestoneTile(
          'Session Consistency',
          recoveryPercent / 100,
          const Color(0xFF3B82F6),
        ),
        _milestoneTile(
          'Morning Check-in Avg',
          avgCompliance / 100,
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _milestoneTile(String title, double progress, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
