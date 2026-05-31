import 'package:flutter/material.dart';

import '../styles.dart';

String? getOrganImagePath(String organ) {
  switch (organ.trim().toLowerCase()) {
    case 'heart':
      return 'assets/images/organs/heart.png';
    case 'liver':
      return 'assets/images/organs/liver.png';
    case 'kidney':
      return 'assets/images/organs/kidney.png';
    case 'lung':
    case 'lungs':
      return 'assets/images/organs/lungs.png';
    case 'diabetes / metabolic':
    case 'diabetes':
    case 'brain / metabolic':
    case 'brain':
      return 'assets/images/organs/brain_metabolic.png';
    case 'inflammation':
    case 'cbc / differential':
    case 'cbc':
      return 'assets/images/organs/inflammation.png';
    case 'pancreas':
    case 'pancreatic enzymes':
      return 'assets/images/organs/pancreas.png';
    case 'cancer awareness':
    case 'cancer':
      return 'assets/images/organs/cancer_awareness.png';
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
        emoji: '🫀',
        background: Color(0xFFFFEAF1),
        border: Color(0xFFFFD1DE),
        accent: Color(0xFFD84D72),
      );
    case 'liver':
      return const OrganVisualStyle(
        emoji: '🩸',
        background: Color(0xFFFFF0E4),
        border: Color(0xFFFFD9BA),
        accent: Color(0xFFD46B25),
      );
    case 'kidney':
      return const OrganVisualStyle(
        emoji: '🫘',
        background: Color(0xFFEDE9FF),
        border: Color(0xFFD9D0FF),
        accent: Color(0xFF7653D9),
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
        background: Color(0xFFFFF4E2),
        border: Color(0xFFFFDFB5),
        accent: Color(0xFFE28C25),
      );
    case 'inflammation':
    case 'cbc / differential':
    case 'cbc':
      return const OrganVisualStyle(
        emoji: '🦠',
        background: Color(0xFFF0E9FF),
        border: Color(0xFFDED1FF),
        accent: Color(0xFF7653D9),
      );
    case 'pancreas':
    case 'pancreatic enzymes':
      return const OrganVisualStyle(
        emoji: '🥐',
        background: Color(0xFFFFF2E8),
        border: Color(0xFFFFD7C0),
        accent: Color(0xFFE1813A),
      );
    case 'cancer awareness':
    case 'cancer':
      return const OrganVisualStyle(
        emoji: '🎗️',
        background: Color(0xFFEAF7FF),
        border: AppStyles.softBlueBorder,
        accent: AppStyles.primary,
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
