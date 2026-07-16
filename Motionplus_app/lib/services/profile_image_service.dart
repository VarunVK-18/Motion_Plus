import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../auth/auth_service.dart';

class ProfileImageService {
  static final ProfileImageService _instance = ProfileImageService._internal();
  factory ProfileImageService() => _instance;
  ProfileImageService._internal();

  final ValueNotifier<String?> profileImagePathNotifier = ValueNotifier<String?>(null);

  Future<void> loadProfileImage() async {
    final userId = await AuthService.getCurrentUserId();
    if (userId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_$userId');
    if (path != null && File(path).existsSync()) {
      profileImagePathNotifier.value = path;
    } else {
      profileImagePathNotifier.value = null;
    }
  }

  Future<void> saveProfileImage(File imageFile) async {
    final userId = await AuthService.getCurrentUserId();
    if (userId == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final ext = imageFile.path.split('.').last;
    final savedImage = await imageFile.copy('${directory.path}/profile_$userId.$ext');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_$userId', savedImage.path);
    
    profileImagePathNotifier.value = savedImage.path;
  }

  Future<void> removeProfileImage() async {
    final userId = await AuthService.getCurrentUserId();
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_$userId');
    
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
      await prefs.remove('profile_image_$userId');
    }
    profileImagePathNotifier.value = null;
  }
}
