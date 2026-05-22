import 'dart:math' as math;

import '../utils/unit_conversion.dart';
import 'risk_rules.dart';

class LocalAnalysisEngine {
  static const disclaimerText =
      'For informational purposes only. This app is not a substitute for clinical diagnosis, treatment, or medical advice. Please consult a qualified healthcare professional for medical decisions.';

  Map<String, dynamic> analyze(Map<String, dynamic> payload) {
    final results = <Map<String, dynamic>>[];
    final moreNeeded = <Map<String, dynamic>>[];

    final profile = _map(payload['profile']);
    final general = _map(payload['general_health']);
    final vitals = _map(payload['vitals']);
    final lipids = _map(payload['lipid_profile']);
    final diabetes = _map(payload['diabetes_profile']);
    final liver = _map(payload['liver_function']);
    final cbc = _map(payload['cbc']);
    final kidney = _map(payload['kidney_function']);
    final pancreas = _map(payload['pancreatic_enzymes']);
    final tumor = _map(payload['tumor_markers']);

    final age = _int(profile['age']);
    final sex = _string(profile['sex']);
    final heightCm = _profileHeightCm(profile);
    final weightKg = _profileWeightKg(profile);
    final waist = _profileWaistCm(profile);
    final bmi = _bmi(heightCm, weightKg);

    final tg = triglyceridesToMgdl(
      _num(lipids['triglycerides']),
      _string(lipids['triglycerides_unit']) ?? 'mg/dL',
    );
    final hdl = cholesterolToMgdl(
      _num(lipids['hdl']),
      _string(lipids['hdl_unit']) ?? 'mg/dL',
    );
    final ldl = cholesterolToMgdl(
      _num(lipids['ldl']),
      _string(lipids['ldl_unit']) ?? 'mg/dL',
    );
    final totalCholesterol = cholesterolToMgdl(
      _num(lipids['total_cholesterol']),
      _string(lipids['total_cholesterol_unit']) ?? 'mg/dL',
    );
    final vldl = cholesterolToMgdl(
      _num(lipids['vldl']),
      _string(lipids['vldl_unit']) ?? 'mg/dL',
    );

    final fasting = glucoseToMgdl(
      _num(diabetes['fasting_glucose']),
      _string(diabetes['fasting_glucose_unit']) ?? 'mg/dL',
    );
    final ppbs = glucoseToMgdl(
      _num(diabetes['ppbs']),
      _string(diabetes['ppbs_unit']) ?? 'mg/dL',
    );
    final randomGlucose = glucoseToMgdl(
      _num(diabetes['random_blood_sugar']),
      _string(diabetes['random_blood_sugar_unit']) ?? 'mg/dL',
    );
    final hba1c = _num(diabetes['hba1c']);

    final ast = _num(liver['ast']);
    final alt = _num(liver['alt']);
    final ggt = _num(liver['ggt']);
    final albumin = albuminToGdl(
      _num(liver['albumin']),
      _string(liver['albumin_unit']) ?? 'g/dL',
    );
    final platelets = plateletsTo10e9L(
      _num(cbc['platelets']),
      _string(cbc['platelets_unit']) ?? '10^9/L',
    );
    final nlrInputs = _nlrInputs(cbc);
    final creatinine = creatinineToMgdl(
      _num(kidney['creatinine']),
      _string(kidney['creatinine_unit']) ?? 'mg/dL',
    );

    _calculateAip(
        results, moreNeeded, general, tg, hdl, ldl, totalCholesterol, vldl);
    _calculateTyg(results, moreNeeded, general, tg, fasting);
    _calculateMetabolic(
      results,
      moreNeeded,
      general,
      fasting,
      hba1c,
      ppbs,
      randomGlucose,
    );
    _calculateApri(results, moreNeeded, general, ast, platelets);
    _calculateFib4(results, moreNeeded, general, age, ast, alt, platelets);
    _calculateFli(results, moreNeeded, general, bmi, waist, ggt, tg);
    _calculateNafld(
      results,
      moreNeeded,
      general,
      age,
      bmi,
      ast,
      alt,
      platelets,
      fasting,
      hba1c,
      ppbs,
      randomGlucose,
      albumin,
    );
    _calculateNlr(results, moreNeeded, general, nlrInputs.$1, nlrInputs.$2);
    _calculateEgfr(results, moreNeeded, general, age, sex, creatinine);
    _calculateSpo2(results, moreNeeded, general, _num(vitals['spo2']));
    _calculateLar(
      results,
      moreNeeded,
      general,
      _num(pancreas['lipase']),
      _num(pancreas['amylase']),
    );
    _calculateTumorMarkers(results, moreNeeded, general, tumor);

    return {
      'overall_risk': overallRisk(
          results.map((result) => result['risk_level']?.toString())),
      'calculated_results': results,
      'more_data_needed': moreNeeded,
      'general_health_pattern': _generalHealthPattern(general),
      'disclaimer': disclaimerText,
      'offline_mode': true,
      'recommendation_mode': 'offline',
    };
  }

