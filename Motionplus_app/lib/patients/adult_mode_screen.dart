import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdultModeScreen extends StatelessWidget {
  const AdultModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5), // Standard background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Therapy Dashboard',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2F3437), // Charcoal
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recovery Progress',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2F3437),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric('Adherence', '92%', Icons.trending_up, Colors.green),
                      _buildMetric('Sessions', '12/15', Icons.calendar_month, const Color(0xFF5C7C6F)),
                      _buildMetric('Pain Level', 'Low', Icons.monitor_heart, Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Quick Actions',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2F3437),
              ),
            ),
            const SizedBox(height: 16),
            
            // Standard Grid Actions
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildActionCard(
                  context,
                  title: 'Today\'s Exercises',
                  subtitle: '4 pending',
                  icon: Icons.fitness_center_rounded,
                  color: const Color(0xFF5C7C6F), // Deep Sage Green
                  onTap: () {},
                ),
                _buildActionCard(
                  context,
                  title: 'View Analytics',
                  subtitle: 'Detailed charts',
                  icon: Icons.bar_chart_rounded,
                  color: const Color(0xFFC8A96A), // Muted Gold
                  onTap: () {},
                ),
                _buildActionCard(
                  context,
                  title: 'Therapist Messages',
                  subtitle: '1 unread',
                  icon: Icons.message_rounded,
                  color: const Color(0xFFA8C686), // Soft Olive
                  onTap: () {},
                ),
                _buildActionCard(
                  context,
                  title: 'Profile & Settings',
                  subtitle: 'Manage account',
                  icon: Icons.settings_rounded,
                  color: const Color(0xFF94A3B8), // Slate
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2F3437),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2F3437),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
