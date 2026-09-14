import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/ui_result_adapter.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/organ_visual.dart';

class HomeOverviewScreen extends StatelessWidget {
  const HomeOverviewScreen({
    super.key,
    required this.response,
    required this.payload,
    required this.lastChecked,
    required this.onStartAnalysis,
    required this.onViewResults,
    required this.onOpenHealthMap,
    required this.onOpenHistory,
    required this.onOpenCheckIn,
  });

  final Map<String, dynamic>? response;
  final Map<String, dynamic>? payload;
  final DateTime? lastChecked;
  final VoidCallback onStartAnalysis;
  final VoidCallback onViewResults;
  final VoidCallback onOpenHealthMap;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenCheckIn;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final metrics = HealthUiAdapter.metricsFromResponse(response, payload: payload);
    final missing = HealthUiAdapter.moreDataNeeded(response);
    final snapshots = HealthUiAdapter.organSnapshots(response, payload: payload);
    final hasResult = response != null && metrics.isNotEmpty;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              toolbarHeight: 72,
              title: const BrandAppBarTitle(title: 'VitalMap'),
            ),
      body: ResponsivePage(
        child: hasResult
            ? _currentOverview(context, metrics, missing, snapshots)
            : _emptyHome(context),
      ),
    );
  }

  Widget _emptyHome(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandLogoMark(size: 56, glow: true),
              const SizedBox(height: 18),
              Text(
                'Build your personal health map',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter values manually or import a reviewed lab report. VitalMap calculates supported screening indicators first, then local Ollama can explain practical wellness steps without changing those results.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.45),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onStartAnalysis,
                icon: const Icon(Icons.add_chart_outlined),
                label: const Text('Start screening'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle(context, 'How VitalMap is meant to be used'),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 3 : 1;
            final width = (constraints.maxWidth - ((columns - 1) * 10)) / columns;
            final cards = const [
              (Icons.edit_note_outlined, '1. Add data', 'Manual values or a reviewed lab-report import.'),
              (Icons.insights_outlined, '2. Understand results', 'Deterministic indicators, contributors and data gaps.'),
              (Icons.timeline_outlined, '3. Track change', 'Use Health Map and History to see what changes over time.'),
            ];
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final card in cards)
                  SizedBox(
                    width: width,
                    child: _featureCard(context, card.$1, card.$2, card.$3),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _currentOverview(
    BuildContext context,
    List<HealthMetric> metrics,
    List<Map<String, dynamic>> missing,
    List<OrganSnapshot> snapshots,
  ) {
    final colors = Theme.of(context).colorScheme;
    final score = HealthUiAdapter.healthScore(metrics, missing);
    final overall = HealthUiAdapter.overallStatus(metrics);
    final overallStyle = AppStyles.themedStatusStyle(context, overall);
    final prioritySystems = snapshots
        .where((item) => item.metrics.isNotEmpty)
        .toList()
      ..sort((a, b) => AppStyles.statusRank(b.rawStatus)
          .compareTo(AppStyles.statusRank(a.rawStatus)));
    final attention = prioritySystems
        .where((item) => AppStyles.statusRank(item.rawStatus) >= AppStyles.statusRank('Monitor'))
        .take(3)
        .toList();
    final calculatedSystems = prioritySystems.length;
    final completion = HealthUiAdapter.completionPercent(payload);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your latest VitalMap',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    lastChecked == null
                        ? 'Current screening overview'
                        : 'Screening from ${_formatDate(lastChecked!)}',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statChip(context, Icons.account_tree_outlined, '$calculatedSystems systems mapped'),
                      _statChip(context, Icons.fact_check_outlined, '$completion% data completion'),
                      _statChip(context, Icons.calculate_outlined, '${metrics.length} indicators'),
                    ],
                  ),
                ],
              );
              final scoreCard = Container(
                width: compact ? double.infinity : 160,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: overallStyle.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: overallStyle.border),
                ),
                child: Column(
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        color: overallStyle.text,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Health score',
                      style: TextStyle(color: overallStyle.text, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStyles.displayStatusLabel(overall),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: overallStyle.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [copy, const SizedBox(height: 14), scoreCard],
                );
              }
              return Row(
                children: [Expanded(child: copy), const SizedBox(width: 18), scoreCard],
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        _quickActions(context),
        const SizedBox(height: 24),
        _sectionTitle(context, 'What matters now'),
        const SizedBox(height: 10),
        if (attention.isEmpty)
          _messageCard(
            context,
            Icons.check_circle_outline,
            'No higher-priority system is being surfaced',
            'Open Result for the full screening breakdown or add another screening later to build your trend history.',
          )
        else
          for (final snapshot in attention) ...[
            _priorityCard(context, snapshot),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 22),
        _sectionTitle(context, 'Next best action'),
        const SizedBox(height: 10),
        _nextAction(context, missing, attention),
        const SizedBox(height: 22),
        _sectionTitle(context, 'Explore your health intelligence'),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 3 : 1;
            final width = (constraints.maxWidth - ((columns - 1) * 10)) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: width,
                  child: _actionFeatureCard(
                    context,
                    Icons.accessibility_new_outlined,
                    'Health Map',
                    'See which body systems have calculated indicators, their status, trend and data coverage.',
                    onOpenHealthMap,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _actionFeatureCard(
                    context,
                    Icons.timeline_outlined,
                    'History',
                    'Track screenings and Daily Check-ins together, then compare any two screenings.',
                    onOpenHistory,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _actionFeatureCard(
                    context,
                    Icons.favorite_border,
                    'Daily Check-in',
                    'Optionally log energy, sleep and symptoms as context for History and Local AI guidance.',
                    onOpenCheckIn,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _quickActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: onViewResults,
          icon: const Icon(Icons.insights_outlined),
          label: const Text('Open detailed result'),
        ),
        OutlinedButton.icon(
          onPressed: onStartAnalysis,
          icon: const Icon(Icons.edit_note_outlined),
          label: const Text('Add or update data'),
        ),
      ],
    );
  }

  Widget _priorityCard(BuildContext context, OrganSnapshot snapshot) {
    final colors = Theme.of(context).colorScheme;
    final status = AppStyles.themedStatusStyle(context, snapshot.rawStatus);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenHealthMap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              OrganVisualIcon(organ: snapshot.name, size: 48, showGlow: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(snapshot.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(snapshot.primaryText, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: status.badgeBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  snapshot.statusLabel,
                  style: TextStyle(color: status.text, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nextAction(
    BuildContext context,
    List<Map<String, dynamic>> missing,
    List<OrganSnapshot> attention,
  ) {
    if (missing.isNotEmpty) {
      final first = missing.first;
      return _messageCard(
        context,
        Icons.add_chart_outlined,
        'Add data that unlocks another indicator',
        HealthUiAdapter.missingActionText(first),
        actionText: 'Go to Input',
        onAction: onStartAnalysis,
      );
    }
    if (attention.isNotEmpty) {
      return _messageCard(
        context,
        Icons.fact_check_outlined,
        'Review the highest-priority result in detail',
        'View Details shows the deterministic result first, then generates Local Ollama guidance from your current context.',
        actionText: 'Open Result',
        onAction: onViewResults,
      );
    }
    return _messageCard(
      context,
      Icons.timeline_outlined,
      'Build a meaningful trend',
      'Add future screenings to History. Comparison becomes useful when you have at least two saved screenings.',
      actionText: 'Open History',
      onAction: onOpenHistory,
    );
  }

  Widget _messageCard(
    BuildContext context,
    IconData icon,
    String title,
    String text, {
    String? actionText,
    VoidCallback? onAction,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(color: colors.onSurfaceVariant, height: 1.35)),
                if (actionText != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  TextButton(onPressed: onAction, child: Text(actionText)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String text,
    VoidCallback onTap,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
                  Icon(Icons.arrow_forward, size: 18, color: colors.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 4),
              Text(text, style: TextStyle(color: colors.onSurfaceVariant, height: 1.35)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard(BuildContext context, IconData icon, String title, String text) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(height: 9),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(text, style: TextStyle(color: colors.onSurfaceVariant, height: 1.35)),
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context, IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      );

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
