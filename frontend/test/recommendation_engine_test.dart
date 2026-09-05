import 'package:flutter_test/flutter_test.dart';
import 'package:vitalmap/core/local_analysis_engine.dart';
import 'package:vitalmap/services/recommendation_engine.dart';

Map<String, dynamic> _basePayload() => {
      'profile': {'age': 40, 'sex': 'Male'},
      'general_health': {
        'physical_activity': 'Low',
        'sugary_drinks': 'Frequently',
        'fried_processed_food': 'Frequent',
        'smoking': 'Yes',
      },
      'lipid_profile': {
        'triglycerides': 100,
        'triglycerides_unit': 'mg/dL',
        'hdl': 60,
        'hdl_unit': 'mg/dL',
      },
      'diabetes_profile': {
        'fasting_glucose': 100,
        'fasting_glucose_unit': 'mg/dL',
        'ifg_diabetes': 'No',
      },
    };

Map<String, dynamic> _result(
  Map<String, dynamic> response,
  String name,
) {
  return Map<String, dynamic>.from(
    (response['calculated_results'] as List)
        .cast<Map>()
        .firstWhere((item) => item['index_name'] == name),
  );
}

void main() {
  test('AIP recommendation is low concern and tied to molar lipid inputs', () {
    final result =
        _result(LocalAnalysisEngine().analyze(_basePayload()), 'AIP');
    final recommendation = Map<String, dynamic>.from(result['recommendation']);

    expect(result['risk_level'], 'Low Concern');
    expect(recommendation['why'], contains('AIP ='));
    expect(recommendation['why'], contains('triglycerides mmol/L'));
    expect(recommendation['rule_ids'], contains('aip_molar_lipids'));
    expect(recommendation['interpretation'], contains('lower-concern'));
    expect(
        recommendation['interpretation'], isNot(contains('Attention Needed')));
  });

  test(
      'TyG monitor recommendation identifies fasting glucose and triglycerides',
      () {
    final payload = _basePayload()
      ..['lipid_profile']['triglycerides'] = 120
      ..['diabetes_profile']['fasting_glucose'] = 90;
    final result = _result(LocalAnalysisEngine().analyze(payload), 'TyG');
    final recommendation = Map<String, dynamic>.from(result['recommendation']);
    final monitoring = (recommendation['monitoring'] as List).join(' ');

    expect(result['score'], closeTo(8.594, 0.002));
    expect(result['risk_level'], 'Monitor');
    expect(monitoring,
        contains('Review fasting glucose and triglycerides separately'));
    expect(recommendation['cautions'].join(' '),
        contains('not a diabetes diagnosis'));
  });

  test('eGFR moderate result recommends trend review without diagnosing CKD',
      () {
    final recommendation = RecommendationEngine().recommend(
      indexName: 'eGFR',
      organ: 'Kidney',
      score: 75,
      riskLevel: 'Monitor',
      valuesUsed: {'age': 40, 'sex': 'Male', 'creatinine_mg/dL': 1.1},
      lifestyle: const {},
      formula: '2021 CKD-EPI Creatinine Equation',
    );
    final text = [
      recommendation.interpretation,
      ...recommendation.monitoring,
      ...recommendation.clinicianFollowUp,
      ...recommendation.cautions,
    ].join(' ');

    expect(text, contains('trend'));
    expect(text, contains('does not diagnose CKD'));
    expect(text, contains('urine albumin'));
  });

  test('NLR and LAR recommendations remain nonspecific and contextual', () {
    final nlr = RecommendationEngine().recommend(
      indexName: 'NLR',
      organ: 'Inflammation',
      score: 10,
      riskLevel: 'Attention Needed',
      valuesUsed: {'neutrophils': 80, 'lymphocytes': 8},
      lifestyle: const {},
      formula: 'NLR = Neutrophils / Lymphocytes',
    );
    final lar = RecommendationEngine().recommend(
      indexName: 'LAR',
      organ: 'Pancreas',
      score: 5,
      riskLevel: 'Attention Needed',
      valuesUsed: {'lipase': 200, 'amylase': 40},
      lifestyle: const {},
      formula: 'LAR = Lipase / Amylase',
    );

    expect(nlr.cautions.join(' '), contains('many other conditions'));
    expect(nlr.cautions.join(' '), isNot(contains('diagnose infection')));
    expect(lar.cautions.join(' '), contains('does not diagnose pancreatitis'));
  });

  test('awareness markers recommend interpretation without cancer claims', () {
    final recommendation = RecommendationEngine().recommend(
      indexName: 'AFP',
      organ: 'Cancer Awareness',
      score: 500,
      riskLevel: 'Attention Needed',
      valuesUsed: {'afp': 500},
      lifestyle: const {},
      formula: 'AFP direct awareness interpretation',
    );
    final text = [
      recommendation.interpretation,
      ...recommendation.clinicianFollowUp,
      ...recommendation.cautions,
    ].join(' ');

    expect(text, contains('cannot diagnose cancer'));
    expect(text, isNot(contains('Cancer detected')));
    expect(recommendation.ruleIds, contains('awareness_marker_only'));
  });

  test('missing index data includes units and estimation warning', () {
    final response = LocalAnalysisEngine().analyze({
      'profile': {'age': 40, 'sex': 'Male'},
      'liver_function': {'ast': 30},
    });
    final missing = (response['more_data_needed'] as List)
        .cast<Map>()
        .firstWhere((item) => item['index_name'] == 'FIB-4');

    expect(missing['required_units'], contains('platelets'));
    expect(missing['why_required'], contains('cannot be estimated'));
  });

  test('consistency validation rejects a mismatched risk category', () {
    expect(
      RecommendationEngine.validateResultConsistency(
        indexName: 'TyG',
        score: 9.0,
        riskLevel: 'Low Concern',
        valuesUsed: const {
          'triglycerides_mg/dL': 150,
          'fasting_glucose_mg/dL': 100,
        },
        formula: 'ln((TG x fasting glucose) / 2)',
      ),
      isFalse,
    );
  });
}
