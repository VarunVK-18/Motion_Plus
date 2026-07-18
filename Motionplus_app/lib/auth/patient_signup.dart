import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../services/api_service.dart';
import 'auth_service.dart';

class PatientSignUpPage extends StatefulWidget {
  const PatientSignUpPage({super.key});

  @override
  State<PatientSignUpPage> createState() => _PatientSignUpPageState();
}

class _PatientSignUpPageState extends State<PatientSignUpPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  List<Map<String, dynamic>> _clinics = [];
  String? _selectedClinicId;
  bool _isLoadingClinics = true;

  @override
  void initState() {
    super.initState();
    _fetchClinics();
  }

  Future<void> _fetchClinics() async {
    try {
      final response = await ApiService.get('/clinics', includeAuth: false);
      if (mounted) {
        setState(() {
          _clinics = List<Map<String, dynamic>>.from(response);
          _isLoadingClinics = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingClinics = false);
      debugPrint('Error fetching clinics: \$e');
    }
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        _firstNameController.text.isEmpty ||
        _selectedClinicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and select a clinic'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Prevent selection_page.dart from automatically redirecting us during profile creation
    AuthService.isSigningUp = true;

    try {
      final response = await ApiService.post('/auth/register', {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'patient',
        'email': email,
        'password': password,
        'clinic_id': _selectedClinicId,
      }, includeAuth: false);

      if (response != null) {
        if (response['token'] != null) {
          await ApiService.saveToken(response['token']);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration Successful!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          if (response['token'] != null) {
            await AuthService.handleRedirection(context, portal: 'patient');
          } else {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      AuthService.isSigningUp = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEFF6FF), Colors.white],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Create Your\nClient Account',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Join the platform to track your physiotherapy progress and access personalized exercise reports.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('FIRST NAME'),
                            _buildTextField(
                              controller: _firstNameController,
                              hint: 'name',
                              icon: Icons.person_outline,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('LAST NAME'),
                            _buildTextField(
                              controller: _lastNameController,
                              hint: 'surename',
                              icon: Icons.person_outline,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('EMAIL ADDRESS'),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'name@gmail.com',
                    icon: Icons.alternate_email_rounded,
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('PHONE NUMBER'),
                  _buildTextField(
                    controller: _phoneController,
                    hint: '+91 1234567890',
                    icon: Icons.phone_android_rounded,
                    type: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('SELECT CLINIC'),
                  _isLoadingClinics
                      ? const Center(child: CircularProgressIndicator())
                      : _buildDropdown(),
                  const SizedBox(height: 20),
                  _buildLabel('CREATE PASSWORD'),
                  _buildTextField(
                    controller: _passwordController,
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('CONFIRM PASSWORD'),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: '••••••••',
                    icon: Icons.lock_clock_outlined,
                    isPassword: true,
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          91,
                          128,
                          215,
                        ),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'CREATE ACCOUNT',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Already have an account? Sign In",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color.fromARGB(255, 91, 128, 215),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1.0),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: type,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: const Color(0xFFCBD5E1),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                    color: const Color(0xFF94A3B8),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1.0),
      ),
      child: DropdownButtonFormField2<String>(
        valueListenable: ValueNotifier(_selectedClinicId),
        items: _clinics.map((clinic) {
          return DropdownItem<String>(
            value: clinic['id'],
            child: Text(
              clinic['name'],
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedClinicId = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Choose your clinic',
          hintStyle: GoogleFonts.outfit(
            color: const Color(0xFFCBD5E1),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(Icons.local_hospital_rounded, size: 20, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        buttonStyleData: const FormFieldButtonStyleData(
          padding: EdgeInsets.only(right: 8),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 250,
          elevation: 0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1.0),
            color: Colors.white,
          ),
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
