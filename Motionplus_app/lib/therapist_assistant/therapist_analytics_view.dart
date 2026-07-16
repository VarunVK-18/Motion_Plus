import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TherapistAnalyticsView extends StatelessWidget {
  const TherapistAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: Text('Analytics & Trends', style: GoogleFonts.outfit(color: const Color(0xFF2F3437), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            Text('Key Metrics', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2F3437))),
            const SizedBox(height: 16),
            _buildMetricBar('Patient Compliance', 0.85, const Color(0xFF5C7C6F)),
            const SizedBox(height: 12),
            _buildMetricBar('Exercise Completion', 0.72, const Color(0xFFA8C686)),
            const SizedBox(height: 12),
            _buildMetricBar('Session Attendance', 0.95, const Color(0xFFC8A96A)),
            const SizedBox(height: 24),
            _buildTrendCard('Pain Trends', 'Average pain decreased by 15% this week.', Icons.trending_down_rounded, const Color(0xFF4ADE80)),
            const SizedBox(height: 16),
            _buildTrendCard('Mood Trends', 'Mood scores are stable across patients.', Icons.trending_flat_rounded, const Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF5C7C6F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text('42 Sessions', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14)),
                const SizedBox(height: 8),
                Text('184 Sessions', style: GoogleFonts.outfit(color: const Color(0xFF2F3437), fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: const Color(0xFF2F3437))),
            Text('${(value * 100).toInt()}%', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildTrendCard(String title, String subtitle, IconData icon, Color iconColor) {
    return Container(
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
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
