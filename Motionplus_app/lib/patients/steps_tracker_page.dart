import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:hugeicons/hugeicons.dart';

class StepsTrackerPage extends StatefulWidget {
  const StepsTrackerPage({super.key});

  @override
  State<StepsTrackerPage> createState() => _StepsTrackerPageState();
}

class _StepsTrackerPageState extends State<StepsTrackerPage> {
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  String _status = 'stopped';
  int _todaySteps = 0;
  int _targetSteps = 10000;
  int? _baselineSteps;
  List<String> _history = [];
  String _selectedInsight = 'Weekly';

  double _calculateAvg(int days) {
    if (_history.isEmpty && _todaySteps == 0) return 0.0;
    int total = _todaySteps;
    int count = 1;
    int historyToRead = (days - 1).clamp(0, _history.length);
    for (int i = 0; i < historyToRead; i++) {
      final parts = _history[i].split(': ');
      if (parts.length > 1) {
        final stepsStr = parts[1].split(' ')[0];
        total += int.tryParse(stepsStr) ?? 0;
        count++;
      }
    }
    return total / count;
  }

  double _calculateProgress(int days) {
    double periodGoal = _targetSteps * days.toDouble();
    int total = _todaySteps;
    int historyToRead = (days - 1).clamp(0, _history.length);
    for (int i = 0; i < historyToRead; i++) {
      final parts = _history[i].split(': ');
      if (parts.length > 1) {
        final stepsStr = parts[1].split(' ')[0];
        total += int.tryParse(stepsStr) ?? 0;
      }
    }
    return (total / periodGoal).clamp(0.0, 1.0);
  }

  double get _currentAvg {
    switch (_selectedInsight) {
      case 'Daily':
        return _todaySteps.toDouble();
      case 'Monthly':
        return _calculateAvg(30);
      default:
        return _calculateAvg(7);
    }
  }

