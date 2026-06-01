import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/ui_result_adapter.dart';
import '../styles.dart';
import '../widgets/organ_visual.dart';

class IndexDetailScreen extends StatelessWidget {
  const IndexDetailScreen({super.key, required this.metric});

  final HealthMetric metric;

  @override
  Widget build(BuildContext context) {
    final status = AppStyles.statusStyle(metric.rawStatus);
    final source = metric.source ?? const <String, dynamic>{};
    final values = _valuesUsed(metric.valuesUsed);
    final contributors = _stringList(source['possible_contributors']);
    final suggestions = <String>[
      ..._stringList(source['suggestions']),
      ..._stringList(source['lifestyle_improvement']),
      ..._stringList(source['food_recommendations']),
      ..._stringList(source['environment_recommendations']),
    ];
    final doctorFollowup = source['doctor_followup']?.toString() ??
        'Clinical review is suggested if values remain outside the expected range or symptoms persist.';

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(metric.indexName),
          backgroundColor: AppStyles.navy,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {},
            ),
          ],
        ),
        body: ResponsiveContainer(
          maxWidth: Responsive.detailMaxWidth,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppStyles.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppStyles.navy.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    OrganVisualIcon(
                      organ: metric.organKey,
                      size: 66,
                      iconSize: 32,
                      showGlow: true,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.indexName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppStyles.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metric.displayName,
                            style: const TextStyle(
                              color: AppStyles.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _statusBadge(status),
                              Text(
                                metric.unit.isEmpty
                                    ? metric.scoreText
                                    : '${metric.scoreText} ${metric.unit}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppStyles.navy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _section('What this means', [metric.summary]),
              _section('Values used', values),
              _section(
                'Possible contributors',
                contributors.isEmpty
                    ? [
                        'No major lifestyle, food, or environment contributors were identified from the entered answers.',
                      ]
                    : contributors,
              ),
              _section(
                'Suggestions',
                suggestions.isEmpty
                    ? [
                        'Maintain healthy habits and review this value with a qualified healthcare professional if it remains outside the expected range.',
                      ]
                    : suggestions,
                checkmarks: true,
              ),
              _section('Doctor follow-up', [doctorFollowup]),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppStyles.border),
                ),
                child: const Text(
                  'For informational purposes only. This app is not a substitute for clinical diagnosis, treatment, or medical advice. Please consult a qualified healthcare professional for medical decisions.',
                  style: TextStyle(
                    color: AppStyles.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(HealthStatusStyle status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.badgeBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.border),
      ),
      child: Text(
        AppStyles.displayStatusLabel(status.label),
        style: TextStyle(
          color: status.text,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _section(String title, List<String> items, {bool checkmarks = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppStyles.text,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map((item) => _bullet(item, checkmarks: checkmarks)),
        ],
      ),
    );
  }

  Widget _bullet(String item, {bool checkmarks = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3, right: 8),
            child: Icon(
              checkmarks ? Icons.check_circle_outline : Icons.circle,
              size: checkmarks ? 16 : 7,
              color: checkmarks
                  ? AppStyles.lowConcernStatus.accent
                  : AppStyles.navy,
            ),
          ),
          Expanded(
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                color: AppStyles.text,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _valuesUsed(Map<String, dynamic> values) {
    if (values.isEmpty) {
      return ['No individual source values were provided for this indicator.'];
    }
    return values.entries
        .map((entry) => '${_prettyKey(entry.key)}: ${entry.value}')
        .toList();
  }

  List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) return [raw];
    return const [];
  }

  String _prettyKey(String key) {
    return key
        .replaceAll('_mg/dL', ' (mg/dL)')
        .replaceAll('_cm', ' (cm)')
        .replaceAll('_%', ' (%)')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}
