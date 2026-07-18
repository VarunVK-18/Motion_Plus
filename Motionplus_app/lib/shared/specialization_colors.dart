import 'package:flutter/material.dart';

class SpecializationColors {
  static Color getColor(String spec) {
    final s = spec.toLowerCase().trim();
    if (s.contains('neuro')) return const Color(0xFF6366F1); // Purple/Blue
    if (s.contains('pediatric')) return const Color(0xFFF472B6); // Bright playful (Pink)
    if (s.contains('cardio')) return const Color(0xFFEF4444); // Red
    if (s.contains('ortho')) return const Color(0xFF94A3B8); // Steel/Grey
    if (s.contains('psychology')) return const Color(0xFF8B5CF6); // Calm pastel (Purple)
    if (s.contains('speech')) return const Color(0xFF06B6D4); // Aqua
    if (s.contains('sensory')) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFF3E84DC); // Default Blue
  }

  static Decoration getDecoration(String spec) {
    final s = spec.toLowerCase().trim();
    if (s.contains('sensory')) {
      return BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
      );
    }
    return BoxDecoration(
      color: getColor(spec).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    );
  }

  static Color getTextColor(String spec) {
    final s = spec.toLowerCase().trim();
    if (s.contains('sensory')) return Colors.white;
    return getColor(spec);
  }
}