  double get _currentProgress {
    switch (_selectedInsight) {
      case 'Daily':
        return (_todaySteps / _targetSteps).clamp(0.0, 1.0);
      case 'Monthly':
        return _calculateProgress(30);
      default:
        return _calculateProgress(7);
    }
  }

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initPlatformState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _history = prefs.getStringList('step_history') ?? [];
      _targetSteps = prefs.getInt('step_goal') ?? 10000;
    });

    // Request permissions
    if (await Permission.activityRecognition.request().isGranted) {
      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
      );
      _pedestrianStatusSubscription?.onError(_onPedestrianStatusError);

      _stepCountSubscription = Pedometer.stepCountStream.listen(_onStepCount);
      _stepCountSubscription?.onError(_onStepCountError);
    } else {
      if (!mounted) return;
      setState(() {
        _status = 'Permission Denied';
      });
    }
  }

  Future<void> _showGoalDialog() async {
    final controller = TextEditingController(text: _targetSteps.toString());
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Set Daily Goal',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter steps (e.g. 10000)',
            suffixText: 'steps',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newGoal = int.tryParse(controller.text);
              if (newGoal != null && newGoal > 0) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('step_goal', newGoal);
                if (!mounted) return;
                setState(() => _targetSteps = newGoal);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save Goal',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onStepCount(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastSavedDate = prefs.getString('last_step_date');
    int sensorTotalSteps = event.steps;

    // Check if it's a new day
    if (lastSavedDate != null && lastSavedDate != today) {
      // Calculate and save the completed day's final steps to history
      int oldBaseline = prefs.getInt('baseline_steps') ?? sensorTotalSteps;
      int completedDaySteps = sensorTotalSteps - oldBaseline;

      List<String> history = prefs.getStringList('step_history') ?? [];
      // Store as "Date: Steps"
      history.insert(0, "$lastSavedDate: $completedDaySteps steps");
      if (history.length > 30) history = history.sublist(0, 30);

      await prefs.setStringList('step_history', history);
      await prefs.setString('last_step_date', today);
      await prefs.setInt('baseline_steps', sensorTotalSteps);

      if (!mounted) return;
      setState(() {
        _history = history;
        _baselineSteps = sensorTotalSteps;
        _todaySteps = 0;
      });
    } else if (lastSavedDate == null) {
      // First time initialization
      await prefs.setString('last_step_date', today);
      await prefs.setInt('baseline_steps', sensorTotalSteps);
      _baselineSteps = sensorTotalSteps;
    } else {
      _baselineSteps = prefs.getInt('baseline_steps') ?? sensorTotalSteps;
    }

    if (!mounted) return;
    setState(() {
      _todaySteps = sensorTotalSteps - (_baselineSteps ?? sensorTotalSteps);
    });
    // Save for dashboard sync
    await prefs.setInt('last_known_steps', _todaySteps);
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    if (!mounted) return;
    setState(() {
      _status = event.status;
    });
  }

  void _onPedestrianStatusError(error) {
    if (!mounted) return;
    setState(() {
      _status = 'Status not available';
    });
  }

  void _onStepCountError(error) {
    if (!mounted) return;
    setState(() {
      _todaySteps = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color orange = Color(0xFFF97316);
    double progress = (_todaySteps / _targetSteps).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Steps Tracker',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: orange.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 15,
                          backgroundColor: orange.withOpacity(0.1),
                          color: orange,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            _todaySteps.toString(),
                            style: GoogleFonts.outfit(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Steps today',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _status == 'walking'
                                      ? Icons.directions_walk
                                      : Icons.accessibility_new_rounded,
                                  size: 14,
                                  color: orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _status.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: _showGoalDialog,
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                _buildMiniStat(
                                  'Goal',
                                  '$_targetSteps',
                                  Icons.track_changes_rounded,
                                  const Color(0xFF3B82F6),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF3B82F6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildMiniStat(
                        'Calories',
                        '${(_todaySteps * 0.04).toStringAsFixed(0)} kcal',
                        Icons.local_fire_department_rounded,
                        const Color(0xFFEF4444), // Red
                      ),
                      _buildMiniStat(
                        'Distance',
                        '${(_todaySteps * 0.0007).toStringAsFixed(1)} km',
                        HugeIcons.strokeRoundedWalking,
                        const Color.fromARGB(255, 8, 164, 112), // Green
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildAnalyticsCard(),
            const SizedBox(height: 32),
            if (_history.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'RECENT HISTORY',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF64748B),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ..._history.map((record) {
                final parts = record.split(': ');
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64748B).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedTransactionHistory,
                              color: Color.fromARGB(255, 0, 0, 0),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            parts[0],
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        parts[1],
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    final double avgSteps = _currentAvg;
    final double avgPercent = (avgSteps / _targetSteps).clamp(0.0, 1.0);
    final double progress = _currentProgress;
    const Color indigo = Color(0xFF6366F1);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: indigo.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedAnalytics03,
                    color: Color.fromARGB(255, 0, 0, 0),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'INSIGHTS',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color.fromARGB(255, 0, 0, 0),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              // Period Selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: ['Daily', 'Weekly', 'Monthly'].map((type) {
                    bool isSelected = _selectedInsight == type;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedInsight = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? indigo : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: indigo.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          type,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Donut Progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: CircularProgressIndicator(
                      value: avgPercent,
                      strokeWidth: 8,
                      backgroundColor: indigo.withOpacity(0.1),
                      color: indigo,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(avgPercent * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        _selectedInsight == 'Daily' ? 'GOAL' : 'AVG',
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Analytics Progress Bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_selectedInsight Progress',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: indigo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: indigo.withOpacity(0.1),
                        color: indigo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedInsight == 'Daily'
                          ? 'Today\'s performance'
                          : 'Based on available history',
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

  Widget _buildMiniStat(String label, String value, dynamic icon, Color color) {
    return Column(
      children: [
        if (icon is IconData)
          Icon(icon, color: color, size: 24)
        else
          HugeIcon(icon: icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
