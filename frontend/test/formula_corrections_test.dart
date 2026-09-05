import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vitalmap/core/local_analysis_engine.dart';
import 'package:vitalmap/core/risk_rules.dart';
import 'package:vitalmap/utils/unit_conversion.dart';

Map<String, dynamic> _payload({
  double? triglycerides,
  double? hdl,
  double? fasting,
  double? spo2,
}) {
  return {
    'profile': {'age': 40, 'sex': 'Male'},
    'lipid_profile': {
      'triglycerides': triglycerides,
      'triglycerides_unit': 'mg/dL',
      'hdl': hdl,
      'hdl_unit': 'mg/dL',
    },
    'diabetes_profile': {
      'fasting_glucose': fasting,
      'fasting_glucose_unit': 'mg/dL',
      'ifg_diabetes': 'No',
    },
    'vitals': {'spo2': spo2},
  };
}

Map<String, dynamic>? _result(
  Map<String, dynamic> response,
  String indexName,
) {
  final results = response['calculated_results'] as List<dynamic>;
  for (final result in results) {
    if ((result as Map)['index_name'] == indexName) {
      return Map<String, dynamic>.from(result);
    }
  }
  return null;
}

void main() {
  test('AIP converts mg/dL to molar concentrations', () {
    final response = LocalAnalysisEngine().analyze(_payload(
      triglycerides: 150,
      hdl: 50,
    ));
    final aip = _result(response, 'AIP')!;
    final expected = math.log((150 / 88.57) / (50 / 38.67)) / math.ln10;
    expect(aip['score'], closeTo(expected, 0.001));
    expect(aip['values_used']['triglycerides_mmol/L'], closeTo(1.693, 0.001));
  });

  test('TyG uses the 8.5 and 8.8 screening boundaries', () {
    final response = LocalAnalysisEngine().analyze(_payload(
      triglycerides: 150,
      fasting: 100,
    ));
    expect(_result(response, 'TyG')!['score'], closeTo(8.918, 0.01));
    expect(tygRisk(8.49).level, lowConcern);
    expect(tygRisk(8.5).level, monitor);
    expect(tygRisk(8.8).level, attentionNeeded);
  });

  test('FLI exactly 60 is attention needed', () {
    expect(fliRisk(59.99).level, monitor);
    expect(fliRisk(60).level, attentionNeeded);
  });

  test('risk boundaries include requested AIP, FIB-4, and FLI rules', () {
    expect(aipRisk(0.10).level, lowConcern);
    expect(aipRisk(0.11).level, monitor);
    expect(aipRisk(0.21).level, monitor);
    expect(aipRisk(0.22).level, attentionNeeded);
    expect(fib4Risk(1.3).level, monitor);
    expect(fib4Risk(2.67).level, monitor);
    expect(fib4Risk(2.671).level, attentionNeeded);
  });

  test('missing and invalid values do not crash analysis', () {
    final response = LocalAnalysisEngine().analyze(_payload(
      triglycerides: -1,
      hdl: 0,
      fasting: null,
      spo2: 101,
    ));
    expect(response['overall_risk'], moreDataNeeded);
    expect(_result(response, 'AIP'), isNull);
    expect(_result(response, 'TyG'), isNull);
  });

  test('awareness markers do not determine overall risk', () {
    final response = LocalAnalysisEngine().analyze({
      ..._payload(),
      'tumor_markers': {'afp': 500},
    });
    expect(response['overall_risk'], moreDataNeeded);
    final afp = _result(response, 'AFP')!;
    expect(
        afp['risk_level'], 'Outside configured awareness/reference threshold');
    expect(afp['summary'], contains('Clinical interpretation is recommended'));
  });

  test('common unit conversions normalize values', () {
    expect(glucoseToMgdl(5.55, 'mmol/L'), closeTo(99.9, 0.01));
    expect(creatinineToMgdl(88.4, 'µmol/L'), closeTo(1, 0.001));
    expect(albuminToGdl(40, 'g/L'), closeTo(4, 0.001));
    expect(weightToKg(10, 'lb'), closeTo(4.53592, 0.00001));
    expect(waistToCm(10, 'inch'), closeTo(25.4, 0.001));
  });
}
