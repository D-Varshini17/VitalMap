// ignore_for_file: curly_braces_in_flow_control_structures

import '../core/formula_metadata.dart';
import '../core/risk_rules.dart';

class HealthRecommendation {
  const HealthRecommendation({
    required this.interpretation,
    required this.actions,
    required this.lifestyle,
    required this.food,
    required this.monitoring,
    required this.clinicianFollowUp,
    required this.cautions,
    required this.evidenceNote,
    required this.why,
    required this.ruleIds,
  });

  final String interpretation;
  final List<String> actions;
  final List<String> lifestyle;
  final List<String> food;
  final List<String> monitoring;
  final List<String> clinicianFollowUp;
  final List<String> cautions;
  final String evidenceNote;
  final String why;
  final List<String> ruleIds;

  Map<String, dynamic> toMap() => {
        'interpretation': interpretation,
        'actions': actions,
        'lifestyle': lifestyle,
        'food': food,
        'monitoring': monitoring,
        'clinician_follow_up': clinicianFollowUp,
        'cautions': cautions,
        'evidence_note': evidenceNote,
        'why': why,
        'rule_ids': ruleIds,
      };
}

class RecommendationEngine {
  static const _safety =
      'For informational purposes only. VitalMap is not a substitute for clinical diagnosis, treatment, or medical advice.';

  static bool validateResultConsistency({
    required String indexName,
    required num? score,
    required String riskLevel,
    required Map<String, dynamic> valuesUsed,
    required String formula,
  }) {
    if (score == null ||
        !score.isFinite ||
        riskLevel.trim().isEmpty ||
        valuesUsed.isEmpty ||
        formula.trim().isEmpty) {
      return false;
    }
    final normalizedRisk = riskLevel.toLowerCase();
    if (indexName == 'AFP' ||
        indexName == 'CA 15-3' ||
        indexName == 'CA 27.29') {
      return normalizedRisk.contains('awareness threshold');
    }
    final expected = switch (indexName) {
      'AIP' => aipRisk(score.toDouble()).level,
      'TyG' => tygRisk(score.toDouble()).level,
      'APRI' => apriRisk(score.toDouble()).level,
      'FIB-4' => fib4Risk(score.toDouble()).level,
      'FLI' => fliRisk(score.toDouble()).level,
      'NAFLD Fibrosis Score' => nafldRisk(score.toDouble()).level,
      'NLR' => nlrRisk(score.toDouble()).level,
      'eGFR' => egfrRisk(score.toDouble()).level,
      'SpO2' => spo2Risk(score.toDouble()).level,
      'LAR' => larRisk(score.toDouble()).level,
      _ => riskLevel,
    };
    return expected == riskLevel;
  }

  HealthRecommendation recommend({
    required String indexName,
    required String organ,
    required num score,
    required String riskLevel,
    required Map<String, dynamic> valuesUsed,
    required Map<String, dynamic> lifestyle,
    required String formula,
  }) {
    final metadata = FormulaMetadata.forIndex(indexName);
    final rank = _rank(riskLevel);
    final ruleIds = <String>[
      '${indexName.toLowerCase().replaceAll(' ', '_')}_$rank'
    ];
    final actions = <String>[];
    final lifestyleAdvice = <String>[];
    final food = <String>[];
    final monitoring = <String>[];
    final followUp = <String>[];
    final cautions = <String>[_safety];

    final interpretation = _interpretation(riskLevel);
    _indexSpecific(
      indexName,
      rank,
      score,
      valuesUsed,
      lifestyle,
      actions,
      lifestyleAdvice,
      food,
      monitoring,
      followUp,
      cautions,
      ruleIds,
    );
    _lifestyleSpecific(
      indexName,
      organ,
      lifestyle,
      lifestyleAdvice,
      food,
      cautions,
      ruleIds,
    );
    _universal(rank, monitoring, followUp, cautions);
    if (rank == 1) {
      lifestyleAdvice.addAll([
        'Continue healthy eating habits.',
        'Maintain regular physical activity appropriate for your health and abilities.',
        'Avoid tobacco and nicotine exposure.',
        'Maintain regular healthy sleep.',
      ]);
      ruleIds.add('universal_low_concern');
    }

    final normalized = valuesUsed.entries
        .map((entry) => '${_label(entry.key)} = ${entry.value}')
        .join('; ');
    final why =
        'This recommendation appears because $indexName = ${_format(score)}, risk = $riskLevel, and the normalized values were $normalized.';
    return HealthRecommendation(
      interpretation: interpretation,
      actions: _unique(actions),
      lifestyle: _unique(lifestyleAdvice),
      food: _unique(food),
      monitoring: _unique(monitoring),
      clinicianFollowUp: _unique(followUp),
      cautions: _unique(cautions),
      evidenceNote: metadata == null
          ? 'Formula metadata is unavailable for this indicator.'
          : '${metadata.interpretationNote} Evidence: ${metadata.evidenceSource}, ${metadata.evidenceYear}.',
      why: '$why Formula: $formula.',
      ruleIds: ruleIds,
    );
  }

