import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ClinicManagementPage extends StatefulWidget {
  const ClinicManagementPage({super.key});

  @override
  State<ClinicManagementPage> createState() => _ClinicManagementPageState();
}

class _ClinicManagementPageState extends State<ClinicManagementPage> {
  bool _isLoading = false;
  late Future<List<dynamic>> _clinicsFuture;

  // Controllers for the form
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  void _loadClinics() {
    setState(() {
      _clinicsFuture = ApiService.get('/clinics', includeAuth: true).then((data) => data as List<dynamic>);
    });
  }

  Future<void> _addClinic() async {
    // Basic Validation
    if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Address are required'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.post('/clinics', {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
      }, includeAuth: true);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        _clearControllers();
        _loadClinics();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New branch added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: \$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearControllers() {
    _nameController.clear();
    _addressController.clear();
    _phoneController.clear();
  }

  void _showAddClinicDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
            'Register New Branch',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(_nameController, 'Clinic Name', Icons.business_rounded),
              _buildTextField(_addressController, 'Full Address', Icons.location_on_rounded),
              _buildTextField(_phoneController, 'Contact Number', Icons.phone_rounded, type: TextInputType.phone),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _addClinic,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Add Branch', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: GoogleFonts.outfit(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          prefixIcon: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.03)
              : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Clinic Management', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddClinicDialog,
            icon: Icon(Icons.add_business_rounded, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _clinicsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 48, color: Colors.redAccent.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Connection Error',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.redAccent),
                  ),
                  Text(
                    'Please check your internet or backend',
                    style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  TextButton(onPressed: _loadClinics, child: const Text('Retry'))
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final clinics = (snapshot.data)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];
          if (clinics.isEmpty) return _buildEmptyState();
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clinics.length,
            itemBuilder: (context, index) {
              final clinic = clinics[index];
              return _buildClinicCard(clinic);
            },
          );
        },
      ),
    );
  }

  Widget _buildClinicCard(dynamic clinic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.business_rounded, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          clinic['name'] ?? 'Unnamed Clinic',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    clinic['address'] ?? 'No address provided',
                    style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  clinic['phone'] ?? 'No phone',
                  style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          onPressed: () async {
            try {
              await ApiService.delete("/clinics/${clinic['id']}");
              _loadClinics();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Clinic deleted successfully'), backgroundColor: Colors.green),
                );
              }
            } catch (e) {
               if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: \$e'), backgroundColor: Colors.red),
                  );
               }
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.blue.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text('No Clinics Added Yet', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddClinicDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Clinic'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
