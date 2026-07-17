import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class MorningFormScreen extends StatefulWidget {
  final String sessionId;

  const MorningFormScreen({super.key, required this.sessionId});

  @override
  State<MorningFormScreen> createState() => _MorningFormScreenState();
}

class _MorningFormScreenState extends State<MorningFormScreen> {
  
  bool _isLoading = false;

  // Form State
  String? _overallDay;
  String? _activeLevel;
  String? _homeExercises;
  String? _painDiscomfort;
  String? _energyLevel;
  String? _sleepQuality;
  String? _mood;
  
  // Multiple Choice (Symptoms)
  final Map<String, bool> _symptoms = {
    'Excessive pain': false,
    'Fatigue': false,
    'Fall or injury': false,
    'Dizziness': false,
    'Stress or anxiety': false,
    'Illness or fever': false,
    'None of the above': false,
  };

  // Multiple Choice (Difficulty)
  final Map<String, bool> _difficulties = {
    'Walking': false,
    'Stairs': false,
    'Dressing': false,
    'Feeding': false,
    'Bathing': false,
    'Work/School': false,
    'Balance': false,
    'No difficulty': false,
  };

  // Multiple Choice (Important Note)
  final Map<String, bool> _importantNotes = {
    'Increased pain': false,
    'New symptoms': false,
    'Better than before': false,
    'Feeling tired': false,
    'Need guidance': false,
    'Nothing specific': false,
  };

  static const Color primaryBlue = Color(0xFF3E84DC);
  static const Color forestGreen = Color(0xFF2D6A4F);
  static const Color darkSlate = Color(0xFF0F172A);