  String _interpretation(String riskLevel) {
    switch (riskLevel) {
      case 'Low Concern':
        return 'Current entered values fall within the lower-concern screening range for this index.';
      case 'Monitor':
        return 'This screening value falls in an intermediate range. A single screening result does not establish a diagnosis.';
      case 'Attention Needed':
        return 'This screening result is outside the lower-concern range and deserves clinical review, especially if the underlying values remain abnormal or symptoms are present.';
      default:
        return 'VitalMap cannot calculate this screening index reliably because required information is missing.';
    }
  }

  void _universal(
    int rank,
    List<String> monitoring,
    List<String> followUp,
    List<String> cautions,
  ) {
    if (rank == 1) {
      monitoring
        ..add('Continue routine health checks when appropriate.')
        ..add('Keep previous laboratory reports so trends can be compared.');
    }
    if (rank >= 2) {
      monitoring
        ..add('Review the individual laboratory values producing the score.')
        ..add('Compare with previous reports when available.');
      followUp.add(
          'Discuss persistent abnormal results with a healthcare professional.');
    }
    if (rank == 3) {
      followUp.add(
          'Review the original laboratory report with a healthcare professional.');
      cautions.add(
          'This result does not diagnose disease and should not be used to start or change medication.');
    }
  }

  void _indexSpecific(
    String indexName,
    int rank,
    num score,
    Map<String, dynamic> values,
    Map<String, dynamic> lifestyle,
    List<String> actions,
    List<String> lifestyleAdvice,
    List<String> food,
    List<String> monitoring,
    List<String> followUp,
    List<String> cautions,
    List<String> ruleIds,
  ) {
    switch (indexName) {
      case 'AIP':
        _aip(
            rank, values, lifestyleAdvice, food, monitoring, followUp, ruleIds);
        break;
      case 'TyG':
        _tyg(rank, values, lifestyleAdvice, food, monitoring, followUp,
            cautions, ruleIds);
        break;
      case 'APRI':
        monitoring.addAll([
          'Review AST, platelet count, and the AST laboratory reference range.',
          'Consider trends across multiple reports.'
        ]);
        if (rank >= 2) {
          followUp.add(
              'Interpret APRI with other liver tests and clinical evaluation.');
        }
        if (rank == 3) {
          cautions.add(
              'APRI is a non-invasive fibrosis screening index; it does not diagnose fibrosis or cirrhosis.');
        }
        ruleIds.add('apri_values_and_uln');
        break;
      case 'FIB-4':
        monitoring.addAll([
          'Review AST, ALT, and platelet trends.',
          'Temporary illness or other conditions can affect liver enzymes.'
        ]);
        followUp.add(
            'FIB-4 interpretation can vary according to age, disease context, and clinical guideline.');
        if (rank == 3) {
          cautions.add(
              'Additional evaluation may be required; advanced fibrosis is not confirmed by FIB-4 alone.');
        }
        ruleIds.add('fib4_age_context');
        break;
      case 'FLI':
        monitoring.add(
            'Review the BMI, waist circumference, GGT, and triglycerides that produced FLI.');
        if (rank >= 2) {
          followUp.add(
              'Review metabolic health, body measurements, and liver tests with a healthcare professional.');
        }
        if (rank == 3) {
          cautions.add(
              'FLI indicates fatty-liver likelihood for screening only; it is not a diagnosis.');
        }
        ruleIds.add('fli_components');
        break;
      case 'NAFLD Fibrosis Score':
        monitoring.addAll([
          'Review AST, ALT, platelets, albumin, and glucose/diabetes status.',
          'This is an indeterminate screening range when classified as Monitor.'
        ]);
        if (rank >= 2) {
          followUp.add(
              'Consider professional liver evaluation if abnormalities persist.');
        }
        if (rank == 3) {
          cautions.add(
              'The score may warrant further assessment but does not diagnose advanced fibrosis.');
        }
        ruleIds.add('nafld_components');
        break;
      case 'NLR':
        cautions.add(
            'NLR can change with infection, inflammation, physiologic stress, and many other conditions.');
        monitoring.add('Interpret NLR with the complete CBC and symptoms.');
        if (rank >= 2) {
          followUp.add(
              'Repeat or professionally review the CBC if abnormal values persist.');
        }
        ruleIds.add('nlr_nonspecific');
        break;
      case 'eGFR':
        final egfr = score.toDouble();
        final category = egfr >= 90
            ? 'G1'
            : egfr >= 60
                ? 'G2'
                : egfr >= 45
                    ? 'G3a'
                    : egfr >= 30
                        ? 'G3b'
                        : egfr >= 15
                            ? 'G4'
                            : 'G5';
        monitoring.add(
            'Estimated filtration category: $category. A single result does not diagnose CKD.');
        if (egfr >= 90) {
          actions.add('Maintain healthy blood pressure and glucose habits.');
          cautions.add(
              'Normal/high estimated filtration does not exclude kidney disease when urine albumin or other evidence is present.');
        } else if (egfr >= 60) {
          followUp.add(
              'Monitor the creatinine/eGFR trend and consider urine albumin testing through a healthcare professional when appropriate.');
        } else {
          followUp.add(
              'Arrange professional kidney evaluation; dietary and fluid decisions should be individualized.');
          cautions.add(
              'Do not independently change potassium, phosphorus, protein, sodium, fluid, or medication intake based on eGFR alone.');
        }
        ruleIds.add('egfr_category_$category');
        break;
      case 'SpO2':
        monitoring.add(
            'Pulse oximeter accuracy can be affected by circulation, movement, skin temperature, nail products, and device quality.');
        if (score >= 95) {
          cautions.add('This reading does not exclude lung or heart disease.');
        }
        if (score >= 92 && score < 95) {
          actions.add(
              'Sit still, warm the hand, remove nail polish if relevant, and repeat according to device instructions.');
        }
        if (score < 92) {
          followUp.add(
              'Seek medical evaluation according to symptoms and established medical guidance; do not rely on the app alone.');
        }
        ruleIds.add('spo2_measurement_context');
        break;
      case 'LAR':
        cautions.add(
            'This ratio must be interpreted with absolute lipase and amylase levels, symptoms, and clinical assessment; it does not diagnose pancreatitis.');
        monitoring.add(
            'Review the absolute enzyme values rather than relying on the ratio alone.');
        if (rank >= 2) {
          followUp.add(
              'Seek professional review when enzyme values are abnormal or abdominal symptoms are present.');
        }
        ruleIds.add('lar_context_only');
        break;
      case 'AFP':
      case 'CA 15-3':
      case 'CA 27.29':
        cautions.add(
            'This laboratory marker cannot diagnose cancer by itself and must be interpreted with clinical history and other investigations.');
        monitoring.add(
            'Use the laboratory-provided reference interval when available.');
        if (rank >= 2) {
          followUp.add(
              'Clinical interpretation is recommended for a value outside the configured awareness/reference range.');
        }
        ruleIds.add('awareness_marker_only');
        break;
    }
  }

