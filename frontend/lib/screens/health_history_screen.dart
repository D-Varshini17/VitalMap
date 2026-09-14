import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/ui_result_adapter.dart';
import '../services/backend_analysis_service.dart';
import '../services/change_intelligence_service.dart';
import '../services/firestore_service.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/simple_trend_chart.dart';

class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>? _future;
  int _mode = 0; // 0 timeline, 1 compare
  int _olderIndex = 1;
  int _newerIndex = 0;
  Map<String, dynamic>? _aiExplanation;
  bool _explaining = false;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final user = Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
    if (user == null) {
      _future = Future.value((<Map<String, dynamic>>[], <Map<String, dynamic>>[]));
      return;
    }
    _future = Future.wait([
      FirestoreService.loadScreeningHistory(user.uid, limit: 90),
      FirestoreService.loadSymptomHistory(user.uid, limit: 90),
    ]).then((values) => (values[0], values[1]));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const BrandAppBarTitle(title: 'History'),
              actions: [IconButton(onPressed: () => setState(_reload), icon: const Icon(Icons.refresh))],
            ),
      body: FutureBuilder<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('History could not be loaded. Check your connection and retry.'),
              TextButton(onPressed: () => setState(_reload), child: const Text('Retry')),
            ]));
          }
          final screenings = snapshot.data?.$1 ?? const <Map<String, dynamic>>[];
          final checkIns = snapshot.data?.$2 ?? const <Map<String, dynamic>>[];
          return ResponsivePage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _purposeCard(),
                const SizedBox(height: 14),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, icon: Icon(Icons.timeline_outlined), label: Text('Timeline')),
                    ButtonSegment(value: 1, icon: Icon(Icons.compare_arrows_outlined), label: Text('Compare')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (value) => setState(() => _mode = value.first),
                ),
                const SizedBox(height: 18),
                if (_mode == 0)
                  _timelineView(screenings, checkIns)
                else
                  _compareView(screenings),
                const SizedBox(height: 28),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _purposeCard() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history_outlined, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'History has one purpose: show how your saved screenings and optional Daily Check-ins change over time. Compare is a mode inside History, not a separate feature.',
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.4, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineView(List<Map<String, dynamic>> screenings, List<Map<String, dynamic>> checkIns) {
    if (screenings.isEmpty && checkIns.isEmpty) {
      return _empty('No history yet', 'Complete a screening or save a Daily Check-in to start your timeline.');
    }
    final scorePoints = <TrendPoint>[];
    for (final record in screenings.reversed.take(12)) {
      final response = _map(record['response']);
      final payload = _map(record['inputData']);
      final metrics = HealthUiAdapter.metricsFromResponse(response, payload: payload);
      final missing = HealthUiAdapter.moreDataNeeded(response);
      final date = DateTime.tryParse(record['timestamp']?.toString() ?? '');
      if (metrics.isNotEmpty && date != null) {
        scorePoints.add(TrendPoint(label: '${date.day}/${date.month}', value: HealthUiAdapter.healthScore(metrics, missing).toDouble()));
      }
    }

    final events = <Map<String, dynamic>>[];
    for (final screening in screenings) {
      events.add({'type': 'screening', ...screening});
    }
    for (final checkIn in checkIns) {
      events.add({'type': 'checkin', ...checkIn});
    }
    events.sort((a, b) {
      final ad = DateTime.tryParse(a['timestamp']?.toString() ?? '') ?? DateTime(1970);
      final bd = DateTime.tryParse(b['timestamp']?.toString() ?? '') ?? DateTime(1970);
      return bd.compareTo(ad);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (scorePoints.isNotEmpty) ...[
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Health-score trend', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('A screening summary trend; individual indicators remain the source of detail.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                SimpleTrendChart(points: scorePoints, height: 200),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        Text('Timeline', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        for (final event in events.take(30)) ...[
          _eventCard(event),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _eventCard(Map<String, dynamic> event) {
    final colors = Theme.of(context).colorScheme;
    final type = event['type']?.toString();
    final date = _date(event['timestamp']);
    if (type == 'checkin') {
      final symptoms = (event['symptoms'] as List? ?? const []).map((e) => e.toString()).toList();
      return _card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eventIcon(Icons.favorite_border),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const Expanded(child: Text('Daily Check-in', style: TextStyle(fontWeight: FontWeight.w900))), Text(date, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12))]),
                  const SizedBox(height: 4),
                  Text('Energy ${event['energy'] ?? '—'}/5 • Sleep ${event['sleepQuality'] ?? '—'}/5${symptoms.isEmpty ? '' : ' • ${symptoms.join(', ')}'}', style: TextStyle(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final response = _map(event['response']);
    final payload = _map(event['inputData']);
    final metrics = HealthUiAdapter.metricsFromResponse(response, payload: payload);
    final missing = HealthUiAdapter.moreDataNeeded(response);
    final score = metrics.isEmpty ? null : HealthUiAdapter.healthScore(metrics, missing);
    final overall = HealthUiAdapter.overallStatus(metrics);
    final style = AppStyles.themedStatusStyle(context, overall);
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eventIcon(Icons.insights_outlined),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [const Expanded(child: Text('VitalMap screening', style: TextStyle(fontWeight: FontWeight.w900))), Text(date, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12))]),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (score != null) Text('Health score $score', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(AppStyles.displayStatusLabel(overall), style: TextStyle(color: style.accent, fontWeight: FontWeight.w900)),
                    Text('${metrics.length} indicators', style: TextStyle(color: colors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compareView(List<Map<String, dynamic>> screenings) {
    if (screenings.length < 2) {
      return _empty('Two screenings are needed', 'Complete another screening later. Compare becomes meaningful only when two saved screening results exist.');
    }
    if (_newerIndex >= screenings.length) _newerIndex = 0;
    if (_olderIndex >= screenings.length) _olderIndex = 1;
    if (_olderIndex == _newerIndex) _olderIndex = _newerIndex == 0 ? 1 : 0;
    final comparison = ChangeIntelligenceService.buildComparison(previous: screenings[_olderIndex], current: screenings[_newerIndex]);
    final changes = (comparison['metric_changes'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final contextChanges = (comparison['context_changes'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose two screenings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 620;
                  final older = _dropdown('Older', _olderIndex, screenings, (value) => setState(() { if (value != null && value != _newerIndex) { _olderIndex = value; _aiExplanation = null; _aiError = null; } }));
                  final newer = _dropdown('Newer', _newerIndex, screenings, (value) => setState(() { if (value != null && value != _olderIndex) { _newerIndex = value; _aiExplanation = null; _aiError = null; } }));
                  return compact ? Column(children: [older, const SizedBox(height: 10), newer]) : Row(children: [Expanded(child: older), const SizedBox(width: 10), Expanded(child: newer)]);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _scoreComparison(comparison),
        const SizedBox(height: 18),
        Text('What changed', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (changes.isEmpty)
          _empty('No comparable indicators', 'The selected screenings do not share enough calculated indicators to compare.')
        else
          for (final change in changes) ...[
            _changeCard(change),
            const SizedBox(height: 8),
          ],
        if (contextChanges.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Input values that changed alongside the result', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                for (final item in contextChanges)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['label']?.toString() ?? 'Input', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${item['previous']} → ${item['current']} ${item['unit'] ?? ''}'),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        _aiCompareCard(comparison),
      ],
    );
  }

  Widget _dropdown(String label, int value, List<Map<String, dynamic>> records, ValueChanged<int?> onChanged) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: '$label screening'),
      items: [
        for (var i = 0; i < records.length; i++) DropdownMenuItem(value: i, child: Text(_date(records[i]['timestamp']))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _scoreComparison(Map<String, dynamic> comparison) {
    final colors = Theme.of(context).colorScheme;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_date(comparison['previous_date'])} → ${_date(comparison['current_date'])}', style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _scoreTile('Previous', comparison['previous_health_score'], comparison['previous_overall_status'])),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, color: colors.primary)),
              Expanded(child: _scoreTile('Current', comparison['current_health_score'], comparison['current_overall_status'])),
            ],
          ),
          const SizedBox(height: 8),
          Text('Comparison is descriptive. VitalMap does not claim that one input change caused another result.', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, height: 1.35)),
        ],
      ),
    );
  }

  Widget _scoreTile(String label, dynamic score, dynamic status) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
          Text('${score ?? '—'}', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          Text(AppStyles.displayStatusLabel(status?.toString()), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _changeCard(Map<String, dynamic> change) {
    final colors = Theme.of(context).colorScheme;
    return _card(
      child: Row(
        children: [
          Icon(Icons.swap_horiz, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(change['display_name']?.toString() ?? change['index_name']?.toString() ?? 'Indicator', style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('${change['previous_score'] ?? '—'} → ${change['current_score'] ?? '—'} ${change['unit'] ?? ''}', style: TextStyle(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(change['status_direction']?.toString() ?? '', textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  Widget _aiCompareCard(Map<String, dynamic> comparison) {
    final colors = Theme.of(context).colorScheme;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.auto_awesome_outlined, color: colors.primary), const SizedBox(width: 8), const Expanded(child: Text('Local AI change explanation', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))), const Text('Ollama • local', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 6),
          Text('Ollama explains the already-computed comparison. It cannot change scores, statuses or formulas.', style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(height: 10),
          if (_aiExplanation == null && !_explaining)
            OutlinedButton.icon(onPressed: () => _explain(comparison), icon: const Icon(Icons.auto_awesome_outlined), label: const Text('Explain this comparison')),
          if (_explaining) const LinearProgressIndicator(),
          if (_aiError != null) ...[
            const SizedBox(height: 8),
            Text(_aiError!, style: TextStyle(color: colors.error)),
          ],
          if (_aiExplanation != null) ...[
            const SizedBox(height: 10),
            Text(_aiExplanation!['summary']?.toString() ?? '', style: const TextStyle(height: 1.4, fontWeight: FontWeight.w600)),
            for (final point in _list(_aiExplanation!['key_points'])) _bullet(point),
            for (final point in _list(_aiExplanation!['possible_context'])) _bullet(point),
          ],
        ],
      ),
    );
  }

  Future<void> _explain(Map<String, dynamic> comparison) async {
    setState(() { _explaining = true; _aiError = null; });
    try {
      final result = await BackendAnalysisService.explainChanges(comparison);
      if (mounted) setState(() => _aiExplanation = result);
    } catch (error) {
      if (mounted) setState(() => _aiError = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _explaining = false);
    }
  }

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6)), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(height: 1.35)))]),
      );

  Widget _eventIcon(IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Container(width: 42, height: 42, decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: colors.primary));
  }

  Widget _card({required Widget child}) {
    final colors = Theme.of(context).colorScheme;
    return Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: colors.outlineVariant)), child: child);
  }

  Widget _empty(String title, String text) => _card(
        child: Column(children: [Icon(Icons.history_toggle_off, size: 42, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 9), Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)), const SizedBox(height: 5), Text(text, textAlign: TextAlign.center)]),
      );

  static Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<String> _list(dynamic value) => value is List ? value.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList() : const [];

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Saved screening';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
