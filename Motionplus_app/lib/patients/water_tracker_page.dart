import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class WaterTrackerPage extends StatefulWidget {
  const WaterTrackerPage({super.key});

  @override
  State<WaterTrackerPage> createState() => _WaterTrackerPageState();
}

class _WaterTrackerPageState extends State<WaterTrackerPage> {
  int _glasses = 0;
  int _targetGlasses = 8;
  List<String> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastSavedDate = prefs.getString('last_water_date');

    int savedTarget = prefs.getInt('water_goal') ?? 8;
    int savedGlasses = 0;
    List<String> savedHistory = prefs.getStringList('water_history') ?? [];

    if (lastSavedDate == today) {
      savedGlasses = prefs.getInt('water_today') ?? 0;
    } else {
      if (lastSavedDate != null) {
        int yesterdayGlasses = prefs.getInt('water_today') ?? 0;
        savedHistory.insert(0, "$lastSavedDate: $yesterdayGlasses glasses");
        if (savedHistory.length > 30) savedHistory = savedHistory.sublist(0, 30);
        await prefs.setStringList('water_history', savedHistory);
      }
      await prefs.setString('last_water_date', today);
      await prefs.setInt('water_today', 0);
    }

    if (!mounted) return;
    setState(() {
      _targetGlasses = savedTarget;
      _glasses = savedGlasses;
      _history = savedHistory;
      _isLoading = false;
    });
  }

  Future<void> _updateGlasses(int delta) async {
    int newCount = _glasses + delta;
    if (newCount < 0) return;

    setState(() {
      _glasses = newCount;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_today', _glasses);

    // Sync to backend
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      await ApiService.post('/daily-stats', {
        'date': today,
        'water_glasses': _glasses
      }, includeAuth: true);
    } catch (e) {
      debugPrint('Error syncing water: $e');
    }
  }

  Future<void> _showGoalDialog() async {
    final controller = TextEditingController(text: _targetGlasses.toString());
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
            hintText: 'Enter glasses (e.g. 8)',
            suffixText: 'glasses',
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
                await prefs.setInt('water_goal', newGoal);
                if (!mounted) return;
                setState(() => _targetGlasses = newGoal);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
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

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3B82F6);
    double progress = _targetGlasses == 0 ? 0 : (_glasses / _targetGlasses).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hydration Tracker',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
            onPressed: _showGoalDialog,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildProgressRing(primaryBlue, progress),
                  const SizedBox(height: 40),
                  _buildControls(primaryBlue),
                  const SizedBox(height: 40),
                  _buildHistoryCard(primaryBlue),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressRing(Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 16,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.water_drop_outlined,
                color: color,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                '$_glasses',
                style: GoogleFonts.outfit(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                  height: 1.0,
                ),
              ),
              Text(
                '/ $_targetGlasses glasses',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.remove_rounded,
          color: const Color(0xFF64748B),
          backgroundColor: Colors.white,
          onTap: () => _updateGlasses(-1),
        ),
        const SizedBox(width: 32),
        _buildControlButton(
          icon: Icons.add_rounded,
          color: Colors.white,
          backgroundColor: color,
          onTap: () => _updateGlasses(1),
          size: 72,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }

  Widget _buildHistoryCard(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.history_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent History',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_history.isEmpty)
            Text(
              'No history available yet.',
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontSize: 14,
              ),
            )
          else
            ..._history.take(5).map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.split(': ')[0], // Date
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      entry.split(': ')[1], // Glasses
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
