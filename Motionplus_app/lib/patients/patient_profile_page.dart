import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart' as hi;
import '../selection_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/profile_image_service.dart';
import 'widgets/patient_timeline.dart';
import 'widgets/assessment_repository.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/glass_card.dart';
import 'elderly_mode_screen.dart';
import 'child_mode_screen.dart';
import 'patientanalytics.dart';
import '../therapist_assistant/access_request_view.dart';


class PatientProfilePage extends StatefulWidget {
  final String email;
  final String? patientId;
  const PatientProfilePage({super.key, required this.email, this.patientId});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final _supabase = Supabase.instance.client;
  String _phone = 'Loading...';
  bool _hasAccess = true;
  bool _isLoadingAccess = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _fetchUserProfile();
  }

  Future<void> _checkAccess() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final targetId = widget.patientId ?? currentUserId;

    if (currentUserId == null || targetId == null) {
      if (mounted) setState(() => _isLoadingAccess = false);
      return;
    }

    if (currentUserId == targetId) {
      if (mounted) setState(() => _isLoadingAccess = false);
      return;
    }

    try {
      final profile = await _supabase.from('profiles').select('role').eq('id', currentUserId).maybeSingle();
      if (profile?['role'] == 'therapist') {
         final assignments = await _supabase.from('sessions')
              .select('id')
              .eq('therapist_id', currentUserId)
              .eq('patient_id', targetId)
              .limit(1);
         if (assignments.isEmpty) {
            _hasAccess = false;
         }
      }
    } catch (e) {
      debugPrint('Access check error: $e');
    }
    
    if (mounted) {
      setState(() => _isLoadingAccess = false);
    }
  }

  Future<void> _fetchUserProfile() async {
    final targetId = widget.patientId ?? _supabase.auth.currentUser?.id;
    if (targetId != null) {
      try {
        final response = await _supabase
            .from('profiles')
            .select('phone')
            .eq('id', targetId)
            .maybeSingle();

        if (mounted) {
          setState(() {
            _phone = response?['phone']?.toString().isNotEmpty == true
                ? response!['phone']
                : 'Not provided';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _phone = 'Error loading phone';
          });
        }
      }
    }
  }

  
  
  
  
  

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Close bottom sheet
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Picture',
              toolbarColor: AppTheme.deepSageGreen,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Profile Picture',
              aspectRatioLockEnabled: true,
            ),
          ],
        );

        if (croppedFile != null) {
          await ProfileImageService().saveProfileImage(File(croppedFile.path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Profile Photo',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: AppTheme.deepSageGreen),
                title: Text('Take a photo', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppTheme.deepSageGreen),
                title: Text('Choose from gallery', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              if (ProfileImageService().profileImagePathNotifier.value != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF87171)),
                  title: Text('Remove photo', style: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: Color(0xFFF87171))),
                  onTap: () async {
                    Navigator.pop(context);
                    await ProfileImageService().removeProfileImage();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLogoutConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Logout',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: GoogleFonts.outfit(color: AppTheme.softSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppTheme.softSlate,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorCoral,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'LOGOUT',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: AppTheme.deepSageGreen),
          ),
        );
      }

      await _supabase.auth.signOut();

      if (mounted) {
        Navigator.pop(context); // close loading
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SelectionPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAccess) {
      return const Scaffold(
        backgroundColor: AppTheme.warmOffWhite,
        body: Center(child: CircularProgressIndicator(color: AppTheme.deepSageGreen)),
      );
    }

    if (!_hasAccess && widget.patientId != null) {
      return AccessRequestView(patientId: widget.patientId!);
    }

    final name = widget.email.split('@')[0].toUpperCase();
    final initial = name.isNotEmpty ? name[0] : '?';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.warmOffWhite,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.charcoal,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'My Profile',
            style: GoogleFonts.outfit(
              color: AppTheme.charcoal,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _showLogoutConfirm,
              icon: const hi.HugeIcon(
                icon: hi.HugeIcons.strokeRoundedLogout03,
                color: Color(0xFFF87171),
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            indicatorColor: AppTheme.deepSageGreen,
            labelColor: AppTheme.deepSageGreen,
            unselectedLabelColor: AppTheme.softSlate,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Medical'),
              Tab(text: 'Documents'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(name, initial),
            _buildMedicalTab(),
            _buildDocumentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(String name, String initial) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
            // Profile Header
            Container(
              width: double.infinity,
              child: GlassCard(
                padding: const EdgeInsets.all(32),
                borderRadius: 32,
                opacity: 0.8,
                child: Column(
                children: [
                  GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ValueListenableBuilder<String?>(
                          valueListenable: ProfileImageService().profileImagePathNotifier,
                          builder: (context, imagePath, child) {
                            return CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.deepSageGreen.withOpacity(0.1),
                              backgroundImage: imagePath != null ? FileImage(File(imagePath)) : null,
                              child: imagePath == null
                                  ? Text(
                                      initial,
                                      style: GoogleFonts.outfit(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.deepSageGreen,
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.deepSageGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.deepSageGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Patient Account',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepSageGreen,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 24),

            // Personal Details Section
            GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 24,
              opacity: 0.9,
              child: Column(
                children: [
                  _buildDetailTile(
                    icon: Icons.email_outlined,
                    label: 'Email Address',
                    value: widget.email,
                  ),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                  _buildDetailTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: _phone,
                  ),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                  _buildDetailTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Member Since',
                    value: 'May 2026', // TODO: Make dynamic
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'App Modes',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 24,
              opacity: 0.9,
              child: Column(
                children: [
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChildModeScreen()),
                    ),
                    child: _buildDetailTile(
                      icon: Icons.child_care_rounded,
                      label: 'Child Mode',
                      value: 'Simplified interface for kids',
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ElderlyModeScreen()),
                    ),
                    child: _buildDetailTile(
                      icon: Icons.elderly_rounded,
                      label: 'Elderly Mode',
                      value: 'Accessible interface for seniors',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Activity',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
            ),
            const SizedBox(height: 16),
            PatientTimeline(patientId: widget.patientId ?? _supabase.auth.currentUser!.id),
            const SizedBox(height: 16),
          ],
        ),
      );
  }

  Widget _buildMedicalTab() {
    return PatientAnalyticsPage(patientId: widget.patientId);
  }

  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AssessmentRepository(patientId: widget.patientId ?? _supabase.auth.currentUser!.id),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.softSlate, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.softSlate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
