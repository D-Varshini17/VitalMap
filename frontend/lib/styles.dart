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

  static const Color primary = Color(0xFF12B5A6);
  static const Color navy = Color(0xFF0B2545);
  static const Color deepBlue = Color(0xFF0B2545);
  static const Color accent = Color(0xFF12B5A6);
  static const Color pageStart = Color(0xFFF3F6FA);
  static const Color pageEnd = Color(0xFFF3F6FA);
  static const Color page = pageStart;
  static const Color surface = Colors.white;
  static const Color glass = Color(0xDFFFFFFF);
  static const Color text = Color(0xFF14212E);
  static const Color muted = Color(0xFF64748B);
  static const Color tertiaryText = Color(0xFF94A3B8);
  static const Color unitText = Color(0xFF64748B);
  static const Color border = Color(0xFFDCE3EA);
  static const Color softBlue = Color(0xFFEAF7FF);
  static const Color softBlueBorder = Color(0xFFCFEFFF);
  static const Color softBlueText = Color(0xFF245D7A);

  static const HealthStatusStyle lowConcernStatus = HealthStatusStyle(
    label: 'Good',
    background: Color(0xFFEAF5EE),
    badgeBackground: Color(0xFFD8EDDF),
    border: Color(0xFFBBDCC7),
    accent: Color(0xFF4F9D69),
    text: Color(0xFF28603D),
    icon: Icons.spa_outlined,
  );

  static const HealthStatusStyle monitorStatus = HealthStatusStyle(
    label: 'Monitor',
    background: Color(0xFFFFF6DF),
    badgeBackground: Color(0xFFFFE9B4),
    border: Color(0xFFF0D28F),
    accent: Color(0xFFE2A93B),
    text: Color(0xFF705019),
    icon: Icons.visibility_outlined,
  );

  static const HealthStatusStyle attentionStatus = HealthStatusStyle(
    label: 'Attention Needed',
    background: Color(0xFFFFEFEC),
    badgeBackground: Color(0xFFFFDCD5),
    border: Color(0xFFF2C0B7),
    accent: Color(0xFFE85D4A),
    text: Color(0xFF913A2D),
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
        value.contains('within awareness threshold') ||
        value.contains('good')) {
      return lowConcernStatus;
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
      fillColor: Colors.white,
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
