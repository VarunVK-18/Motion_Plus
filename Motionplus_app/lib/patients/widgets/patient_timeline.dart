import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import '../../shared/theme/app_theme.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hugeicons/hugeicons.dart';

class PatientTimeline extends StatefulWidget {
  final String patientId;

  const PatientTimeline({super.key, required this.patientId});

  @override
  State<PatientTimeline> createState() => _PatientTimelineState();
}

class _PatientTimelineState extends State<PatientTimeline> {
  Map<String, dynamic>? _currentUser;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  final Set<String> _expandedDates = {'Today'};

  @override
  void initState() {
    super.initState();
    ApiService.get('/profiles/me', includeAuth: true).then((user) {
      if (mounted) {
        setState(() {
          _currentUser = user as Map<String, dynamic>?;
        });
        _fetchTimelineEvents();
      }
    });
  }

  Future<void> _fetchTimelineEvents() async {
    try {
      // Fetch completed sessions
      final sessions = await ApiService.get('/sessions?patient_id=${widget.patientId}&completed_count[gt]=0&_sort=scheduled_date:desc&_limit=10', includeAuth: true) as List;

      // Fetch morning check-ins
      final checkins = await ApiService.get('/morning_checkins?patient_id=${widget.patientId}&_sort=created_at:desc&_limit=10', includeAuth: true) as List;

      final List<Map<String, dynamic>> mergedEvents = [];

      for (var s in sessions) {
        final dateStr = s['scheduled_date'] ?? s['created_at'];
        mergedEvents.add({
          'date': DateTime.parse(dateStr),
          'title': 'Therapy Session Completed',
          'type': 'session',
        });
      }

      for (var c in checkins) {
        mergedEvents.add({
          'date': DateTime.parse(c['created_at']),
          'title': 'Morning Check-In: ${c['overall_day'] ?? 'Completed'}',
          'type': 'checkin',
          'readiness': c['readiness_score'] ?? 0,
        });
      }

      // Fetch patient media files
      final mediaFiles = await ApiService.get('/patient_media_files?patient_id=${widget.patientId}&_sort=created_at:desc&_limit=10', includeAuth: true) as List;

      for (var m in mediaFiles) {
        mergedEvents.add({
          'date': m['created_at'] != null ? DateTime.parse(m['created_at']) : DateTime.now(),
          'title': 'Uploaded ${m['file_type']}: ${m['title'] ?? 'Document'}',
          'type': 'document',
        });
      }

      // Add a registration event
      final profile = await ApiService.get('/profiles/${widget.patientId}', includeAuth: true);
      if (profile != null && profile['created_at'] != null) {
        mergedEvents.add({
          'date': DateTime.parse(profile['created_at']),
          'title': 'Registered Account',
          'type': 'registration',
        });
      }

      // Sort by descending date
      mergedEvents.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      if (mounted) {
        setState(() {
          _events = mergedEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching timeline: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Timeline Fetch Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    }
    return DateFormat('MMMM d, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  void _showUploadMediaDialog() {
    final titleCtrl = TextEditingController();
    String? fileType = 'pdf';
    PlatformFile? selectedFile;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
          return Container(
            margin: EdgeInsets.only(bottom: keyboardSpace),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Upload Media',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.deepSageGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add documents, images, or videos to the patient\'s timeline.',
                    style: GoogleFonts.outfit(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  
                  // File type dropdown
                  DropdownButtonFormField<String>(
                    initialValue: fileType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'pdf', child: Text('PDF Document')),
                      DropdownMenuItem(value: 'image', child: Text('Image')),
                      DropdownMenuItem(value: 'video', child: Text('Video')),
                      DropdownMenuItem(value: 'voice_note', child: Text('Voice Note')),
                    ],
                    onChanged: (val) => setState(() => fileType = val),
                    decoration: InputDecoration(
                      labelText: 'File Type',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title TextField
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Document Title',
                      hintText: 'e.g. Discharge Summary',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.title, color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // File Picker Area
                  GestureDetector(
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.pickFiles();
                      if (result != null) {
                        setState(() => selectedFile = result.files.first);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      decoration: BoxDecoration(
                        color: selectedFile != null ? AppTheme.deepSageGreen.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: Border.all(
                          color: selectedFile != null ? AppTheme.deepSageGreen : Colors.grey.shade300,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            selectedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                            size: 48,
                            color: selectedFile != null ? AppTheme.deepSageGreen : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            selectedFile != null ? selectedFile!.name : 'Tap to select a file',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              color: selectedFile != null ? AppTheme.deepSageGreen : Colors.grey.shade600,
                            ),
                          ),
                          if (selectedFile != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${(selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                              style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Upload Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepSageGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: isUploading || selectedFile == null || titleCtrl.text.isEmpty
                          ? null
                          : () async {
                              setState(() => isUploading = true);
                              try {
                                final bytes = await File(selectedFile!.path!).readAsBytes();
                                final base64String = base64Encode(bytes);
                                final fileName = selectedFile!.name;
                                
                                final response = await ApiService.post('/patient_media_files', {
                                  'patient_id': widget.patientId,
                                  'uploader_id': _currentUser?['id'],
                                  'media_type': fileType,
                                  'file_name': titleCtrl.text,
                                  'file_url': base64String,
                                }, includeAuth: true);
                                
                                if (response == null) {
                                  throw Exception('Database rejected the insert. Row Level Security might be blocking it.');
                                }
                                
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                _fetchTimelineEvents(); // refresh
                              } catch (e) {
                                setState(() => isUploading = false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            },
                      child: isUploading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Upload Media',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(color: Color(0xFF5C7C6F)),
      ));
    }

    if (_events.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timeline', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'No events found.',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    // Group events by date header
    final groupedEvents = <String, List<Map<String, dynamic>>>{};
    for (var event in _events) {
      final dateString = _formatDateHeader(event['date'] as DateTime);
      if (!groupedEvents.containsKey(dateString)) {
        groupedEvents[dateString] = [];
      }
      groupedEvents[dateString]!.add(event);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Timeline', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
        const SizedBox(height: 24),
        ...groupedEvents.entries.map((entry) {
          final dateHeader = entry.key;
          final eventsForDate = entry.value;

              final isExpanded = _expandedDates.contains(dateHeader);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedDates.remove(dateHeader);
                        } else {
                          _expandedDates.add(dateHeader);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Text(
                            dateHeader.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.softSlate,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.softSlate,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Events for this date
                  if (isExpanded)
                    ...eventsForDate.asMap().entries.map((eventEntry) {
                      final index = eventEntry.key;
                      final event = eventEntry.value;
                      final isLast = index == eventsForDate.length - 1;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Timeline connector
                            Column(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _buildIconForType(
                                    event['type']!,
                                    _getColorForType(event['type']!),
                                  ),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Event Card
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: _buildEventCard(event),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
              const SizedBox(height: 8), // Extra space between date groups
            ],
          );
        }),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return InkWell(
      onTap: () {
        // Future: Handle taps (e.g. show document preview or session details)
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event['title']!,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.charcoal,
                    ),
                  ),
                ),
                Text(
                  _formatTime(event['date'] as DateTime),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppTheme.softSlate,
                  ),
                ),
              ],
            ),
            if (event['type'] == 'checkin') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (event['readiness'] >= 80)
                      ? Colors.green.shade50
                      : (event['readiness'] >= 50)
                          ? Colors.orange.shade50
                          : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Readiness: ${event['readiness']}%',
                  style: GoogleFonts.outfit(
                    color: (event['readiness'] >= 80)
                        ? Colors.green.shade700
                        : (event['readiness'] >= 50)
                            ? Colors.orange.shade700
                            : Colors.red.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildIconForType(String type, Color color) {
    switch (type) {
      case 'session':
        return HugeIcon(icon: HugeIcons.strokeRoundedDumbbell02, color: color, size: 16);
      case 'checkin':
        return HugeIcon(icon: HugeIcons.strokeRoundedSunrise, color: color, size: 16);
      case 'document':
        return HugeIcon(icon: HugeIcons.strokeRoundedGoogleDoc, color: color, size: 16);
      case 'registration':
        return HugeIcon(icon: HugeIcons.strokeRoundedUserCircle02, color: color, size: 16);
      default:
        return Icon(Icons.circle, color: color, size: 16);
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'session':
        return AppTheme.deepSageGreen;
      case 'checkin':
        return AppTheme.softOlive;
      case 'document':
        return AppTheme.mutedGold;
      case 'registration':
        return AppTheme.softSlate;
      default:
        return AppTheme.deepSageGreen;
    }
  }
}
