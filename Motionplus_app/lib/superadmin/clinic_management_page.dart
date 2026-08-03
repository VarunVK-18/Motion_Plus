import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'branch_management_page.dart';


class ClinicManagementPage extends StatefulWidget {
  const ClinicManagementPage({super.key});

  @override
  State<ClinicManagementPage> createState() => _ClinicManagementPageState();
}

class _ClinicManagementPageState extends State<ClinicManagementPage> {
  bool _isLoading = false;
  late Future<List<dynamic>> _clinicsFuture;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _expiryDate;
  bool _codeManuallyEdited = false;

  @override
  void initState() {
    super.initState();
    _loadClinics();
    
    _nameController.addListener(() {
      if (!_codeManuallyEdited) {
        String name = _nameController.text.trim();
        String prefix = name.replaceAll(RegExp(r'[^A-Za-z]'), '');
        if (prefix.length > 3) prefix = prefix.substring(0, 3);
        if (prefix.isEmpty) prefix = 'CLI';
        _codeController.text = '${prefix.toUpperCase()}@1';
      }
    });
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
        'company_code': _codeController.text.trim(),
        'amount_paid': double.tryParse(_amountController.text.trim()) ?? 0,
        if (_expiryDate != null) 'subscription_expiry': _expiryDate!.toIso8601String(),
      }, includeAuth: true);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        _clearControllers();
        _loadClinics();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New clinic added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
    _codeController.clear();
    _amountController.clear();
    _expiryDate = null;
    _codeManuallyEdited = false;
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
            'Register New Clinic',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(_nameController, 'Clinic Name', Icons.business_rounded),
              _buildTextField(_codeController, 'Company Code (Auto-generated)', Icons.tag_rounded, onChanged: (val) {
                if (val.isNotEmpty) {
                  _codeManuallyEdited = true;
                }
              }),
              _buildTextField(_addressController, 'Full Address', Icons.location_on_rounded),
              _buildTextField(_phoneController, 'Contact Number', Icons.phone_rounded, type: TextInputType.phone),
              _buildTextField(_amountController, 'Amount Paid (₹)', Icons.currency_rupee_rounded, type: const TextInputType.numberWithOptions(decimal: true)),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setModalState(() => _expiryDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _expiryDate != null ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}' : 'Select Expiry Date',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: _expiryDate != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                : Text('Add Clinic', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType type = TextInputType.text, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        onChanged: onChanged,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClinicDialog,
        backgroundColor: const Color(0xFF3B82F6),
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
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
    final clinicId = clinic['id'] ?? clinic['_id'] ?? '';
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
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BranchManagementPage(
                clinicId: clinicId,
                clinicName: clinic['name'] ?? 'Clinic',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.business_rounded,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic['name'] ?? 'Unnamed Clinic',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    if (clinic['company_code'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Code: ${clinic['company_code']}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Builder(
                      builder: (context) {
                        final expiryStr = clinic['subscription_expiry'];
                        if (expiryStr == null) {
                          return Text('No Expiry Set', style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange));
                        }
                        final expiryDate = DateTime.tryParse(expiryStr.toString());
                        if (expiryDate == null) return const SizedBox.shrink();
                        
                        final daysLeft = expiryDate.difference(DateTime.now()).inDays;
                        final isExpiringSoon = daysLeft <= 30;
                        final isExpired = daysLeft < 0;
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isExpired ? Colors.red.withValues(alpha: 0.1) : (isExpiringSoon ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isExpired ? 'Expired' : (isExpiringSoon ? 'Expiring in $daysLeft days' : 'Active (Valid for $daysLeft days)'),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isExpired ? Colors.red : (isExpiringSoon ? Colors.orange : Colors.green),
                            ),
                          ),
                        );
                      }
                    ),
                    if (clinic['address'] != null) ...[
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.location_on_outlined,
                            size: 13,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            clinic['address'],
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Tap to manage branches →',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.autorenew_rounded, color: Color(0xFF3B82F6)),
                tooltip: 'Renew Subscription',
                onPressed: () => _showRenewDialog(clinicId, clinic['name']),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                onSelected: (value) async {
                  if (value == 'suspend') {
                    final isSuspended = clinic['subscription_status'] == 'suspended';
                    try {
                      await ApiService.put('/clinics/$clinicId', {
                        'subscription_status': isSuspended ? 'active' : 'suspended'
                      });
                      _loadClinics();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isSuspended ? 'Clinic activated!' : 'Clinic suspended!'),
                            backgroundColor: isSuspended ? Colors.green : Colors.orange,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Toggle error: $e');
                    }
                  } else if (value == 'delete') {
                    try {
                      await ApiService.delete('/clinics/$clinicId');
                      _loadClinics();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Clinic deleted successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'suspend',
                    child: Row(
                      children: [
                        Icon(clinic['subscription_status'] == 'suspended' ? Icons.play_circle_outline : Icons.pause_circle_outline, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(clinic['subscription_status'] == 'suspended' ? 'Activate Clinic' : 'Suspend Clinic'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Delete Clinic', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenewDialog(String clinicId, String? clinicName) {
    final renewAmountController = TextEditingController();
    int additionalMonths = 12;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Renew ${clinicName ?? 'Clinic'}', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(renewAmountController, 'Renewal Amount Paid (₹)', Icons.currency_rupee_rounded, type: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text('Extend by:', style: GoogleFonts.outfit(fontSize: 14)),
                  const Spacer(),
                  DropdownButton<int>(
                    value: additionalMonths,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 Month')),
                      DropdownMenuItem(value: 6, child: Text('6 Months')),
                      DropdownMenuItem(value: 12, child: Text('1 Year')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => additionalMonths = val);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await ApiService.post('/clinics/$clinicId/renew', {
                    'amount_paid': double.tryParse(renewAmountController.text.trim()) ?? 0,
                    'additional_months': additionalMonths,
                  }, includeAuth: true);
                  _loadClinics();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription renewed successfully!'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error renewing: $e'), backgroundColor: Colors.red));
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('Renew Now'),
            ),
          ],
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
