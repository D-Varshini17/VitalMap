import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/ui_result_adapter.dart';
import '../services/export_summary_service.dart';
import '../styles.dart';
import '../widgets/organ_visual.dart';

class IndexDetailScreen extends StatelessWidget {
  const IndexDetailScreen({super.key, required this.metric});

  final HealthMetric metric;

  @override
  Widget build(BuildContext context) {
    final status = AppStyles.themedStatusStyle(context, metric.rawStatus);
    final source = metric.source ?? const <String, dynamic>{};
    final recommendation = Map<String, dynamic>.from(
      source['recommendation'] as Map? ?? const {},
    );
    final metadata = Map<String, dynamic>.from(
      source['formula_metadata'] as Map? ?? const {},
    );
    final values = _valuesUsed(metric.valuesUsed);
    final contributors = _stringList(source['possible_contributors']);
    final suggestions = <String>[
      ..._stringList(recommendation['actions']),
      ..._stringList(recommendation['lifestyle']),
      ..._stringList(recommendation['food']),
      ..._stringList(recommendation['monitoring']),
    ];
    final doctorFollowup = _doctorFollowup(source, recommendation);

    return Scaffold(
      appBar: AppBar(
        title: Text(metric.indexName),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _exportSummary(context),
          ),
        ],
      ),
      body: ResponsivePage(
        maxWidth: Responsive.detailMaxWidth,
        topPadding: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .shadow
                        .withValues(alpha: 0.08),
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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          metric.displayName,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                            _statusBadge(context, status),
                            Text(
                              metric.unit.isEmpty
                                  ? metric.scoreText
                                  : '${metric.scoreText} ${metric.unit}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
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
            _section(context, 'What this means', [metric.summary]),
            _section(context, 'Values used', values),
            _section(context, 'Formula', [
              source['formula_used']?.toString() ??
                  'Formula metadata unavailable.',
            ]),
            _section(context, 'Why am I seeing this?', [
              recommendation['why']?.toString() ??
                  'This recommendation is based on the calculated index and entered values.',
            ]),
            _section(
              context,
              'Possible contributors',
              contributors.isEmpty
                  ? [
                      'No major lifestyle, food, or environment contributors were identified from the entered answers.',
                    ]
                  : contributors,
            ),
            _section(
              context,
              'Suggestions',
              suggestions.isEmpty
                  ? [
                      'Maintain healthy habits and review this value with a qualified healthcare professional if it remains outside the expected range.',
                    ]
                  : suggestions,
              checkmarks: true,
            ),
            _doctorFollowupSection(context, doctorFollowup),
            _section(context, 'Limitations and cautions', [
              ..._stringList(recommendation['cautions']),
              recommendation['evidence_note']?.toString() ??
                  metadata['interpretation_note']?.toString() ??
                  'This is a screening calculation and does not diagnose disease.',
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Text(
                'For informational purposes only. This app is not a substitute for clinical diagnosis, treatment, or medical advice. Please consult a qualified healthcare professional for medical decisions.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSummary(BuildContext context) async {
    final result = await ExportSummaryService.exportLastSummary();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Widget _statusBadge(BuildContext context, HealthStatusStyle status) {
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

  Widget _section(BuildContext context, String title, List<String> items,
      {bool checkmarks = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ...items
              .map((item) => _bullet(context, item, checkmarks: checkmarks)),
        ],
      ),
    );
  }

  Widget _doctorFollowupSection(BuildContext context, String followup) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? Color.alphaBlend(
            colors.primary.withValues(alpha: 0.14),
            colors.surface,
          )
        : Color.alphaBlend(
            colors.primary.withValues(alpha: 0.08),
            colors.surface,
          );
    final border = isDark
        ? colors.primary.withValues(alpha: 0.38)
        : colors.primary.withValues(alpha: 0.22);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: isDark ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.medical_services_outlined,
              color: colors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doctor follow-up',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  followup,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface,
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(BuildContext context, String item, {bool checkmarks = false}) {
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
                  ? AppStyles.themedStatusStyle(context, 'Good').accent
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
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

  String _doctorFollowup(
    Map<String, dynamic> source,
    Map<String, dynamic> recommendation,
  ) {
    final direct = source['doctor_followup']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final nested = _stringList(recommendation['clinician_follow_up']);
    if (nested.isNotEmpty) return nested.join(' ');
    final normalized = metric.doctorFollowup.trim();
    if (normalized.isNotEmpty) return normalized;
    if (metric.rawStatus == 'More Data Needed') {
      return 'Additional information is needed before this screening indicator can be interpreted. Consider discussing the required laboratory values with a healthcare professional.';
    }
    return 'Discuss your screening results with a qualified healthcare professional if you have questions or concerns.';
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
