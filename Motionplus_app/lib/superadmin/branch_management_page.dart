import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

/// BranchManagementPage — shown when a Superadmin taps a Clinic card.
/// Allows viewing, adding, editing, and deleting branches for that clinic.
class BranchManagementPage extends StatefulWidget {
  final String clinicId;
  final String clinicName;

  const BranchManagementPage({
    super.key,
    required this.clinicId,
    required this.clinicName,
  });

  @override
  State<BranchManagementPage> createState() => _BranchManagementPageState();
}

class _BranchManagementPageState extends State<BranchManagementPage> {
  late Future<List<dynamic>> _branchesFuture;
  bool _isLoading = false;

  // Form controllers
  final _nameController    = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController   = TextEditingController();
  final _emailController   = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadBranches() {
    setState(() {
      _branchesFuture = ApiService.get(
        '/branches?clinic_id=${widget.clinicId}',
        includeAuth: true,
      ).then((data) => data as List<dynamic>);
    });
  }

  void _clearControllers() {
    _nameController.clear();
    _addressController.clear();
    _phoneController.clear();
    _emailController.clear();
  }

  // ──────────────────────────────────────────────────────────
  // Add / Edit Branch Dialog
  // ──────────────────────────────────────────────────────────
  void _showBranchDialog({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    if (isEdit) {
      _nameController.text    = existing['name'] ?? '';
      _addressController.text = existing['address'] ?? '';
      _phoneController.text   = existing['phone'] ?? '';
      _emailController.text   = existing['email'] ?? '';
    } else {
      _clearControllers();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_location_alt_rounded,
                    color: Color(0xFF3B82F6), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Edit Branch' : 'Add New Branch',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _buildField(_nameController, 'Branch Name - Location *',
                    Icons.business_rounded),
                _buildField(_addressController, 'Address',
                    Icons.location_on_rounded),
                _buildField(_phoneController, 'Phone Number',
                    Icons.phone_rounded,
                    inputType: TextInputType.phone),
                _buildField(_emailController, 'Email',
                    Icons.email_outlined,
                    inputType: TextInputType.emailAddress),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => isEdit
                            ? _updateBranch(existing['id'] ?? existing['_id'], ctx)
                            : _createBranch(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            isEdit ? 'Save Changes' : 'Add Branch',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // API calls
  // ──────────────────────────────────────────────────────────
  Future<void> _createBranch(BuildContext ctx) async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Branch name is required', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.post('/branches', {
        'name':     _nameController.text.trim(),
        'clinic_id': widget.clinicId,
        'address':  _addressController.text.trim(),
        'phone':    _phoneController.text.trim(),
        'email':    _emailController.text.trim(),
      }, includeAuth: true);

      if (ctx.mounted) {
        Navigator.pop(ctx);
        _clearControllers();
        _loadBranches();
        _showSnack('Branch added successfully!');
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBranch(String branchId, BuildContext ctx) async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Branch name is required', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.put('/branches/$branchId', {
        'name':    _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone':   _phoneController.text.trim(),
        'email':   _emailController.text.trim(),
      });

      if (ctx.mounted) {
        Navigator.pop(ctx);
        _clearControllers();
        _loadBranches();
        _showSnack('Branch updated successfully!');
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBranch(String branchId, String branchName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Branch',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "$branchName"?\n\nThis will fail if any users or sessions are still linked to this branch.',
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.delete('/branches/$branchId');
      _loadBranches();
      _showSnack('Branch deleted successfully!');
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  // ──────────────────────────────────────────────────────────
  // Build helpers
  // ──────────────────────────────────────────────────────────
  Widget _buildField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: inputType,
        style: GoogleFonts.outfit(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon,
              color: Theme.of(context).colorScheme.primary, size: 20),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.04)
              : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Branches',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            Text(
              widget.clinicName,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBranchDialog(),
        backgroundColor: const Color(0xFF3B82F6),
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _branchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text('Could not load branches',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, color: Colors.red)),
                  TextButton(
                    onPressed: _loadBranches,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final branches = snapshot.data
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [];

          if (branches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_mall_directory_outlined,
                      size: 64,
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No branches yet',
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Text('Tap "Add Branch" to create the first location.',
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: const Color(0xFF94A3B8))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: branches.length,
            itemBuilder: (context, index) {
              final branch = branches[index];
              return _buildBranchCard(branch);
            },
          );
        },
      ),
    );
  }

  Widget _buildBranchCard(Map<String, dynamic> branch) {
    final branchId = branch['id'] ?? branch['_id'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.store_rounded,
                  color: Color(0xFF3B82F6), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch['name'] ?? 'Unnamed Branch',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (branch['address'] != null &&
                      branch['address'].toString().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            branch['address'],
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (branch['phone'] != null &&
                      branch['phone'].toString().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Text(
                          branch['phone'],
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Edit button
            IconButton(
              onPressed: () => _showBranchDialog(existing: branch),
              icon: const Icon(Icons.edit_outlined,
                  color: Color(0xFF3B82F6), size: 20),
              tooltip: 'Edit branch',
            ),
            // Delete button
            IconButton(
              onPressed: () =>
                  _deleteBranch(branchId, branch['name'] ?? 'this branch'),
              icon:
                  const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              tooltip: 'Delete branch',
            ),
          ],
        ),
      ),
    );
  }
}
