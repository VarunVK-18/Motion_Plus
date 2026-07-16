import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'log_entry_sheet.dart';
import 'morningform.dart';
import 'reminders_page.dart';

class CaregiverDashboard extends StatelessWidget {
  final VoidCallback? onBookAppointment;

  const CaregiverDashboard({super.key, this.onBookAppointment});

  Future<void> _handleMorningQuestionnaire(BuildContext context) async {
    final now = DateTime.now();
    // A cycle is from 5 AM today to 4:59 AM tomorrow.
    final currentCycleStart = DateTime(
      now.year,
      now.month,
      now.day,
      5,
      0,
    ).subtract(Duration(days: now.hour < 5 ? 1 : 0));
    final currentCycleEnd = currentCycleStart.add(const Duration(days: 1));

    final previousCycleStart = currentCycleStart.subtract(const Duration(days: 1));
    final previousCycleEnd = currentCycleStart;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = await ApiService.get('/profiles/me', includeAuth: true);
      final userId = user['id'];

      // 1. Check if morning form is already submitted in the current cycle
      final checkins = await ApiService.get('/morning_checkins?patient_id=$userId&created_at[gte]=${currentCycleStart.toIso8601String()}&created_at[lt]=${currentCycleEnd.toIso8601String()}', includeAuth: true);

      if (!context.mounted) return;

      if (checkins.isNotEmpty) {
        Navigator.pop(context); // Close loading
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Already Submitted', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: Text('You have already submitted your morning questions for today.', style: GoogleFonts.outfit()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: GoogleFonts.outfit(color: const Color(0xFF0F766E))),
              ),
            ],
          ),
        );
        return;
      }

      // 2. Check if a therapy session was done yesterday
      final sessions = await ApiService.get('/sessions?patient_id=$userId&status=completed&scheduled_date[gte]=${previousCycleStart.toIso8601String()}&scheduled_date[lt]=${previousCycleEnd.toIso8601String()}', includeAuth: true);
          
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      if (sessions.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('No Therapy Done Yesterday', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: Text('Please book an appointment to continue.', style: GoogleFonts.outfit()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  if (onBookAppointment != null) {
                    Navigator.pop(context); // Also pop the dashboard itself to go back to parent view
                    onBookAppointment!();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
                child: Text('Book Appointment', style: GoogleFonts.outfit()),
              ),
            ],
          ),
        );
        return;
      }

      // 3. Both conditions passed
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MorningFormScreen(sessionId: '')),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: Text(
          'Caregiver Dashboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF2F3437)),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // One tap therapist contact
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contacting Therapist...')));
            },
            icon: const Icon(Icons.support_agent_rounded, color: Color(0xFF5C7C6F)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning, Caregiver',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2F3437)),
            ),
            const SizedBox(height: 24),
            
            // Morning Questionnaire Card
            _buildActionCard(
              title: 'Morning Questionnaire',
              subtitle: 'Log sleep, mood, and initial pain levels',
              icon: Icons.wb_sunny_rounded,
              color: const Color(0xFFC8A96A),
              onTap: () => _handleMorningQuestionnaire(context),
            ),
            const SizedBox(height: 16),
            
            // Medication Tracker
            _buildActionCard(
              title: 'Medication Tracker',
              subtitle: 'Next: Painkiller at 2:00 PM',
              icon: Icons.medical_services_rounded,
              color: const Color(0xFF5C7C6F),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RemindersPage()),
                );
              },
            ),
            const SizedBox(height: 16),

            // Daily Logs Grid
            Text(
              'Daily Logs',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2F3437)),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildLogTile(context, 'Pain Level', Icons.thermostat_rounded, const Color(0xFFF87171)),
                _buildLogTile(context, 'Food Intake', Icons.restaurant_rounded, const Color(0xFFA8C686)),
                _buildLogTile(context, 'Falls Obs.', Icons.warning_rounded, const Color(0xFFF59E0B)),
                _buildLogTile(context, 'Mood', Icons.mood_rounded, const Color(0xFF94A3B8)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF2F3437))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTile(BuildContext context, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => LogEntrySheet(logType: title),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF2F3437))),
          ],
        ),
      ),
    );
  }
}