  void _calculateAip(
    List<Map<String, dynamic>> results,
    List<Map<String, dynamic>> moreNeeded,
    Map<String, dynamic> general,
    double? tg,
    double? hdl,
    double? ldl,
    double? totalCholesterol,
    double? vldl,
  ) {
    if (tg != null && hdl != null && tg > 0 && hdl > 0) {
      final score = math.log(tg / hdl) / math.ln10;
      final values = <String, dynamic>{
        'triglycerides_mg/dL': _round(tg, 2),
        'hdl_mg/dL': _round(hdl, 2),
      };
      if (ldl != null) values['ldl_mg/dL'] = _round(ldl, 2);
      if (totalCholesterol != null) {
        values['total_cholesterol_mg/dL'] = _round(totalCholesterol, 2);
      }
      if (vldl != null) values['vldl'] = _round(vldl, 2);
      results.add(_result(
        organ: 'Heart',
        indexName: 'AIP',
        score: _round(score, 3),
        risk: aipRisk(score),
        valuesUsed: values,
        formulaUsed: 'AIP = log10(Triglycerides / HDL)',
        general: general,
      ));
    } else {
      _moreNeeded(moreNeeded, 'AIP', 'Heart', {
        'triglycerides': tg,
        'hdl': hdl,
      });
    }
  }

  void _calculateTyg(
    List<Map<String, dynamic>> results,
    List<Map<String, dynamic>> moreNeeded,
    Map<String, dynamic> general,
    double? tg,
    double? fasting,
  ) {
    if (tg != null && fasting != null && tg > 0 && fasting > 0) {
      final score = math.log((tg * fasting) / 2.0);
      results.add(_result(
        organ: 'Diabetes / Metabolic',
        indexName: 'TyG',
        score: _round(score, 3),
        risk: tygRisk(score),
        valuesUsed: {
          'triglycerides_mg/dL': _round(tg, 2),
          'fasting_glucose_mg/dL': _round(fasting, 2),
        },
        formulaUsed: 'TyG = ln((Triglycerides x Fasting Glucose) / 2)',
        general: general,
      ));
    } else {
      _moreNeeded(moreNeeded, 'TyG', 'Diabetes / Metabolic', {
        'triglycerides': tg,
        'fasting_glucose': fasting,
      });
    }
  }

