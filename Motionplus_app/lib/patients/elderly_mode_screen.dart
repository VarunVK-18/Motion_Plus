import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart' as hi;
import 'package:url_launcher/url_launcher.dart';
import '../shared/theme/app_theme.dart';
import 'exercise_tracker_page.dart';
import 'reminders_page.dart';

class ElderlyModeScreen extends StatelessWidget {
  const ElderlyModeScreen({super.key});

  Future<void> _triggerSOS(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Emergency SOS',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            color: const Color(0xFFDC2626),
            fontSize: 24,
          ),
        ),
        content: Text(
          'Do you want to call emergency services now?',
          style: GoogleFonts.outfit(
            fontSize: 20,
            color: AppTheme.charcoal,
            fontWeight: FontWeight.w500,
          ),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.softSlate,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'CALL SOS',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final Uri url = Uri.parse('tel:911');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not launch dialer',
                style: GoogleFonts.outfit(fontSize: 18),
              ),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Soft off-white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.charcoal, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My App',
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.charcoal,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const hi.HugeIcon(
              icon: hi.HugeIcons.strokeRoundedVolumeHigh,
              color: AppTheme.deepSageGreen,
              size: 32,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Voice Guidance Enabled',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppTheme.deepSageGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            // SOS Button (High Contrast, Large Target)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 100),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFBE123C), width: 1.5),
                ),
              ),
              onPressed: () => _triggerSOS(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const hi.HugeIcon(
                    icon: hi.HugeIcons.strokeRoundedTelephone,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'EMERGENCY SOS',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Simplified Navigation Items
            Expanded(
              child: GridView.count(
                crossAxisCount: 1,
                mainAxisSpacing: 20,
                childAspectRatio: 2.8,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildLargeButton(
                    context,
                    title: 'My Exercises',
                    icon: hi.HugeIcons.strokeRoundedWalking,
                    color: AppTheme.deepSageGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExerciseTrackerPage(),
                        ),
                      );
                    },
                  ),
                  _buildLargeButton(
                    context,
                    title: 'Medication',
                    icon: hi.HugeIcons.strokeRoundedPill,
                    color: const Color(0xFF1E40AF), // Deep Blue
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RemindersPage(),
                        ),
                      );
                    },
                  ),
                  _buildLargeButton(
                    context,
                    title: 'Contact Therapist',
                    icon: hi.HugeIcons.strokeRoundedCustomerService01,
                    color: const Color(0xFF92400E), // High contrast Amber/Brown
                    onTap: () async {
                      final Uri url = Uri.parse('tel:1234567890');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeButton(
    BuildContext context, {
    required String title,
    required dynamic icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          highlightColor: color.withOpacity(0.05),
          splashColor: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: hi.HugeIcon(
                    icon: icon,
                    size: 40,
                    color: color,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoal,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.softSlate.withOpacity(0.5),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
