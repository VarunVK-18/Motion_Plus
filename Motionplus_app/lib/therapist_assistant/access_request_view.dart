import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audit_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccessRequestView extends StatefulWidget {
  final String patientId;

  const AccessRequestView({super.key, required this.patientId});

  @override
  State<AccessRequestView> createState() => _AccessRequestViewState();
}

class _AccessRequestViewState extends State<AccessRequestView> {
  final _reasonController = TextEditingController();
  bool _isRequesting = false;
  bool _requested = false;

  Future<void> _requestAccess() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;

    setState(() => _isRequesting = true);

    try {
      final supabase = Supabase.instance.client;
      final therapistId = supabase.auth.currentUser?.id;

      if (therapistId != null) {
        await supabase.from('access_requests').insert({
          'therapist_id': therapistId,
          'patient_id': widget.patientId,
          'reason': reason,
          'status': 'PENDING',
        });

        await AuditLogger.logEvent(
          action: 'ACCESS_REQUEST',
          reason: reason,
          targetId: widget.patientId,
        );

        if (mounted) {
          setState(() {
            _requested = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to request access: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: Text('Access Restricted', style: GoogleFonts.outfit(color: const Color(0xFF2F3437), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2F3437)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 64, color: Color(0xFF94A3B8)),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2F3437)),
              ),
              const SizedBox(height: 12),
              Text(
                'You don\'t currently have access to this patient.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 32),
              if (_requested)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80)),
                      const SizedBox(width: 8),
                      Text('Access Request Submitted', style: GoogleFonts.outfit(color: const Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else ...[
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    hintText: 'Reason for access...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isRequesting ? null : _requestAccess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C7C6F),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isRequesting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Request Access', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
