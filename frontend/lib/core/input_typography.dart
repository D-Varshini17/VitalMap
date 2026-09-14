import 'package:flutter/material.dart';
import 'responsive.dart';

/// Typography scoped to the assessment form, without scaling other screens.
abstract final class InputTypography {
  static const value = 15.0;
  static const label = 14.0;
  static const helper = 12.0;
  static double heading(BuildContext context) =>
      Responsive.isMobile(context) ? 21 : 26;
  static double section(BuildContext context) =>
      Responsive.isMobile(context) ? 18 : 20;
}
