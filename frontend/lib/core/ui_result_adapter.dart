import 'dart:math' as math;

import '../styles.dart';

class HealthMetric {
  const HealthMetric({
    required this.indexName,
    required this.displayName,
    required this.organKey,
    required this.organName,
    required this.scoreText,
    required this.unit,
    required this.rawStatus,
    required this.statusLabel,
    required this.summary,
    required this.valuesUsed,
    this.source,
  });

  final String indexName;
  final String displayName;
  final String organKey;
  final String organName;
  final String scoreText;
  final String unit;
  final String rawStatus;
  final String statusLabel;
  final String summary;
  final Map<String, dynamic> valuesUsed;
  final Map<String, dynamic>? source;
}

class OrganSnapshot {
  const OrganSnapshot({
    required this.key,
    required this.name,
    required this.statusLabel,
    required this.rawStatus,
    required this.primaryText,
    required this.message,
    required this.metrics,
    required this.missingCount,
  });

  final String key;
  final String name;
  final String statusLabel;
  final String rawStatus;
  final String primaryText;
  final String message;
  final List<HealthMetric> metrics;
  final int missingCount;
}

class HealthUiAdapter {
  static const disclaimer =
      'For informational purposes only. This app is not a substitute for clinical diagnosis, treatment, or medical advice. Please consult a qualified healthcare professional for medical decisions.';

  static const totalExpectedValues = 35;

  static final organOrder = <String>[
    'Heart',
    'Liver',
    'Kidney',
    'Lung',
    'Diabetes / Metabolic',
    'Inflammation',
    'Pancreas',
    'Cancer Awareness',
  ];

  static List<HealthMetric> metricsFromResponse(
    Map<String, dynamic>? response, {
    Map<String, dynamic>? payload,
  }) {
    // Only include calculated indicators — profile-derived metrics (BMI, waist)
    // should not appear as final result cards per product rules.
    final metrics = <HealthMetric>[];
    final results = (response?['calculated_results'] as List<dynamic>?) ?? [];
    for (final item in results) {
      if (item is! Map) continue;
      final result = Map<String, dynamic>.from(item);
      final indexName = result['index_name']?.toString() ?? 'Indicator';
      final organKey = result['organ']?.toString() ?? 'General';
      final score = result['score'];
      final unit = result['unit']?.toString() ?? '';
      final rawStatus = result['risk_level']?.toString() ?? 'More Data Needed';
      metrics.add(
        HealthMetric(
          indexName: indexName,
          displayName: displayName(indexName),
          organKey: organKey,
          organName: organName(organKey),
          scoreText: _formatScore(score),
          unit: unit,
          rawStatus: rawStatus,
          statusLabel:
              AppStyles.displayStatusLabel(rawStatus, indexName: indexName),
          summary: result['summary']?.toString() ??
              'Calculated from the values available in your report.',
          valuesUsed: Map<String, dynamic>.from(
              result['values_used'] as Map? ?? const {}),
          source: result,
        ),
      );
    }
    // Filter to approved final indicators only.
    const approved = {
      'AIP',
      'APRI',
      'FIB-4',
      'FLI',
      'NAFLD Fibrosis Score',
      'SpO2',
      'SpO₂',
      'TyG',
      'NLR',
      'LAR',
      'eGFR',
      'AFP',
      'CA 15-3',
      'CA 27.29',
    };
    final filtered = metrics.where((m) => approved.contains(m.indexName)).toList();
    filtered.sort((a, b) =>
        _metricOrder(a.indexName).compareTo(_metricOrder(b.indexName)));
    return filtered;
  }