  void _calculateMetabolic(
    List<Map<String, dynamic>> results,
    List<Map<String, dynamic>> moreNeeded,
    Map<String, dynamic> general,
    double? fasting,
    double? hba1c,
    double? ppbs,
    double? randomGlucose,
  ) {
    if ([fasting, hba1c, ppbs, randomGlucose].any((value) => value != null)) {
      final values = <String, dynamic>{};
      if (fasting != null) values['fasting_glucose_mg/dL'] = _round(fasting, 2);
      if (hba1c != null) values['hba1c_%'] = hba1c;
      if (ppbs != null) values['ppbs_mg/dL'] = _round(ppbs, 2);
      if (randomGlucose != null) {
        values['random_blood_sugar_mg/dL'] = _round(randomGlucose, 2);
      }
      final score = hba1c ?? fasting ?? ppbs ?? randomGlucose;
      results.add(_result(
        organ: 'Diabetes / Metabolic',
        indexName: 'Metabolic screening insight',
        score: score == null ? null : _round(score, 2),
        risk: metabolicRisk(
          fasting: fasting,
          hba1c: hba1c,
          ppbs: ppbs,
          randomBloodSugar: randomGlucose,
        ),
        valuesUsed: values,
        formulaUsed: 'Direct glucose and HbA1c screening interpretation',
        general: general,
      ));
    } else {
      _moreNeeded(
          moreNeeded, 'Metabolic screening insight', 'Diabetes / Metabolic', {
        'fasting_glucose_or_hba1c_or_ppbs_or_random_blood_sugar': null,
      });
    }
  }

  void _calculateApri(
    List<Map<String, dynamic>> results,
    List<Map<String, dynamic>> moreNeeded,
    Map<String, dynamic> general,
    double? ast,
    double? platelets,
  ) {
    if (ast != null && platelets != null && platelets > 0) {
      final score = ((ast / 40.0) / platelets) * 100.0;
      results.add(_result(
        organ: 'Liver',
        indexName: 'APRI',
        score: _round(score, 3),
        risk: apriRisk(score),
        valuesUsed: {'ast': ast, 'platelets': platelets},
        formulaUsed: 'APRI = ((AST / 40) / Platelets) x 100',
        general: general,
      ));
    } else {
      _moreNeeded(
          moreNeeded, 'APRI', 'Liver', {'ast': ast, 'platelets': platelets});
    }
  }

  void _calculateFib4(
    List<Map<String, dynamic>> results,
    List<Map<String, dynamic>> moreNeeded,
    Map<String, dynamic> general,
    int? age,
    double? ast,
    double? alt,
    double? platelets,
  ) {
    if (age != null &&
        ast != null &&
        alt != null &&
        alt > 0 &&
        platelets != null &&
        platelets > 0) {
      final score = (age * ast) / (platelets * math.sqrt(alt));
      results.add(_result(
        organ: 'Liver',
        indexName: 'FIB-4',
        score: _round(score, 3),
        risk: fib4Risk(score),
        valuesUsed: {
          'age': age,
          'ast': ast,
          'alt': alt,
          'platelets': platelets,
        },
        formulaUsed: 'FIB-4 = (Age x AST) / (Platelets x sqrt(ALT))',
        general: general,
      ));
    } else {
      _moreNeeded(moreNeeded, 'FIB-4', 'Liver', {
        'age': age,
        'ast': ast,
        'alt': alt,
        'platelets': platelets,
      });
    }
  }

  void _calculateFli(
    List<Map<String, dynamic>> results,
    List<Map<String, dynamic>> moreNeeded,
    Map<String, dynamic> general,
    double? bmi,
    double? waist,
    double? ggt,
    double? tg,
  ) {
    if (bmi != null &&
        waist != null &&
        ggt != null &&
        ggt > 0 &&
        tg != null &&
        tg > 0) {
      final linear = 0.953 * math.log(tg) +
          0.139 * bmi +
          0.718 * math.log(ggt) +
          0.053 * waist -
          15.745;
      final score = (math.exp(linear) / (1 + math.exp(linear))) * 100;
      results.add(_result(
        organ: 'Liver',
        indexName: 'FLI',
        score: _round(score, 2),
        risk: fliRisk(score),
        valuesUsed: {
          'bmi': _round(bmi, 2),
          'waist_cm': _round(waist, 2),
          'ggt': ggt,
          'triglycerides_mg/dL': _round(tg, 2),
        },
        formulaUsed: 'FLI = logistic BMI + waist + GGT + triglycerides formula',
        general: general,
      ));
    } else {
      _moreNeeded(moreNeeded, 'FLI', 'Liver', {
        'bmi': bmi,
        'waist_cm': waist,
        'ggt': ggt,
        'triglycerides': tg,
      });
    }
  }

