import 'package:flutter/material.dart';

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
    final status = AppStyles.statusStyle(rawStatus);
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
            actions: [
              IconButton(
                tooltip: 'More',
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _topCard(primary, status),
                    const SizedBox(height: 12),
                    _tabs(),
                    SizedBox(
                      height: 520,
                      child: TabBarView(
                        children: [
                          _overviewTab(primary, status),
                          _indicatorsTab(),
                          _insightsTab(primary),
                          _tipsTab(primary),
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
    );
  }

  Widget _topCard(HealthMetric? primary, HealthStatusStyle status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppStyles.border),
        boxShadow: [
          BoxShadow(
            color: status.accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          OrganVisualIcon(organ: organKey, size: 88, iconSize: 50),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
                  style: const TextStyle(
                    color: AppStyles.muted,
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
                    backgroundColor: AppStyles.border,
                    color: status.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppStyles.border)),
      ),
      child: const TabBar(
        labelColor: AppStyles.primary,
        unselectedLabelColor: AppStyles.muted,
        indicatorColor: AppStyles.primary,
        labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        tabs: [
          Tab(text: 'Overview'),
          Tab(text: 'Indicators'),
          Tab(text: 'Insights'),
          Tab(text: 'Tips'),
        ],
      ),
    );
  }

  Widget _overviewTab(HealthMetric? primary, HealthStatusStyle status) {
    return ListView(
      padding: const EdgeInsets.only(top: 14),
      children: [
        _riskLevelCard(status, primary),
        const SizedBox(height: 12),
        _keyIndicatorsCard(),
        const SizedBox(height: 12),
        _recommendationButton(status),
        const SizedBox(height: 12),
        const DisclaimerWidget(),
      ],
    );
  }

  Widget _riskLevelCard(HealthStatusStyle status, HealthMetric? primary) {
    return _detailCard(
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
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: status.accent, width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low', style: TextStyle(color: AppStyles.muted)),
              Text('Moderate', style: TextStyle(color: AppStyles.muted)),
              Text('High', style: TextStyle(color: AppStyles.muted)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            primary?.summary ??
                'Add available values to unlock this organ insight.',
            style: const TextStyle(color: AppStyles.text, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _keyIndicatorsCard() {
    return _detailCard(
      title: 'Key Indicators',
      child: metrics.isEmpty
          ? Text(
              missingCount == 0
                  ? 'No report values are available for this organ yet.'
                  : '$missingCount values can improve this insight.',
              style: const TextStyle(color: AppStyles.muted),
            )
          : Column(
              children: [
                for (final metric in metrics) _indicatorRow(metric),
              ],
            ),
    );
  }

  Widget _indicatorRow(HealthMetric metric) {
    final status = AppStyles.statusStyle(metric.rawStatus);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              metric.indexName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
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

  Widget _indicatorsTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 14),
      children: [
        _detailCard(
          title: 'Indicators',
          child: metrics.isEmpty
              ? const Text(
                  'More report values are needed for this organ.',
                  style: TextStyle(color: AppStyles.muted),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final metric in metrics) ...[
                      Text(metric.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in metric.valuesUsed.entries)
                            Chip(
                              backgroundColor: AppStyles.softBlue,
                              side: const BorderSide(
                                  color: AppStyles.softBlueBorder),
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

  Widget _insightsTab(HealthMetric? primary) {
    return ListView(
      padding: const EdgeInsets.only(top: 14),
      children: [
        _detailCard(
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

  Widget _tipsTab(HealthMetric? primary) {
    final suggestions =
        (primary?.source?['suggestions'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList();
    return ListView(
      padding: const EdgeInsets.only(top: 14),
      children: [
        _detailCard(
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
                            const Icon(Icons.check_circle_outline,
                                color: AppStyles.primary, size: 18),
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

  Widget _recommendationButton(HealthStatusStyle status) {
    return Container(
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextButton.icon(
        onPressed: () {},
        icon: Icon(Icons.lightbulb_outline, color: status.accent),
        label: Text(
          'View Recommendations',
          style: TextStyle(color: status.text, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _detailCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.border),
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
        (a, b) => AppStyles.statusRank(b.rawStatus)
            .compareTo(AppStyles.statusRank(a.rawStatus)),
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