  Future<void> _submitForm() async {
    if (_overallDay == null ||
        _activeLevel == null ||
        _homeExercises == null ||
        _painDiscomfort == null ||
        _energyLevel == null ||
        _sleepQuality == null ||
        _mood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all single-choice questions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ApiService.get('/profiles/me', includeAuth: true);
      if (user == null) throw Exception('Not logged in');

      // Calculate Scores
      int readinessScore = 100;
      if (_sleepQuality == 'Poor sleep') readinessScore -= 20;
      if (_sleepQuality == 'Average sleep') readinessScore -= 5;
      if (_energyLevel == 'Low') readinessScore -= 20;
      if (_energyLevel == 'Moderate') readinessScore -= 5;
      if (_painDiscomfort == 'Increased') readinessScore -= 20;
      if (_mood == 'Low' || _mood == 'Stressed') readinessScore -= 10;
      
      int complianceScore = 100;
      if (_homeExercises == 'Not done') complianceScore = 0;
      if (_homeExercises == 'Partially completed') complianceScore = 50;

      // Extract JSON lists
      List<String> symptomsList = _symptoms.entries.where((e) => e.value).map((e) => e.key).toList();
      List<String> difficultiesList = _difficulties.entries.where((e) => e.value).map((e) => e.key).toList();
      List<String> importantNotesList = _importantNotes.entries.where((e) => e.value).map((e) => e.key).toList();

      // Smart Notifications Generation
      List<String> notifications = [];
      if (_sleepQuality == 'Poor sleep' && _painDiscomfort == 'Increased' && _symptoms['Fatigue'] == true) {
        notifications.add('Patient may require modified intensity today.');
      }
      if (_homeExercises == 'Not done') {
        notifications.add('Missed home exercise. Consider motivational counseling and exercise modification.');
      }
      if (_mood == 'Low') {
        notifications.add('Low mood reported. Monitor psychological well-being and treatment engagement.');
      }
      if (_symptoms['Fall or injury'] == true) {
        notifications.add('CRITICAL: Patient reported a fall or injury.');
      }

      await ApiService.post('/morning_checkins', {
        'patient_id': user['id'],
        'session_id': widget.sessionId,
        'overall_day': _overallDay,
        'active_level': _activeLevel,
        'home_exercises': _homeExercises,
        'pain_discomfort': _painDiscomfort,
        'energy_level': _energyLevel,
        'sleep_quality': _sleepQuality,
        'symptoms': symptomsList,
        'mood': _mood,
        'difficulty_activities': difficultiesList,
        'important_note': importantNotesList,
        'readiness_score': readinessScore,
        'compliance_score': complianceScore,
        'smart_notifications': notifications,
      }, includeAuth: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Morning Check-In completed successfully!'),
            backgroundColor: forestGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting form: $e')),
        );
        // Pop with true even on error so it doesn't keep pestering the user
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildRadioQuestion(String question, List<String> options, String? groupValue, Function(String?) onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: darkSlate,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((option) => RadioListTile<String>(
                  title: Text(option, style: GoogleFonts.outfit(fontSize: 14)),
                  value: option,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: forestGreen,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxQuestion(String question, Map<String, bool> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: darkSlate,
              ),
            ),
            const SizedBox(height: 12),
            ...items.keys.map((key) => CheckboxListTile(
                  title: Text(key, style: GoogleFonts.outfit(fontSize: 14)),
                  value: items[key],
                  onChanged: (val) {
                    setState(() {
                      if (key.contains('None') || key.contains('No difficulty') || key.contains('Nothing specific')) {
                        if (val == true) {
                          // Uncheck all others
                          items.updateAll((k, v) => k == key ? true : false);
                        } else {
                          items[key] = false;
                        }
                      } else {
                        items[key] = val ?? false;
                        // Uncheck the "None" option
                        final noneKey = items.keys.firstWhere((k) => k.contains('None') || k.contains('No difficulty') || k.contains('Nothing specific'), orElse: () => '');
                        if (noneKey.isNotEmpty) items[noneKey] = false;
                      }
                    });
                  },
                  activeColor: forestGreen,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: darkSlate),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Morning Recovery Check-In',
          style: GoogleFonts.outfit(
            color: darkSlate,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: forestGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryBlue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wb_sunny_rounded, color: primaryBlue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'How was your day yesterday? This helps us personalize your treatment.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: primaryBlue.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildRadioQuestion('1. How was your overall day yesterday?', ['Good', 'Average', 'Difficult'], _overallDay, (v) => setState(() => _overallDay = v)),
                  _buildRadioQuestion('2. How active were you?', ['Active', 'Moderately active', 'Mostly resting'], _activeLevel, (v) => setState(() => _activeLevel = v)),
                  _buildRadioQuestion('3. Did you perform your home exercises?', ['Fully completed', 'Partially completed', 'Not done'], _homeExercises, (v) => setState(() => _homeExercises = v)),
                  _buildRadioQuestion('4. How was your pain or discomfort yesterday?', ['Better', 'Same', 'Increased', 'No pain'], _painDiscomfort, (v) => setState(() => _painDiscomfort = v)),
                  _buildRadioQuestion('5. How was your energy level?', ['Good', 'Moderate', 'Low'], _energyLevel, (v) => setState(() => _energyLevel = v)),
                  _buildRadioQuestion('6. How did you sleep?', ['Good sleep', 'Average sleep', 'Poor sleep'], _sleepQuality, (v) => setState(() => _sleepQuality = v)),
                  _buildCheckboxQuestion('7. Did you experience any of the following?', _symptoms),
                  _buildRadioQuestion('8. How was your mood?', ['Happy', 'Neutral', 'Low', 'Stressed'], _mood, (v) => setState(() => _mood = v)),
                  _buildCheckboxQuestion('9. Did you face any difficulty with daily activities?', _difficulties),
                  _buildCheckboxQuestion('10. Is there anything important you want your therapist to know today?', _importantNotes),

                  const SizedBox(height: 16),
                  Text(
                    'Disclaimer: This daily check-in helps your therapist understand your recent activities and overall well-being. Daily responses may vary and are used to personalize treatment.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: forestGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Submit Check-In',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