  void _calculateNafld(
    List<Map<String, dynamic>> results,
    List<Map<String, dynamic>> moreNeeded,
    Map<String, dynamic> general,
    int? age,
    double? bmi,
    double? ast,
    double? alt,
    double? platelets,
    double? fasting,
    double? hba1c,
    double? ppbs,
    double? randomGlucose,
    double? albumin,
  ) {
    final glucoseAvailable =
        [fasting, hba1c, ppbs, randomGlucose].any((value) => value != null);
    if (age != null &&
        bmi != null &&
        ast != null &&
        alt != null &&
        alt > 0 &&
        platelets != null &&
        albumin != null &&
        glucoseAvailable) {
      final glucoseFlag = (fasting != null && fasting >= 100) ||
              (hba1c != null && hba1c >= 5.7) ||
              (ppbs != null && ppbs >= 140) ||
              (randomGlucose != null && randomGlucose >= 140)
          ? 1
          : 0;
      final score = -1.675 +
          (0.037 * age) +
          (0.094 * bmi) +
          (1.13 * glucoseFlag) +
          (0.99 * (ast / alt)) -
          (0.013 * platelets) -
          (0.66 * albumin);
      results.add(_result(
        organ: 'Liver',
        indexName: 'NAFLD Fibrosis Score',
        score: _round(score, 3),
        risk: nafldRisk(score),
        valuesUsed: {
          'age': age,
          'bmi': _round(bmi, 2),
          'ast': ast,
          'alt': alt,
          'platelets': platelets,
          'glucose_pattern_flag': glucoseFlag,
          'albumin': albumin,
        },
        formulaUsed:
            'NAFLD = age + BMI + AST/ALT + platelets + glucose pattern + albumin formula',
        general: general,
      ));
    } else {
      _moreNeeded(moreNeeded, 'NAFLD Fibrosis Score', 'Liver', {
        'age': age,
        'bmi': bmi,
        'ast': ast,
        'alt': alt,
        'platelets': platelets,
        'glucose_or_hba1c': glucoseAvailable ? 1 : null,
        'albumin': albumin,
      });
    }
  }

  void _calculateNlr(
    List<Map<String, dynamic>> results,
    List<Map<String, dynamic>> moreNeeded,
    Map<String, dynamic> general,
    double? neutrophils,
    double? lymphocytes,
  ) {
    if (neutrophils != null && lymphocytes != null && lymphocytes > 0) {
      final score = neutrophils / lymphocytes;
      results.add(_result(
        organ: 'Inflammation',
        indexName: 'NLR',
        score: _round(score, 3),
        risk: nlrRisk(score),
        valuesUsed: {'neutrophils': neutrophils, 'lymphocytes': lymphocytes},
        formulaUsed: 'NLR = Neutrophils / Lymphocytes',
        general: general,
      ));
    } else {
      _moreNeeded(moreNeeded, 'NLR', 'Inflammation',
          {'neutrophils': neutrophils, 'lymphocytes': lymphocytes});
    }
  }

  void _calculateEgfr(
    List<Map<String, dynamic>> results,
    List<Map<String, dynamic>> moreNeeded,
    Map<String, dynamic> general,
    int? age,
    String? sex,
    double? creatinine,
  ) {
    if (age != null && sex != null && creatinine != null && creatinine > 0) {
      final sexLower = sex.toLowerCase();
      final isFemale = sexLower.startsWith('f');
      final k = isFemale ? 0.7 : 0.9;
      final alpha = isFemale ? -0.241 : -0.302;
      final score = 142 *
          math.pow(math.min(creatinine / k, 1), alpha) *
          math.pow(math.max(creatinine / k, 1), -1.200) *
          math.pow(0.9938, age) *
          (isFemale ? 1.012 : 1);
      results.add(_result(
        organ: 'Kidney',
        indexName: 'eGFR',
        score: _round(score, 1),
        risk: egfrRisk(score.toDouble()),
        valuesUsed: {
          'age': age,
          'sex': sex,
          'creatinine_mg/dL': _round(creatinine, 3),
        },
        formulaUsed:
            'eGFR = age + sex + creatinine based CKD-EPI 2021 estimate',
        general: general,
      ));
    } else {
      _moreNeeded(moreNeeded, 'eGFR', 'Kidney',
          {'age': age, 'sex': sex, 'creatinine': creatinine});
    }
  }