  void _aip(
      int rank,
      Map<String, dynamic> values,
      List<String> lifestyle,
      List<String> food,
      List<String> monitoring,
      List<String> followUp,
      List<String> ruleIds) {
    food.addAll([
      'Include vegetables, fruits, whole grains, nuts, seeds, and appropriate lean protein.',
      'Prefer unsaturated fats over foods high in saturated or trans fats.'
    ]);
    lifestyle.addAll([
      'Maintain regular physical activity appropriate for your health and abilities.',
      'Avoid tobacco, vaping, nicotine, and second-hand smoke.',
      'Maintain regular healthy sleep.'
    ]);
    if (rank >= 2) {
      monitoring.add('Review triglycerides and HDL-C individually.');
      followUp.add(
          'Review the full lipid profile, blood pressure, glucose status, family history, and other cardiovascular factors with a healthcare professional if abnormalities persist.');
    }
    ruleIds.add('aip_molar_lipids');
  }

  void _tyg(
      int rank,
      Map<String, dynamic> values,
      List<String> lifestyle,
      List<String> food,
      List<String> monitoring,
      List<String> followUp,
      List<String> cautions,
      List<String> ruleIds) {
    lifestyle.addAll(
        ['Maintain regular physical activity.', 'Maintain healthy sleep.']);
    food.add(
        'Limit frequent sugary beverages and highly processed/refined carbohydrate foods.');
    monitoring.add('Review fasting glucose and triglycerides separately.');
    final fasting = (values['fasting_glucose_mg/dL'] as num?)?.toDouble();
    final triglycerides = (values['triglycerides_mg/dL'] as num?)?.toDouble();
    if (fasting != null && fasting > 100) {
      monitoring.add(
          'Fasting glucose is elevated in the entered values and should be reviewed separately.');
    }
    if (triglycerides != null && triglycerides > 150) {
      monitoring.add(
          'Triglycerides are elevated in the entered values and should be reviewed separately.');
    }
    if (rank >= 2) {
      followUp.add(
          'Discuss persistent fasting-glucose or lipid abnormalities with a healthcare professional.');
    }
    cautions.add(
        'TyG is a surrogate metabolic/insulin-resistance-related indicator and is not a diabetes diagnosis.');
    ruleIds.add('tyg_population_dependent_cutoffs');
  }

