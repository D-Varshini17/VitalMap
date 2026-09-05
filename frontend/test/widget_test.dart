import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vitalmap/core/responsive.dart';
import 'package:vitalmap/main.dart';
import 'package:vitalmap/theme/app_theme_controller.dart';

void main() {
  test('responsive breakpoints classify phone, tablet, and desktop widths', () {
    expect(Responsive.sizeForWidth(390), ResponsiveSize.mobile);
    expect(Responsive.sizeForWidth(800), ResponsiveSize.tablet);
    expect(Responsive.sizeForWidth(1440), ResponsiveSize.desktop);
  });

  test('appearance mode persists and restores all supported modes', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final controller = AppThemeController();

    await controller.setThemeMode(ThemeMode.dark);
    expect(controller.themeMode, ThemeMode.dark);

    final restored = AppThemeController();
    await restored.load();
    expect(restored.themeMode, ThemeMode.dark);

    await restored.setThemeMode(ThemeMode.system);
    final systemRestored = AppThemeController();
    await systemRestored.load();
    expect(systemRestored.themeMode, ThemeMode.system);

    controller.dispose();
    restored.dispose();
    systemRestored.dispose();
  });

  testWidgets('login screen is shown before authentication',
      (WidgetTester tester) async {
    await _openApp(tester);

    expect(find.text('Welcome to VitalMap'), findsOneWidget);
    expect(
        find.text(
            'Sign in to continue your personalized health screening journey.'),
        findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('desktop auth layout keeps the login card centered',
      (WidgetTester tester) async {
    await _setViewport(tester, const Size(1440, 1000));
    await _openApp(tester);

    expect(find.text('Welcome to VitalMap'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
  });

  testWidgets('phone auth layout keeps the login card centered',
      (WidgetTester tester) async {
    await _setViewport(tester, const Size(390, 844));
    await _openApp(tester);

    expect(find.text('Welcome to VitalMap'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
  });
}

Future<void> _openApp(WidgetTester tester) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(const MyApp());
  await tester.pump(const Duration(milliseconds: 3800));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
