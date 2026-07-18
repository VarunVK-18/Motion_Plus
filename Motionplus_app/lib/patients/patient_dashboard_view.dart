import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'caregiver_dashboard.dart';

class PatientDashboardView extends StatelessWidget {
  const PatientDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: Text('Recovery Dashboard', style: GoogleFonts.outfit(color: const Color(0xFF2F3437), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Suggestion Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF5C7C6F), Color(0xFF2D6A4F)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI Suggestion: Great job walking yesterday! Try adding 5 more minutes today.',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Progress Section
            Text('Recovery Journey', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2F3437))),
            const SizedBox(height: 16),
            _buildProgressCard('Overall Progress', 0.65, const Color(0xFF5C7C6F)),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildStatBox('Sessions', '12/20', Icons.event_available_rounded, const Color(0xFFC8A96A))),
                const SizedBox(width: 16),
                Expanded(child: _buildStatBox('Pain Level', '3/10', Icons.thermostat_rounded, const Color(0xFF4ADE80))),
              ],
            ),
            const SizedBox(height: 24),
            
            Text('Achievements', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2F3437))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBadge(Icons.local_fire_department_rounded, '7 Day Streak', const Color(0xFFF59E0B)),
                _buildBadge(Icons.star_rounded, 'Perfect Week', const Color(0xFFC8A96A)),
                _buildBadge(Icons.directions_walk_rounded, '10k Steps', const Color(0xFF5C7C6F)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7F8F5),
                  foregroundColor: const Color(0xFF2F3437),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: const Color(0xFF5C7C6F).withValues(alpha: 0.3)),
                  ),
                ),
                icon: const Icon(Icons.family_restroom_rounded, color: Color(0xFF5C7C6F)),
                label: Text('Open Caregiver Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CaregiverDashboard()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF2F3437))),
              Text('${(value * 100).toInt()}%', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: value,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2F3437))),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2F3437))),
      ],
    );
  }
}
