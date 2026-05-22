import 'package:flutter/material.dart';

import 'core/risk_rules.dart';

class HealthStatusStyle {
  final String label;
  final Color background;
  final Color badgeBackground;
  final Color border;
  final Color accent;
  final Color text;
  final IconData icon;

  const HealthStatusStyle({
    required this.label,
    required this.background,
    required this.badgeBackground,
    required this.border,
    required this.accent,
    required this.text,
    required this.icon,
  });
}

class ContributorStyle {
  final Color background;
  final Color badgeBackground;
  final Color border;
  final Color accent;
  final Color text;
  final IconData icon;

  const ContributorStyle({
    required this.background,
    required this.badgeBackground,
    required this.border,
    required this.accent,
    required this.text,
    required this.icon,
  });
}

class AppStyles {
  static const String logoAsset = 'assets/logo_medid.jpeg';

  static const Color primary = Color(0xFF0E86C8);
  static const Color navy = Color(0xFF08264A);
  static const Color accent = Color(0xFF23D6C8);
  static const Color page = Color(0xFFF4FBFF);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF102B3F);
  static const Color muted = Color(0xFF5F7886);
  static const Color border = Color(0xFFDDEEF5);
  static const Color softBlue = Color(0xFFEAF7FF);
  static const Color softBlueBorder = Color(0xFFCFEFFF);
  static const Color softBlueText = Color(0xFF245D7A);

  static const HealthStatusStyle lowConcernStatus = HealthStatusStyle(
    label: 'Low Concern',
    background: Color(0xFFECF8EF),
    badgeBackground: Color(0xFFDDF2E4),
    border: Color(0xFFCBEAD5),
    accent: Color(0xFF65B985),
    text: Color(0xFF245E3E),
    icon: Icons.spa_outlined,
  );

  static const HealthStatusStyle monitorStatus = HealthStatusStyle(
    label: 'Monitor',
    background: Color(0xFFFFF7E7),
    badgeBackground: Color(0xFFFFE9BE),
    border: Color(0xFFF3D8A2),
    accent: Color(0xFFD99D41),
    text: Color(0xFF75501F),
    icon: Icons.visibility_outlined,
  );

  static const HealthStatusStyle attentionStatus = HealthStatusStyle(
    label: 'Attention Needed',
    background: Color(0xFFFFF0F2),
    badgeBackground: Color(0xFFFFDDE3),
    border: Color(0xFFF4CCD3),
    accent: Color(0xFFD97082),
    text: Color(0xFF813945),
    icon: Icons.favorite_border,
  );

  static const HealthStatusStyle moreDataStatus = HealthStatusStyle(
    label: 'More Data Needed',
    background: Color(0xFFF5F3FA),
    badgeBackground: Color(0xFFE9E3F5),
    border: Color(0xFFDDD4EF),
    accent: Color(0xFF9C89CD),
    text: Color(0xFF584B70),
    icon: Icons.add_chart_outlined,
  );

  static const ContributorStyle lifestyleContributor = ContributorStyle(
    background: Color(0xFFF5EEFF),
    badgeBackground: Color(0xFFE9D9FF),
    border: Color(0xFFE0CCF7),
    accent: Color(0xFFA675D6),
    text: Color(0xFF5D3D7C),
    icon: Icons.self_improvement,
  );

  static const ContributorStyle foodContributor = ContributorStyle(
    background: Color(0xFFFFF2E8),
    badgeBackground: Color(0xFFFFDEC3),
    border: Color(0xFFF2D3B8),
    accent: Color(0xFFE49A52),
    text: Color(0xFF744C22),
    icon: Icons.restaurant_menu,
  );

  static const ContributorStyle environmentContributor = ContributorStyle(
    background: Color(0xFFEAF8F6),
    badgeBackground: Color(0xFFD3F0EC),
    border: Color(0xFFC4E8E2),
    accent: Color(0xFF48B7AB),
    text: Color(0xFF235D57),
    icon: Icons.eco_outlined,
  );

  static const ContributorStyle generalInfo = ContributorStyle(
    background: softBlue,
    badgeBackground: Color(0xFFD8F1FF),
    border: softBlueBorder,
    accent: primary,
    text: softBlueText,
    icon: Icons.info_outline,
  );

  static HealthStatusStyle statusStyle(String? rawStatus) {
    final value = (rawStatus ?? '').trim().toLowerCase();
    if (value.isEmpty ||
        value.contains('more data') ||
        value.contains('needed') && !value.contains('attention')) {
      return moreDataStatus;
    }
    if (value.startsWith('high') ||
        value.contains('attention') ||
        value.contains('clinical review') ||
        value.contains('awareness indicator')) {
      return attentionStatus;
    }
    if (value.startsWith('moderate') ||
        value.contains('monitor') ||
        value.contains('monitoring')) {
      return monitorStatus;
    }
    if (value.startsWith('low') ||
        value.contains('optimal') ||
        value.contains('within awareness threshold')) {
      return lowConcernStatus;
    }
    return moreDataStatus;
  }

  static String statusLabel(String? rawStatus) => statusStyle(rawStatus).label;

  static int statusRank(String? rawStatus) {
    return severityRank(rawStatus);
  }

  static ContributorStyle contributorStyle(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('food')) return foodContributor;
    if (normalized.contains('environment')) return environmentContributor;
    if (normalized.contains('lifestyle')) return lifestyleContributor;
    return generalInfo;
  }

  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: page,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: accent,
      surface: surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: page,
      foregroundColor: text,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: muted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: text, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: text, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(color: text),
      bodyMedium: TextStyle(color: muted),
      labelLarge: TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}
