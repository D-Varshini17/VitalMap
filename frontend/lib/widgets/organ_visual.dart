import 'package:flutter/material.dart';

import '../styles.dart';

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
      child: Icon(
        style.icon,
        color: style.accent,
        size: iconSize ?? size * 0.45,
      ),
    );
  }
}

class OrganVisualStyle {
  const OrganVisualStyle({
    required this.icon,
    required this.background,
    required this.border,
    required this.accent,
  });

  final IconData icon;
  final Color background;
  final Color border;
  final Color accent;
}

OrganVisualStyle organVisualStyle(String organ) {
  switch (organ.trim().toLowerCase()) {
    case 'heart':
      return const OrganVisualStyle(
        icon: Icons.favorite_border,
        background: Color(0xFFFFEAF1),
        border: Color(0xFFFFD1DE),
        accent: Color(0xFFD84D72),
      );
    case 'liver':
      return const OrganVisualStyle(
        icon: Icons.science_outlined,
        background: Color(0xFFECF8EF),
        border: Color(0xFFCBEAD5),
        accent: Color(0xFF2F9D62),
      );
    case 'kidney':
      return const OrganVisualStyle(
        icon: Icons.water_drop_outlined,
        background: Color(0xFFEAF7FF),
        border: Color(0xFFCFEFFF),
        accent: Color(0xFF0B63CE),
      );
    case 'lung':
    case 'lungs':
      return const OrganVisualStyle(
        icon: Icons.air_outlined,
        background: Color(0xFFE7FBFF),
        border: Color(0xFFC8F1F7),
        accent: Color(0xFF21AFC2),
      );
    case 'diabetes / metabolic':
    case 'diabetes':
      return const OrganVisualStyle(
        icon: Icons.monitor_heart_outlined,
        background: Color(0xFFFFF4E2),
        border: Color(0xFFFFDFB5),
        accent: Color(0xFFE28C25),
      );
    case 'brain / metabolic':
    case 'brain':
      return const OrganVisualStyle(
        icon: Icons.psychology_outlined,
        background: Color(0xFFF3EEFF),
        border: Color(0xFFE0D3FF),
        accent: Color(0xFF7C5ACF),
      );
    case 'inflammation':
    case 'cbc / differential':
    case 'cbc':
      return const OrganVisualStyle(
        icon: Icons.bloodtype_outlined,
        background: Color(0xFFFFEEF0),
        border: Color(0xFFFFCDD3),
        accent: Color(0xFFD94A5F),
      );
    case 'pancreas':
    case 'pancreatic enzymes':
      return const OrganVisualStyle(
        icon: Icons.biotech_outlined,
        background: Color(0xFFFFF2E8),
        border: Color(0xFFFFD7C0),
        accent: Color(0xFFE1813A),
      );
    case 'cancer awareness':
    case 'cancer':
      return const OrganVisualStyle(
        icon: Icons.health_and_safety_outlined,
        background: Color(0xFFFFF8E5),
        border: Color(0xFFFFE6A3),
        accent: Color(0xFFC89216),
      );
    default:
      return const OrganVisualStyle(
        icon: Icons.health_and_safety_outlined,
        background: AppStyles.softBlue,
        border: AppStyles.softBlueBorder,
        accent: AppStyles.primary,
      );
  }
}
