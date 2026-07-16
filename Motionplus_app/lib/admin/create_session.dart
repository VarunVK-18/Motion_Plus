import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'patient_details.dart';

class CreateSessionPage extends StatefulWidget {
  const CreateSessionPage({super.key});

  @override
  State<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends State<CreateSessionPage> {
  final _supabase = Supabase.instance.client;
  final _feeController = TextEditingController();

  final ValueNotifier<String?> _selectedPatientId = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<String?> _selectedSpecialization = ValueNotifier<String?>(
    'Ortho',
  );
  final ValueNotifier<String?> _selectedLocation = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _selectedPackage = ValueNotifier<String?>(null);

  bool _isLoading = false;
  dynamic _adminClinicId;

  Map<String, String> _livePackages = {
    'Session-based Packages': '500',
    'Monthly Rehab Packages': '15000',
    'Pediatric Therapy Packages': 'Custom',
    'Hybrid Therapy Packages': 'Flexible',
    'Online Consulting': '999',
  };

  final List<String> _specializations = [
    'Ortho',
    'Neuro',
    'Pediatrics',
    'Cardio',
    'Psychology',
    'Speech',
    'Sensory Integration',
  ];

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAdminClinicId();
    _selectedPackage.addListener(() {
      final pkg = _selectedPackage.value;
      if (pkg != null) {
        final price = _livePackages[pkg];
        if (price != null && price != 'Custom' && price != 'Flexible') {
          _feeController.text = price;
        } else {
          _feeController.clear();
        }
      }
    });
  }

