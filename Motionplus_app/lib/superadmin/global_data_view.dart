import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:hugeicons/hugeicons.dart';
import '../admin/patient_details.dart';
import '../admin/therapist_details.dart';

class GlobalDataView extends StatefulWidget {
  const GlobalDataView({super.key});

  @override
  State<GlobalDataView> createState() => _GlobalDataViewState();
}

class _GlobalDataViewState extends State<GlobalDataView>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          ' People Database',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Staff & Therapists'),
            Tab(text: 'All Patients'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(['therapist', 'therapist_assistant']),
          _buildUserList(['patient']),
        ],
      ),
    );
  }

  Widget _buildUserList(List<String> roles) {
    return FutureBuilder(
      future: ApiService.get('/profiles', includeAuth: true),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, size: 48, color: Colors.redAccent.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'Database Offline',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.redAccent),
                ),
                Text(
                  'Check your connection to sync users',
                  style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allUsers = (snapshot.data as List?)?.cast<Map<String, dynamic>>() ?? [];
        final users = allUsers.where((u) => roles.contains(u['role'])).toList();
        if (users.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserCard(user);
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final bool isStaff = user['role'] != 'patient';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isStaff
              ? const Color(0xFFEEF2FF)
              : const Color(0xFFECFDF5),
          child: HugeIcon(
            icon: isStaff ? HugeIcons.strokeRoundedDoctor01 : HugeIcons.strokeRoundedUserCircle,
            color: isStaff ? const Color(0xFF6366F1) : const Color(0xFF10B981),
            size: 20,
          ),
        ),
        title: Text(
          user['full_name'] ?? 'Unnamed User',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          user['email'] ?? 'No email provided',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        onTap: () {
          final role = user['role']?.toString().toLowerCase();
          final id = user['id']?.toString() ?? '';
          final name = user['full_name']?.toString() ?? 'Unnamed User';
          
          if (role == 'patient') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailsPage(
                  patientId: id,
                  patientName: name,
                ),
              ),
            );
          } else if (role == 'therapist' || role == 'therapist_assistant') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TherapistDetailsPage(
                  therapistId: id,
                  therapistName: name,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off_rounded,
            size: 64,
            color: Colors.indigo.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No users found in this category',
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
