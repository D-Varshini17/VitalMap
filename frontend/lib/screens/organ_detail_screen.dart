import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/ui_result_adapter.dart';
import '../styles.dart';
import '../widgets/disclaimer.dart';
import '../widgets/health_dashboard_widgets.dart';
import '../widgets/organ_visual.dart';

class OrganDetailScreen extends StatelessWidget {
  const OrganDetailScreen({
    super.key,
    required this.organKey,
    required this.organName,
    required this.metrics,
    required this.missingCount,
  });

  final String organKey;
  final String organName;
  final List<HealthMetric> metrics;
  final int missingCount;

  @override
  Widget build(BuildContext context) {
    final primary = _primaryMetric();
    final rawStatus = primary?.rawStatus ?? 'More Data Needed';
    final status = AppStyles.themedStatusStyle(context, rawStatus);
    return DefaultTabController(
      length: 4,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                OrganVisualIcon(organ: organKey, size: 34, iconSize: 19),
                const SizedBox(width: 9),
                Expanded(child: Text(organName)),
              ],
            ),
          ),
          body: ResponsiveContainer(
            maxWidth: Responsive.detailMaxWidth,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                    children: [
                      _topCard(context, primary, status),
                      const SizedBox(height: 12),
                      _tabs(context),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.66,
                        child: TabBarView(
                          children: [
                            _overviewTab(context, primary, status),
                            _indicatorsTab(context),
                            _insightsTab(context, primary),
                            _tipsTab(context, primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topCard(
      BuildContext context, HealthMetric? primary, HealthStatusStyle status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: status.accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageSize = constraints.maxWidth < 520 ? 112.0 : 160.0;
          final image = OrganVisualIcon(
            organ: organKey,
            size: imageSize,
            iconSize: imageSize * 0.45,
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$organName Health',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              StatusBadge(status: status),
              const SizedBox(height: 10),
              Text(
                primary?.displayName ?? 'More Data Needed',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                primary == null
                    ? 'Add report values'
                    : '${primary.scoreText}${primary.unit.isEmpty ? '' : ' ${primary.unit}'}',
                style: TextStyle(
                  color: status.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: _progressForStatus(status),
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                  color: status.accent,
                ),
              ),
            ],
          );
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: image),
                const SizedBox(height: 14),
                details,
              ],
            );
          }
          return Row(
            children: [
              image,
              const SizedBox(width: 16),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }

  Widget _tabs(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: TabBar(
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        tabs: [
          Tab(text: 'Summary'),
          Tab(text: 'Indicators'),
          Tab(text: 'Insights'),
          Tab(text: 'Tips'),
        ],
      ),
    );
  }

  Widget _overviewTab(
      BuildContext context, HealthMetric? primary, HealthStatusStyle status) {
    return ListView(
      padding: const EdgeInsets.only(top: 14),
      children: [
        _riskLevelCard(context, status, primary),
        const SizedBox(height: 12),
        _keyIndicatorsCard(context),
        const SizedBox(height: 12),
        const DisclaimerWidget(),
      ],
    );
  }

  Widget _riskLevelCard(
      BuildContext context, HealthStatusStyle status, HealthMetric? primary) {
    return _detailCard(
      context,
      title: 'Risk Level',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: const [
                    Expanded(child: ColoredBox(color: Color(0xFF6CCB8D))),
                    Expanded(child: ColoredBox(color: Color(0xFFFFBE5A))),
                    Expanded(child: ColoredBox(color: Color(0xFFFFA6B7))),
                  ],
                ),
                Align(
                  alignment: Alignment(_markerAlignment(status), 0),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: status.accent, width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text('Moderate',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text('High',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            primary?.summary ??
                'Add available values to unlock this organ insight.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _keyIndicatorsCard(BuildContext context) {
    return _detailCard(
      context,
      title: 'Key Indicators',
      child: metrics.isEmpty
          ? Text(
              missingCount == 0
                  ? 'No report values are available for this organ yet.'
                  : '$missingCount values can improve this insight.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            )
          : Column(
              children: [
                for (final metric in metrics) _indicatorRow(context, metric)
              ],
            ),
    );
  }

  Widget _indicatorRow(BuildContext context, HealthMetric metric) {
    final status = AppStyles.themedStatusStyle(context, metric.rawStatus);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          Text(
            metric.indexName,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            '${metric.scoreText}${metric.unit.isEmpty ? '' : ' ${metric.unit}'}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 10),
          StatusBadge(status: status),
        ],
      ),
    );
  }

  Widget _indicatorsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 14),
      children: [
        _detailCard(
          context,
          title: 'Indicators',
          child: metrics.isEmpty
              ? Text(
                  'More report values are needed for this organ.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final metric in metrics) ...[
                      Text(
                        metric.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in metric.valuesUsed.entries)
                            Chip(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              label: Text(
                                '${HealthUiAdapter.cleanKey(entry.key)}: ${entry.value}',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _insightsTab(BuildContext context, HealthMetric? primary) {
    return ListView(
      padding: const EdgeInsets.only(top: 14),
      children: [
        _detailCard(
          context,
          title: 'Insights',
          child: Text(
            primary?.summary ??
                'Add available report values to generate deeper insight.',
            style: const TextStyle(height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _tipsTab(BuildContext context, HealthMetric? primary) {
    final suggestions =
        (primary?.source?['suggestions'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList();
    return ListView(
      padding: const EdgeInsets.only(top: 14),
      children: [
        _detailCard(
          context,
          title: 'Tips',
          child: suggestions.isEmpty
              ? const Text(
                  'Keep routine follow-up and discuss persistent unusual values with a qualified healthcare professional.',
                  style: TextStyle(height: 1.4),
                )
              : Column(
                  children: [
                    for (final item in suggestions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _detailCard(BuildContext context,
      {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  HealthMetric? _primaryMetric() {
    if (metrics.isEmpty) return null;
    final ordered = [...metrics]..sort(
        (a, b) => AppStyles.statusRank(
          b.rawStatus,
        ).compareTo(AppStyles.statusRank(a.rawStatus)),
      );
    return ordered.first;
  }

  double _progressForStatus(HealthStatusStyle status) {
    if (status.label == AppStyles.attentionStatus.label) return 0.88;
    if (status.label == AppStyles.monitorStatus.label) return 0.58;
    if (status.label == AppStyles.lowConcernStatus.label) return 0.28;
    return 0.12;
  }

  double _markerAlignment(HealthStatusStyle status) {
    if (status.label == AppStyles.attentionStatus.label) return 0.78;
    if (status.label == AppStyles.monitorStatus.label) return 0.0;
    if (status.label == AppStyles.lowConcernStatus.label) return -0.78;
    return -0.92;
  }
}
