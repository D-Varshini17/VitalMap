import 'package:flutter/material.dart';

import '../storage/local_storage.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/disclaimer.dart';
import '../widgets/health_dashboard_widgets.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, this.response, this.lastChecked});

  final Map<String, dynamic>? response;
  final DateTime? lastChecked;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Map<String, dynamic>? response;
  DateTime? lastChecked;

  @override
  void initState() {
    super.initState();
    response = widget.response;
    lastChecked = widget.lastChecked;
    if (response == null) _loadLast();
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
    final stored = await LocalStorage.loadLastResponse();
    if (!mounted || stored == null) return;
    setState(() {
      response = stored['response'] as Map<String, dynamic>?;
      final timestamp = stored['timestamp'] as String?;
      lastChecked = timestamp == null ? null : DateTime.tryParse(timestamp);
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = (response?['calculated_results'] as List<dynamic>?) ?? [];
    final moreNeeded = (response?['more_data_needed'] as List<dynamic>?) ?? [];
    final overallRisk =
        response?['overall_risk']?.toString() ?? 'More Data Needed';
    final resultMaps =
        results.map((item) => Map<String, dynamic>.from(item as Map)).toList();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const BrandAppBarTitle(title: 'Results'),
        ),
        body: response == null
            ? _emptyState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  VitalMapHeroCard(
                    title: 'VitalMap Results',
                    subtitle: 'Screening insight summary',
                    description:
                        'Review calculated indexes, missing data, and personalized guidance.',
                    trailing: _resultsHeroStats(
                      overallRisk,
                      results.length,
                      moreNeeded.length,
                    ),
                  ),
                  OverallInsightCard(
                    overallRisk: overallRisk,
                    calculatedCount: results.length,
                    moreDataCount: moreNeeded.length,
                    lastChecked: lastChecked,
                  ),
                  if (resultMaps.isNotEmpty)
                    _sectionTitle('Calculated Indexes'),
                  for (final result in resultMaps) _resultCard(result),
                  _recommendationCard(resultMaps),
                  if (moreNeeded.isNotEmpty) _moreDataCard(moreNeeded),
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
        const VitalMapHeroCard(
          title: 'VitalMap Results',
          subtitle: 'Screening insight summary',
          description:
              'Complete your inputs to view calculated indexes and guidance.',
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppStyles.softBlueBorder),
          ),
          child: const Column(
            children: [
              Icon(Icons.assignment_outlined,
                  size: 48, color: AppStyles.primary),
              SizedBox(height: 12),
              Text('No screening insight yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text(
                'Complete the input screen to calculate available risk indicators.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppStyles.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resultsHeroStats(
      String overallRisk, int calculatedCount, int moreDataCount) {
    final status = AppStyles.statusStyle(overallRisk);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Overall Status',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          StatusBadge(status: status),
          const SizedBox(height: 8),
          Text(
            '$calculatedCount indicators calculated',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$moreDataCount needing more data',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last checked: ${lastChecked == null ? 'Not checked yet' : _formatDate(lastChecked!)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _resultCard(Map<String, dynamic> result) {
    final risk = result['risk_level']?.toString() ?? 'More Data Needed';
    final status = AppStyles.statusStyle(risk);
    final score = result['score'];
    final values =
        Map<String, dynamic>.from(result['values_used'] as Map? ?? {});

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: status.border),
        boxShadow: [
          BoxShadow(
            color: status.accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          iconColor: status.text,
          collapsedIconColor: status.text,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _softIcon(_organIcon(result['organ']?.toString()),
                      status.accent, status.border),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_titleFor(result),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                          '${result['index_name']} Score: ${score == null ? 'More Data Needed' : score.toString()}',
                          style: TextStyle(
                            color: status.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _shortSummary(result, status),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: status.text,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: status.border),
                  ),
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      color: status.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          children: [
            _valuesBlock(values),
            _textBlock('Detailed Summary', result['summary']?.toString() ?? ''),
            _bulletBlock(
                'Possible Contributors', result['possible_contributors']),
            _bulletBlock('Suggestions', result['suggestions']),
            _bulletBlock(
                'Lifestyle Improvement', result['lifestyle_improvement']),
            _bulletBlock(
                'Food Recommendations', result['food_recommendations']),
            _bulletBlock('Environmental Recommendations',
                result['environment_recommendations']),
            _textBlock('Doctor Follow-up',
                result['doctor_followup']?.toString() ?? ''),
            _textBlock('Disclaimer', result['disclaimer']?.toString() ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _recommendationCard(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return const SizedBox.shrink();
    final primary = _primaryResult(results) ?? results.first;
    final rec =
        Map<String, dynamic>.from(primary['ai_recommendation'] as Map? ?? {});
    if (rec.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF7FF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppStyles.softBlueBorder),
        boxShadow: [
          BoxShadow(
            color: AppStyles.primary.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _softIcon(Icons.auto_awesome_outlined, AppStyles.primary,
                  AppStyles.softBlueBorder),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Personalized Recommendation',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              _guidanceChip(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _friendlyStatusText(rec['simple_summary']?.toString() ?? ''),
            style: const TextStyle(color: AppStyles.text, height: 1.35),
          ),
          _compactList('Possible contributors', rec['possible_contributors']),
          _compactList(
              'Lifestyle suggestions', rec['lifestyle_recommendations']),
          _compactList('Food suggestions', rec['food_recommendations']),
          _compactList(
              'Environment suggestions', rec['environment_recommendations']),
          _textBlock(
              'Doctor Follow-up', rec['doctor_followup']?.toString() ?? ''),
        ],
      ),
    );
  }

  Widget _guidanceChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppStyles.softBlue,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppStyles.softBlueBorder),
      ),
      child: const Text(
        'Guidance',
        style: TextStyle(
          color: AppStyles.softBlueText,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _moreDataCard(List<dynamic> items) {
    const status = AppStyles.moreDataStatus;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: status.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _softIcon(Icons.add_chart_outlined, status.accent, status.border),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('More Data Can Improve Insights',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'These optional values can unlock more organ-wise screening indicators.',
            style: TextStyle(color: AppStyles.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in items.take(10))
                _missingDataChip(Map<String, dynamic>.from(item as Map)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _missingDataChip(Map<String, dynamic> item) {
    final missing = (item['missing_inputs'] as List<dynamic>? ?? [])
        .map((value) => _cleanKey(value.toString()))
        .join(', ');
    final indexName = item['index_name']?.toString() ?? 'Insight';
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppStyles.moreDataStatus.border),
      ),
      child: Text(
        '$indexName needs ${missing.isEmpty ? 'more values' : missing}',
        style: const TextStyle(
          color: AppStyles.text,
          fontWeight: FontWeight.w700,
          height: 1.25,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _textBlock(String title, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(_friendlyStatusText(text),
              style: const TextStyle(color: AppStyles.text, height: 1.35)),
        ],
      ),
    );
  }

  Widget _bulletBlock(String title, dynamic items) {
    final list = (items as List<dynamic>?)
            ?.map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList() ??
        [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (final item in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- ', style: TextStyle(color: AppStyles.primary)),
                  Expanded(
                    child: Text(item,
                        style: const TextStyle(
                            color: AppStyles.text, height: 1.3)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _valuesBlock(Map<String, dynamic> values) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Values Used',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in values.entries)
                Chip(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppStyles.border),
                  label: Text('${_cleanKey(entry.key)}: ${entry.value}'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactList(String title, dynamic items) {
    final list = (items as List<dynamic>?)
            ?.map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .take(4)
            .toList() ??
        [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text('$title: ${list.join('; ')}',
          style: const TextStyle(color: AppStyles.muted, height: 1.3)),
    );
  }

  Map<String, dynamic>? _primaryResult(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return null;
    Map<String, dynamic>? topResult;
    var topRank = -1;
    for (final result in results) {
      final rank = AppStyles.statusRank(result['risk_level']?.toString());
      if (rank > topRank) {
        topRank = rank;
        topResult = result;
      }
    }
    return topResult;
  }

  Widget _softIcon(IconData icon, Color color, Color borderColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  String _titleFor(Map<String, dynamic> result) {
    final organ = result['organ']?.toString() ?? 'Health';
    if (organ == 'Heart') return 'Heart Health';
    if (organ == 'Diabetes / Metabolic') return 'Metabolic Health';
    if (organ == 'Cancer Awareness') return 'Cancer Awareness';
    return '$organ Health';
  }

  IconData _organIcon(String? organ) {
    switch (organ) {
      case 'Heart':
        return Icons.favorite_border;
      case 'Diabetes / Metabolic':
        return Icons.local_fire_department_outlined;
      case 'Liver':
        return Icons.science_outlined;
      case 'Kidney':
        return Icons.water_drop_outlined;
      case 'Lung':
        return Icons.air_outlined;
      case 'Inflammation':
        return Icons.bloodtype_outlined;
      case 'Pancreas':
        return Icons.biotech_outlined;
      case 'Cancer Awareness':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.monitor_heart_outlined;
    }
  }

  String _shortSummary(Map<String, dynamic> result, HealthStatusStyle status) {
    final subject =
        _indicatorSubject(result['index_name']?.toString() ?? '', result);
    if (status.label == AppStyles.attentionStatus.label) {
      return '$subject needs clinical review if values persist.';
    }
    if (status.label == AppStyles.monitorStatus.label) {
      return '$subject should be monitored and reviewed over time.';
    }
    if (status.label == AppStyles.lowConcernStatus.label) {
      return '$subject appears within a low concern range.';
    }
    return 'More report values are needed for this screening insight.';
  }

  String _indicatorSubject(String indexName, Map<String, dynamic> result) {
    switch (indexName) {
      case 'AIP':
        return 'Lipid-related screening indicator';
      case 'TyG':
      case 'Metabolic screening insight':
        return 'Metabolic screening indicator';
      case 'APRI':
      case 'FIB-4':
      case 'FLI':
      case 'NAFLD Fibrosis Score':
        return 'Liver screening indicator';
      case 'eGFR':
        return 'Kidney filtration estimate';
      case 'SpO2':
        return 'Oxygen saturation indicator';
      case 'NLR':
        return 'Inflammation marker';
      case 'LAR':
        return 'Pancreatic enzyme ratio';
      case 'AFP':
      case 'CA 15-3':
      case 'CA 27.29':
        return 'Cancer awareness marker';
      default:
        return '${result['organ'] ?? 'Health'} screening indicator';
    }
  }

  String _friendlyStatusText(String text) {
    return text.replaceAllMapped(
      RegExp(r'(current )?risk indicator is ([^.\n]+)', caseSensitive: false),
      (match) =>
          'screening status is ${AppStyles.statusLabel(match.group(2)).toLowerCase()}',
    );
  }

  String _cleanKey(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAll('mg/dL', 'mg/dL')
        .replaceAll('%', '')
        .replaceAll('or', 'or');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
