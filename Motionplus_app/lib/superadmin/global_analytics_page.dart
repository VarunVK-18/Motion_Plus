import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class GlobalAnalyticsPage extends StatefulWidget {
  const GlobalAnalyticsPage({super.key});

  @override
  State<GlobalAnalyticsPage> createState() => _GlobalAnalyticsPageState();
}

class _GlobalAnalyticsPageState extends State<GlobalAnalyticsPage>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;

  // Filter State
  String _selectedFilter = 'Today';
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    if (_selectedFilter == 'Today') {
      return DateTime(now.year, now.month, now.day);
    } else if (_selectedFilter == 'This Month') {
      return DateTime(now.year, now.month, 1);
    } else if (_selectedFilter == 'Custom' && _customRange != null) {
      return _customRange!.start;
    }
    return DateTime(2000);
  }

  DateTime _getEndDate() {
    final now = DateTime.now();
    if (_selectedFilter == 'Today') {
      return DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_selectedFilter == 'This Month') {
      return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (_selectedFilter == 'Custom' && _customRange != null) {
      return DateTime(
        _customRange!.end.year,
        _customRange!.end.month,
        _customRange!.end.day,
        23,
        59,
        59,
      );
    }
    return now.add(const Duration(days: 365));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Global Analytics',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (_selectedFilter != 'Today')
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'Today';
                  _customRange = null;
                });
              },
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Colors.redAccent,
              ),
              label: Text(
                'Reset',
                style: GoogleFonts.outfit(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF3B82F6),
            ),
            onPressed: _selectCustomRange,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Today'),
                      const SizedBox(width: 8),
                      _filterChip('This Month'),
                      const SizedBox(width: 8),
                      _filterChip('Custom'),
                    ],
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Treatment Stats'),
                  Tab(text: 'Hourly Trends'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder(
        future: ApiService.get('/sessions', includeAuth: true),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: Colors.redAccent.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Analytics Unavailable',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                  Text(
                    'Check your connection to sync data',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allSessions = (snapshot.data as List?)?.cast<Map<String, dynamic>>() ?? [];

          final startDate = _getStartDate();
          final endDate = _getEndDate();

          final sessions = allSessions.where((s) {
            DateTime? sessionDate;
            try {
              if (s['scheduled_time'] != null) {
                sessionDate = DateTime.parse(s['scheduled_time']);
              }
            } catch (_) {}
            sessionDate ??= DateTime.tryParse(s['created_at'] ?? '');
            if (sessionDate == null) return false;
            return sessionDate.isAfter(
                  startDate.subtract(const Duration(seconds: 1)),
                ) &&
                sessionDate.isBefore(endDate.add(const Duration(seconds: 1)));
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTreatmentStats(sessions),
              _buildHourlyTrends(sessions),
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF3B82F6),
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                    surface: Color(0xFF0F172A),
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF3B82F6),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF0F172A),
                    surface: Colors.white,
                  ),
            appBarTheme: AppBarTheme(
              systemOverlayStyle:
                  isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() {
        _customRange = range;
        _selectedFilter = 'Custom';
      });
    }
  }

  Widget _filterChip(String label) {
    bool isSelected = _selectedFilter == label;
    String displayText = label;
    if (label == 'Custom' && _customRange != null) {
      displayText =
          '${DateFormat('MMM d').format(_customRange!.start)} - ${DateFormat('MMM d').format(_customRange!.end)}';
    }

    return GestureDetector(
      onTap: () {
        if (label == 'Custom') {
          _selectCustomRange();
        } else {
          setState(() {
            _selectedFilter = label;
            _customRange = null;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              displayText,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentStats(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) {
      return _buildEmptyState('No sessions found for this period');
    }

    int completed = sessions.where((s) => s['status'] == 'completed').length;
    int assigned = sessions.where((s) => s['status'] == 'assigned').length;
    int pending = sessions.where((s) => s['status'] == 'pending').length;
    int total = sessions.length;

    double completedPerc = total > 0 ? (completed / total) * 100 : 0;
    double assignedPerc = total > 0 ? (assigned / total) * 100 : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Treatment Distribution',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 240,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback:
                            (FlTouchEvent event, pieTouchResponse) {},
                      ),
                      sectionsSpace: 4,
                      centerSpaceRadius: 60,
                      sections: [
                        PieChartSectionData(
                          value: completed.toDouble(),
                          title: '${completedPerc.toStringAsFixed(0)}%',
                          radius: 50,
                          color: const Color(0xFF10B981),
                          titleStyle: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        PieChartSectionData(
                          value: assigned.toDouble(),
                          title: '${assignedPerc.toStringAsFixed(0)}%',
                          radius: 50,
                          color: const Color(0xFF3B82F6),
                          titleStyle: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        if (pending > 0)
                          PieChartSectionData(
                            value: pending.toDouble(),
                            title: '',
                            radius: 40,
                            color: const Color(0xFFF59E0B),
                          ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutBack,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendItem('Completed', const Color(0xFF10B981)),
                    const SizedBox(width: 24),
                    _legendItem('Assigned', const Color(0xFF3B82F6)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _statCard(
            'Period Session Count',
            total.toString(),
            Icons.analytics_rounded,
            Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyTrends(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) return _buildEmptyState('No trends available');

    Map<int, int> hourCounts = {};

    for (var session in sessions) {
      int? hour;

      // 1. Try scheduled_time (String format like "10:30 AM")
      if (session['scheduled_time'] != null) {
        try {
          final timeStr = session['scheduled_time'].toString().toLowerCase();
          final parts = timeStr.split(':');
          if (parts.length >= 2) {
            int h = int.parse(parts[0]);
            bool isPm = timeStr.contains('pm');
            bool isAm = timeStr.contains('am');

            if (isPm && h < 12) h += 12;
            if (isAm && h == 12) h = 0;
            hour = h;
          }
        } catch (_) {}
      }

      // 2. Fallback to scheduled_date if it's a full DateTime string
      if (hour == null && session['scheduled_date'] != null) {
        try {
          DateTime dt = DateTime.parse(session['scheduled_date']);
          hour = dt.hour;
        } catch (_) {}
      }

      // 3. Last fallback to created_at
      if (hour == null && session['created_at'] != null) {
        try {
          DateTime dt = DateTime.parse(session['created_at']).toLocal();
          hour = dt.hour;
        } catch (_) {}
      }

      if (hour != null && hour >= 8 && hour <= 20) {
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
    }

    List<FlSpot> spots = [];
    for (int i = 8; i <= 20; i++) {
      spots.add(FlSpot(i.toDouble(), (hourCounts[i] ?? 0).toDouble()));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFF1F5F9),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Flow Trends',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) =>
                          Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 4,
                        getTitlesWidget: (value, meta) {
                          String text = '';
                          if (value == 8) text = '8AM';
                          if (value == 12) text = '12PM';
                          if (value == 16) text = '4PM';
                          if (value == 20) text = '8PM';
                          return Text(
                            text,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF3B82F6),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutQuad,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 64,
            color: Colors.blue.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.blue.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            text,
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
