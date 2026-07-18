import 'package:flutter/material.dart';
import '../admin/admin_dashboard.dart';
import '../superadmin/super_admin_dashboard.dart';
import '../therapist_assistant/therapist_dashboard.dart';
import '../patients/patient_dashboard.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../notifications/notification_service.dart';

class AuthService {
  static bool isPasswordRecovery = false;
  static bool isSigningUp = false;

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final data = await ApiService.get('/auth/me', includeAuth: true);
      return data;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getCurrentUserId() async {
    final user = await getCurrentUser();
    return user?['_id'] ?? user?['id'];
  }

  static Future<void> signOut(BuildContext context) async {
    await ApiService.clearToken();
    SocketService.disconnect();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/selection', (route) => false);
    }
  }

  // Function to handle redirection based on role
  static Future<void> handleRedirection(BuildContext context,
      {String? portal}) async {
    final user = await getCurrentUser();
    if (user == null) {
      if (context.mounted) await signOut(context);
      return;
    }

    try {
      final String role = user['role'] ?? 'patient';
      final userId = user['_id'] ?? user['id'];
      if (userId != null) {
        SocketService.initializeSocket(userId.toString());
        
        // Also register FCM token for background push notifications (don't block routing if it hangs)
        NotificationService().getToken().timeout(const Duration(seconds: 3)).then((fcmToken) {
          if (fcmToken != null) {
            ApiService.post('/auth/fcm-token', {'token': fcmToken}, includeAuth: true).catchError((e) {
              debugPrint('Failed to save FCM token: $e');
            });
          }
        }).catchError((e) {
          debugPrint('FCM token fetch timed out or failed: $e');
        });
      }

      // Validation logic
      if (portal == 'patient' && role != 'patient') {
        await ApiService.clearToken();
        throw 'Please use the Medical Staff Portal for Admin/Therapist access.';
      }

      if (portal == 'staff' && role == 'patient') {
        await ApiService.clearToken();
        throw 'This portal is for Medical Staff only. Please use the Patient Portal.';
      }

      if (!context.mounted) return;

      // Navigate based on role with safety callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        
        if (role == 'superadmin' || role == 'super_admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SuperAdminDashboard()),
            (route) => false,
          );
        } else if (role == 'admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
            (route) => false,
          );
        } else if (role == 'therapist' || role == 'therapist_assistant') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const TherapistDashboard()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const PatientDashboard()),
            (route) => false,
          );
        }
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      rethrow;
    }
  }
}
