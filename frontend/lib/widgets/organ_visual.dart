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
        size: iconSize ?? size * 0.52,
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
  switch (organ) {
    case 'Heart':
      return const OrganVisualStyle(
        icon: Icons.favorite,
        background: Color(0xFFFFEAF1),
        border: Color(0xFFFFD1DE),
        accent: Color(0xFFD84D72),
      );
    case 'Liver':
      return const OrganVisualStyle(
        icon: Icons.science,
        background: Color(0xFFFFF0E4),
        border: Color(0xFFFFD9BA),
        accent: Color(0xFFD46B25),
      );
    case 'Kidney':
      return const OrganVisualStyle(
        icon: Icons.water_drop,
        background: Color(0xFFEDE9FF),
        border: Color(0xFFD9D0FF),
        accent: Color(0xFF7653D9),
      );
    case 'Lung':
    case 'Lungs':
      return const OrganVisualStyle(
        icon: Icons.air,
        background: Color(0xFFE7FBFF),
        border: Color(0xFFC8F1F7),
        accent: Color(0xFF21AFC2),
      );
    case 'Diabetes / Metabolic':
    case 'Brain / Metabolic':
    case 'Brain':
      return const OrganVisualStyle(
        icon: Icons.psychology_alt,
        background: Color(0xFFFFF4E2),
        border: Color(0xFFFFDFB5),
        accent: Color(0xFFE28C25),
      );
    case 'Inflammation':
      return const OrganVisualStyle(
        icon: Icons.bloodtype,
        background: Color(0xFFF0E9FF),
        border: Color(0xFFDED1FF),
        accent: Color(0xFF7653D9),
      );
    case 'Pancreas':
      return const OrganVisualStyle(
        icon: Icons.biotech,
        background: Color(0xFFFFF2E8),
        border: Color(0xFFFFD7C0),
        accent: Color(0xFFE1813A),
      );
    case 'Cancer Awareness':
      return const OrganVisualStyle(
        icon: Icons.health_and_safety,
        background: Color(0xFFEAF7FF),
        border: AppStyles.softBlueBorder,
        accent: AppStyles.primary,
      );
    default:
      return const OrganVisualStyle(
        icon: Icons.monitor_heart,
        background: AppStyles.softBlue,
        border: AppStyles.softBlueBorder,
        accent: AppStyles.primary,
      );
  }
}
