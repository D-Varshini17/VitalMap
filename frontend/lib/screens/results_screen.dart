import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/ui_result_adapter.dart';
import '../storage/local_storage.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/disclaimer.dart';
import '../widgets/health_dashboard_widgets.dart';
import '../widgets/organ_visual.dart';
import 'organ_detail_screen.dart';
import 'add_missing_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    this.response,
    this.lastChecked,
    this.onViewOverview,
  });

  final Map<String, dynamic>? response;
  final DateTime? lastChecked;
  final VoidCallback? onViewOverview;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Map<String, dynamic>? response;
  Map<String, dynamic>? payload;
  DateTime? lastChecked;

  @override
  void initState() {
    super.initState();
    response = widget.response;
    lastChecked = widget.lastChecked;
    _loadLast();
  }

  @override
  void didUpdateWidget(covariant ResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.response != oldWidget.response ||
        widget.lastChecked != oldWidget.lastChecked) {
      response = widget.response;
      lastChecked = widget.lastChecked;
    }
  }

  Future<void> _loadLast() async {
    final storedResponse = await LocalStorage.loadLastResponse();
    final storedPayload = await LocalStorage.loadLastPayload();
    if (!mounted) return;
    setState(() {
      payload = storedPayload;
      if (response == null && storedResponse != null) {
        response = storedResponse['response'] as Map<String, dynamic>?;
        final timestamp = storedResponse['timestamp'] as String?;
        lastChecked = timestamp == null ? null : DateTime.tryParse(timestamp);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics =
        HealthUiAdapter.metricsFromResponse(response, payload: payload);
    final moreData = HealthUiAdapter.moreDataNeeded(response);
    final counts = HealthUiAdapter.statusCounts(metrics, moreData);
    final overallRaw = HealthUiAdapter.overallStatus(metrics);
    final overallStyle = AppStyles.statusStyle(overallRaw);
    final healthScore = HealthUiAdapter.healthScore(metrics, moreData);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const BrandAppBarTitle(title: 'Results'),
          actions: [
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export screening summary is coming soon.'),
                ),
              ),
            ),
          ],
        ),
        body: metrics.isEmpty && response == null
            ? _emptyState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _summaryHero(
                    status: overallStyle,
                    score: healthScore,
                    calculatedCount: counts['calculated']!,
                    moreDataCount: counts['moreData']!,
                  ),
                  const SizedBox(height: 12),
                  _metricSummaryRow(counts),
                  const SizedBox(height: 18),
                  _sectionHeader('Calculated Indexes', 'View All'),
                  const SizedBox(height: 8),
                  for (final metric in metrics) _metricRow(metric),
                  _meaningCard(overallRaw, counts['calculated']!),
                  _viewOverviewButton(),
                  _recommendationCard(metrics),
                  if (moreData.isNotEmpty) _moreDataCard(moreData),
                  const DisclaimerWidget(),
                ],
              ),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _summaryHero(
          status: AppStyles.moreDataStatus,
          score: 0,
          calculatedCount: 0,
          moreDataCount: 0,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppStyles.border),
          ),
          child: const Column(
            children: [
              Icon(Icons.assignment_outlined,
                  size: 46, color: AppStyles.primary),
              SizedBox(height: 12),
              Text(
                'No screening insight yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 6),
              Text(
                'Complete the input screen to calculate available indicators.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppStyles.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryHero({
    required HealthStatusStyle status,
    required int score,
    required int calculatedCount,
    required int moreDataCount,
  }) {
    final summary = HealthUiAdapter.summaryText(status.label, calculatedCount);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppStyles.navy, AppStyles.deepBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppStyles.navy.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Health Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Calculated from available data',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _heroStatusBadge(status),
                const SizedBox(height: 10),
                Text(
                  summary,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Last checked: ${lastChecked == null ? 'Not checked yet' : _formatDate(lastChecked!)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _ScoreRing(score: score),
        ],
      ),
    );
  }

  Widget _heroStatusBadge(HealthStatusStyle status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: status.badgeBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppStyles.displayStatusLabel(status.label),
        style: TextStyle(
          color: status.text,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _metricSummaryRow(Map<String, int> counts) {
    return Row(
      children: [
        Expanded(
          child: _summaryTile(
            counts['calculated']!.toString(),
            'Calculated\nIndicators',
            AppStyles.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryTile(
            counts['monitor']!.toString(),
            'Monitor',
            AppStyles.monitorStatus.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryTile(
            counts['moreData']!.toString(),
            'More Data\nNeeded',
            AppStyles.moreDataStatus.accent,
          ),
        ),
      ],
    );
  }

  Widget _summaryTile(String value, String label, Color color) {
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppStyles.text,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String action) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: AppStyles.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _metricRow(HealthMetric metric) {
    final status = AppStyles.statusStyle(metric.rawStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppStyles.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _openMetricDetail(metric),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              OrganVisualIcon(organ: metric.organKey, size: 42, iconSize: 23),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${metric.indexName} (${metric.displayName})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metric.organName,
                      style: const TextStyle(
                        color: AppStyles.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${metric.scoreText}${metric.unit.isEmpty ? '' : ' ${metric.unit}'}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 10),
              _smallStatusBadge(status, metric.statusLabel),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppStyles.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallStatusBadge(HealthStatusStyle status, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: status.badgeBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: status.text,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _meaningCard(String rawStatus, int calculatedCount) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppStyles.softBlue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.info_outline, color: AppStyles.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What this means',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  HealthUiAdapter.summaryText(rawStatus, calculatedCount),
                  style: const TextStyle(color: AppStyles.muted, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const SizedBox(width: 62, height: 54, child: _MiniChart()),
        ],
      ),
    );
  }

  Widget _recommendationCard(List<HealthMetric> metrics) {
    final primary = _primaryMetric(metrics);
    final rec = Map<String, dynamic>.from(
      primary?.source?['ai_recommendation'] as Map? ?? const {},
    );
    if (primary == null && rec.isEmpty) return const SizedBox.shrink();
    final summary = rec['simple_summary']?.toString() ?? primary!.summary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.softBlueBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personalized Recommendations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(summary, style: const TextStyle(height: 1.35)),
          _compactList('Lifestyle', rec['lifestyle_recommendations']),
          _compactList('Food', rec['food_recommendations']),
          _compactList('Environment', rec['environment_recommendations']),
          if (rec['doctor_followup'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Doctor follow-up: ${rec['doctor_followup']}',
                style: const TextStyle(
                  color: AppStyles.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _viewOverviewButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: GradientActionButton(
          onPressed: widget.onViewOverview,
          label: 'View Full Overview',
          icon: Icons.arrow_forward,
        ),
      ),
    );
  }

  Widget _compactList(String title, dynamic values) {
    final list = (values as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .take(3)
        .toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        '$title: ${list.join('; ')}',
        style: const TextStyle(color: AppStyles.muted, height: 1.35),
      ),
    );
  }

  Widget _moreDataCard(List<Map<String, dynamic>> moreData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppStyles.moreDataStatus.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.moreDataStatus.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'More Data Needed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add missing values to unlock deeper organ-wise insight.',
            style: TextStyle(color: AppStyles.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in moreData.take(8))
                ActionChip(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppStyles.border),
                  label: Text(
                    '${item['index_name'] ?? 'Insight'}: ${HealthUiAdapter.missingText(item)}',
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AddMissingScreen()),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  HealthMetric? _primaryMetric(List<HealthMetric> metrics) {
    if (metrics.isEmpty) return null;
    final ordered = [...metrics]..sort(
        (a, b) => AppStyles.statusRank(b.rawStatus)
            .compareTo(AppStyles.statusRank(a.rawStatus)),
      );
    return ordered.first;
  }

  void _openMetricDetail(HealthMetric metric) {
    final metrics = HealthUiAdapter.metricsFromResponse(
      response,
      payload: payload,
    ).where((item) => item.organKey == metric.organKey).toList();
    final missing = HealthUiAdapter.moreDataNeeded(response)
        .where((item) => item['organ']?.toString() == metric.organKey)
        .length;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OrganDetailScreen(
          organKey: metric.organKey,
          organName: metric.organName,
          metrics: metrics,
          missingCount: missing,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final progress = score <= 0 ? 0.0 : score / 100;
    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(116),
            painter: _ScoreRingPainter(progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2 - 8;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.16);
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = AppStyles.accent;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * math.pi * 2,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _MiniChart extends StatelessWidget {
  const _MiniChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MiniChartPainter());
  }
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFBCD9FF);
    final bars = [0.28, 0.46, 0.62, 0.84];
    for (var i = 0; i < bars.length; i++) {
      final width = size.width / 7;
      final left = i * width * 1.55 + 6;
      final height = size.height * bars[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - height, width, height),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }
    final line = Paint()
      ..color = AppStyles.primary.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(3, size.height * 0.72)
      ..lineTo(size.width * 0.34, size.height * 0.48)
      ..lineTo(size.width * 0.62, size.height * 0.58)
      ..lineTo(size.width - 3, size.height * 0.18);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
