import 'package:supabase_flutter/supabase_flutter.dart';

class AuditLogger {
  static final _supabase = Supabase.instance.client;

  /// Logs an action to the audit_logs table
  /// [action] is the type of action (e.g., 'ACCESS_REQUEST', 'RECORD_UPDATE')
  /// [reason] is an optional reason for the action
  /// [targetId] is the ID of the patient or record being accessed
  static Future<void> logEvent({
    required String action,
    String? reason,
    String? targetId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('audit_logs').insert({
        'actor_id': userId,
        'action': action,
        'details': reason != null ? {'reason': reason} : null,
        'target_id': targetId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // Print or handle silently to not disrupt the user flow
      print('Failed to log audit event: $e');
    }
  }
}
