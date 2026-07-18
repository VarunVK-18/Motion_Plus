import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAnalyticsView extends StatelessWidget {
  const AdminAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: Text('Admin Intelligence', style: GoogleFonts.outfit(color: const Color(0xFF2F3437), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Automated Alerts', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2F3437))),
            const SizedBox(height: 16),
            _buildAlertCard(
              title: 'Plateau Detected',
              description: 'Patient #1042 has shown no progress in ROM for 3 weeks.',
              icon: Icons.trending_flat_rounded,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 12),
            _buildAlertCard(
              title: 'Flare-Up Detected',
              description: 'Patient #2099 reported a 3-point pain increase for 3 consecutive days.',
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFF87171),
            ),
            const SizedBox(height: 32),
            
            Text('Clinic Metrics', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2F3437))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMetricBox('Active Patients', '1,204', Icons.people_alt_rounded, const Color(0xFF5C7C6F))),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricBox('Therapists', '24', Icons.medical_services_rounded, const Color(0xFFA8C686))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMetricBox('Recovery Rate', '88%', Icons.health_and_safety_rounded, const Color(0xFFC8A96A))),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricBox('Monthly Growth', '+12%', Icons.trending_up_rounded, const Color(0xFF5C7C6F))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard({required String title, required String description, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.outfit(color: const Color(0xFF2F3437), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2F3437))),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13)),
        ],
      ),
    );
  }
}