  Future<void> _fetchAdminClinicId() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await _supabase.from('profiles').select('clinic_id').eq('id', user.id).single();
        if (mounted) {
          setState(() {
            _adminClinicId = data['clinic_id'];
          });
        }
      } catch (e) {
        debugPrint('Error fetching admin clinic: $e');
      }
    }
  }

  @override
  void dispose() {
    _selectedPatientId.dispose();
    _selectedSpecialization.dispose();
    _selectedLocation.dispose();
    _selectedPackage.dispose();
    _feeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    if (_selectedPatientId.value == null || _feeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.from('sessions').insert({
        'patient_id': _selectedPatientId.value,
        'clinic_id': _adminClinicId, // Assign to Admin's clinic
        'specialization_required':
            _selectedSpecialization.value?.toLowerCase() ?? 'ortho',
        'fee_charged': double.parse(_feeController.text),
        'status': 'pending',
        'location': _selectedLocation.value ?? 'TBD',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session Request Created!'),
            backgroundColor: Color(0xFF2D6A4F),
          ),
        );
        _feeController.clear();
        _selectedPatientId.value = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFBE123C),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRegistry(String title, String role, Color themeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
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
              'Clinic $title',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder(
                future: _adminClinicId != null 
                  ? _supabase
                      .from('profiles')
                      .select('id, full_name, phone, specialization, email')
                      .eq('role', role)
                      .eq('clinic_id', _adminClinicId!)
                  : _supabase
                      .from('profiles')
                      .select('id, full_name, phone, specialization, email')
                      .eq('role', role),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snapshot.data as List<dynamic>;
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'No $title found.',
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final person = list[index];
                      final name = person['full_name'] ?? 'Unknown';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: themeColor.withOpacity(0.08),
                          child: Text(
                            name[0].toUpperCase(),
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          person['phone'] ?? '---',
                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFCBD5E1),
                          size: 18,
                        ),
                        onTap: () {
                          if (role == 'patient') {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientDetailsPage(
                                  patientId: person['id'].toString(),
                                  patientName: name,
                                ),
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Text(
                                  'Staff Details',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Name: $name', style: GoogleFonts.outfit(fontSize: 15)),
                                    const SizedBox(height: 8),
                                    Text('Email: ${person['email'] ?? 'No Email'}', style: GoogleFonts.outfit(fontSize: 15)),
                                    const SizedBox(height: 8),
                                    Text('Phone: ${person['phone'] ?? '---'}', style: GoogleFonts.outfit(fontSize: 15)),
                                    const SizedBox(height: 8),
                                    Text('Specialization: ${(person['specialization'] ?? 'N/A').toString().toUpperCase()}', style: GoogleFonts.outfit(fontSize: 15)),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('CLOSE', style: GoogleFonts.outfit(color: const Color(0xFF334155), fontWeight: FontWeight.w600)),
                                  )
                                ],
                              )
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _supabase.auth.currentUser;
    final adminName = currentUser?.userMetadata?['full_name'] ?? 'Admin';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, $adminName!',
            style: GoogleFonts.outfit(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'New Session Request',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSectionTitle('Select Patient', Icons.person_search),
                FutureBuilder(
                  future: _adminClinicId != null
                    ? _supabase
                        .from('profiles')
                        .select()
                        .eq('role', 'patient')
                        .eq('clinic_id', _adminClinicId)
                    : _supabase
                        .from('profiles')
                        .select()
                        .eq('role', 'patient'),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Error loading patients: ${snapshot.error}',
                          style: GoogleFonts.outfit(color: Colors.red, fontSize: 12),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final patients = snapshot.data as List<dynamic>;
                    if (patients.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No patients found in your clinic.',
                          style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      );
                    }
                    return _buildModernDropdown(
                      hint: 'Choose from list',
                      listenable: _selectedPatientId,
                      items: patients
                          .map(
                            (p) => DropdownItem<String>(
                              value: p['id'].toString(),
                              child: Text(p['full_name'] ?? 'Unknown'),
                            ),
                          )
                          .toList(),
                      showSearch: true,
                    );
                  },
                ),
                const SizedBox(height: 18),
                _buildSectionTitle(
                  'Specialization Needed',
                  Icons.medical_services_outlined,
                ),
                _buildModernDropdown(
                  hint: 'Select category',
                  listenable: _selectedSpecialization,
                  items: _specializations
                      .map(
                        (s) => DropdownItem<String>(value: s, child: Text(s)),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                _buildSectionTitle(
                  'Clinic Location',
                  Icons.location_on_outlined,
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _supabase.from('clinics').select().order('name'),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final clinics = snapshot.data ?? [];
                    return _buildModernDropdown(
                      hint: 'Select Clinic Location',
                      listenable: _selectedLocation,
                      items: clinics.map((c) {
                        return DropdownItem<String>(
                          value: c['name'],
                          child: Text(c['name'] ?? 'Unnamed Clinic'),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _buildSectionTitle('Payment Package', Icons.local_offer_outlined),
                StreamBuilder(
                  stream: _supabase.from('platform_settings').stream(primaryKey: ['id']),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final settings = {
                        for (var s in (snapshot.data as List)) s['key']: s['value'],
                      };
                      _livePackages = {
                        'Session-based Packages': settings['pkg_Session-based Packages']?.toString() ?? '500',
                        'Monthly Rehab Packages': settings['pkg_Monthly Rehab Packages']?.toString() ?? '15000',
                        'Pediatric Therapy Packages': settings['pkg_Pediatric Therapy Packages']?.toString() ?? 'Custom',
                        'Hybrid Therapy Packages': settings['pkg_Hybrid Therapy Packages']?.toString() ?? 'Flexible',
                        'Online Consulting': settings['pkg_Online Consulting']?.toString() ?? '999',
                      };
                    }

                    return _buildModernDropdown(
                      hint: 'Select Package',
                      listenable: _selectedPackage,
                      items: _livePackages.keys.map((pkg) {
                        final price = _livePackages[pkg]!;
                        final displayPrice = (double.tryParse(price.replaceAll(',', '')) != null) ? '₹$price' : price;
                        return DropdownItem<String>(
                          value: pkg,
                          child: Text('$pkg - $displayPrice'),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _buildSectionTitle('Service Fee (₹)', Icons.payments_outlined),
                TextField(
                  controller: _feeController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  decoration: _inputDecoration('Enter amount in Rupees')
                      .copyWith(
                        prefixIcon: const Icon(Icons.currency_rupee, size: 16),
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E84DC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'CREATE REQUEST',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Text(
            'Clinic Registry',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildClickableCard(
                  'Therapists',
                  'therapist_assistant',
                  Icons.medical_services_rounded,
                  const Color(0xFF2D6A4F),
                  const Color(0xFFF0FAF7),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildClickableCard(
                  'Patients',
                  'patient',
                  Icons.people_alt_rounded,
                  const Color(0xFFB45309),
                  const Color(0xFFFFFBEB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildClickableCard(
    String title,
    String role,
    IconData icon,
    Color themeColor,
    Color bgColor,
  ) {
    return StreamBuilder(
      stream: _supabase
          .from('profiles')
          .stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        var count = 0;
        if (snapshot.hasData) {
          final list = snapshot.data as List<dynamic>;
          count = list.where((p) => p['role'] == role && (_adminClinicId == null || p['clinic_id'] == _adminClinicId)).length;
        }
        return InkWell(
          onTap: () => _showRegistry(title, role, themeColor),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: themeColor.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, color: themeColor, size: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  '$count',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: themeColor.withOpacity(0.8),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: themeColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernDropdown({
    required String hint,
    required ValueNotifier<String?> listenable,
    required List<DropdownItem<String>> items,
    bool showSearch = false,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Text(
          hint,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
        items: items,
        valueListenable: listenable,
        onChanged: (val) => listenable.value = val,
        buttonStyleData: ButtonStyleData(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            color: const Color(0xFFF8FAFC),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          offset: const Offset(0, -6),
        ),
        dropdownSearchData: showSearch
            ? DropdownSearchData(
                searchController: _searchController,
                searchBarWidgetHeight: 50,
                searchBarWidget: Container(
                  height: 50,
                  padding: const EdgeInsets.only(
                    top: 8,
                    bottom: 4,
                    right: 8,
                    left: 8,
                  ),
                  child: TextFormField(
                    expands: true,
                    maxLines: null,
                    controller: _searchController,
                    style: GoogleFonts.outfit(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      hintText: 'Search patient...',
                      hintStyle: GoogleFonts.outfit(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.search, size: 16),
                    ),
                  ),
                ),
                searchMatchFn: (item, searchValue) {
                  final itemText = (item.child as Text).data ?? '';
                  return itemText.toLowerCase().contains(
                    searchValue.toLowerCase(),
                  );
                },
              )
            : null,
        onMenuStateChange: (isOpen) {
          if (!isOpen) {
            _searchController.clear();
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF3E84DC)),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(
        fontSize: 13,
        color: const Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3E84DC), width: 1.5),
      ),
    );
  }
}
