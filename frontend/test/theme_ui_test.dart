import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalmap/styles.dart';
import 'package:vitalmap/main.dart';
import 'package:vitalmap/storage/local_storage.dart';
import 'package:vitalmap/core/local_analysis_engine.dart';
import 'package:vitalmap/core/ui_result_adapter.dart';
import 'package:vitalmap/screens/login_screen.dart';
import 'package:vitalmap/screens/signup_screen.dart';
import 'package:vitalmap/screens/input_screen.dart';
import 'package:vitalmap/screens/results_screen.dart';
import 'package:vitalmap/screens/insight_screen.dart';
import 'package:vitalmap/screens/index_detail_screen.dart';
import 'package:vitalmap/screens/organ_detail_screen.dart';
import 'package:vitalmap/screens/add_missing_screen.dart';
import 'package:vitalmap/screens/more_screen.dart';
import 'package:vitalmap/theme/app_theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final response = LocalAnalysisEngine().analyze({
    'profile': {'age': 60, 'sex': 'Female', 'height_cm': 160, 'weight_kg': 70},
    'lipid_profile': {'triglycerides': 265.71, 'hdl': 38.67},
    'diabetes_profile': {'fasting_glucose': 126},
    'kidney_function': {'creatinine': 1.13},
  });
  final metric = HealthUiAdapter.metricsFromResponse(response).first;
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final theme =
        mode == ThemeMode.light ? AppStyles.lightTheme : AppStyles.darkTheme;
    test('$mode text and semantic status contrast meets AA', () {
      final c = theme.colorScheme;
      final e = theme.extension<VitalMapColors>()!;
      final pairs = [
        (c.onSurface, c.surface),
        (c.onSurfaceVariant, c.surface),
        (c.onSurface, theme.scaffoldBackgroundColor),
        (c.onSurfaceVariant, c.surfaceContainer),
        (c.onPrimary, c.primary),
        (e.onSuccessContainer, e.successContainer),
        (e.onWarningContainer, e.warningContainer),
        (e.onInfoContainer, e.infoContainer),
        (c.onErrorContainer, c.errorContainer),
      ];
      for (final pair in pairs) {
        final a = pair.$1.computeLuminance();
        final b = pair.$2.computeLuminance();
        expect(((a > b ? a : b) + .05) / ((a > b ? b : a) + .05),
            greaterThanOrEqualTo(4.5),
            reason: '$pair');
      }
    });
    for (final size in [
      const Size(360, 800),
      const Size(390, 844),
      const Size(430, 932),
      const Size(768, 1024),
      const Size(1024, 768),
      const Size(1280, 720),
      const Size(1366, 768),
      const Size(1440, 900),
      const Size(1920, 1080)
    ]) {
      testWidgets('$mode major screens at $size', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = AppThemeController();
        addTearDown(controller.dispose);
        final screens = <Widget>[
          HomeContainer(
              themeController: controller, onSignOut: () {}, userEmail: null),
          LoginScreen(onLogin: (_) {}),
          const SignupScreen(),
          InputScreen(onAnalysisComplete: (_) {}),
          const ResultsScreen(),
          ResultsScreen(response: response),
          const InsightScreen(),
          IndexDetailScreen(metric: metric),
          OrganDetailScreen(
              organKey: metric.organKey,
              organName: metric.organName,
              metrics: [metric],
              missingCount: 1),
          const AddMissingScreen(),
          MoreScreen(
              onStartAnalysis: () {},
              onViewResults: () {},
              onSignOut: () {},
              userEmail: 'test@example.com',
              themeMode: mode,
              onThemeModeChanged: (_) {}),
        ];
        for (final screen in screens) {
          await tester.pumpWidget(MaterialApp(
              theme: AppStyles.lightTheme,
              darkTheme: AppStyles.darkTheme,
              themeMode: mode,
              home: screen));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '${screen.runtimeType} $mode $size');
          expect(find.byType(Text), findsWidgets);
          for (final scrollable
              in find.byType(Scrollable).evaluate().toList()) {
            if (!scrollable.mounted) continue;
            final state =
                (scrollable as StatefulElement).state as ScrollableState;
            if (state.position.hasContentDimensions &&
                state.position.maxScrollExtent.isFinite) {
              state.position.jumpTo(state.position.maxScrollExtent);
              await tester.pump();
              expect(tester.takeException(), isNull,
                  reason: '${screen.runtimeType} scrolled');
            }
          }
          await tester.pumpWidget(const SizedBox());
        }
      });
    }
  }
  testWidgets('appearance sheet rebuilds app and saves selected mode',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppThemeController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(AnimatedBuilder(
        animation: controller,
        builder: (context, child) => MaterialApp(
              theme: AppStyles.lightTheme,
              darkTheme: AppStyles.darkTheme,
              themeMode: controller.themeMode,
              home: MoreScreen(
                  onStartAnalysis: () {},
                  onViewResults: () {},
                  onSignOut: () {},
                  userEmail: null,
                  themeMode: controller.themeMode,
                  onThemeModeChanged: controller.setThemeMode),
            )));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Appearance'));
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(find.text('Dark theme selected'), findsOneWidget);
    expect(Theme.of(tester.element(find.byType(MoreScreen))).brightness,
        Brightness.dark);
    final restored = AppThemeController();
    await restored.load();
    expect(restored.themeMode, ThemeMode.dark);
    restored.dispose();
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('clearing saved data refreshes preserved shell pages',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.saveLastPayload({
      'profile': {'age': 60}
    });
    await LocalStorage.saveLastResponse(response);
    final controller = AppThemeController();
    await tester.pumpWidget(MaterialApp(
      theme: AppStyles.lightTheme,
      home: HomeContainer(
          themeController: controller, onSignOut: () {}, userEmail: null),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Your Health Summary'), findsOneWidget);
    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Clear Saved Data'));
    await tester.tap(find.text('Clear Saved Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Clear'));
    await tester.pumpAndSettle();
    expect(await LocalStorage.loadLastResponse(), isNull);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('No screening insight yet'), findsOneWidget);
    await tester.tap(find.text('Input'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
