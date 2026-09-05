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

class VitalMapColors extends ThemeExtension<VitalMapColors> {
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color infoContainer;
  final Color onInfoContainer;

  const VitalMapColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  @override
  VitalMapColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? infoContainer,
    Color? onInfoContainer,
  }) {
    return VitalMapColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    );
  }

  @override
  VitalMapColors lerp(ThemeExtension<VitalMapColors>? other, double t) {
    if (other is! VitalMapColors) return this;
    return VitalMapColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}

class AppStyles {
  static const String logoAsset = 'assets/logo_medid.jpeg';

  static const Color primary = Color(0xFF0F6E56);
  static const Color accent = Color(0xFF0F6E56);
  static const Color pageStart = Color(0xFFF4F7F6);
  static const Color pageEnd = Color(0xFFF4F7F6);
  static const Color page = pageStart;
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF15201D);
  static const Color muted = Color(0xFF52605C);
  static const Color tertiaryText = Color(0xFF52605C);
  static const Color unitText = Color(0xFF52605C);
  static const Color border = Color(0xFFD9E4DF);
  static const Color softBlue = Color(0xFFEEF5F2);
  static const Color softBlueBorder = Color(0xFFD9E4DF);
  static const Color softBlueText = Color(0xFF15201D);

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

  static HealthStatusStyle themedStatusStyle(
    BuildContext context,
    String? rawStatus,
  ) {
    final base = statusStyle(rawStatus);
    final scheme = Theme.of(context).colorScheme;
    final extension = Theme.of(context).extension<VitalMapColors>();
    final label = base.label;
    if (label == 'Good') {
      return HealthStatusStyle(
        label: label,
        background: extension?.successContainer ?? scheme.secondaryContainer,
        badgeBackground:
            extension?.successContainer ?? scheme.secondaryContainer,
        border: scheme.outline,
        accent: extension?.success ?? scheme.primary,
        text: extension?.onSuccessContainer ?? scheme.onSecondaryContainer,
        icon: base.icon,
      );
    }
    if (label == 'Monitor') {
      return HealthStatusStyle(
        label: label,
        background: extension?.warningContainer ?? scheme.secondaryContainer,
        badgeBackground:
            extension?.warningContainer ?? scheme.secondaryContainer,
        border: scheme.outline,
        accent: extension?.warning ?? scheme.primary,
        text: extension?.onWarningContainer ?? scheme.onSecondaryContainer,
        icon: base.icon,
      );
    }
    if (label == 'Attention Needed') {
      return HealthStatusStyle(
        label: label,
        background: scheme.errorContainer,
        badgeBackground: scheme.errorContainer,
        border: scheme.error,
        accent: scheme.error,
        text: scheme.onErrorContainer,
        icon: base.icon,
      );
    }
    return HealthStatusStyle(
      label: label,
      background: extension?.infoContainer ?? scheme.surfaceContainer,
      badgeBackground: extension?.infoContainer ?? scheme.surfaceContainer,
      border: scheme.outline,
      accent: scheme.primary,
      text: extension?.onInfoContainer ?? scheme.onSurface,
      icon: base.icon,
    );
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

  static ContributorStyle themedContributorStyle(
      BuildContext context, String title) {
    final base = contributorStyle(title);
    final scheme = Theme.of(context).colorScheme;
    return ContributorStyle(
        background: scheme.surfaceContainer,
        badgeBackground: scheme.primaryContainer,
        border: scheme.outlineVariant,
        accent: scheme.primary,
        text: scheme.onSurface,
        icon: base.icon);
  }

  static ContributorStyle contributorStyle(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('food')) return foodContributor;
    if (normalized.contains('environment')) return environmentContributor;
    if (normalized.contains('lifestyle')) return lifestyleContributor;
    return generalInfo;
  }

  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    pageColor: Color(0xFFF4F7F6),
    surfaceColor: Color(0xFFFFFFFF),
    secondarySurface: Color(0xFFEEF5F2),
    primaryColor: primary,
    onPrimaryColor: Colors.white,
    textColor: text,
    mutedColor: muted,
    borderColor: border,
    extension: VitalMapColors(
      success: Color(0xFF0F6E56),
      successContainer: Color(0xFFE4F1EC),
      onSuccessContainer: Color(0xFF124D3E),
      warning: Color(0xFF9A6700),
      warningContainer: Color(0xFFFFF2CC),
      onWarningContainer: Color(0xFF5F4300),
      infoContainer: Color(0xFFE8F0F5),
      onInfoContainer: Color(0xFF243B4A),
    ),
  );

  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    pageColor: Color(0xFF0E1513),
    surfaceColor: Color(0xFF151F1C),
    secondarySurface: Color(0xFF1B2925),
    primaryColor: Color(0xFF62C5A5),
    onPrimaryColor: Color(0xFF07382B),
    textColor: Color(0xFFF2F7F5),
    mutedColor: Color(0xFFB5C5C0),
    borderColor: Color(0xFF30423C),
    extension: VitalMapColors(
      success: Color(0xFF62C5A5),
      successContainer: Color(0xFF1B3A30),
      onSuccessContainer: Color(0xFFBDEAD9),
      warning: Color(0xFFFFC857),
      warningContainer: Color(0xFF493817),
      onWarningContainer: Color(0xFFFFE5A3),
      infoContainer: Color(0xFF20333D),
      onInfoContainer: Color(0xFFC5E4F2),
    ),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color pageColor,
    required Color surfaceColor,
    required Color secondarySurface,
    required Color primaryColor,
    required Color onPrimaryColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required VitalMapColors extension,
  }) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: pageColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        onPrimary: onPrimaryColor,
        error: brightness == Brightness.dark
            ? const Color(0xFFFFB4AB)
            : const Color(0xFFB42318),
        onError: brightness == Brightness.dark
            ? const Color(0xFF690005)
            : Colors.white,
        errorContainer: brightness == Brightness.dark
            ? const Color(0xFF442520)
            : const Color(0xFFFFF1EF),
        onErrorContainer: brightness == Brightness.dark
            ? const Color(0xFFFFDAD6)
            : const Color(0xFF7A271A),
        secondary: primaryColor,
        surface: surfaceColor,
        surfaceContainer: secondarySurface,
        onSurface: textColor,
        onSurfaceVariant: mutedColor,
        outlineVariant: borderColor,
        primaryContainer: extension.successContainer,
        onPrimaryContainer: extension.onSuccessContainer,
        outline: mutedColor,
      ),
      extensions: [extension],
      textSelectionTheme: TextSelectionThemeData(
          cursorColor: primaryColor,
          selectionColor: primaryColor.withValues(alpha: 0.25),
          selectionHandleColor: primaryColor),
      dialogTheme: DialogThemeData(backgroundColor: surfaceColor),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surfaceColor),
      popupMenuTheme: PopupMenuThemeData(
          color: surfaceColor, textStyle: TextStyle(color: textColor)),
      textTheme: TextTheme(
        titleLarge: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, color: textColor),
        titleMedium: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
        titleSmall: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
        bodyLarge: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: mutedColor),
        bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: mutedColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: pageColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: mutedColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondarySurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: mutedColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: TextStyle(
            color: mutedColor, fontSize: 13, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(
            color: mutedColor, fontSize: 13, fontWeight: FontWeight.w500),
        suffixStyle: TextStyle(
            color: mutedColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: borderColor),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  static ThemeData get theme => lightTheme;
}
