import 'package:flutter_test/flutter_test.dart';
import 'package:vitalmap/core/local_analysis_engine.dart';
import 'package:vitalmap/core/risk_rules.dart';

void main() {
  test('risk rules expose normalized severity ranks', () {
    expect(aipRisk(0.05).level, lowConcern);
    expect(aipRisk(0.2).level, monitor);
    expect(aipRisk(0.4).level, attentionNeeded);
    expect(
        severityRank('High awareness indicator; clinical review suggested'), 3);
    expect(overallRisk([lowConcern, monitor]), monitor);
  });

  test('local analysis engine calculates available indicators', () {
    final response = LocalAnalysisEngine().analyze({
      'profile': {
        'age': 60,
        'sex': 'Female',
        'height_cm': 160,
        'weight_kg': 70,
        'waist_cm': 92,
      },
      'general_health': {
        'physical_activity': 'Low',
        'high_sugar_intake': 'High',
      },
      'lipid_profile': {
        'triglycerides': 265.71,
        'triglycerides_unit': 'mg/dL',
        'hdl': 38.67,
        'hdl_unit': 'mg/dL',
      },
      'diabetes_profile': {
        'fasting_glucose': 126,
        'fasting_glucose_unit': 'mg/dL',
        'hba1c': 7.2,
      },
      'liver_function': {'ast': 80, 'alt': 60, 'ggt': 90, 'albumin': 3.5},
      'cbc': {
        'platelets': 150,
        'platelets_unit': '10^9/L',
        'neutrophils': 70,
        'neutrophils_unit': '%',
        'lymphocytes': 20,
        'lymphocytes_unit': '%',
      },
      'kidney_function': {'creatinine': 1.13},
      'vitals': {'spo2': 89},
      'pancreatic_enzymes': {'lipase': 200, 'amylase': 40},
      'tumor_markers': {'afp': 250},
    });

    final results = List<Map<String, dynamic>>.from(
      response['calculated_results'] as List,
    );
    expect(response['overall_risk'], attentionNeeded);
    expect(results.map((item) => item['index_name']), contains('AIP'));
    expect(results.map((item) => item['index_name']), contains('TyG'));
    expect(results.map((item) => item['index_name']), contains('eGFR'));
    expect(results.first['ai_recommendation'], isA<Map<String, dynamic>>());
  });
}
