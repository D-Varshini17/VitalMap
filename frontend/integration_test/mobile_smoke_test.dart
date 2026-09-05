import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalmap/core/local_analysis_engine.dart';
import 'package:vitalmap/main.dart';
import 'package:vitalmap/storage/local_storage.dart';
import 'package:vitalmap/styles.dart';
import 'package:vitalmap/theme/app_theme_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android auth presentation, screening, navigation and appearance',
      (tester) async {
    // Run only on a dedicated test device: all data below is synthetic.
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('theme_mode');
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Welcome to VitalMap'), findsOneWidget);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your full name'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());

    final payload = <String, dynamic>{
      'selected_report_sections': ['heart'],
      'profile': {
        'age': 60,
        'sex': 'Female',
        'height_cm': 160,
        'weight_kg': 70
      },
      'lipid_profile': {'triglycerides': 265.71, 'hdl': 38.67},
    };
    final result = LocalAnalysisEngine().analyze(payload);
    await LocalStorage.saveLastPayload(payload);
    await LocalStorage.saveLastResponse(result);
    final controller = AppThemeController();
    await controller.load();
    await tester.pumpWidget(AnimatedBuilder(
      animation: controller,
      builder: (context, child) => MaterialApp(
        theme: AppStyles.lightTheme,
        darkTheme: AppStyles.darkTheme,
        themeMode: controller.themeMode,
        home: HomeContainer(
          themeController: controller,
          onSignOut: () {},
          userEmail: null,
        ),
      ),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Your Health Summary'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Input'));
    await tester.pumpAndSettle();
    final age = find.byType(TextFormField).first;
    await tester.ensureVisible(age);
    await tester.enterText(age, '61');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Appearance'));
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(find.text('Dark theme selected'), findsOneWidget);
    final restored = AppThemeController();
    await restored.load();
    expect(restored.themeMode, ThemeMode.dark);
    restored.dispose();
    await tester.tap(find.text('Input'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(age).controller!.text, '61');
    expect(Theme.of(tester.element(age)).brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await LocalStorage.clearAll();
    await preferences.remove('theme_mode');
  });
}
