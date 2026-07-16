import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'selection_page.dart';
import 'shared/splash_screen.dart';
import 'notifications/notification_service.dart';
import 'shared/theme/app_theme.dart';

import 'widgets/connectivity_banner.dart';
import 'core/constants/port.dart'; // Ensure it's imported if needed

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await NotificationService.init();

  // Default to light mode globally. Module-specific themes are handled within those modules.
  themeNotifier.value = ThemeMode.light;

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Physio Tracker',
          themeMode: ThemeMode.light,
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.dark,
              child: ConnectivityBanner(child: child!),
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
