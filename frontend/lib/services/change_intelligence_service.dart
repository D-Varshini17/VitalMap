import '../core/ui_result_adapter.dart';
import '../styles.dart';

class ChangeIntelligenceService {
  static Map<String, dynamic> buildComparison({
    required Map<String, dynamic> previous,
    required Map<String, dynamic> current,
  }) {
    final previousResponse = _map(previous['response']);
    final currentResponse = _map(current['response']);
    final previousPayload = _map(previous['inputData']);
    final currentPayload = _map(current['inputData']);

    final previousMetrics = HealthUiAdapter.metricsFromResponse(
      previousResponse,
      payload: previousPayload,
    );
    final currentMetrics = HealthUiAdapter.metricsFromResponse(
      currentResponse,
      payload: currentPayload,
    );
    final previousMissing = HealthUiAdapter.moreDataNeeded(previousResponse);
    final currentMissing = HealthUiAdapter.moreDataNeeded(currentResponse);
    final previousScore = HealthUiAdapter.healthScore(
      previousMetrics,
      previousMissing,
    );
    final currentScore = HealthUiAdapter.healthScore(
      currentMetrics,
      currentMissing,
    );

    final oldByName = {for (final metric in previousMetrics) metric.indexName: metric};
    final metricChanges = <Map<String, dynamic>>[];
    for (final metric in currentMetrics) {
      final old = oldByName[metric.indexName];
      if (old == null) {
        metricChanges.add({
          'index_name': metric.indexName,
          'display_name': metric.displayName,
          'organ': metric.organName,
          'change_type': 'newly_available',
          'previous_score': null,
          'current_score': metric.scoreText,
          'unit': metric.unit,
          'previous_status': null,
          'current_status': metric.statusLabel,
          'status_direction': 'Newly available',
        });
        continue;
      }
      final oldNumber = double.tryParse(old.scoreText);
      final currentNumber = double.tryParse(metric.scoreText);
      final oldRank = AppStyles.statusRank(old.rawStatus);
      final currentRank = AppStyles.statusRank(metric.rawStatus);
      final direction = currentRank < oldRank
          ? 'Lower concern label'
          : currentRank > oldRank
              ? 'Higher concern label'
              : 'Same screening label';
      metricChanges.add({
        'index_name': metric.indexName,
        'display_name': metric.displayName,
        'organ': metric.organName,
        'change_type': 'comparable',
        'previous_score': old.scoreText,
        'current_score': metric.scoreText,
        'unit': metric.unit,
        'numeric_delta': oldNumber != null && currentNumber != null
            ? currentNumber - oldNumber
            : null,
        'previous_status': old.statusLabel,
        'current_status': metric.statusLabel,
        'status_direction': direction,
      });
    }

    final currentNames = {for (final metric in currentMetrics) metric.indexName};
    for (final old in previousMetrics) {
      if (currentNames.contains(old.indexName)) continue;
      metricChanges.add({
        'index_name': old.indexName,
        'display_name': old.displayName,
        'organ': old.organName,
        'change_type': 'not_available_now',
        'previous_score': old.scoreText,
        'current_score': null,
        'unit': old.unit,
        'previous_status': old.statusLabel,
        'current_status': null,
        'status_direction': 'Not available in latest screening',
      });
    }

    final contextChanges = _contextChanges(previousPayload, currentPayload);
    return {
      'previous_date': previous['timestamp']?.toString(),
      'current_date': current['timestamp']?.toString(),
      'previous_health_score': previousScore,
      'current_health_score': currentScore,
      'health_score_delta': currentScore - previousScore,
      'previous_overall_status': HealthUiAdapter.overallStatus(previousMetrics),
      'current_overall_status': HealthUiAdapter.overallStatus(currentMetrics),
      'metric_changes': metricChanges,
      'context_changes': contextChanges,
      'interpretation_rule':
          'Input changes are shown as changes that occurred alongside the screening result, not proven causes.',
    };
  }

  static List<Map<String, dynamic>> _contextChanges(
    Map<String, dynamic> previous,
    Map<String, dynamic> current,
  ) {
    const paths = <(String, String, String)>[
      ('general_health', 'physical_activity', 'Physical activity'),
      ('general_health', 'sleep_duration', 'Sleep duration'),
      ('general_health', 'stress_level', 'Stress level'),
      ('general_health', 'smoking', 'Smoking'),
      ('general_health', 'passive_smoking', 'Passive smoke exposure'),
      ('general_health', 'high_sugar_intake', 'High-sugar intake'),
      ('general_health', 'fruit_veg_intake', 'Fruit & vegetable intake'),
      ('lipid_profile', 'triglycerides', 'Triglycerides'),
      ('lipid_profile', 'hdl', 'HDL'),
      ('diabetes_profile', 'fasting_glucose', 'Fasting glucose'),
      ('liver_function', 'ast', 'AST'),
      ('liver_function', 'alt', 'ALT'),
      ('liver_function', 'ggt', 'GGT'),
      ('liver_function', 'albumin', 'Albumin'),
      ('cbc', 'platelets', 'Platelets'),
      ('cbc', 'neutrophils', 'Neutrophils'),
      ('cbc', 'lymphocytes', 'Lymphocytes'),
      ('kidney_function', 'creatinine', 'Creatinine'),
      ('vitals', 'spo2', 'SpO2'),
      ('pancreatic_enzymes', 'lipase', 'Lipase'),
      ('pancreatic_enzymes', 'amylase', 'Amylase'),
    ];
    final out = <Map<String, dynamic>>[];
    for (final path in paths) {
      final oldValue = _value(previous, path.$1, path.$2);
      final newValue = _value(current, path.$1, path.$2);
      if (oldValue == null || newValue == null) continue;
      if (_same(oldValue, newValue)) continue;
      final unit = _value(current, path.$1, '${path.$2}_unit') ??
          _value(previous, path.$1, '${path.$2}_unit');
      out.add({
        'label': path.$3,
        'previous': oldValue,
        'current': newValue,
        'unit': unit,
      });
    }
    return out;
  }

  static dynamic _value(Map<String, dynamic> map, String section, String key) {
    final nested = map[section];
    if (nested is! Map) return null;
    final value = nested[key];
    if (value == null || value.toString().trim().isEmpty) return null;
    return value;
  }

  static bool _same(dynamic a, dynamic b) {
    final aNum = a is num ? a.toDouble() : double.tryParse(a.toString());
    final bNum = b is num ? b.toDouble() : double.tryParse(b.toString());
    if (aNum != null && bNum != null) return (aNum - bNum).abs() < 0.000001;
    return a.toString().trim().toLowerCase() == b.toString().trim().toLowerCase();
  }

  static Map<String, dynamic> _map(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  }
}
