import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heart_bpm/heart_bpm.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class HeartRatePage extends StatefulWidget {
  const HeartRatePage({super.key});

  @override
  State<HeartRatePage> createState() => _HeartRatePageState();
}

class _HeartRatePageState extends State<HeartRatePage> {
  List<SensorValue> data = [];
  int? bpmValue;
  int? _tempBpm;
  bool isMeasuring = false;
  bool cameraPermissionGranted = false;
  Timer? _timer;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMeasurement() {
    setState(() {
      isMeasuring = true;
      _progress = 0.0;
      _tempBpm = null;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress += 0.02; // 0.1s / 5s = 0.02
        if (_progress >= 1.0) {
          _timer?.cancel();
          if (_tempBpm != null) {
            bpmValue = _tempBpm;
            _saveBPM(bpmValue!);
          }
          isMeasuring = false;
        }
      });
    });
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      cameraPermissionGranted = status.isGranted || status.isLimited;
    });

    if (status.isPermanentlyDenied) {
      // If user denied permanently, suggest going to settings
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Camera permission is required. Please enable it in settings.',
            ),
            action: SnackBarAction(
              label: 'SETTINGS',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color heartRed = Color(0xFFEF4444);
    const Color darkSlate = Color(0xFF0F172A);
    const Color softSlate = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: darkSlate,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Heart Rate',
          style: GoogleFonts.outfit(
            color: darkSlate,
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
            // Instructions Card
            Container(
              padding: const EdgeInsets.all(20),
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
                      const Icon(
                        Icons.info_outline_rounded,
                        color: heartRed,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'HOW TO MEASURE',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: softSlate,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStep(
                    1,
                    'Gently place your index finger over the back camera lens and flash.',
                  ),
                  _buildStep(2, 'Ensure the camera lens is fully covered.'),
                  _buildStep(
                    3,
                    'Keep your hand still and relax until the measurement is complete.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Measurement Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: heartRed.withOpacity(0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (!isMeasuring)
                    Column(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: heartRed.withOpacity(0.2),
                          size: 80,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          bpmValue != null ? '$bpmValue' : '--',
                          style: GoogleFonts.outfit(
                            fontSize: 72,
                            fontWeight: FontWeight.w800,
                            color: darkSlate,
                          ),
                        ),
                        if (bpmValue != null) ...[
                          Text(
                            _getHeartRateStatus(bpmValue!),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _getHeartRateColor(bpmValue!),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          'Beats per minute',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: softSlate,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: cameraPermissionGranted
                              ? _startMeasurement
                              : _checkPermission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              226,
                              83,
                              83,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            cameraPermissionGranted
                                ? 'START MEASURING'
                                : 'GRANT PERMISSION',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: HeartBPMDialog(
                              context: context,
                              onBPM: (value) {
                                _tempBpm = value;
                              },
                              onRawData: (value) {
                                setState(() {
                                  if (data.length >= 100) data.removeAt(0);
                                  data.add(value);
                                });
                              },
                              sampleDelay: 1000 ~/ 30,
                              child: const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: heartRed.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            heartRed,
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Measuring Pulse...',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: heartRed,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Keep your finger steady on the camera',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: softSlate,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {
                            _timer?.cancel();
                            setState(() => isMeasuring = false);
                          },
                          child: Text(
                            'CANCEL',
                            style: GoogleFonts.outfit(
                              color: softSlate,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Disclaimer: This measurement is for informational purposes only and may not be 100% accurate. For clinical diagnosis, please use a medical-grade device.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$num',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBPM(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_known_bpm', value);
  }

  String _getHeartRateStatus(int bpm) {
    if (bpm < 60) return 'Your heartbeat is low';
    if (bpm <= 90) return 'Your heartbeat is normal';
    if (bpm <= 110) return 'Heartbeat is slightly high';
    return 'Heartbeat is high, take some rest';
  }

  Color _getHeartRateColor(int bpm) {
    if (bpm < 60) return const Color(0xFF3B82F6); // Blue
    if (bpm <= 90) return const Color(0xFF10B981); // Green
    if (bpm <= 110) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }
}
