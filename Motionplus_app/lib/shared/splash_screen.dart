import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../selection_page.dart';
import 'theme/app_theme.dart';
import '../services/api_service.dart';
import '../auth/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _showLoader = false;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Show loader after animation completes (1.5s)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() {
      _showLoader = true;
      _statusText = 'Connecting to server...';
    });

    // Check auth (which hits the backend)
    final shouldRedirect = await _checkAuth();

    if (!mounted) return;

    setState(() {
      _statusText = 'Almost there...';
    });

    // Brief pause so the status text is readable
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    if (shouldRedirect) {
      try {
        await AuthService.handleRedirection(context);
        return;
      } catch (e) {
        // Fall back to SelectionPage if routing fails
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SelectionPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  Future<bool> _checkAuth() async {
    try {
      final token = await ApiService.getToken();
      return token != null &&
          !AuthService.isPasswordRecovery &&
          !AuthService.isSigningUp;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepSageGreen,
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.eco_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'OLEVEO',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'by MotionPlus Initiative',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Heal. Move. Thrive.',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.warmOffWhite,
                    letterSpacing: 1.2,
                  ),
                ),

                // ── Loader section (appears after animation) ──
                AnimatedOpacity(
                  opacity: _showLoader ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _statusText,
                          key: ValueKey(_statusText),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.65),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
