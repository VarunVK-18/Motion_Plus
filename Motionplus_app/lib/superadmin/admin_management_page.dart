import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../services/api_service.dart';

class AdminManagementPage extends StatefulWidget {
  const AdminManagementPage({super.key});

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  bool _isLoading = false;
  String _searchQuery = '';
  bool _obscurePassword = true;

  late Future<List<dynamic>> _adminsFuture;

  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedClinicId;
  List<dynamic> _clinics = [];

  @override
  void initState() {
    super.initState();
    _fetchClinics();
    _loadAdmins();
  }

  void _loadAdmins() {
    setState(() {
      _adminsFuture = ApiService.get('/profiles?role=admin', includeAuth: true)
          .then((data) => data as List<dynamic>);
    });
  }

  Future<void> _fetchClinics() async {
    try {
      final response = await ApiService.get('/clinics', includeAuth: true);
      if (mounted) {
        setState(() {
          _clinics = response;
        });
      }
    } catch (e) {
      debugPrint('Error fetching clinics: \$e');
    }
  }

  void _showCreateAdminDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUserAdd02,
                  color: Color(0xFF0F172A),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Register New Admin',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'Create system access for a new branch',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _buildTextField(
                  _nameController,
                  'Full Name',
                  HugeIcons.strokeRoundedUser,
                ),
                _buildTextField(
                  _emailController,
                  'Email Address',
                  HugeIcons.strokeRoundedMail01,
                  type: TextInputType.emailAddress,
                ),
                _buildTextField(
                  _phoneController,
                  'Phone Number',
                  HugeIcons.strokeRoundedSmartPhone01,
                  type: TextInputType.phone,
                ),
                _buildClinicDropdown(setModalState),
                _buildTextField(
                  _passwordController,
                  'Create Password',
                  HugeIcons.strokeRoundedLockPassword,
                  isPassword: true,
                  setModalState: setModalState,
                ),
                _buildTextField(
                  _confirmPasswordController,
                  'Confirm Password',
                  HugeIcons.strokeRoundedLockKey,
                  isPassword: true,
                  setModalState: setModalState,
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _registerAdmin(setModalState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Register Admin',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerAdmin(StateSetter setModalState) async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty ||
        _selectedClinicId == null) {
      _showError('Please fill in all details and select a clinic to proceed');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showError('Please enter a valid email address');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setModalState(() => _isLoading = true);

    try {
      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Admin';

      await ApiService.post('/auth/register', {
        'first_name': firstName,
        'last_name': lastName,
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'admin',
        'clinic_id': _selectedClinicId,
      }, includeAuth: false);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        _showSuccess('Admin registered successfully!');
        _clearControllers();
        _loadAdmins();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setModalState(() => _isLoading = false);
      }
    }
  }

  void _clearControllers() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _selectedClinicId = null;
    });
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
                color: Color(0xFFBE123C),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Action Required',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: const Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'UNDERSTOOD',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    dynamic icon, {
    bool isPassword = false,
    TextInputType type = TextInputType.text,
    StateSetter? setModalState,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: type,
        style: GoogleFonts.outfit(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: _renderIcon(icon, const Color(0xFF64748B), 20),
          ),
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
                    if (setModalState != null) {
                      setModalState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    } else {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    }
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.03)
              : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _renderIcon(dynamic icon, Color color, double size) {
    if (icon is IconData && icon.fontFamily == 'MaterialIcons') {
      return Icon(icon, color: color, size: size);
    }
    return HugeIcon(icon: icon, color: color, size: size);
  }

  Widget _buildClinicDropdown(StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField2<String>(
        valueListenable: ValueNotifier(_selectedClinicId),
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: HugeIcon(icon: HugeIcons.strokeRoundedHospital01, color: Color(0xFF64748B), size: 20),
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.03)
              : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        hint: Text('Select Clinic Location', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14)),
        items: _clinics.map((clinic) {
          return DropdownItem<String>(
            value: clinic['id'].toString(),
            child: Text(clinic['name'] ?? 'Unknown Clinic', style: GoogleFonts.outfit(fontSize: 15)),
          );
        }).toList(),
        onChanged: (value) {
          setModalState(() {
            _selectedClinicId = value;
          });
        },
        buttonStyleData: const FormFieldButtonStyleData(
          padding: EdgeInsets.only(right: 8),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Admin Management',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showCreateAdminDialog,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedUserAdd02,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBox(),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _adminsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded, size: 48, color: Colors.redAccent.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'Connection Error',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.redAccent),
                          ),
                          Text(
                            'Please check your network: \${snapshot.error}',
                            style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final admins = (snapshot.data as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];

                  // Local Filtering for responsive search
                  final filteredAdmins = admins.where((admin) {
                    final name = (admin['full_name'] ?? '')
                        .toString()
                        .toLowerCase();
                    final email = (admin['email'] ?? '')
                        .toString()
                        .toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    return name.contains(query) || email.contains(query);
                  }).toList();

                  if (filteredAdmins.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    itemCount: filteredAdmins.length,
                    itemBuilder: (context, index) =>
                        _buildAdminCard(filteredAdmins[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateAdminDialog,
        backgroundColor: const Color(0xFF0F172A),
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedUserAdd02,
          color: Colors.white,
          size: 24,
        ),
        label: Text(
          'Add Clinic Admin',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            size: 64,
            color: const Color(0xFF0F172A).withOpacity(0.05),
          ),
          const SizedBox(height: 16),
          Text(
            'No Admins Found',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search admins...',
          hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 10),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedUserSearch01,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 20,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> admin) {
    // We populated clinic_id in backend, so it might be an object instead of ID
    final clinicObj = admin['clinic_id'];
    final clinicName = clinicObj != null && clinicObj is Map ? clinicObj['name'] : 'Unassigned Clinic';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 2,
      shadowColor: Colors.black.withOpacity(0.03),
      color: Theme.of(context).cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedUserCheck01,
            color: Theme.of(context).colorScheme.primary,
            size: 18,
          ),
        ),
        title: Text(
          admin['full_name'] ?? admin['email'] ?? 'Unnamed Admin',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          "Admin • ${admin['phone'] ?? 'No Phone'}\n$clinicName",
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedDelete01,
            color: Color.fromARGB(255, 247, 133, 133),
            size: 20,
          ),
          onPressed: () => _deleteAdmin(admin),
        ),
      ),
    );
  }

  Future<void> _deleteAdmin(Map<String, dynamic> admin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedUserRemove01,
                color: Color.fromARGB(255, 235, 112, 143),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Admin?',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          "This will permanently delete \${admin['full_name'] ?? 'this account'} and revoke all system access. This action cannot be undone.",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBE123C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'DELETE',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);

        await ApiService.delete("/profiles/${admin['id']}", includeAuth: true);

        if (mounted) {
          _showSuccess('Admin deleted permanently');
          _loadAdmins();
        }
      } catch (e) {
        if (mounted) {
          _showError('Error deleting admin: \$e');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
