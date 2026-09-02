import 'package:flutter/material.dart';

import '../styles.dart';

String? getOrganImagePath(String organ) {
  switch (organ.trim().toLowerCase()) {
    case 'heart':
      return 'assets/organs/images/heart.jpeg';
    case 'liver':
      return 'assets/organs/images/liver.jpeg';
    case 'kidney':
      return 'assets/organs/images/kidney.jpeg';
    case 'lung':
    case 'lungs':
      return 'assets/organs/images/lungs.jpeg';
    case 'diabetes / metabolic':
    case 'diabetes':
    case 'brain / metabolic':
    case 'brain':
      return 'assets/organs/images/brain_metabolic.jpeg';
    case 'inflammation':
    case 'cbc / differential':
    case 'cbc':
      return 'assets/organs/images/inflammation.jpeg';
    case 'pancreas':
    case 'pancreatic enzymes':
      return 'assets/organs/images/pancreas.jpeg';
    case 'cancer awareness':
    case 'cancer':
      return 'assets/organs/images/cancer_awareness.jpeg';
    default:
      return null;
  }
}

class OrganVisualIcon extends StatelessWidget {
  const OrganVisualIcon({
    super.key,
    required this.organ,
    this.size = 52,
    this.iconSize,
    this.showGlow = false,
  });

  final String organ;
  final double size;
  final double? iconSize;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final style = organVisualStyle(organ);
    final imagePath = getOrganImagePath(organ);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: style.border),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: style.accent.withValues(alpha: 0.22),
                  blurRadius: size * 0.42,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: imagePath != null
              ? Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        style.emoji,
                        style: TextStyle(
                          fontSize: iconSize ?? size * 0.45,
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text(
                    style.emoji,
                    style: TextStyle(
                      fontSize: iconSize ?? size * 0.52,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class OrganVisualStyle {
  const OrganVisualStyle({
    required this.emoji,
    required this.background,
    required this.border,
    required this.accent,
  });

  final String emoji;
  final Color background;
  final Color border;
  final Color accent;
}

OrganVisualStyle organVisualStyle(String organ) {
  switch (organ.trim().toLowerCase()) {
    case 'heart':
      return const OrganVisualStyle(
        emoji: '❤️',
        background: Color(0xFFFFEAF1),
        border: Color(0xFFFFD1DE),
        accent: Color(0xFFD84D72),
      );
    case 'liver':
      return const OrganVisualStyle(
        emoji: '🧪',
        background: Color(0xFFECF8EF),
        border: Color(0xFFCBEAD5),
        accent: Color(0xFF2F9D62),
      );
    case 'kidney':
      return const OrganVisualStyle(
        emoji: '💧',
        background: Color(0xFFEAF7FF),
        border: Color(0xFFCFEFFF),
        accent: Color(0xFF0B63CE),
      );
    case 'lung':
    case 'lungs':
      return const OrganVisualStyle(
        emoji: '🫁',
        background: Color(0xFFE7FBFF),
        border: Color(0xFFC8F1F7),
        accent: Color(0xFF21AFC2),
      );
    case 'diabetes / metabolic':
    case 'diabetes':
      return const OrganVisualStyle(
        emoji: '🍬',
        background: Color(0xFFFFF4E2),
        border: Color(0xFFFFDFB5),
        accent: Color(0xFFE28C25),
      );
    case 'brain / metabolic':
    case 'brain':
      return const OrganVisualStyle(
        emoji: '🧠',
        background: Color(0xFFF3EEFF),
        border: Color(0xFFE0D3FF),
        accent: Color(0xFF7C5ACF),
      );
    case 'inflammation':
    case 'cbc / differential':
    case 'cbc':
      return const OrganVisualStyle(
        emoji: '🩸',
        background: Color(0xFFFFEEF0),
        border: Color(0xFFFFCDD3),
        accent: Color(0xFFD94A5F),
      );
    case 'pancreas':
    case 'pancreatic enzymes':
      return const OrganVisualStyle(
        emoji: '🔬',
        background: Color(0xFFFFF2E8),
        border: Color(0xFFFFD7C0),
        accent: Color(0xFFE1813A),
      );
    case 'cancer awareness':
    case 'cancer':
      return const OrganVisualStyle(
        emoji: '🎗️',
        background: Color(0xFFFFF8E5),
        border: Color(0xFFFFE6A3),
        accent: Color(0xFFC89216),
      );
    default:
      return const OrganVisualStyle(
        emoji: '❤️',
        background: AppStyles.softBlue,
        border: AppStyles.softBlueBorder,
        accent: AppStyles.primary,
      );
  }
}
