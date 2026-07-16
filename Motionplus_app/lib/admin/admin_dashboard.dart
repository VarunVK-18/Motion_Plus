import 'package:flutter/material.dart';
import 'dart:ui'; // Required for ImageFilter
import '../services/api_service.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../selection_page.dart';
import 'manage_therapists.dart';
import 'manage_patients.dart';
import 'allot_sessions.dart';
import 'create_session.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {

  int _currentIndex = 0;
  late PageController _pageController;

  static const Color primaryBlue = Color(0xFF3E84DC);
  static const Color darkSlate = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildModernHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    children: const [
                      CreateSessionPage(),
                      AllotSessionsPage(),
                      ManageTherapistsPage(),
                      ManagePatientsPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildFloatingNavbar(),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirm() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Sign Out?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to log out of the Admin portal?',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'LOGOUT',
              style: GoogleFonts.outfit(
                color: const Color(0xFFBE123C),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await ApiService.clearToken();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SelectionPage()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.02)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'ADMIN ACCESS',
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: primaryBlue,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getTitle(_currentIndex),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: darkSlate,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _showLogoutConfirm,
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFEE2E2)),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFBE123C),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavbar() {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: darkSlate.withOpacity(0.85), // Semi-transparent dark slate
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  HugeIcons.strokeRoundedUserAdd01,
                  HugeIcons.strokeRoundedUserAdd01,
                  'Create',
                ),
                _buildNavItem(
                  1,
                  HugeIcons.strokeRoundedAssignments,
                  HugeIcons.strokeRoundedAssignments,
                  'Allot',
                ),
                _buildNavItem(
                  2,
                  HugeIcons.strokeRoundedDoctor02,
                  HugeIcons.strokeRoundedDoctor02,
                  'Therapists',
                ),
                _buildNavItem(
                  3,
                  Icons.people_outline_rounded,
                  Icons.people_rounded,
                  'Patients',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    dynamic icon,
    dynamic activeIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final displayIcon = isSelected ? activeIcon : icon;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            displayIcon is IconData
                ? Icon(
                    displayIcon,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    size: 22,
                  )
                : HugeIcon(
                    icon: displayIcon,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    size: 22,
                  ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'New Session';
      case 1:
        return 'Assignment';
      case 2:
        return 'Staff Directory';
      case 3:
        return 'Patient Registry';
      default:
        return 'Portal';
    }
  }
}
