import 'package:firebase_core/firebase_core.dart';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/ui_result_adapter.dart';
import '../services/firestore_service.dart';
import '../storage/local_storage.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/organ_visual.dart';
import 'index_detail_screen.dart';

class BodyHealthMapScreen extends StatefulWidget {
  const BodyHealthMapScreen({super.key});

  @override
  State<BodyHealthMapScreen> createState() => _BodyHealthMapScreenState();
}

class _BodyHealthMapScreenState extends State<BodyHealthMapScreen> {
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadHistory();
  }

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    final user = Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final history = await FirestoreService.loadScreeningHistory(user.uid, limit: 20);
        if (history.isNotEmpty) return history;
      } catch (_) {}
    }

    final stored = await LocalStorage.loadLastResponse();
    if (stored == null) return <Map<String, dynamic>>[];
    final response = stored['response'];
    if (response is! Map) return <Map<String, dynamic>>[];
    final payload = await LocalStorage.loadLastPayload();
    return [
      {
        'response': Map<String, dynamic>.from(response),
        'inputData': payload ?? <String, dynamic>{},
        'timestamp': stored['timestamp'],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const BrandAppBarTitle(title: 'Health Map'),
              actions: [
                IconButton(
                  tooltip: 'Refresh health map',
                  onPressed: () => setState(() => _future = _loadHistory()),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _message(
              Icons.error_outline,
              'Could not load your Health Map',
              snapshot.error.toString(),
            );
          }
          final history = snapshot.data ?? const <Map<String, dynamic>>[];
          if (history.isEmpty) {
            return _message(
              Icons.accessibility_new_outlined,
              'No screening available yet',
              'Complete a VitalMap screening first. Your supported organ-health indicators will then appear on this map.',
            );
          }

          final latest = history.first;
          final previous = history.length > 1 ? history[1] : null;
          final response = _map(latest['response']);
          final payload = _map(latest['inputData']);
          final latestSnapshots = HealthUiAdapter.organSnapshots(response, payload: payload);
          final previousSnapshots = previous == null
              ? <OrganSnapshot>[]
              : HealthUiAdapter.organSnapshots(
                  _map(previous['response']),
                  payload: _map(previous['inputData']),
                );
          final latestByKey = {for (final item in latestSnapshots) item.key: item};
          final previousByKey = {for (final item in previousSnapshots) item.key: item};

          return ResponsivePage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _purposeCard(),
                const SizedBox(height: 12),
                _summaryCard(response, payload, latestSnapshots, latest['timestamp']?.toString()),
                const SizedBox(height: 14),
                _legend(),
                const SizedBox(height: 12),
                _interactiveMap(latestByKey, previousByKey),
                const SizedBox(height: 10),
                Text(
                  'Tap a highlighted system on the image. On smaller screens you can pinch to zoom and drag the map.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                _systemOverview(latestSnapshots, previousByKey),
                const SizedBox(height: 20),
                _additionalAreas(latestByKey, previousByKey),
                const SizedBox(height: 14),
                Text(
                  'The Health Map visualizes existing VitalMap screening indicators. It is not an anatomical diagnosis and it does not infer disease from the image.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 26),
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
          Icon(Icons.accessibility_new_outlined, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Health Map answers one question: which body systems have supported screening information right now? Tap a hotspot to see its indicators, status, change from the previous screening and whether more input data is needed. The image is navigation, not an anatomical diagnosis.',
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.4, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    Map<String, dynamic> response,
    Map<String, dynamic> payload,
    List<OrganSnapshot> snapshots,
    String? timestamp,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = HealthUiAdapter.metricsFromResponse(response, payload: payload);
    final missing = HealthUiAdapter.moreDataNeeded(response);
    final score = HealthUiAdapter.healthScore(metrics, missing);
    final overall = HealthUiAdapter.overallStatus(metrics);
    final style = AppStyles.themedStatusStyle(context, overall);
    final activeSystems = snapshots.where((item) => item.metrics.isNotEmpty).length;
    final monitorSystems = snapshots.where((item) => AppStyles.statusRank(item.rawStatus) >= AppStyles.statusRank('Monitor')).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final scoreWidget = Container(
            width: compact ? double.infinity : 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: style.border),
            ),
            child: Column(
              children: [
                Text('$score', style: TextStyle(color: style.text, fontSize: 28, fontWeight: FontWeight.w900)),
                Text('Health score', style: TextStyle(color: style.text, fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          );
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your current Health Map', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                '${_formatDate(timestamp)} • $activeSystems systems with calculated data • $monitorSystems worth reviewing',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                'The highlighted map regions use the same deterministic statuses shown in Result > View Details.',
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
              ),
            ],
          );
          if (compact) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [copy, const SizedBox(height: 12), scoreWidget]);
          }
          return Row(children: [Expanded(child: copy), const SizedBox(width: 16), scoreWidget]);
        },
      ),
    );
  }

  Widget _legend() {
    final entries = <(String, String)>[
      ('Good', 'Stable / good'),
      ('Monitor', 'Monitor'),
      ('Attention Needed', 'Attention'),
      ('More Data Needed', 'More data'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in entries)
          Builder(
            builder: (context) {
              final style = AppStyles.themedStatusStyle(context, entry.$1);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: style.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: style.accent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(entry.$2, style: TextStyle(color: style.text, fontWeight: FontWeight.w800, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _interactiveMap(
    Map<String, OrganSnapshot> latest,
    Map<String, OrganSnapshot> previous,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      height: 560,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mapWidth = math.max(constraints.maxWidth, math.min(880.0, constraints.maxWidth * 1.7));
          final mapHeight = mapWidth * (745 / 1424);
          return InteractiveViewer(
            constrained: false,
            minScale: 1,
            maxScale: 3,
            boundaryMargin: const EdgeInsets.all(80),
            child: SizedBox(
              width: mapWidth,
              height: mapHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/body_health_map.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: scheme.surfaceContainer,
                        alignment: Alignment.center,
                        child: const Text('Health Map image could not be loaded.'),
                      ),
                    ),
                  ),
                  _hotspot(latest['Diabetes / Metabolic'], previous['Diabetes / Metabolic'], 0.502, 0.138, mapWidth, mapHeight),
                  _hotspot(latest['Lung'], previous['Lung'], 0.404, 0.325, mapWidth, mapHeight),
                  _hotspot(latest['Heart'], previous['Heart'], 0.550, 0.379, mapWidth, mapHeight),
                  _hotspot(latest['Liver'], previous['Liver'], 0.598, 0.497, mapWidth, mapHeight),
                  _hotspot(latest['Pancreas'], previous['Pancreas'], 0.495, 0.572, mapWidth, mapHeight),
                  _hotspot(latest['Kidney'], previous['Kidney'], 0.383, 0.633, mapWidth, mapHeight),
                  _hotspot(latest['Kidney'], previous['Kidney'], 0.624, 0.633, mapWidth, mapHeight),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _hotspot(
    OrganSnapshot? current,
    OrganSnapshot? previous,
    double x,
    double y,
    double mapWidth,
    double mapHeight,
  ) {
    if (current == null) return const SizedBox.shrink();
    final style = AppStyles.themedStatusStyle(context, current.rawStatus);
    final size = (mapWidth * 0.064).clamp(46.0, 76.0).toDouble();
    return Positioned(
      left: (mapWidth * x) - size / 2,
      top: (mapHeight * y) - size / 2,
      child: Tooltip(
        message: '${current.name}: ${current.statusLabel}',
        child: GestureDetector(
          onTap: () => _showSystem(current, previous),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: style.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: style.accent, width: 3),
              boxShadow: [
                BoxShadow(
                  color: style.accent.withValues(alpha: 0.30),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                width: size * 0.24,
                height: size * 0.24,
                decoration: BoxDecoration(
                  color: style.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _systemOverview(
    List<OrganSnapshot> latest,
    Map<String, OrganSnapshot> previous,
  ) {
    if (latest.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 3 : constraints.maxWidth >= 600 ? 2 : 1;
            final width = (constraints.maxWidth - ((columns - 1) * 10)) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in latest.where((item) => !{'Inflammation', 'Cancer Awareness'}.contains(item.key)))
                  SizedBox(
                    width: width,
                    child: _systemCard(item, previous[item.key]),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _systemCard(OrganSnapshot current, OrganSnapshot? previous) {
    final scheme = Theme.of(context).colorScheme;
    final style = AppStyles.themedStatusStyle(context, current.rawStatus);
    final trend = _trendText(current, previous);
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showSystem(current, previous),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              OrganVisualIcon(organ: current.name, size: 46, showGlow: true),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(current.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(current.statusLabel, style: TextStyle(color: style.accent, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(trend, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _additionalAreas(
    Map<String, OrganSnapshot> latest,
    Map<String, OrganSnapshot> previous,
  ) {
    final items = [
      if (latest['Inflammation'] != null) latest['Inflammation']!,
      if (latest['Cancer Awareness'] != null) latest['Cancer Awareness']!,
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Additional screening areas', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        for (final item in items) ...[
          _systemCard(item, previous[item.key]),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  void _showSystem(OrganSnapshot current, OrganSnapshot? previous) {
    final scheme = Theme.of(context).colorScheme;
    final style = AppStyles.themedStatusStyle(context, current.rawStatus);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.82,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            children: [
              Row(
                children: [
                  OrganVisualIcon(organ: current.name, size: 54, showGlow: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(current.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(current.statusLabel, style: TextStyle(color: style.accent, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timeline_outlined, color: scheme.primary),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Compared with previous screening', style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(_trendText(current, previous), style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(current.message, style: const TextStyle(height: 1.45)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: Text('Calculated indicators', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                  Text('${current.metrics.length}', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 8),
              if (current.metrics.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    current.missingCount > 0
                        ? '${current.missingCount} additional input item(s) are needed before this system has a calculated indicator.'
                        : 'No calculated indicator is currently available for this screening area.',
                  ),
                )
              else
                for (final metric in current.metrics) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(this.context).push(
                        MaterialPageRoute(builder: (_) => IndexDetailScreen(metric: metric)),
                      );
                    },
                    leading: OrganVisualIcon(organ: current.name, size: 38),
                    title: Text(metric.displayName, style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text(metric.statusLabel),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${metric.scoreText}${metric.unit.isEmpty ? '' : ' ${metric.unit}'}'),
                        const SizedBox(width: 3),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: scheme.outlineVariant),
                ],
              const SizedBox(height: 16),
              Text(
                'Tap an indicator to open the normal VitalMap View Details page with formula, values used, contributors, existing follow-up guidance and Local AI wellness suggestions.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _trendText(OrganSnapshot current, OrganSnapshot? previous) {
    if (previous == null) return 'No previous screening to compare yet.';
    final currentRank = AppStyles.statusRank(current.rawStatus);
    final previousRank = AppStyles.statusRank(previous.rawStatus);
    if (currentRank < previousRank) return 'Screening label moved to a lower-concern category.';
    if (currentRank > previousRank) return 'Screening label moved to a higher-concern category.';
    if (current.metrics.length != previous.metrics.length) {
      return 'Same screening label; available indicator coverage changed.';
    }
    return 'Screening label is stable compared with the previous saved screening.';
  }

  Widget _message(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  String _formatDate(String? value) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) return 'Latest screening';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }
}