  static List<Map<String, dynamic>> moreDataNeeded(
      Map<String, dynamic>? response) {
    return ((response?['more_data_needed'] as List<dynamic>?) ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Map<String, int> statusCounts(
    List<HealthMetric> metrics,
    List<Map<String, dynamic>> moreData,
  ) {
    var monitor = 0;
    var attention = 0;
    for (final metric in metrics) {
      final style = AppStyles.statusStyle(metric.rawStatus);
      if (style.label == AppStyles.monitorStatus.label) monitor++;
      if (style.label == AppStyles.attentionStatus.label) attention++;
    }
    return {
      'calculated': metrics.length,
      'monitor': monitor,
      'attention': attention,
      'moreData': moreData.length,
    };
  }

  static String overallStatus(List<HealthMetric> metrics) {
    if (metrics.isEmpty) return 'More Data Needed';
    var topRank = 0;
    String top = 'Low Concern';
    for (final metric in metrics) {
      final rank = AppStyles.statusRank(metric.rawStatus);
      if (rank > topRank) {
        topRank = rank;
        top = metric.rawStatus;
      }
    }
    return top;
  }

  static int healthScore(
    List<HealthMetric> metrics,
    List<Map<String, dynamic>> moreData,
  ) {
    if (metrics.isEmpty) return 0;
    final counts = statusCounts(metrics, moreData);
    final score = 94 -
        (counts['monitor']! * 7) -
        (counts['attention']! * 16) -
        math.min(counts['moreData']!, 8) * 2;
    return score.clamp(35, 96).round();
  }

  static String summaryText(String rawStatus, int calculatedCount) {
    final status = AppStyles.statusStyle(rawStatus);
    if (calculatedCount == 0) {
      return 'Add available report values to view organ-wise insights.';
    }
    if (status.label == AppStyles.attentionStatus.label) {
      return 'Some indicators need attention.';
    }
    if (status.label == AppStyles.monitorStatus.label) {
      return 'Some indicators need monitoring.';
    }
    return 'Your overall health looks good.';
  }

  static int completedValueCount(Map<String, dynamic>? payload) {
    if (payload == null) return 0;
    var count = 0;
    void walk(dynamic value) {
      if (value == null) return;
      if (value is Map) {
        value.forEach((key, nested) {
          final name = key.toString();
          if (name.contains('unit') || name == 'selected_report_sections') {
            return;
          }
          walk(nested);
        });
        return;
      }
      if (value is List) return;
      if (value.toString().trim().isNotEmpty) count++;
    }

    walk(payload);
    return count.clamp(0, totalExpectedValues).toInt();
  }

  static int completionPercent(Map<String, dynamic>? payload) {
    return ((completedValueCount(payload) / totalExpectedValues) * 100)
        .clamp(0, 100)
        .round();
  }

  static List<OrganSnapshot> organSnapshots(
    Map<String, dynamic>? response, {
    Map<String, dynamic>? payload,
  }) {
    final metrics = metricsFromResponse(response, payload: payload);
    final moreData = moreDataNeeded(response);
    return [
      for (final key in organOrder) _snapshotForOrgan(key, metrics, moreData),
    ];
  }

  static String displayName(String indexName) {
    switch (indexName) {
      case 'AIP':
        return 'Atherogenic Index';
      case 'BMI':
        return 'Body Mass Index';
      case 'Waist Circumference':
        return 'Waist Circumference';
      case 'TyG':
        return 'Triglyceride Glucose Index';
      case 'APRI':
        return 'AST to Platelet Ratio Index';
      case 'FIB-4':
        return 'Fibrosis-4 Index';
      case 'FLI':
        return 'Fatty Liver Index';
      case 'NAFLD Fibrosis Score':
        return 'NAFLD Fibrosis Score';
      case 'NLR':
        return 'Neutrophil Lymphocyte Ratio';
      case 'eGFR':
        return 'Estimated Glomerular Filtration Rate';
      case 'SpO2':
      case 'SpO₂':
        return 'Oxygen Saturation';
      case 'LAR':
        return 'Lipase Amylase Ratio';
      case 'AFP':
        return 'Alpha-fetoprotein';
      case 'CA 15-3':
        return 'CA 15-3 Marker';
      case 'CA 27.29':
        return 'CA 27.29 Marker';
      case 'Metabolic screening insight':
        return 'Metabolic Screening Insight';
      default:
        return indexName;
    }
  }

  static String organName(String organKey) {
    switch (organKey) {
      case 'Lung':
        return 'Lungs';
      case 'Diabetes / Metabolic':
        return 'Brain / Metabolic';
      default:
        return organKey;
    }
  }

  static String cleanKey(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAll('spo2', 'SpO2')
        .replaceAll('egfr', 'eGFR')
        .trim();
  }

  static String missingText(Map<String, dynamic> item) {
    final missing = (item['missing_inputs'] as List<dynamic>? ?? [])
        .map((value) => cleanKey(value.toString()))
        .where((value) => value.isNotEmpty)
        .toList();
    if (missing.isEmpty) return 'Needs more values';
    if (missing.length == 1) return 'Needs ${missing.first}';
    return '${missing.length} values missing';
  }

  static List<HealthMetric> _profileMetrics(Map<String, dynamic>? payload) {
    final profile =
        Map<String, dynamic>.from(payload?['profile'] as Map? ?? const {});
    final sex = profile['sex']?.toString();
    final heightCm = _asDouble(profile['height_cm']);
    final weightKg = _asDouble(profile['weight_kg']);
    final waistCm = _asDouble(profile['waist_cm']);
    final metrics = <HealthMetric>[];
    if (heightCm != null && weightKg != null && heightCm > 0) {
      final bmi = weightKg / math.pow(heightCm / 100, 2);
      final rawStatus = bmi >= 30
          ? 'Attention Needed'
          : bmi >= 25 || bmi < 18.5
              ? 'Monitor'
              : 'Low Concern';
      metrics.add(
        HealthMetric(
          indexName: 'BMI',
          displayName: 'Body Mass Index',
          organKey: 'Diabetes / Metabolic',
          organName: 'Brain / Metabolic',
          scoreText: bmi.toStringAsFixed(1),
          unit: 'kg/m²',
          rawStatus: rawStatus,
          statusLabel:
              AppStyles.displayStatusLabel(rawStatus, indexName: 'BMI'),
          summary: 'Body mass index is auto-calculated from height and weight.',
          valuesUsed: {'height_cm': heightCm, 'weight_kg': weightKg},
        ),
      );
    }
    if (waistCm != null) {
      final isFemale = sex?.toLowerCase().startsWith('f') ?? false;
      final attention = isFemale ? 88 : 102;
      final monitor = isFemale ? 80 : 94;
      final rawStatus = waistCm >= attention
          ? 'Attention Needed'
          : waistCm >= monitor
              ? 'Monitor'
              : 'Low Concern';
      metrics.add(
        HealthMetric(
          indexName: 'Waist Circumference',
          displayName: 'Waist Circumference',
          organKey: 'Heart',
          organName: 'Heart',
          scoreText: waistCm.toStringAsFixed(waistCm % 1 == 0 ? 0 : 1),
          unit: 'cm',
          rawStatus: rawStatus,
          statusLabel: AppStyles.displayStatusLabel(rawStatus),
          summary:
              'Waist measurement can add context to metabolic and lipid-related screening insights.',
          valuesUsed: {'waist_cm': waistCm},
        ),
      );
    }
    return metrics;
  }

  static OrganSnapshot _snapshotForOrgan(
    String key,
    List<HealthMetric> metrics,
    List<Map<String, dynamic>> moreData,
  ) {
    final organMetrics =
        metrics.where((metric) => metric.organKey == key).toList();
    final missing =
        moreData.where((item) => item['organ']?.toString() == key).toList();
    if (organMetrics.isEmpty) {
      final message = missing.isEmpty
          ? 'Add values to unlock this insight.'
          : missingText(missing.first);
      return OrganSnapshot(
        key: key,
        name: organName(key),
        statusLabel: 'More Data Needed',
        rawStatus: 'More Data Needed',
        primaryText: missing.isEmpty
            ? 'More Data'
            : '${missing.length} value${missing.length == 1 ? '' : 's'} missing',
        message: message,
        metrics: const [],
        missingCount: missing.length,
      );
    }
    organMetrics.sort((a, b) => AppStyles.statusRank(b.rawStatus)
        .compareTo(AppStyles.statusRank(a.rawStatus)));
    final primary = organMetrics.first;
    return OrganSnapshot(
      key: key,
      name: organName(key),
      statusLabel: primary.statusLabel,
      rawStatus: primary.rawStatus,
      primaryText:
          '${primary.indexName} ${primary.scoreText}${primary.unit.isEmpty ? '' : ' ${primary.unit}'}',
      message: primary.summary,
      metrics: organMetrics,
      missingCount: missing.length,
    );
  }

  static int _metricOrder(String indexName) {
    const order = [
      'AIP',
      'BMI',
      'Waist Circumference',
      'TyG',
      'FIB-4',
      'APRI',
      'FLI',
      'NAFLD Fibrosis Score',
      'NLR',
      'eGFR',
      'SpO2',
      'LAR',
      'AFP',
      'CA 15-3',
      'CA 27.29',
    ];
    final index = order.indexOf(indexName);
    return index == -1 ? 999 : index;
  }

  static String _formatScore(dynamic score) {
    if (score == null) return 'More Data';
    if (score is num) return score.toString();
    return score.toString();
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == null) return null;
    return double.tryParse(value.toString());
  }
}