  void _calculateSpo2(
    List<Map<String, dynamic>> results,
    List<Map<String, dynamic>> moreNeeded,
    Map<String, dynamic> general,
    double? spo2,
  ) {
    if (spo2 != null) {
      results.add(_result(
        organ: 'Lung',
        indexName: 'SpO2',
        score: spo2,
        risk: spo2Risk(spo2),
        valuesUsed: {'spo2_%': spo2},
        formulaUsed: 'SpO2 direct interpretation',
        general: general,
      ));
    } else {
      _moreNeeded(moreNeeded, 'SpO2', 'Lung', {'spo2': spo2});
    }
  }

  void _calculateLar(
    List<Map<String, dynamic>> results,
    List<Map<String, dynamic>> moreNeeded,
    Map<String, dynamic> general,
    double? lipase,
    double? amylase,
  ) {
    if (lipase != null && amylase != null && amylase > 0) {
      final score = lipase / amylase;
      results.add(_result(
        organ: 'Pancreas',
        indexName: 'LAR',
        score: _round(score, 3),
        risk: larRisk(score),
        valuesUsed: {'lipase': lipase, 'amylase': amylase},
        formulaUsed: 'LAR = Lipase / Amylase',
        general: general,
      ));
    } else {
      _moreNeeded(moreNeeded, 'LAR', 'Pancreas',
          {'lipase': lipase, 'amylase': amylase});
    }
  }

  void _calculateTumorMarkers(
    List<Map<String, dynamic>> results,
    List<Map<String, dynamic>> moreNeeded,
    Map<String, dynamic> general,
    Map<String, dynamic> tumor,
  ) {
    const markers = [
      ('AFP', 'afp', 200.0),
      ('CA 15-3', 'ca15_3', 30.0),
      ('CA 27.29', 'ca27_29', 38.0),
    ];
    for (final marker in markers) {
      final value = _num(tumor[marker.$2]);
      if (value == null) {
        _moreNeeded(
            moreNeeded, marker.$1, 'Cancer Awareness', {marker.$2: value});
        continue;
      }
      results.add(_result(
        organ: 'Cancer Awareness',
        indexName: marker.$1,
        score: value,
        risk: tumorMarkerRisk(value, marker.$3),
        valuesUsed: {marker.$2: value},
        formulaUsed: '${marker.$1} direct awareness interpretation',
        general: general,
      ));
    }
  }

  Map<String, dynamic> _result({
    required String organ,
    required String indexName,
    required num? score,
    required RiskRuleResult risk,
    required Map<String, dynamic> valuesUsed,
    required String formulaUsed,
    required Map<String, dynamic> general,
  }) {
    return {
      'organ': organ,
      'index_name': indexName,
      'score': score,
      'risk_level': risk.level,
      'color': risk.color,
      'summary': _summary(indexName, organ, risk.level),
      'possible_contributors': _contributors(organ, general),
      'suggestions': _suggestions(organ, indexName),
      'lifestyle_improvement': _lifestyleImprovement(organ),
      'food_recommendations': _foodRecommendations(organ),
      'environment_recommendations': _environmentRecommendations(organ),
      'doctor_followup': _doctorFollowup(risk.level),
      'ai_recommendation': {
        'simple_summary': _summary(indexName, organ, risk.level),
        'possible_contributors': _contributors(organ, general),
        'lifestyle_recommendations': _lifestyleImprovement(organ),
        'food_recommendations': _foodRecommendations(organ),
        'environment_recommendations': _environmentRecommendations(organ),
        'doctor_followup': _doctorFollowup(risk.level),
        'disclaimer': disclaimerText,
        'mode': 'offline',
      },
      'values_used': valuesUsed,
      'disclaimer': disclaimerText,
      'formula_used': formulaUsed,
    };
  }

