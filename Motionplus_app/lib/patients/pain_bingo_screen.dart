import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class PainBingoScreen extends StatefulWidget {
  const PainBingoScreen({super.key});

  @override
  State<PainBingoScreen> createState() => _PainBingoScreenState();
}

class _PainBingoScreenState extends State<PainBingoScreen> {
  final List<String> _bodyParts = [
    'Head', 'Neck', 'Shoulder',
    'Tummy', 'Back', 'Arm',
    'Leg', 'Knee', 'Foot'
  ];
  
  final Set<String> _selectedParts = {};
  bool _isSubmitting = false;

  void _togglePart(String part) {
    setState(() {
      if (_selectedParts.contains(part)) {
        _selectedParts.remove(part);
      } else {
        _selectedParts.add(part);
      }
    });
  }

  Future<void> _submitBingo() async {
    if (_selectedParts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one area!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = await ApiService.get('/profiles/me', includeAuth: true);
      final userId = user != null ? user['id'] : null;
      
      if (userId != null) {
        await ApiService.post('/pain_bingo_assessments', {
          'patient_id': userId,
          'pain_score': _selectedParts.length * 2, // arbitrary logic for gamification
          'selected_areas': _selectedParts.toList(),
        }, includeAuth: true);
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('BINGO!', style: GoogleFonts.baloo2(fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B))),
              content: Text('You earned ${_selectedParts.length * 10} points for telling us how you feel!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // close screen
                  },
                  child: const Text('Yay!'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving bingo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Pain Bingo',
          style: GoogleFonts.baloo2(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Tap where it hurts!',
              style: GoogleFonts.baloo2(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _bodyParts.length,
                itemBuilder: (context, index) {
                  final part = _bodyParts[index];
                  final isSelected = _selectedParts.contains(part);
                  return GestureDetector(
                    onTap: () => _togglePart(part),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF87171) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? const Color(0xFFDC2626) : Colors.grey.withValues(alpha: 0.2), width: 2),
                        boxShadow: [
                          if (!isSelected)
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          part,
                          style: GoogleFonts.baloo2(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _isSubmitting ? null : _submitBingo,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Submit Bingo!', style: GoogleFonts.baloo2(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
