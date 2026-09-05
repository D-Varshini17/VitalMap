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
      child: Padding(
        padding: EdgeInsets.all(size * 0.12),
        child: Image.asset(
          style.assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.image_not_supported_outlined,
            color: style.accent,
            size: iconSize ?? size * 0.45,
          ),
        ),
      ),
    );
  }
}

class OrganVisualStyle {
  const OrganVisualStyle({
    required this.assetPath,
    required this.background,
    required this.border,
    required this.accent,
  });

  final String assetPath;
  final Color background;
  final Color border;
  final Color accent;
}

OrganVisualStyle organVisualStyle(String organ) {
  switch (organ.trim().toLowerCase()) {
    case 'heart':
      return const OrganVisualStyle(
        assetPath: 'assets/images/organs/heart.png',
        background: AppStyles.surface,
        border: AppStyles.border,
        accent: AppStyles.primary,
      );
    case 'liver':
      return const OrganVisualStyle(
        assetPath: 'assets/images/organs/liver.png',
        background: AppStyles.surface,
        border: AppStyles.border,
        accent: AppStyles.primary,
      );
    case 'kidney':
      return const OrganVisualStyle(
        assetPath: 'assets/images/organs/kidney.png',
        background: AppStyles.surface,
        border: AppStyles.border,
        accent: AppStyles.primary,
      );
    case 'lung':
    case 'lungs':
      return const OrganVisualStyle(
        assetPath: 'assets/images/organs/lungs.png',
        background: AppStyles.surface,
        border: AppStyles.border,
        accent: AppStyles.primary,
      );
    case 'diabetes / metabolic':
    case 'diabetes':
      return const OrganVisualStyle(
        assetPath: 'assets/images/organs/brain_metabolic.png',
        background: AppStyles.surface,
        border: AppStyles.border,
        accent: AppStyles.primary,
      );
    case 'brain / metabolic':
    case 'brain':
      return const OrganVisualStyle(
        assetPath: 'assets/images/organs/brain_metabolic.png',
        background: AppStyles.surface,
        border: AppStyles.border,
        accent: AppStyles.primary,
      );
    case 'inflammation':
    case 'cbc / differential':
    case 'cbc':
      return const OrganVisualStyle(
        assetPath: 'assets/images/organs/inflammation.png',
        background: AppStyles.surface,
        border: AppStyles.border,
        accent: AppStyles.primary,
      );
    case 'pancreas':
    case 'pancreatic enzymes':
      return const OrganVisualStyle(
        assetPath: 'assets/images/organs/pancreas.png',
        background: AppStyles.surface,
        border: AppStyles.border,
        accent: AppStyles.primary,
      );
    case 'cancer awareness':
    case 'cancer':
      return const OrganVisualStyle(
        assetPath: 'assets/images/organs/cancer_awareness.png',
        background: AppStyles.surface,
        border: AppStyles.border,
        accent: AppStyles.primary,
      );
    default:
      return const OrganVisualStyle(
        assetPath: 'assets/images/organs/heart.png',
        background: AppStyles.softBlue,
        border: AppStyles.softBlueBorder,
        accent: AppStyles.primary,
      );
  }
}
