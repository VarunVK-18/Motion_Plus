import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BloodPressurePage extends StatelessWidget {
  const BloodPressurePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFFE11D48); // Rose/Red for Blood Pressure
    const Color darkSlate = Color(0xFF0F172A);
    const Color softSlate = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: darkSlate,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Blood Pressure',
          style: GoogleFonts.outfit(
            color: darkSlate,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Measurement Card Placeholder
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withOpacity(0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.favorite_outline_rounded,
                    color: brandColor.withOpacity(0.2),
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '120',
                        style: GoogleFonts.outfit(
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          color: darkSlate,
                        ),
                      ),
                      Text(
                        '/',
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          color: softSlate,
                        ),
                      ),
                      Text(
                        '80',
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: darkSlate,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'mmHg',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: softSlate,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Normal Blood Pressure',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981), // Green
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Integration coming soon. This is placeholder data for demonstration purposes.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                        height: 1.4,
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
}
