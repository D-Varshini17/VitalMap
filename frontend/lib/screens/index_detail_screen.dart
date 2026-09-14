import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/ui_result_adapter.dart';
import '../services/backend_analysis_service.dart';
import '../services/export_summary_service.dart';
import '../services/firestore_service.dart';
import '../storage/local_storage.dart';
import '../styles.dart';
import '../widgets/organ_visual.dart';
import '../widgets/simple_trend_chart.dart';

class IndexDetailScreen extends StatefulWidget {
  const IndexDetailScreen({super.key, required this.metric});

  final HealthMetric metric;

  @override
  State<IndexDetailScreen> createState() => _IndexDetailScreenState();
}

class _IndexDetailScreenState extends State<IndexDetailScreen> {
  Map<String, dynamic>? _guidance;
  String? _aiError;
  bool _loadingAi = false;
  List<TrendPoint> _trend = const [];
  List<Map<String, dynamic>> _recentCheckIns = const [];
  Map<String, dynamic> _generalHealth = const {};
  Map<String, dynamic> _profile = const {};

  HealthMetric get metric => widget.metric;

  @override
  void initState() {
    super.initState();
    _loadContextAndGuidance();
  }

  Future<void> _loadContextAndGuidance() async {
    final payload = await LocalStorage.loadLastPayload();
    final general = payload?['general_health'];
    final profile = payload?['profile'];
    _profile = profile is Map ? Map<String, dynamic>.from(profile) : {};
    _generalHealth = general is Map ? Map<String, dynamic>.from(general) : <String, dynamic>{};

    final user = Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final results = await Future.wait([
          FirestoreService.loadScreeningHistory(user.uid, limit: 8),
          FirestoreService.loadSymptomHistory(user.uid, limit: 14),
        ]);
        _trend = _buildTrend(results[0]);
        _recentCheckIns = results[1].take(7).map((entry) {
          return <String, dynamic>{
            'timestamp': entry['timestamp'],
            'energy': entry['energy'],
            'sleep_quality': entry['sleepQuality'],
            'symptoms': entry['symptoms'],
            'severity': entry['severity'],
          };
        }).toList();
      } catch (_) {}
    }
    if (mounted) setState(() {});
    await _generateGuidance();
  }

  List<TrendPoint> _buildTrend(List<Map<String, dynamic>> history) {
    final points = <TrendPoint>[];
    for (final record in history.reversed) {
      final response = record['response'];
      final payload = record['inputData'];
      if (response is! Map) continue;
      final metrics = HealthUiAdapter.metricsFromResponse(
        Map<String, dynamic>.from(response),
        payload: payload is Map ? Map<String, dynamic>.from(payload) : null,
      );
      final match = metrics.where((item) => item.indexName == metric.indexName).toList();
      if (match.isEmpty) continue;
      final numeric = double.tryParse(match.first.scoreText);
      final date = DateTime.tryParse(record['timestamp']?.toString() ?? '');
      if (numeric == null || date == null) continue;
      points.add(TrendPoint(label: '${date.day}/${date.month}', value: numeric));
    }
    return points;
  }

  Future<void> _generateGuidance() async {
    if (_loadingAi) return;
    setState(() {
      _loadingAi = true;
      _aiError = null;
    });
    try {
      final result = await BackendAnalysisService.metricGuidance(
        metric: _metricContext(),
        generalHealth: _generalHealth,
        profile: _profile,
        recentCheckIns: _recentCheckIns,
        recentTrend: [
          for (final point in _trend) {'label': point.label, 'value': point.value},
        ],
      );
      if (mounted) setState(() => _guidance = result);
    } catch (error) {
      if (mounted) {
        setState(() => _aiError = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  Map<String, dynamic> _metricContext() {
    final source = metric.source ?? const <String, dynamic>{};
    return {
      'index_name': metric.indexName,
      'display_name': metric.displayName,
      'organ': metric.organName,
      'score': metric.scoreText,
      'unit': metric.unit,
      'status': metric.statusLabel,
      'raw_status': metric.rawStatus,
      'summary': metric.summary,
      'values_used': metric.valuesUsed,
      'formula_used': source['formula_used'],
      'possible_contributors': source['possible_contributors'],
      'recommendation_context': source['recommendation'],
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = AppStyles.themedStatusStyle(context, metric.rawStatus);
    final source = metric.source ?? const <String, dynamic>{};
    final contributors = _stringList(source['possible_contributors']);
    final metadata = Map<String, dynamic>.from(source['formula_metadata'] as Map? ?? const {});

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
            tooltip: 'Export screening summary',
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
            _hero(status),
            const SizedBox(height: 18),
            _section('What this means', [metric.summary]),
            _section('Values used', _valuesUsed(metric.valuesUsed)),
            _section('Formula', [source['formula_used']?.toString() ?? 'Formula metadata unavailable.']),
            if (contributors.isNotEmpty) _section('Possible contributors already identified by VitalMap', contributors),
            if (_trend.length >= 2) _trendCard(),
            _localAiCard(),
            _followUpCard(),
            _section('Limitations and cautions', [
              metadata['interpretation_note']?.toString() ?? 'This is a screening calculation and does not diagnose disease.',
              HealthUiAdapter.disclaimer,
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _hero(HealthStatusStyle status) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          OrganVisualIcon(organ: metric.organKey, size: 66, iconSize: 32, showGlow: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metric.indexName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(metric.displayName, style: TextStyle(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _statusBadge(status),
                    Text(
                      metric.unit.isEmpty ? metric.scoreText : '${metric.scoreText} ${metric.unit}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendCard() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Saved values for this same VitalMap indicator.', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 8),
          SimpleTrendChart(points: _trend, height: 190, valueSuffix: metric.unit.isEmpty ? '' : ' ${metric.unit}'),
        ],
      ),
    );
  }

  Widget _localAiCard() {
    final colors = Theme.of(context).colorScheme;
    final guidance = _guidance;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, color: colors.primary),
              const SizedBox(width: 9),
              const Expanded(child: Text('Local AI Guidance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                child: const Text('Ollama • local', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Generated from this finalized indicator, your entered lifestyle context, recent trend and optional Daily Check-ins. Ollama cannot change the score or status above.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (_loadingAi) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Generating detailed local guidance...'),
          ] else if (_aiError != null) ...[
            Text(_aiError!, style: TextStyle(color: colors.error)),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: _generateGuidance, icon: const Icon(Icons.refresh), label: const Text('Retry Local AI')),
          ] else if (guidance != null) ...[
            if ((guidance['summary']?.toString().trim() ?? '').isNotEmpty)
              Text(guidance['summary'].toString(), style: const TextStyle(height: 1.45, fontWeight: FontWeight.w600)),
            _guidanceGroup('Food', Icons.restaurant_outlined, _stringList(guidance['food'])),
            _guidanceGroup('Lifestyle', Icons.self_improvement_outlined, _stringList(guidance['lifestyle'])),
            _guidanceGroup('Activity', Icons.directions_walk_outlined, _stringList(guidance['exercise'])),
            _guidanceGroup('Risk factors to review', Icons.fact_check_outlined, _stringList(guidance['risk_factors'])),
            _guidanceGroup('What to monitor next', Icons.monitor_heart_outlined, _stringList(guidance['monitor_next'])),
            const SizedBox(height: 10),
            Text(
              guidance['safety_note']?.toString() ?? 'General wellness guidance only. This does not replace clinical advice.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 8),
            TextButton.icon(onPressed: _generateGuidance, icon: const Icon(Icons.refresh, size: 18), label: const Text('Regenerate locally')),
          ],
        ],
      ),
    );
  }

  Widget _guidanceGroup(String title, IconData icon, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 19, color: colors.primary), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900))]),
          const SizedBox(height: 7),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: colors.primary),
                  const SizedBox(width: 7),
                  Expanded(child: Text(item, style: const TextStyle(height: 1.38))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _followUpCard() {
    var followup = metric.doctorFollowup.trim();
    if (followup.isEmpty) {
      final recommendation = metric.source?['recommendation'];
      final items = recommendation is Map ? recommendation['clinician_follow_up'] : null;
      if (items is List) followup = items.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).join(' ');
    }
    if (followup.isEmpty) {
      followup = 'Discuss your screening results with a qualified healthcare professional if you have questions or concerns.';
    }
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medical_information_outlined, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Follow-up note', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(followup, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
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
        style: TextStyle(color: status.text, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _section(String title, List<String> items) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          for (final item in items.where((e) => e.trim().isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: colors.primary)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: const TextStyle(height: 1.38))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<String> _valuesUsed(Map<String, dynamic> values) {
    if (values.isEmpty) return ['No individual source values were provided for this indicator.'];
    return values.entries.map((entry) => '${_prettyKey(entry.key)}: ${entry.value}').toList();
  }

  List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String && raw.trim().isNotEmpty) return [raw.trim()];
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
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  Future<void> _exportSummary(BuildContext context) async {
    final result = await ExportSummaryService.exportLastSummary();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
  }
}
