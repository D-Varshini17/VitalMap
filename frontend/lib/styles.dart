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

  static const Color primary = Color(0xFF0F6E56);
  static const Color accent = Color(0xFF0F6E56);
  static const Color pageStart = Color(0xFFF7F9FB);
  static const Color pageEnd = Color(0xFFF7F9FB);
  static const Color page = pageStart;
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF10161C);
  static const Color muted = Color(0xFF5F6B76);
  static const Color tertiaryText = Color(0xFF5F6B76);
  static const Color unitText = Color(0xFF5F6B76);
  static const Color border = Color(0xFFE2E8ED);
  static const Color softBlue = Color(0xFFF1F4F7);
  static const Color softBlueBorder = Color(0xFFE2E8ED);
  static const Color softBlueText = Color(0xFF10161C);

  static const HealthStatusStyle lowConcernStatus = HealthStatusStyle(
    label: 'Good',
    background: Color(0xFFF1F4F7),
    badgeBackground: Color(0xFFE2F1EB),
    border: border,
    accent: primary,
    text: text,
    icon: Icons.spa_outlined,
  );

  static const HealthStatusStyle monitorStatus = HealthStatusStyle(
    label: 'Monitor',
    background: Color(0xFFF1F4F7),
    badgeBackground: Color(0xFFE8EEF2),
    border: border,
    accent: primary,
    text: text,
    icon: Icons.visibility_outlined,
  );

  static const HealthStatusStyle attentionStatus = HealthStatusStyle(
    label: 'Attention Needed',
    background: Color(0xFFFFF1EF),
    badgeBackground: Color(0xFFFFDDD8),
    border: Color(0xFFE8A59C),
    accent: Color(0xFFB42318),
    text: Color(0xFF7A271A),
    icon: Icons.favorite_border,
  );

  static const HealthStatusStyle moreDataStatus = HealthStatusStyle(
    label: 'More Data Needed',
    background: Color(0xFFF1F4F7),
    badgeBackground: Color(0xFFE8EEF2),
    border: border,
    accent: primary,
    text: text,
    icon: Icons.add_chart_outlined,
  );

  static const ContributorStyle lifestyleContributor = ContributorStyle(
    background: softBlue,
    badgeBackground: Color(0xFFE2F1EB),
    border: border,
    accent: primary,
    text: text,
    icon: Icons.self_improvement,
  );

  static const ContributorStyle foodContributor = ContributorStyle(
    background: softBlue,
    badgeBackground: Color(0xFFE2F1EB),
    border: border,
    accent: primary,
    text: text,
    icon: Icons.restaurant_menu,
  );

  static const ContributorStyle environmentContributor = ContributorStyle(
    background: softBlue,
    badgeBackground: Color(0xFFE2F1EB),
    border: border,
    accent: primary,
    text: text,
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
        value.contains('within awareness threshold') ||
        value.contains('within configured awareness threshold') ||
        value.contains('good')) {
      return lowConcernStatus;
    }
    if (value.contains('outside configured awareness threshold')) {
      return attentionStatus;
    }
    return moreDataStatus;
  }

  static String statusLabel(String? rawStatus) => statusStyle(rawStatus).label;

  static String displayStatusLabel(String? rawStatus, {String? indexName}) {
    final label = statusStyle(rawStatus).label;
    if (label == 'Good') {
      return indexName == 'BMI' ? 'Normal' : 'Good';
    }
    return label;
  }

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
    textTheme: const TextTheme(
      titleLarge:
          TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text),
      titleMedium:
          TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text),
      titleSmall:
          TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text),
      bodyLarge:
          TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: text),
      bodyMedium:
          TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: muted),
      bodySmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, color: tertiaryText),
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
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(
          color: muted, fontSize: 13, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(
          color: tertiaryText, fontSize: 13, fontWeight: FontWeight.w500),
      suffixStyle: const TextStyle(
          color: unitText,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0),
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
    // Consolidated textTheme is defined earlier; avoid duplicate named argument.
  );
}
