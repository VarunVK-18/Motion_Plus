import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';

class PdfViewerPage extends StatelessWidget {
  final String url;
  final String fileName;

  const PdfViewerPage({super.key, required this.url, required this.fileName});

  Future<Uint8List> _fetchPdf() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load PDF from server');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          fileName,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: PdfPreview(
        build: (format) => _fetchPdf(),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
