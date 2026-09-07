import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalmap/core/local_analysis_engine.dart';
import 'package:vitalmap/core/ui_result_adapter.dart';
import 'package:vitalmap/theme/app_theme_controller.dart';
import 'package:vitalmap/screens/index_detail_screen.dart';
import 'package:vitalmap/styles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first launch defaults to light when no saved theme exists', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppThemeController();
    addTearDown(controller.dispose);

    expect(controller.themeMode, ThemeMode.light);
    await controller.load();

    expect(controller.themeMode, ThemeMode.light);
  });

  test('unknown saved theme falls back to light', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'unexpected'});
    final controller = AppThemeController();
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.themeMode, ThemeMode.light);
  });

  test('explicit system theme still restores as system', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'system'});
    final controller = AppThemeController();
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.themeMode, ThemeMode.system);
  });

  testWidgets('doctor follow-up uses recommendation when direct field is blank',
      (tester) async {
    final metric = HealthMetric(
      indexName: 'AIP',
      displayName: 'Atherogenic Index',
      organKey: 'Heart',
      organName: 'Heart',
      scoreText: '0.10',
      unit: '',
      rawStatus: 'Low Concern',
      statusLabel: 'Low Concern',
      summary: 'Calculated from the values available in your report.',
      doctorFollowup: '',
      valuesUsed: const {'triglycerides_mg/dL': 100, 'hdl_mg/dL': 50},
      source: const {
        'doctor_followup': '   ',
        'formula_used': 'AIP formula',
        'recommendation': {
          'clinician_follow_up': [
            'Routine health follow-up may be appropriate.',
          ],
        },
      },
    );

    await tester.pumpWidget(MaterialApp(
      theme: AppStyles.lightTheme,
      darkTheme: AppStyles.darkTheme,
      home: IndexDetailScreen(metric: metric),
    ));

    expect(find.text('Routine health follow-up may be appropriate.'),
        findsOneWidget);
  });

  testWidgets(
      'doctor follow-up uses neutral fallback when all sources are blank',
      (tester) async {
    final metric = HealthMetric(
      indexName: 'AIP',
      displayName: 'Atherogenic Index',
      organKey: 'Heart',
      organName: 'Heart',
      scoreText: '0.10',
      unit: '',
      rawStatus: 'Low Concern',
      statusLabel: 'Low Concern',
      summary: 'Calculated from the values available in your report.',
      doctorFollowup: '',
      valuesUsed: const {'triglycerides_mg/dL': 100, 'hdl_mg/dL': 50},
      source: const {
        'doctor_followup': '   ',
        'formula_used': 'AIP formula',
        'recommendation': {'clinician_follow_up': []},
      },
    );

    await tester.pumpWidget(MaterialApp(
      theme: AppStyles.lightTheme,
      darkTheme: AppStyles.darkTheme,
      home: IndexDetailScreen(metric: metric),
    ));

    expect(
      find.text(
        'Discuss your screening results with a qualified healthcare professional if you have questions or concerns.',
      ),
      findsOneWidget,
    );
  });

  test('more data needed entries expose doctor follow-up detail data', () {
    final response = LocalAnalysisEngine().analyze(const <String, dynamic>{});
    final missing = HealthUiAdapter.moreDataNeeded(response)
        .firstWhere((item) => item['index_name'] == 'AIP');
    final metric = HealthUiAdapter.metricFromMissingData(missing);
    final source = metric.source!;

    expect(metric.rawStatus, 'More Data Needed');
    expect(source['doctor_followup'].toString().trim(), isNotEmpty);
    expect(
      source['doctor_followup'].toString(),
      contains('Additional information is needed'),
    );
  });

  // Regression coverage for every final result card's detail data source.
  test(
      'every implemented calculated indicator exposes nonblank detail follow-up data',
      () {
    final response = LocalAnalysisEngine().analyze({
      'profile': {
        'age': 55,
        'sex': 'Female',
        'height_cm': 160,
        'weight_kg': 72,
        'waist_cm': 88,
      },
      'general_health': {
        'physical_activity': 'Low',
        'smoking': 'No',
        'passive_smoking': 'No',
        'sugary_drinks': 'Sometimes',
        'fried_processed_food': 'Occasional',
        'fruit_veg_intake': 'Moderate',
        'high_salt_intake': 'Moderate',
        'sleep_duration': '6-8 hrs',
        'stress_level': 'Moderate',
        'air_pollution': 'Low',
        'cooking_smoke': 'No',
      },
      'lipid_profile': {
        'triglycerides': 160,
        'triglycerides_unit': 'mg/dL',
        'hdl': 45,
        'hdl_unit': 'mg/dL',
      },
      'diabetes_profile': {
        'fasting_glucose': 105,
        'fasting_glucose_unit': 'mg/dL',
        'ifg_diabetes': 'Yes',
      },
      'liver_function': {
        'ast': 42,
        'alt': 38,
        'ggt': 55,
        'albumin': 4.1,
        'albumin_unit': 'g/dL',
        'ast_uln': 40,
      },
      'cbc': {
        'platelets': 210,
        'platelets_unit': '10^9/L',
        'neutrophils': 60,
        'lymphocytes': 30,
      },
      'kidney_function': {'creatinine': 1.0, 'creatinine_unit': 'mg/dL'},
      'vitals': {'spo2': 97},
      'pancreatic_enzymes': {'lipase': 45, 'amylase': 50},
      'tumor_markers': {'afp': 5, 'ca15_3': 20, 'ca27_29': 25},
    });
    final metrics = HealthUiAdapter.metricsFromResponse(response);
    final names = metrics.map((metric) => metric.indexName).toSet();

    expect(
      names,
      containsAll({
        'AIP',
        'TyG',
        'APRI',
        'FIB-4',
        'FLI',
        'NAFLD Fibrosis Score',
        'NLR',
        'eGFR',
        'SpO2',
        'LAR',
        'AFP',
        'CA 15-3',
        'CA 27.29',
      }),
    );

    for (final metric in metrics) {
      expect(metric.doctorFollowup.trim(), isNotEmpty,
          reason: '${metric.indexName} should carry follow-up detail data');
    }
  });
}
