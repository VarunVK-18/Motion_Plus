import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../auth/auth_service.dart';

class LogEntrySheet extends StatefulWidget {
  final String logType;

  const LogEntrySheet({super.key, required this.logType});

  @override
  State<LogEntrySheet> createState() => _LogEntrySheetState();
}

class _LogEntrySheetState extends State<LogEntrySheet> {
  final _notesController = TextEditingController();
  double _severity = 5;
  bool _isSubmitting = false;

  Future<void> _submitLog() async {
    setState(() => _isSubmitting = true);
    try {
      final user = await ApiService.get('/profiles/me', includeAuth: true);
      // In a real app, get the actual patientId assigned to this caregiver. 
      // For now, we assume the caregiver is logging for a specific patient.
      // We will just use the caregiver's own ID as patient_id for demo if not linked.
      final userId = user != null ? user['id'] : null;
      
      if (userId != null) {
        await ApiService.post('/caregiver_observation_logs', {
          'patient_id': userId, // Placeholder: in real app, get target patient ID
          'logger_id': userId,
          'log_type': widget.logType.toLowerCase(),
          'severity': widget.logType == 'Pain Level' || widget.logType == 'Mood' ? _severity.toInt() : null,
          'notes': _notesController.text,
        }, includeAuth: true);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.logType} log saved!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving log: $e')),
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
    final needsSeverity = widget.logType == 'Pain Level' || widget.logType == 'Mood';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log ${widget.logType}',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (needsSeverity) ...[
            Text('Severity (1-10)', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            Slider(
              value: _severity,
              min: 1,
              max: 10,
              divisions: 9,
              label: _severity.round().toString(),
              activeColor: const Color(0xFF5C7C6F),
              onChanged: (val) => setState(() => _severity = val),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add notes...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF5C7C6F), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C7C6F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSubmitting ? null : _submitLog,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : Text('Save Log', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
