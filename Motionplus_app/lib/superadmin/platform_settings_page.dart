import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/api_service.dart';

class PlatformSettingsPage extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  const PlatformSettingsPage({super.key, this.onThemeChanged});

  @override
  State<PlatformSettingsPage> createState() => _PlatformSettingsPageState();
}

class _PlatformSettingsPageState extends State<PlatformSettingsPage> {
  late Future<List<dynamic>> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _settingsFuture = ApiService.get('/settings', includeAuth: true).then((data) => data as List<dynamic>);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Platform Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return Center(child: Text('Error: \${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }

          final settingsList = (snapshot.data)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];
          final settings = {
            for (var s in settingsList) s['key']: s['value'],
          };

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSettingsGroup('Appearance & Theme', [
                _buildSwitchTile(
                  HugeIcons.strokeRoundedMoon02,
                  'Dark Mode',
                  'Enable dark mode for the super admin dashboard',
                  settings['dark_mode_support'] == 'true',
                  (val) => _updateSetting('dark_mode_support', val.toString()),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateSetting(String key, String value) async {
    try {
      await ApiService.post('/settings', {
        'key': key,
        'value': value,
      }, includeAuth: true);
      
      if (key == 'dark_mode_support' && widget.onThemeChanged != null) {
        widget.onThemeChanged!(value == 'true');
      }

      _loadSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update setting: $e')));
      }
    }
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    dynamic icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: HugeIcon(
        icon: icon,
        color: Theme.of(context).colorScheme.primary,
        size: 22,
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      activeThumbColor: const Color(0xFF10B981),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildSettingTile(
    dynamic icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: HugeIcon(
        icon: icon,
        color: Theme.of(context).colorScheme.primary,
        size: 22,
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFFCBD5E1),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  void _showPolicyDialog(String key, String? current) {
    // Implementation for policy dialog
  }
}