  void _moreNeeded(
    List<Map<String, dynamic>> moreNeeded,
    String indexName,
    String organ,
    Map<String, dynamic> fields,
  ) {
    var missing = fields.entries
        .where((entry) => entry.value == null)
        .map((entry) => entry.key)
        .toList();
    if (missing.isEmpty) missing = fields.keys.toList();
    moreNeeded.add({
      'index_name': indexName,
      'organ': organ,
      'missing_inputs': missing,
      'message': '$indexName needs ${missing.join(', ')}.',
    });
  }

  double? _profileHeightCm(Map<String, dynamic> profile) {
    final unit = _string(profile['height_unit']) ?? 'cm';
    if (profile['height_input'] != null || unit == 'ft-in') {
      if (unit == 'ft-in') {
        return heightFeetInchesToCm(
          _num(profile['height_feet']),
          _num(profile['height_inches']),
        );
      }
      return heightToCm(_num(profile['height_input']), unit);
    }
    return _num(profile['height_cm']);
  }

  double? _profileWeightKg(Map<String, dynamic> profile) {
    if (profile['weight_input'] != null) {
      return weightToKg(
        _num(profile['weight_input']),
        _string(profile['weight_unit']) ?? 'kg',
      );
    }
    return _num(profile['weight_kg']);
  }

  double? _profileWaistCm(Map<String, dynamic> profile) {
    if (profile['waist_input'] != null) {
      return waistToCm(
        _num(profile['waist_input']),
        _string(profile['waist_unit']) ?? 'cm',
      );
    }
    return _num(profile['waist_cm']);
  }

  double? _bmi(double? heightCm, double? weightKg) {
    if (heightCm == null || weightKg == null || heightCm <= 0) return null;
    return weightKg / math.pow(heightCm / 100.0, 2);
  }

  (double?, double?) _nlrInputs(Map<String, dynamic> cbc) {
    final neutUnit = _string(cbc['neutrophils_unit']) ?? '%';
    final lymphUnit = _string(cbc['lymphocytes_unit']) ?? '%';
    final bothPercent = isPercentUnit(neutUnit) && isPercentUnit(lymphUnit);
    final bothAbsolute =
        isAbsoluteCountUnit(neutUnit) && isAbsoluteCountUnit(lymphUnit);
    if (!bothPercent && !bothAbsolute) return (null, null);
    if (bothAbsolute) {
      return (
        absoluteCountTo10e9L(_num(cbc['neutrophils']), neutUnit),
        absoluteCountTo10e9L(_num(cbc['lymphocytes']), lymphUnit),
      );
    }
    return (_num(cbc['neutrophils']), _num(cbc['lymphocytes']));
  }

  List<String> _generalHealthPattern(Map<String, dynamic> general) {
    final out = <String>[];
    if (general.isEmpty) return out;
    if (['Former', 'Yes'].contains(general['smoking'])) {
      out.add('Smoking exposure reported');
    }
    if (general['alcohol'] == 'Frequent') {
      out.add('Frequent alcohol intake reported');
    }
    if (general['physical_activity'] == 'Low') {
      out.add('Low physical activity reported');
    }
    if (general['sleep_duration'] == '<5 hrs') {
      out.add('Short sleep duration reported');
    }
    if (general['stress_level'] == 'High') {
      out.add('High stress level reported');
    }
    if (general['family_history'] != null &&
        general['family_history'] != 'None') {
      out.add('Family history reported: ${general['family_history']}');
    }
    if (general['high_sugar_intake'] == 'High') {
      out.add('High sugar intake reported');
    }
    if (general['high_salt_intake'] == 'High') {
      out.add('High salt intake reported');
    }
    if (general['fried_processed_food'] == 'Frequent') {
      out.add('Frequent fried or processed food intake reported');
    }
    if (general['fruit_veg_intake'] == 'Low') {
      out.add('Low fruit and vegetable intake reported');
    }
    if (general['sugary_drinks'] == 'Frequently') {
      out.add('Frequent sugary drink intake reported');
    }
    if (['Moderate', 'High'].contains(general['air_pollution'])) {
      out.add('${general['air_pollution']} air pollution exposure reported');
    }
    if (general['occupational_exposure'] == 'Yes') {
      out.add('Occupational dust or chemical exposure reported');
    }
    if (general['passive_smoking'] == 'Yes') {
      out.add('Passive smoking exposure reported');
    }
    if (general['cooking_smoke'] == 'Yes' ||
        general['cooking_fuel_smoke'] == 'Yes') {
      out.add('Cooking smoke exposure reported');
    }
    return out;
  }

