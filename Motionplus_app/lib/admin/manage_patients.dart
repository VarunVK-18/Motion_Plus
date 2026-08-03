import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'patient_details.dart';

class ManagePatientsPage extends StatefulWidget {
  const ManagePatientsPage({super.key});

  @override
  State<ManagePatientsPage> createState() => _ManagePatientsPageState();
}

class _ManagePatientsPageState extends State<ManagePatientsPage> {
  static const Color honeyAmber = Color(0xFFB45309);
  static const Color eliteRed = Color(0xFFBE123C);
  static const Color slate = Color(0xFF475569);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  dynamic _adminClinicId;
  dynamic _adminBranchId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminClinicId();
  }

  Future<void> _fetchAdminClinicId() async {
    try {
      final user = await ApiService.get('/profiles/me', includeAuth: true);
      if (user != null) {
        if (mounted) {
          setState(() {
            _adminClinicId = user['clinic_id'] is Map ? (user['clinic_id']['id'] ?? user['clinic_id']['_id']) : user['clinic_id'];
            _adminBranchId = user['branch_id'] is Map ? (user['branch_id']['id'] ?? user['branch_id']['_id']) : user['branch_id'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching admin clinic: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Build the patient query URL with clinic and optional branch filter
  String _buildPatientQueryUrl() {
    if (_adminClinicId == null) return '/profiles?role=patient';
    String url = '/profiles?clinic_id=$_adminClinicId&role=patient';
    if (_adminBranchId != null) {
      url += '&branch_id=$_adminBranchId';
    }
    return url;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Search patients...',
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF94A3B8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: honeyAmber))
            : _adminClinicId == null
              ? Center(
                  child: Text(
                    'No clinic assigned to this admin.',
                    style: GoogleFonts.outfit(color: slate, fontSize: 16),
                  ),
                )
              : FutureBuilder(
            future: ApiService.get(_buildPatientQueryUrl(), includeAuth: true),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: honeyAmber),
                );
              }

              var patients = snapshot.data!
                  .where((p) => p['role'] == 'patient')
                  .toList();

              if (_searchQuery.isNotEmpty) {
                patients = patients.where((p) {
                  final name = (p['full_name'] ?? '').toString().toLowerCase();
                  final phone = (p['phone'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      phone.contains(_searchQuery);
                }).toList();
              }

              if (patients.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isEmpty
                            ? Icons.person_search_rounded
                            : Icons.search_off_rounded,
                        size: 48,
                        color: slate.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No Registered Patients'
                            : 'No patients match your search',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: slate,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  final name = patient['full_name'] ?? 'Guest Patient';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFF1F5F9),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 35,
                        height: 35,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'P',
                            style: GoogleFonts.outfit(
                              color: const Color.fromARGB(255, 14, 12, 54),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          const Icon(
                            Icons.phone_rounded,
                            size: 11,
                            color: slate,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            patient['phone'] ?? '---',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: slate,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'delete') {
                            _showDeletePatientDialog(
                              context,
                              patient['id'],
                              name,
                            );
                          } else if (val == 'transfer') {
                            _showTransferDialog(
                              context,
                              patient['id'],
                              name,
                              patient['branch_id'] is Map ? (patient['branch_id']['id'] ?? patient['branch_id']['_id']) : patient['branch_id'],
                            );
                          }
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
                            value: 'transfer',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 16,
                                  color: Color(0xFF3B82F6),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Transfer Branch',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3B82F6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: eliteRed,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Remove Patient',
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientDetailsPage(
                              patientId: patient['id'],
                              patientName: name,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showTransferDialog(BuildContext context, String patientId, String name, dynamic currentBranchId) {
    String? selectedBranchId = currentBranchId;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            backgroundColor: Colors.white,
            title: Text(
              'Transfer $name',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                fontSize: 18,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select new branch for patient:', style: GoogleFonts.outfit(fontSize: 13, color: slate)),
                  const SizedBox(height: 12),
                  FutureBuilder(
                    future: ApiService.get('/branches?clinic_id=$_adminClinicId', includeAuth: true),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final branches = snapshot.data as List<dynamic>;
                      return DropdownButtonFormField<String>(
                        initialValue: selectedBranchId,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: branches.map<DropdownMenuItem<String>>((b) {
                          return DropdownMenuItem<String>(
                            value: b['id'] ?? b['_id'],
                            child: Text(b['name']),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() => selectedBranchId = val);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL', style: GoogleFonts.outfit(color: slate, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSaving ? null : () async {
                  if (selectedBranchId == null || selectedBranchId == currentBranchId) {
                    Navigator.pop(context);
                    return;
                  }
                  setModalState(() => isSaving = true);
                  try {
                    await ApiService.put('/profiles/$patientId', {'branch_id': selectedBranchId}, includeAuth: true);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient Transferred Successfully')));
                      setState(() {});
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      setModalState(() => isSaving = false);
                    }
                  }
                },
                child: isSaving 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('TRANSFER', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 11)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showDeletePatientDialog(
    BuildContext context,
    String patientId,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        title: Text(
          'Delete Records?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
        content: Text(
          'This will permanently remove treatment history for $name.',
          style: GoogleFonts.outfit(color: slate, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(
                color: slate,
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
            onPressed: () async {
              try {
                await ApiService.delete('/sessions?patient_id=$patientId', includeAuth: true);
                await ApiService.delete('/profiles/$patientId', includeAuth: true);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Records Removed Successfully'),
                    ),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: eliteRed,
                    ),
                  );
                }
              }
            },
            child: Text(
              'DELETE',
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
}
