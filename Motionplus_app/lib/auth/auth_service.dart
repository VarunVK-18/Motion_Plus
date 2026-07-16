import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_dashboard.dart';
import '../superadmin/super_admin_dashboard.dart';
import '../therapist_assistant/therapist_dashboard.dart';
import '../patients/patient_dashboard.dart';

class AuthService {
  static final client = Supabase.instance.client;
  static bool isPasswordRecovery = false;
  static bool isSigningUp = false;

  // Function to handle redirection based on role
  static Future<void> handleRedirection(BuildContext context,
      {String? portal}) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch the role from the profiles table
      final data = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        // Auto-create a missing profile for older test accounts
        await client.from('profiles').insert({
          'id': user.id,
          'role': 'patient',
          'first_name': 'Unknown',
          'last_name': 'User',
          'full_name': 'Unknown User',
          'email': user.email ?? '',
        });
      }

      final String role = data?['role'] ?? 'patient';

      // Validation logic
      if (portal == 'patient' && role != 'patient') {
        await client.auth.signOut();
        throw 'Please use the Medical Staff Portal for Admin/Therapist access.';
      }

      if (portal == 'staff' && role == 'patient') {
        await client.auth.signOut();
        throw 'This portal is for Medical Staff only. Please use the Patient Portal.';
      }

      if (!context.mounted) return;

      // Navigate based on role with safety callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        
        if (role == 'super_admin') {
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
        } else if (role == 'therapist_assistant') {
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