  void _lifestyleSpecific(
      String indexName,
      String organ,
      Map<String, dynamic> lifestyle,
      List<String> advice,
      List<String> food,
      List<String> cautions,
      List<String> ruleIds) {
    if (lifestyle['physical_activity'] == 'Low') {
      advice.add(
          'Regular physical activity supports cardiovascular and metabolic health. Gradually increase activity appropriate to your health and abilities.');
      ruleIds.add('lifestyle_low_activity');
    }
    if (['Yes', 'Former'].contains(lifestyle['smoking'])) {
      advice.add(
          'Avoiding tobacco and nicotine exposure is beneficial for cardiovascular and overall health.');
      ruleIds.add('lifestyle_smoking');
    }
    if (lifestyle['passive_smoking'] == 'Yes') {
      advice.add('Reduce second-hand smoke exposure where possible.');
      ruleIds.add('environment_passive_smoke');
    }
    if (lifestyle['sugary_drinks'] == 'Frequently' &&
        ['AIP', 'TyG', 'FLI'].contains(indexName)) {
      food.add(
          'Reduce frequent sugar-sweetened drinks and choose water or unsweetened alternatives more often.');
      ruleIds.add('food_sugary_drinks');
    }
    if (lifestyle['fried_processed_food'] == 'Frequent') {
      food.add(
          'Choose minimally processed foods more often and reduce frequent highly processed or fried foods.');
      ruleIds.add('food_processed_food');
    }
    if (lifestyle['fruit_veg_intake'] == 'Low') {
      food.add(
          'Increase variety of vegetables and fruits as part of a balanced eating pattern.');
      ruleIds.add('food_low_fruit_vegetable');
    }
    if (lifestyle['high_salt_intake'] == 'High' &&
        ['Heart', 'Kidney', 'Diabetes / Metabolic'].contains(organ)) {
      food.add(
          'Reduce highly salted and heavily processed foods where practical.');
      ruleIds.add('food_high_salt');
    }
    if (lifestyle['sleep_duration'] == '<5 hrs') {
      advice.add(
          'Regular adequate sleep supports cardiovascular, metabolic, and general health.');
      ruleIds.add('lifestyle_short_sleep');
    }
    if (lifestyle['stress_level'] == 'High') {
      advice.add(
          'Stress-management practices such as regular routines, relaxation activities, social support, and adequate sleep may support overall wellbeing.');
      ruleIds.add('lifestyle_high_stress');
    }
    if (['Moderate', 'High'].contains(lifestyle['air_pollution']) &&
        organ == 'Lung') {
      advice.add(
          'Reduce avoidable exposure to heavy smoke, dust, and high-pollution environments where practical.');
      ruleIds.add('environment_pollution');
    }
    if (lifestyle['cooking_smoke'] == 'Yes' && organ == 'Lung') {
      advice.add(
          'Improve kitchen ventilation and reduce avoidable smoke exposure where practical.');
      ruleIds.add('environment_cooking_smoke');
    }
    if (organ == 'Kidney') {
      cautions.add(
          'Follow an individualized balanced eating plan; potassium, phosphorus, protein, sodium, and fluid requirements vary when kidney function is reduced.');
    }
  }

  int _rank(String riskLevel) {
    if (riskLevel == 'Attention Needed') return 3;
    if (riskLevel == 'Monitor') return 2;
    if (riskLevel == 'Low Concern' || riskLevel == 'Good') return 1;
    return 0;
  }

  String _format(num value) => value.toStringAsFixed(3);

  String _label(String key) => key.replaceAll('_', ' ');

  List<String> _unique(List<String> values) => values.toSet().toList();
}