  List<String> _contributors(String organ, Map<String, dynamic> general) {
    final out = <String>[];
    if (general['physical_activity'] == 'Low') out.add('Low physical activity');
    if (general['fried_processed_food'] == 'Frequent') {
      out.add('Frequent fried or processed food intake');
    }
    if (general['high_sugar_intake'] == 'High') out.add('High sugar intake');
    if (general['sugary_drinks'] == 'Frequently') {
      out.add('Frequent sugary drinks');
    }
    if (general['high_salt_intake'] == 'High' &&
        ['Heart', 'Kidney', 'Diabetes / Metabolic'].contains(organ)) {
      out.add('High salt intake');
    }
    if (['Former', 'Yes'].contains(general['smoking']) ||
        general['passive_smoking'] == 'Yes') {
      out.add('Smoking exposure');
    }
    if (general['stress_level'] == 'High') out.add('High stress level');
    if (general['sleep_duration'] == '<5 hrs') out.add('Short sleep duration');
    if (['Liver', 'Pancreas'].contains(organ) &&
        ['Occasional', 'Frequent'].contains(general['alcohol'])) {
      out.add('Alcohol intake');
    }
    if (organ == 'Lung' &&
        ['Moderate', 'High'].contains(general['air_pollution'])) {
      out.add('Air pollution exposure');
    }
    if (organ == 'Lung' && general['cooking_smoke'] == 'Yes') {
      out.add('Cooking smoke exposure');
    }
    if (organ == 'Lung' && general['cooking_fuel_smoke'] == 'Yes') {
      out.add('Cooking fuel smoke exposure');
    }
    if (general['family_history'] != null &&
        general['family_history'] != 'None') {
      out.add('Family history');
    }
    return out.take(6).toList();
  }

  String _summary(String indexName, String organ, String riskLevel) {
    final labels = {
      'AIP':
          'The entered triglycerides and HDL values were used to create a lipid-related screening insight for heart and metabolic health.',
      'TyG':
          'The entered triglycerides and fasting glucose values were used to create a metabolic screening insight.',
      'Metabolic screening insight':
          'The entered glucose-related values were reviewed as a simple metabolic risk indicator.',
      'APRI':
          'The entered AST and platelet values were used to create a liver fibrosis screening insight.',
      'FIB-4':
          'The entered age, AST, ALT, and platelet values were used to create a liver fibrosis screening insight.',
      'FLI':
          'BMI, waist circumference, GGT, and triglycerides were used to create a fatty liver screening insight.',
      'NAFLD Fibrosis Score':
          'Age, BMI, AST, ALT, platelets, glucose pattern, and albumin were used to create a liver fibrosis screening insight.',
      'NLR':
          'Neutrophil and lymphocyte values were used to create an inflammation screening insight.',
      'LAR':
          'Lipase and amylase values were used to create a pancreatic enzyme ratio screening insight.',
      'SpO2':
          'Oxygen saturation was interpreted as a lung oxygen screening indicator.',
      'eGFR':
          'Age, sex, and creatinine were used to estimate a kidney function screening indicator.',
      'AFP': 'AFP was interpreted as a cancer awareness marker only.',
      'CA 15-3': 'CA 15-3 was interpreted as a cancer awareness marker only.',
      'CA 27.29': 'CA 27.29 was interpreted as a cancer awareness marker only.',
    };
    final base = labels[indexName] ??
        '$indexName was calculated as a $organ risk indicator.';
    return '$base The current risk indicator is ${riskLevel.toLowerCase()}.';
  }

