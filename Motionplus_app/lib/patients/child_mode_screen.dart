import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart' as hi;
import '../services/api_service.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/glass_card.dart';
import 'exercise_tracker_page.dart';
import 'patientanalytics.dart';
import 'ai_assistant_view.dart';
import 'patient_profile_page.dart';
import 'pain_bingo_screen.dart';

class ChildModeScreen extends StatelessWidget {
  const ChildModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Zoho style soft off-white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Physio Adventure',
          style: GoogleFonts.baloo2(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar and Stars
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
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
                          color: const Color(0xFFFFFBEB),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                        ),
                        child: const hi.HugeIcon(
                          icon: hi.HugeIcons.strokeRoundedPacman01,
                          color: Color(0xFFF59E0B),
                          size: 48,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Super Hero!',
                              style: GoogleFonts.baloo2(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(
                                5,
                                (index) => const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFBBF24),
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '5 Magic Stars!',
                              style: GoogleFonts.baloo2(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Big Action Buttons Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildFunButton(
                        context,
                        title: 'My Daily\nQuest',
                        icon: hi.HugeIcons.strokeRoundedRocket02,
                        gradient: const [Color(0xFF34D399), Color(0xFF10B981)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExerciseTrackerPage(),
                            ),
                          );
                        },
                      ),
                      _buildFunButton(
                        context,
                        title: 'My\nTrophies',
                        icon: hi.HugeIcons.strokeRoundedAward01,
                        gradient: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PatientAnalyticsPage(),
                            ),
                          );
                        },
                      ),
                      _buildFunButton(
                        context,
                        title: 'Magic\nHelper',
                        icon: hi.HugeIcons.strokeRoundedMagicWand01,
                        gradient: const [Color(0xFFF472B6), Color(0xFFEC4899)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AIAssistantView(),
                            ),
                          );
                        },
                      ),
                      _buildFunButton(
                        context,
                        title: 'My\nBackpack',
                        icon: hi.HugeIcons.strokeRoundedBackpack01,
                        gradient: const [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                        onTap: () {
                          ApiService.get('/profiles/me', includeAuth: true).then((user) {
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientProfilePage(
                                  email: user != null ? user['email'] ?? '' : '',
                                ),
                              ),
                            );
                          });
                        },
                      ),
                      _buildFunButton(
                        context,
                        title: 'Pain\nBingo',
                        icon: hi.HugeIcons.strokeRoundedGameController01,
                        gradient: const [Color(0xFFF43F5E), Color(0xFFBE123C)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PainBingoScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunButton(
    BuildContext context, {
    required String title,
    required dynamic icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    final primaryColor = gradient.first;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: hi.HugeIcon(
                icon: icon,
                size: 42,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.baloo2(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
