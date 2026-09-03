import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/ui_result_adapter.dart';
import '../services/export_summary_service.dart';
import '../storage/local_storage.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/disclaimer.dart';
import '../widgets/organ_visual.dart';
import 'add_missing_screen.dart';
import 'index_detail_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen(
      {super.key, this.response, this.payload, this.lastChecked});

  final Map<String, dynamic>? response;
  final Map<String, dynamic>? payload;
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
    payload = widget.payload;
    lastChecked = widget.lastChecked;
    _loadLast();
  }

  @override
  void didUpdateWidget(covariant ResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.response != oldWidget.response ||
        widget.payload != oldWidget.payload ||
        widget.lastChecked != oldWidget.lastChecked) {
      response = widget.response;
      payload = widget.payload;
      lastChecked = widget.lastChecked;
    }
  }

  Future<void> _loadLast() async {
    final storedResponse = await LocalStorage.loadLastResponse();
    final storedPayload = await LocalStorage.loadLastPayload();
    if (!mounted) return;
    setState(() {
      payload ??= storedPayload;
      if (response == null && storedResponse != null) {
        response = storedResponse['response'] as Map<String, dynamic>?;
        final timestamp = storedResponse['timestamp'] as String?;
        lastChecked = timestamp == null ? null : DateTime.tryParse(timestamp);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final metrics = HealthUiAdapter.metricsFromResponse(
      response,
      payload: payload,
    );
    final moreData = HealthUiAdapter.moreDataNeeded(response);
    final counts = HealthUiAdapter.statusCounts(metrics, moreData);
    final overallRaw = HealthUiAdapter.overallStatus(metrics);
    final overallStyle = AppStyles.statusStyle(overallRaw);
    final healthScore = HealthUiAdapter.healthScore(metrics, moreData);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const BrandAppBarTitle(title: 'VitalMap'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: _exportSummary,
                ),
              ],
            ),
      body: ResponsivePage(
        child: metrics.isEmpty && response == null
            ? _emptyState()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  _calculatedIndicators(metrics),
                  const SizedBox(height: 24),
                  _personalizedRecommendations(metrics),
                  const SizedBox(height: 24),
                  _tipsForImprovement(metrics),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              Icon(
                Icons.assignment_outlined,
                size: 46,
                color: AppStyles.primary,
              ),
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
    // Compact, balanced hero summary
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppStyles.navy,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppStyles.navy.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Health Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Calculated from available data',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              _heroStatusBadge(status),
            ],
          );
          final stats = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                lastChecked == null
                    ? 'Not checked yet'
                    : _formatDate(lastChecked!),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statItem(calculatedCount.toString(), 'Calculated'),
                  const SizedBox(width: 12),
                  _statItem(moreDataCount.toString(), 'More Data'),
                ],
              ),
            ],
          );
          if (constraints.maxWidth < 680) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: intro),
                    const SizedBox(width: 12),
                    _ScoreRing(score: score),
                  ],
                ),
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerLeft, child: stats),
              ],
            );
          }
          return Row(
            children: [
              intro,
              const Spacer(),
              _ScoreRing(score: score),
              const SizedBox(width: 12),
              stats,
            ],
          );
        },
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            height: 1.2,
          ),
        ),
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
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFD46B25),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Needs Your Attention',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Text(
              'View All',
              style: TextStyle(
                color: AppStyles.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (Responsive.isMobile(context)) {
              return SizedBox(
                height: 116,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: attentionItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) => SizedBox(
                    width: 260,
                    child: _attentionCard(attentionItems[index]),
                  ),
                ),
              );
            }
            final columns = Responsive.isDesktop(context) ? 3 : 2;
            final width =
                (constraints.maxWidth - (12 * (columns - 1))) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final metric in attentionItems)
                  SizedBox(width: width, child: _attentionCard(metric)),
              ],
            );
          },
        ),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        metric.indexName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      _smallStatusBadge(status),
                      Text(
                        '${metric.scoreText} >',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppStyles.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    metric.summary,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppStyles.muted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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

  Widget _organWiseOverview(
    List<HealthMetric> metrics,
    List<Map<String, dynamic>> moreData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Organ-wise Result Cards',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'View All',
              style: TextStyle(
                color: AppStyles.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = Responsive.columns(
              context,
              mobile: 2,
              tablet: 2,
              desktop: 4,
            );
            final width =
                (constraints.maxWidth - (12 * (columns - 1))) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final card in [
                  _organGridCard('Heart', 'AIP', metrics, moreData),
                  _organGridCard('Liver', 'FIB-4', metrics, moreData),
                  _organGridCard('Kidney', 'eGFR', metrics, moreData),
                  _organGridCard('Lungs', 'SpO₂', metrics, moreData),
                  _organGridCard(
                    'Brain / Metabolic',
                    'TyG',
                    metrics,
                    moreData,
                  ),
                  _organGridCard('Inflammation', 'NLR', metrics, moreData),
                  _organGridCard('Pancreas', 'LAR', metrics, moreData),
                  _organGridCard(
                    'Cancer Awareness',
                    'AFP',
                    metrics,
                    moreData,
                  ),
                ])
                  SizedBox(width: width, child: card),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _organGridCard(
    String organName,
    String defaultIndex,
    List<HealthMetric> metrics,
    List<Map<String, dynamic>> moreData,
  ) {
    final organKey = organName.toLowerCase();
    final organMetrics = metrics
        .where((m) => m.organName == organName || m.organKey == organKey)
        .toList();
    HealthStatusStyle statusStyle = AppStyles.moreDataStatus;
    String scoreText = '';
    String label = 'More Data';
    String message = 'Add values to calculate.';
    HealthMetric? matchedMetric;

    if (organMetrics.isNotEmpty) {
      matchedMetric = organMetrics.first;
      statusStyle = AppStyles.statusStyle(matchedMetric.rawStatus);
      scoreText = matchedMetric.scoreText;
      defaultIndex = matchedMetric.indexName;
      label = statusStyle.label;
      message = matchedMetric.summary;
    } else {
      final missingForOrgan = moreData
          .where((m) => m['organ']?.toString().toLowerCase() == organKey)
          .toList();
      if (missingForOrgan.isNotEmpty) {
        message =
            HealthUiAdapter.missingSummaryForOrgan(organName, missingForOrgan);
      }
    }
    final imageSize = Responsive.isDesktop(context) ? 112.0 : 96.0;
    final detailMetric = matchedMetric;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusStyle.background, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppStyles.border),
        boxShadow: [
          BoxShadow(
            color: statusStyle.accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: OrganVisualIcon(organ: organKey, size: imageSize)),
          const SizedBox(height: 12),
          Text(
            organName,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: AppStyles.navy,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            defaultIndex,
            style: const TextStyle(
              fontSize: 12,
              color: AppStyles.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusStyle.badgeBackground,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusStyle.border),
                ),
                child: Text(
                  AppStyles.displayStatusLabel(label),
                  style: TextStyle(
                    color: statusStyle.text,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (scoreText.isNotEmpty)
                Text(
                  'Score $scoreText',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppStyles.navy,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: AppStyles.text,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: detailMetric == null
                  ? null
                  : () {
                      _openDetail(detailMetric);
                    },
              style: TextButton.styleFrom(
                foregroundColor: AppStyles.primary,
                disabledForegroundColor: AppStyles.muted,
                backgroundColor: Colors.white.withValues(alpha: 0.62),
                side: BorderSide(
                  color: detailMetric == null
                      ? AppStyles.border
                      : AppStyles.primary.withValues(alpha: 0.18),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text(
                'View Details',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calculatedIndicators(List<HealthMetric> metrics) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Calculated Indicators',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Tap to view details',
              style: TextStyle(
                color: AppStyles.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppStyles.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < metrics.length; i++) ...[
                _indicatorRow(metrics[i]),
                if (i != metrics.length - 1)
                  const Divider(height: 1, color: AppStyles.border),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _indicatorRow(HealthMetric metric) {
    final status = AppStyles.statusStyle(metric.rawStatus);
    return InkWell(
      onTap: () => _openDetail(metric),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            OrganVisualIcon(organ: metric.organKey, size: 34, iconSize: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.indexName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppStyles.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric.displayName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppStyles.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              metric.unit.isEmpty
                  ? metric.scoreText
                  : '${metric.scoreText} ${metric.unit}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppStyles.navy,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status.badgeBackground,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                AppStyles.displayStatusLabel(status.label),
                style: TextStyle(
                  color: status.text,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppStyles.muted),
          ],
        ),
      ),
    );
  }

  Widget _personalizedRecommendations(List<HealthMetric> metrics) {
    final cards = _recommendationCards(metrics);
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personalized Recommendations',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = Responsive.isDesktop(context) ? 2 : 1;
            final width =
                (constraints.maxWidth - (12 * (columns - 1))) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final card in cards) SizedBox(width: width, child: card),
              ],
            );
          },
        ),
      ],
    );
  }

  List<Widget> _recommendationCards(List<HealthMetric> metrics) {
    final allSources =
        metrics.map((m) => m.source ?? const <String, dynamic>{}).toList();
    final lifestyle = _firstItems(
      allSources,
      ['lifestyle_improvement', 'suggestions'],
      fallback:
          'Keep regular activity, consistent sleep, and stress control based on your profile.',
    );
    final food = _firstItems(
      allSources,
      ['food_recommendations', 'suggestions'],
      fallback:
          'Maintain balanced meals, reduce excess sugar/salt, and limit processed food.',
    );
    final environment = _firstItems(
      allSources,
      ['environment_recommendations'],
      fallback: 'Reduce smoke, dust, and pollution exposure where possible.',
    );
    final follow = _firstText(allSources, 'doctor_followup') ??
        'Discuss persistent abnormal values with a qualified healthcare professional.';
    return [
      _recommendationCard(
        Icons.directions_walk,
        'Lifestyle',
        lifestyle,
        AppStyles.lifestyleContributor,
      ),
      _recommendationCard(
        Icons.restaurant_menu,
        'Food Habits',
        food,
        AppStyles.foodContributor,
      ),
      _recommendationCard(
        Icons.eco_outlined,
        'Environment',
        environment,
        AppStyles.environmentContributor,
      ),
      _recommendationCard(
        Icons.medical_services_outlined,
        'Follow-up',
        follow,
        AppStyles.generalInfo,
      ),
    ];
  }

  String _firstItems(
    List<Map<String, dynamic>> sources,
    List<String> keys, {
    required String fallback,
  }) {
    for (final source in sources) {
      for (final key in keys) {
        final raw = source[key];
        if (raw is List && raw.isNotEmpty) return raw.first.toString();
        if (raw is String && raw.trim().isNotEmpty) return raw;
        final ai = source['ai_recommendation'];
        if (ai is Map) {
          final aiRaw = ai[key];
          if (aiRaw is List && aiRaw.isNotEmpty) return aiRaw.first.toString();
          if (aiRaw is String && aiRaw.trim().isNotEmpty) return aiRaw;
        }
      }
    }
    return fallback;
  }

  String? _firstText(List<Map<String, dynamic>> sources, String key) {
    for (final source in sources) {
      final raw = source[key];
      if (raw is String && raw.trim().isNotEmpty) return raw;
      final ai = source['ai_recommendation'];
      if (ai is Map) {
        final aiRaw = ai[key];
        if (aiRaw is String && aiRaw.trim().isNotEmpty) return aiRaw;
      }
    }
    return null;
  }

  Widget _recommendationCard(
    IconData icon,
    String title,
    String text,
    ContributorStyle style,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: style.accent, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: style.text,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: const TextStyle(
              color: AppStyles.text,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
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
        const Text(
          'More Data Can Improve Insights',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = Responsive.isDesktop(context) ? 2 : 1;
            final width =
                (constraints.maxWidth - (12 * (columns - 1))) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final item in moreData)
                  SizedBox(
                    width: width,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppStyles.moreDataStatus.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppStyles.moreDataStatus.border,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final text = Text(
                            HealthUiAdapter.missingActionText(item),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          );
                          final button = ElevatedButton(
                            onPressed: _openAddMissing,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Text(
                              'Add Data',
                              style: TextStyle(fontSize: 11),
                            ),
                          );
                          if (constraints.maxWidth < 420) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    OrganVisualIcon(
                                      organ: item['organ']?.toString() ?? '',
                                      size: 36,
                                      iconSize: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: text),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(width: double.infinity, child: button),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              OrganVisualIcon(
                                organ: item['organ']?.toString() ?? '',
                                size: 36,
                                iconSize: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: text),
                              const SizedBox(width: 12),
                              button,
                            ],
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _openDetail(HealthMetric metric) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IndexDetailScreen(metric: metric)),
    );
  }

  Widget _tipsForImprovement(List<HealthMetric> metrics) {
    final tips = <String>{};
    for (final metric in metrics) {
      final source = metric.source ?? const <String, dynamic>{};
      for (final key in [
        'suggestions',
        'lifestyle_improvement',
        'food_recommendations',
        'environment_recommendations',
      ]) {
        final raw = source[key];
        if (raw is List) {
          for (final item in raw) {
            final text = item.toString().trim();
            if (text.isNotEmpty) tips.add(text);
          }
        }
      }
    }
    if (tips.isEmpty) {
      tips.addAll([
        'Keep regular physical activity, consistent sleep, and balanced meals.',
        'Track report values over time and review persistent unusual values with a qualified healthcare professional.',
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tips for Improvement',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = Responsive.isDesktop(context) ? 2 : 1;
            final width =
                (constraints.maxWidth - (12 * (columns - 1))) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final tip in tips.take(6))
                  SizedBox(
                    width: width,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppStyles.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppStyles.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(
                                color: AppStyles.text,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _openAddMissing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMissingScreen()),
    );
  }

  Future<void> _exportSummary() async {
    final result = await ExportSummaryService.exportLastSummary();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
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
      'Dec',
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
