import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/theme/app_theme.dart';

class AssessmentRepository extends StatefulWidget {
  final String patientId;
  const AssessmentRepository({super.key, required this.patientId});

  @override
  State<AssessmentRepository> createState() => _AssessmentRepositoryState();
}

class _AssessmentRepositoryState extends State<AssessmentRepository> {
  Map<String, dynamic>? _currentUser;
  List<Map<String, dynamic>> _assessments = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    ApiService.get('/profiles/me', includeAuth: true).then((user) {
      if (mounted) {
        setState(() {
          _currentUser = user as Map<String, dynamic>?;
        });
        _fetchAssessments();
      }
    });
  }

  Future<void> _fetchAssessments() async {
    try {
      final response = await ApiService.get('/patient_documents?patient_id=${widget.patientId}&_sort=created_at:desc', includeAuth: true);

      if (mounted) {
        setState(() {
          _assessments = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching assessments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _askForDocumentName(String defaultName) async {
    final controller = TextEditingController(text: defaultName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Document Name', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter document name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepSageGreen),
            child: Text('Save', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadDocument(String type) async {
    Navigator.pop(context); // close bottom sheet
    setState(() => _isUploading = true);

    try {
      File? fileToUpload;
      String fileName = '';

      if (type == 'IMAGE' || type == 'VIDEO') {
        final picker = ImagePicker();
        final pickedFile = type == 'IMAGE' 
            ? await picker.pickImage(source: ImageSource.gallery)
            : await picker.pickVideo(source: ImageSource.gallery);
            
        if (pickedFile != null) {
          fileToUpload = File(pickedFile.path);
          fileName = pickedFile.name;
        }
      } else {
        // PDF or audio
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: type == 'PDF' ? ['pdf'] : ['m4a', 'mp3', 'wav'],
        );

        if (result != null && result.files.single.path != null) {
          fileToUpload = File(result.files.single.path!);
          fileName = result.files.single.name;
        }
      }

      if (fileToUpload == null) {
        setState(() => _isUploading = false);
        return; // User canceled
      }

      // Ask for document name
      final customName = await _askForDocumentName(fileName);
      if (customName == null || customName.trim().isEmpty) {
        setState(() => _isUploading = false);
        return; // User canceled
      }
      
      final finalFileName = customName.trim();

      // 1. Convert to Base64 and Upload
      final bytes = await fileToUpload.readAsBytes();
      final base64String = base64Encode(bytes);
      final fileName_ = fileToUpload.path.split('/').last;
      
      final endpoint = type == 'PDF' ? '/patient_documents' : '/patient_media_files';
      
      final payload = {
        'patient_id': widget.patientId,
        'file_name': fileName_,
        'file_url': base64String, // Store base64 directly
      };
      if (type == 'PDF') {
        payload['document_type'] = type;
      } else {
        payload['media_type'] = type;
      }
      
      final response = await ApiService.post(endpoint, payload, includeAuth: true);
      
      final newDoc = {
        'id': response['_id'],
        'patient_id': response['patient_id'],
        'uploader_id': _currentUser?['id'] ?? response['patient_id'],
        'file_name': response['file_name'],
        'file_type': response['document_type'] ?? response['media_type'],
        'url': response['file_url'],
        'created_at': response['created_at'] ?? DateTime.now().toUtc().toIso8601String(),
      };
      
      setState(() {
        _assessments.insert(0, newDoc);
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload successful!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Document Repository',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            if (_isUploading)
              const SizedBox(
                width: 24, height: 24, 
                child: CircularProgressIndicator(color: AppTheme.deepSageGreen, strokeWidth: 3)
              )
            else
              IconButton(
                onPressed: () {
                  _showUploadOptions(context);
                },
                icon: const Icon(Icons.add_circle_rounded, color: AppTheme.deepSageGreen, size: 32),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: AppTheme.deepSageGreen),
          ))
        else if (_assessments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No documents uploaded yet.',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _assessments.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey.withOpacity(0.2)),
            itemBuilder: (context, index) {
              final doc = _assessments[index];
              final dateStr = DateFormat('MMM d, yyyy').format(DateTime.parse(doc['created_at']));
              final isPatientUploader = doc['uploader_id'] == widget.patientId;
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warmOffWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIconForType(doc['type'] ?? 'Unknown'), color: AppTheme.deepSageGreen),
                ),
                title: Text(
                  doc['title'] ?? 'Untitled Document',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.charcoal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr • ${doc['type'] ?? 'Unknown'}',
                      style: GoogleFonts.outfit(
                        color: AppTheme.softSlate,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPatientUploader ? AppTheme.deepSageGreen.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isPatientUploader ? 'Patient Uploaded' : 'Therapist Uploaded',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isPatientUploader ? AppTheme.deepSageGreen : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_rounded, color: AppTheme.deepSageGreen),
                      onPressed: () {
                        final url = doc['file_url'];
                        if (url != null) launchUrl(Uri.parse(url));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: AppTheme.deepSageGreen),
                      onPressed: () {
                        final url = doc['file_url'];
                        if (url != null) launchUrl(Uri.parse(url));
                      },
                    ),
                  ],
                ),
                onTap: () {
                  final url = doc['file_url'];
                  if (url != null) launchUrl(Uri.parse(url));
                },
              );
            },
          ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'IMAGE':
        return Icons.image_rounded;
      case 'VIDEO':
        return Icons.videocam_rounded;
      case 'AUDIO':
        return Icons.mic_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Upload Assessment',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: AppTheme.deepSageGreen),
                  title: Text('PDF Document', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                  onTap: () => _uploadDocument('PDF'),
                ),
                ListTile(
                  leading: const Icon(Icons.image, color: AppTheme.deepSageGreen),
                  title: Text('Image', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                  onTap: () => _uploadDocument('IMAGE'),
                ),
                ListTile(
                  leading: const Icon(Icons.videocam, color: AppTheme.deepSageGreen),
                  title: Text('Video', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                  onTap: () => _uploadDocument('VIDEO'),
                ),
                ListTile(
                  leading: const Icon(Icons.mic, color: AppTheme.deepSageGreen),
                  title: Text('Voice Note', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                  onTap: () => _uploadDocument('AUDIO'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
