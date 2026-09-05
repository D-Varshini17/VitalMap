import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalmap/theme/app_theme_controller.dart';
import 'package:vitalmap/styles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all appearance values survive a new controller', () async {
    for (final mode in ThemeMode.values) {
      SharedPreferences.setMockInitialValues({});
      final controller = AppThemeController();
      await controller.setThemeMode(mode);
      final restored = AppThemeController();
      await restored.load();
      expect(restored.themeMode, mode);
      controller.dispose();
      restored.dispose();
    }
  });
  test('late preference load does not notify a disposed controller', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final controller = AppThemeController();
    final loading = controller.load();
    controller.dispose();
    await loading;
  });
  testWidgets('system theme follows live platform brightness changes',
      (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(MaterialApp(
        theme: AppStyles.lightTheme,
        darkTheme: AppStyles.darkTheme,
        themeMode: ThemeMode.system,
        home: const Scaffold(body: Text('System appearance'))));
    expect(Theme.of(tester.element(find.text('System appearance'))).brightness,
        Brightness.light);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('System appearance'))).brightness,
        Brightness.dark);
  });
}
