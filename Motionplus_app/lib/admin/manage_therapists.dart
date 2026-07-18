import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:hugeicons/hugeicons.dart';

class ManageTherapistsPage extends StatefulWidget {
  const ManageTherapistsPage({super.key});

  @override
  State<ManageTherapistsPage> createState() => _ManageTherapistsPageState();
}

class _ManageTherapistsPageState extends State<ManageTherapistsPage> {
  Map<String, dynamic>? currentUser;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final ValueNotifier<String?> _selectedSpecialization = ValueNotifier<String?>(
    null,
  );
  bool _obscurePassword = true;
  String _filterCategory = 'All';
  dynamic _adminClinicId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminClinicId();
  }

  Future<void> _fetchAdminClinicId() async {
    try {
      final user = await ApiService.get('/auth/me', includeAuth: true);
      if (mounted) {
        setState(() {
          currentUser = user;
          _adminClinicId = user['clinic_id'] is Map ? (user['clinic_id']['id'] ?? user['clinic_id']['_id']) : user['clinic_id'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin clinic: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final List<String> _categories = [
    'All',
    'Ortho',
    'Neuro',
    'Pediatrics',
    'Cardio',
    'Psychology',
    'Speech',
    'Sensory Integration',
  ];
  final List<String> _allSpecializations = [
    'Ortho',
    'Neuro',
    'Pediatrics',
    'Cardio',
    'Psychology',
    'Speech',
    'Sensory Integration',
  ];

  static const Color primaryGreen = Color(0xFF2D6A4F);
  static const Color softSage = Color(0xFFF0FAF7);
  static const Color eliteRed = Color(0xFF991B1B);

  @override
  void dispose() {
    _selectedSpecialization.dispose();
    super.dispose();
  }

  Future<void> _addTherapist() async {
    if (_emailController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _selectedSpecialization.value == null) {
      _showError(
        'Please fill in all details and select a specialization to proceed.',
      );
      return;
    }
    
    if (_adminClinicId == null) {
      _showError('No clinic assigned to your admin account. Cannot create therapist.');
      return;
    }

    if (_passwordController.text.trim().length < 6) {
      _showError('Password must be at least 6 characters long for security.');
      return;
    }

    try {
      final names = _nameController.text.trim().split(' ');
      final firstName = names[0];
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : 'Therapist';
      
      final response = await ApiService.post('/auth/register', {
        'first_name': firstName,
        'last_name': lastName,
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'therapist',
        'specialization': _selectedSpecialization.value!.toLowerCase(),
        'clinic_id': _adminClinicId,
      });

      if (response != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Therapist Added Successfully!'),
              backgroundColor: primaryGreen,
            ),
          );
          _clearControllers();
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Registration Error: $e');
      }
    }
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

  Future<void> _updateTherapist(String id) async {
    try {
      await ApiService.put('/profiles/$id', {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      }, includeAuth: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile Updated!'),
            backgroundColor: primaryGreen,
          ),
        );
        _clearControllers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update Error: $e'),
            backgroundColor: eliteRed,
          ),
        );
      }
    }
  }

  Future<void> _deleteTherapist(String id) async {
    try {
      await ApiService.delete('/profiles/$id', includeAuth: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff Removed'),
            backgroundColor: Color(0xFF475569),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete Error: $e'),
            backgroundColor: eliteRed,
          ),
        );
      }
    }
  }

  void _clearControllers() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _phoneController.clear();
    _selectedSpecialization.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildFilterBar(),
              Expanded(child: _buildStaffList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Directory',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Manage clinical therapists.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showAddDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: primaryGreen,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              'ADD',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _filterCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) => setState(() => _filterCategory = cat),
              selectedColor: primaryGreen,
              backgroundColor: Colors.white,
              labelStyle: GoogleFonts.outfit(
                fontSize: 12,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              showCheckmark: false,
              elevation: isSelected ? 1 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaffList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryGreen));
    }
    if (_adminClinicId == null) {
      return Center(
        child: Text(
          'No clinic assigned to this admin.',
          style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 16),
        ),
      );
    }
    return FutureBuilder(
      future: _adminClinicId != null
          ? ApiService.get('/profiles?role=therapist&clinic_id=$_adminClinicId', includeAuth: true)
          : ApiService.get('/profiles?role=therapist', includeAuth: true),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: primaryGreen),
          );
        }

        var staff = (snapshot.data as List<dynamic>)
            .where((s) {
              final sClinicId = s['clinic_id'] is Map ? (s['clinic_id']['id'] ?? s['clinic_id']['_id']) : s['clinic_id'];
              return (_adminClinicId == null || sClinicId == _adminClinicId) && s['role'] == 'therapist';
            })
            .toList();
        if (_filterCategory != 'All') {
          staff = staff
              .where(
                (s) => s['specialization'] == _filterCategory.toLowerCase(),
              )
              .toList();
        }

        if (staff.isEmpty) {
          return Center(
            child: Text(
              'No therapists found',
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontSize: 13,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
          itemCount: staff.length,
          itemBuilder: (context, index) {
            final person = staff[index];
            return _buildStaffCard(person);
          },
        );
      },
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> person) {
    final spec = person['specialization']?.toString().toUpperCase() ?? 'N/A';
    final id = person['id'].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: softSage,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedDoctor01,
                  color: primaryGreen,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person['full_name'] ?? 'Therapist',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'THERAPIST',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          spec,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                      Text(
                        person['phone'] ?? '---',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '•',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        person['email'] ?? 'No Email',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(person);
                } else if (value == 'remove')
                  _showDeleteConfirm(id, person['full_name']);
              },
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFFCBD5E1),
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Edit Details',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: eliteRed,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Remove',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: eliteRed,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(String id, String? name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Remove Staff?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to remove ${name ?? "this staff"}?',
          style: GoogleFonts.outfit(
            color: const Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: eliteRed,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteTherapist(id);
            },
            child: Text(
              'REMOVE',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> person) {
    _nameController.text = person['full_name'] ?? '';
    _phoneController.text = person['phone'] ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
          32,
          32,
          32,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Edit Details',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('FULL NAME'),
              _buildDialogField(
                _nameController,
                'Name',
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              _buildLabel('PHONE NUMBER'),
              _buildDialogField(_phoneController, 'Phone', Icons.phone_rounded),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _updateTherapist(person['id']);
                  },
                  child: Text(
                    'SAVE CHANGES',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    _clearControllers();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
          32,
          32,
          32,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Register Staff',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('FULL NAME'),
              _buildDialogField(
                _nameController,
                'Therapist Name',
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              _buildLabel('EMAIL ADDRESS'),
              _buildDialogField(
                _emailController,
                'Therapist Email',
                Icons.alternate_email_rounded,
              ),
              const SizedBox(height: 14),
              _buildLabel('PHONE NUMBER'),
              _buildDialogField(
                _phoneController,
                'Therapist Phone Number',
                Icons.phone_rounded,
              ),
              const SizedBox(height: 14),
              _buildLabel('SECURE PASSWORD'),
              _buildDialogField(
                _passwordController,
                '••••••••',
                Icons.lock_outline_rounded,
                obscure: true,
              ),
              const SizedBox(height: 14),
              _buildLabel('SPECIALIZATION'),
              _buildModernDropdown(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _addTherapist();
                  },
                  child: Text(
                    'CREATE ACCOUNT',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdown() {
    final List<String> itemsList = [
      'Ortho',
      'Neuro',
      'Pediatrics',
      'Cardio',
      'Psychology',
      'Speech',
      'Sensory Integration',
    ];

    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Text(
          'Select Category',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
        items: itemsList
            .map(
              (String item) => DropdownItem<String>(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            )
            .toList(),
        valueListenable: _selectedSpecialization,
        onChanged: (String? value) {
          _selectedSpecialization.value = value;
        },
        buttonStyleData: ButtonStyleData(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            color: const Color(0xFFF8FAFC),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          offset: const Offset(0, -6),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure ? _obscurePassword : false,
        style: GoogleFonts.outfit(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          suffixIcon: obscure
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
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
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
