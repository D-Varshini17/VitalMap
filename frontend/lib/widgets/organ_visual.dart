import 'package:flutter/material.dart';

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
    final style = organVisualStyle(context, organ);

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

OrganVisualStyle organVisualStyle(BuildContext context, String organ) {
  switch (organ.trim().toLowerCase()) {
    case 'heart':
      return OrganVisualStyle(
        assetPath: 'assets/images/organs/heart.png',
        background: Theme.of(context).colorScheme.surface,
        border: Theme.of(context).colorScheme.outlineVariant,
        accent: Theme.of(context).colorScheme.primary,
      );
    case 'liver':
      return OrganVisualStyle(
        assetPath: 'assets/images/organs/liver.png',
        background: Theme.of(context).colorScheme.surface,
        border: Theme.of(context).colorScheme.outlineVariant,
        accent: Theme.of(context).colorScheme.primary,
      );
    case 'kidney':
      return OrganVisualStyle(
        assetPath: 'assets/images/organs/kidney.png',
        background: Theme.of(context).colorScheme.surface,
        border: Theme.of(context).colorScheme.outlineVariant,
        accent: Theme.of(context).colorScheme.primary,
      );
    case 'lung':
    case 'lungs':
      return OrganVisualStyle(
        assetPath: 'assets/images/organs/lungs.png',
        background: Theme.of(context).colorScheme.surface,
        border: Theme.of(context).colorScheme.outlineVariant,
        accent: Theme.of(context).colorScheme.primary,
      );
    case 'diabetes / metabolic':
    case 'diabetes':
      return OrganVisualStyle(
        assetPath: 'assets/images/organs/brain_metabolic.png',
        background: Theme.of(context).colorScheme.surface,
        border: Theme.of(context).colorScheme.outlineVariant,
        accent: Theme.of(context).colorScheme.primary,
      );
    case 'brain / metabolic':
    case 'brain':
      return OrganVisualStyle(
        assetPath: 'assets/images/organs/brain_metabolic.png',
        background: Theme.of(context).colorScheme.surface,
        border: Theme.of(context).colorScheme.outlineVariant,
        accent: Theme.of(context).colorScheme.primary,
      );
    case 'inflammation':
    case 'cbc / differential':
    case 'cbc':
      return OrganVisualStyle(
        assetPath: 'assets/images/organs/inflammation.png',
        background: Theme.of(context).colorScheme.surface,
        border: Theme.of(context).colorScheme.outlineVariant,
        accent: Theme.of(context).colorScheme.primary,
      );
    case 'pancreas':
    case 'pancreatic enzymes':
      return OrganVisualStyle(
        assetPath: 'assets/images/organs/pancreas.png',
        background: Theme.of(context).colorScheme.surface,
        border: Theme.of(context).colorScheme.outlineVariant,
        accent: Theme.of(context).colorScheme.primary,
      );
    case 'cancer awareness':
    case 'cancer':
      return OrganVisualStyle(
        assetPath: 'assets/images/organs/cancer_awareness.png',
        background: Theme.of(context).colorScheme.surface,
        border: Theme.of(context).colorScheme.outlineVariant,
        accent: Theme.of(context).colorScheme.primary,
      );
    default:
      return OrganVisualStyle(
        assetPath: 'assets/images/organs/heart.png',
        background: Theme.of(context).colorScheme.surfaceContainer,
        border: Theme.of(context).colorScheme.outlineVariant,
        accent: Theme.of(context).colorScheme.primary,
      );
  }
}