  List<String> _suggestions(String organ, String indexName) {
    final common = [
      'Review these values with a qualified healthcare professional if they are outside the expected range.',
      'Track the same report values over time instead of relying on one reading only.',
    ];
    final organSpecific = {
      'Heart': [
        'Monitor blood pressure and glucose values if available.',
        'Discuss lipid profile results during a routine clinical review.',
      ],
      'Diabetes / Metabolic': [
        'Review glucose values with a healthcare professional.',
        'Consider repeat testing if values were taken during illness or unusual stress.',
      ],
      'Liver': [
        'Review liver function results with a healthcare professional.',
        'Avoid self-interpreting liver markers in isolation.',
      ],
      'Kidney': [
        'Review creatinine and eGFR trends with a healthcare professional.',
        'Discuss hydration, medicines, and repeat testing if results are unexpected.',
      ],
      'Lung': [
        'Recheck SpO2 with a reliable device if the reading seems unusual.',
        'Seek clinical advice if low oxygen readings persist or symptoms are present.',
      ],
      'Inflammation': [
        'Interpret CBC ratios along with symptoms and the full blood report.',
        'Repeat or review the CBC if values were taken during infection or stress.',
      ],
      'Pancreas': [
        'Review enzyme values with a healthcare professional if abdominal symptoms are present.',
        'Avoid interpreting enzyme ratios without clinical context.',
      ],
      'Cancer Awareness': [
        'Use this marker only as an awareness indicator, not as a cancer screening confirmation.',
        'Discuss abnormal or persistent marker values with a qualified healthcare professional.',
      ],
    };
    return [...(organSpecific[organ] ?? const <String>[]), ...common];
  }

  List<String> _lifestyleImprovement(String organ) {
    final base = [
      'Aim for regular walking or moderate physical activity as tolerated.',
      'Prefer vegetables, fruits, whole grains, and lean protein.',
      'Reduce sugary drinks, high-salt foods, and fried or processed foods.',
      'Avoid smoking exposure and limit alcohol intake.',
    ];
    if (organ == 'Lung') {
      base.add('Reduce smoke, dust, and pollution exposure where practical.');
    }
    if (organ == 'Kidney') {
      base.add(
          'Avoid unnecessary over-the-counter pain medicines unless advised by a clinician.');
    }
    return base;
  }

  List<String> _foodRecommendations(String organ) {
    final advice = [
      'Prefer vegetables, fruits, whole grains, and fiber-rich foods.',
      'Reduce sugary drinks and frequent fried or processed foods.',
      'Keep high-salt packaged foods occasional where practical.',
    ];
    if (['Heart', 'Diabetes / Metabolic', 'Liver'].contains(organ)) {
      advice.add('Choose lean protein and unsaturated fats more often.');
    }
    if (organ == 'Kidney') {
      advice.add(
          'Discuss any major diet restriction with a qualified healthcare professional.');
    }
    return advice;
  }

  List<String> _environmentRecommendations(String organ) {
    final advice = [
      'Avoid smoking and passive smoking exposure where possible.',
      'Reduce dust, chemical, and smoke exposure when practical.',
      'Use ventilation during cooking when smoke exposure is present.',
    ];
    if (organ == 'Lung') {
      advice.add(
          'Consider checking air quality and limiting outdoor exposure during high pollution periods.');
    }
    return advice;
  }

  String _doctorFollowup(String riskLevel) {
    final rank = severityRank(riskLevel);
    if (rank >= 3) {
      return 'Clinical review is suggested soon, especially if abnormal values persist or symptoms are present.';
    }
    if (rank == 2) {
      return 'Clinical review is suggested if the value persists, increases, or is linked with symptoms.';
    }
    if (rank == 1) {
      return 'Routine follow-up can be considered during regular health checkups.';
    }
    return 'More report values are needed before this risk indicator can be interpreted.';
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String? _string(dynamic value) => value?.toString();

  double? _num(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double _round(num value, int places) {
    final factor = math.pow(10, places).toDouble();
    return (value * factor).round() / factor;
  }
}
