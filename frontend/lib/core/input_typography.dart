import 'package:flutter/material.dart';
import 'responsive.dart';

/// Typography scoped to the assessment form, without scaling other screens.
abstract final class InputTypography {
  static const value = 14.0;
  static const label = 13.0;
  static const body = 14.0;
  static const helper = 12.0;
  static double heading(BuildContext context) =>
      Responsive.isMobile(context) ? 20 : 24;
  static double section(BuildContext context) =>
      Responsive.isMobile(context) ? 17 : 19;

  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: body),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: body),
        bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: helper),
        titleLarge:
            base.textTheme.titleLarge?.copyWith(fontSize: section(context)),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: value),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontSize: value),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        labelStyle: const TextStyle(fontSize: label),
        floatingLabelStyle: const TextStyle(fontSize: label),
        helperStyle: const TextStyle(fontSize: helper),
        errorStyle: const TextStyle(fontSize: helper),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: base.elevatedButtonTheme.style?.copyWith(
        textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: value, fontWeight: FontWeight.w600)),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: base.outlinedButtonTheme.style?.copyWith(
        textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: value, fontWeight: FontWeight.w600)),
      )),
    );
  }
}
