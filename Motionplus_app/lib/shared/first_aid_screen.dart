import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirstAidScreen extends StatelessWidget {
  const FirstAidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: const Text('First Aid & Education'),
        backgroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('first_aid_conditions').select(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final conditions = snapshot.data ?? [];
          if (conditions.isEmpty) {
            return const Center(child: Text('No first aid topics available.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: conditions.length,
            itemBuilder: (context, index) {
              final condition = conditions[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConditionDetailScreen(condition: condition),
                    ),
                  );
                },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C7C6F).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForString(condition['icon_name'] as String? ?? ''),
                      color: const Color(0xFF5C7C6F),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    condition['title'] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: const Color(0xFF2F3437),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ),
);
  }

  IconData _getIconForString(String iconName) {
    switch (iconName) {
      case 'smartphone': return Icons.smartphone_rounded;
      case 'airline_seat_recline_normal': return Icons.airline_seat_recline_normal_rounded;
      case 'sports_gymnastics': return Icons.sports_gymnastics_rounded;
      default: return Icons.medical_services_rounded;
    }
  }
}

class ConditionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> condition;

  const ConditionDetailScreen({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    final title = condition['title'] as String? ?? 'Detail';
    final overview = condition['overview'] as String? ?? '';
    final dos = (condition['dos'] as List<dynamic>?)?.cast<String>() ?? [];
    final donts = (condition['donts'] as List<dynamic>?)?.cast<String>() ?? [];
    final redFlags = (condition['red_flags'] as List<dynamic>?)?.cast<String>() ?? [];
    final iceHeat = condition['ice_heat_guidance'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Overview', overview),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildListSection('Do\'s', dos, const Color(0xFF4ADE80))),
                const SizedBox(width: 16),
                Expanded(child: _buildListSection('Don\'ts', donts, const Color(0xFFF87171))),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection('Ice & Heat Guidance', iceHeat),
            const SizedBox(height: 24),
            if (redFlags.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF87171).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF87171).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171)),
                        const SizedBox(width: 8),
                        Text(
                          'Red Flags (Seek Medical Help)',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF87171),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      redFlags.map((rf) => '• $rf').join('\n'),
                      style: GoogleFonts.outfit(color: const Color(0xFF2F3437)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String heading, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF2F3437),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: const Color(0xFF94A3B8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(String heading, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.outfit(color: const Color(0xFF2F3437), fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
