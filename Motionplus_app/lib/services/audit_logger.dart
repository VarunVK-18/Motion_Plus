import '../services/api_service.dart';
import '../auth/auth_service.dart';
import 'package:flutter/foundation.dart';

class AuditLogger {
  /// Logs an action to the audit_logs table
  /// [action] is the type of action (e.g., 'ACCESS_REQUEST', 'RECORD_UPDATE')
  /// [reason] is an optional reason for the action
  /// [targetId] is the ID of the patient or record being accessed
  static Future<void> logEvent({
    required String action,
    String? reason,
    String? targetId,
  }) async {
    final userId = await AuthService.getCurrentUserId();
    if (userId == null) return;

    try {
      await ApiService.post('/audit_logs', {
        'actor_id': userId,
        'action': action,
        'details': reason != null ? {'reason': reason} : null,
        'target_id': targetId,
      }, includeAuth: true);
    } catch (e) {
      // Print or handle silently to not disrupt the user flow
      debugPrint('Failed to log audit event: $e');
    }
  }
}
