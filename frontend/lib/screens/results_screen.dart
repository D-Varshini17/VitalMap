import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/ui_result_adapter.dart';
import '../storage/local_storage.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/disclaimer.dart';
import '../widgets/organ_visual.dart';
import 'index_detail_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    this.response,
    this.lastChecked,
  });

  final Map<String, dynamic>? response;
  final DateTime? lastChecked;

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
    final metrics = HealthUiAdapter.metricsFromResponse(response, payload: payload);
    final moreData = HealthUiAdapter.moreDataNeeded(response);
    final counts = HealthUiAdapter.statusCounts(metrics, moreData);
    final overallRaw = HealthUiAdapter.overallStatus(metrics);
    final overallStyle = AppStyles.statusStyle(overallRaw);
    final healthScore = HealthUiAdapter.healthScore(metrics, moreData);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const BrandAppBarTitle(title: 'VitalMap'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {},
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
                    monitorCount: counts['monitor']!,
                    attentionCount: counts['attention']!,
                    moreDataCount: counts['moreData']!,
                  ),
                  const SizedBox(height: 24),
                  _needsAttentionSection(metrics),
                  const SizedBox(height: 24),
                  _organWiseOverview(metrics, moreData),
                  const SizedBox(height: 24),
                  if (moreData.isNotEmpty) _moreDataNeededCards(moreData),
                  const SizedBox(height: 24),
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
          monitorCount: 0,
          attentionCount: 0,
          moreDataCount: 0,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppStyles.border),
          ),
          child: const Column(
            children: [
              Icon(Icons.assignment_outlined, size: 46, color: AppStyles.primary),
              SizedBox(height: 12),
              Text(
                'No screening insight yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    required int monitorCount,
    required int attentionCount,
    required int moreDataCount,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppStyles.navy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppStyles.navy.withValues(alpha: 0.15),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Health Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _ScoreRing(score: score),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Status', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _heroStatusBadge(status),
                  const SizedBox(height: 16),
                  const Text('Last checked', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    lastChecked == null ? 'Not checked yet' : _formatDate(lastChecked!),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem(calculatedCount.toString(), 'Calculated\nIndicators'),
              _statItem(monitorCount.toString(), 'Monitor\nIndicators'),
              _statItem(attentionCount.toString(), 'Attention\nIndicators'),
              _statItem(moreDataCount.toString(), 'More Data\nIndicators'),
            ],
          )
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.2)),
      ],
    );
  }

  Widget _heroStatusBadge(HealthStatusStyle status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: status.badgeBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppStyles.displayStatusLabel(status.label),
        style: TextStyle(
          color: status.text,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _needsAttentionSection(List<HealthMetric> metrics) {
    final attentionItems = metrics.where((m) {
      final l = AppStyles.statusLabel(m.rawStatus);
      return l == 'Monitor' || l == 'Attention Needed';
    }).toList();

    if (attentionItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFFFFF0E4), shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD46B25), size: 16),
            ),
            const SizedBox(width: 8),
            const Text('Needs Your Attention', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Text('View All', style: TextStyle(color: AppStyles.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ...attentionItems.map((m) => _attentionCard(m)),
      ],
    );
  }

  Widget _attentionCard(HealthMetric metric) {
    final status = AppStyles.statusStyle(metric.rawStatus);
    return GestureDetector(
      onTap: () => _openDetail(metric),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppStyles.border),
          boxShadow: [
            BoxShadow(
              color: AppStyles.navy.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrganVisualIcon(organ: metric.organKey, size: 42, iconSize: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(metric.indexName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      _smallStatusBadge(status),
                      const Spacer(),
                      Text('${metric.scoreText} >', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(metric.summary, style: const TextStyle(fontSize: 12, color: AppStyles.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallStatusBadge(HealthStatusStyle status) {
    return Text(
      AppStyles.displayStatusLabel(status.label),
      style: TextStyle(
        color: status.accent,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _organWiseOverview(List<HealthMetric> metrics, List<Map<String, dynamic>> moreData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Organ-wise Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('View All', style: TextStyle(color: AppStyles.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          children: [
            _organGridCard('Heart', 'AIP', metrics, moreData),
            _organGridCard('Liver', 'FIB-4', metrics, moreData),
            _organGridCard('Kidney', 'eGFR', metrics, moreData),
            _organGridCard('Lungs', 'SpO₂', metrics, moreData),
            _organGridCard('Brain / Metabolic', 'TyG', metrics, moreData),
            _organGridCard('Inflammation', 'NLR', metrics, moreData),
            _organGridCard('Pancreas', 'LAR', metrics, moreData),
            _organGridCard('Cancer Awareness', 'AFP', metrics, moreData),
          ],
        ),
      ],
    );
  }

  Widget _organGridCard(String organName, String defaultIndex, List<HealthMetric> metrics, List<Map<String, dynamic>> moreData) {
    final organMetrics = metrics.where((m) => m.organName == organName || m.organKey == organName.toLowerCase()).toList();
    HealthStatusStyle status = AppStyles.moreDataStatus;
    String scoreText = '';
    String label = 'More Data Needed';

    if (organMetrics.isNotEmpty) {
      final primary = organMetrics.first;
      status = AppStyles.statusStyle(primary.rawStatus);
      scoreText = primary.scoreText;
      defaultIndex = primary.indexName;
      label = status.label;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.border),
        boxShadow: [
          BoxShadow(
            color: AppStyles.navy.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OrganVisualIcon(organ: organName.toLowerCase(), size: 36, iconSize: 22, showGlow: false),
          const SizedBox(height: 8),
          Text(organName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center, maxLines: 1),
          if (scoreText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('$defaultIndex: $scoreText', style: const TextStyle(fontSize: 10, color: AppStyles.text)),
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: status.badgeBackground,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              AppStyles.displayStatusLabel(label),
              style: TextStyle(color: status.text, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moreDataNeededCards(List<Map<String, dynamic>> moreData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('More Data Can Improve Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...moreData.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppStyles.moreDataStatus.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppStyles.moreDataStatus.border),
              ),
              child: Row(
                children: [
                  OrganVisualIcon(organ: item['organ']?.toString() ?? '', size: 36, iconSize: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add ${HealthUiAdapter.missingText(item)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Add Data', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  void _openDetail(HealthMetric metric) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IndexDetailScreen(metric: metric),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(104),
            painter: _ScoreRingPainter(progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12,
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
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.16);
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
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
