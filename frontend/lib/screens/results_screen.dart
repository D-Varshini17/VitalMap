import 'package:flutter/material.dart';

import '../storage/local_storage.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/disclaimer.dart';

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
    final pattern =
        (response?['general_health_pattern'] as List<dynamic>?) ?? [];
    final overallRisk =
        response?['overall_risk'] as String? ?? 'More Data Needed';

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
                  _summaryCard(overallRisk, results.length),
                  for (final item in results)
                    _resultCard(Map<String, dynamic>.from(item as Map)),
                  if (moreNeeded.isNotEmpty) _moreDataCard(moreNeeded),
                  _generalPatternCard(pattern),
                  const DisclaimerWidget(),
                ],
              ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.assignment_outlined, size: 48, color: AppStyles.primary),
            SizedBox(height: 12),
            Text('No screening insight yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text(
              'Complete the input screen to calculate available risk indicators.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppStyles.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String overallRisk, int count) {
    final status = AppStyles.statusStyle(overallRisk);
    return Card(
      color: AppStyles.softBlue,
      shape: _softCardShape(AppStyles.softBlueBorder),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _softIcon(Icons.insights_outlined, AppStyles.primary,
                    AppStyles.softBlueBorder),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Overall Screening Insight',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _riskPill(status),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$count calculated risk indicator${count == 1 ? '' : 's'}',
                    style: const TextStyle(color: AppStyles.muted),
                  ),
                ),
              ],
            ),
            if (lastChecked != null) ...[
              const SizedBox(height: 8),
              Text('Last checked: ${_formatDate(lastChecked!)}',
                  style: const TextStyle(color: AppStyles.muted)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultCard(Map<String, dynamic> result) {
    final risk = result['risk_level']?.toString() ?? 'More Data Needed';
    final status = AppStyles.statusStyle(risk);
    final values =
        Map<String, dynamic>.from(result['values_used'] as Map? ?? {});
    return Card(
      color: status.background,
      shape: _softCardShape(status.border),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('${result['index_name']} - ${result['organ']}',
                          style: const TextStyle(color: AppStyles.muted)),
                    ],
                  ),
                ),
                _riskPill(status),
              ],
            ),
            const SizedBox(height: 14),
            _scoreRow(result, status),
            _textBlock(
                'Formula Used', result['formula_used']?.toString() ?? ''),
            _textBlock('Detailed Summary', result['summary']?.toString() ?? ''),
            _bulletBlock(
                'Possible Contributors', result['possible_contributors']),
            _bulletBlock('Suggestions', result['suggestions']),
            _bulletBlock(
                'Lifestyle Improvement', result['lifestyle_improvement']),
            _bulletBlock('Food Habit Advice', result['food_recommendations']),
            _bulletBlock(
                'Environmental Advice', result['environment_recommendations']),
            _aiRecommendationBlock(result['ai_recommendation']),
            _textBlock('Doctor Follow-up',
                result['doctor_followup']?.toString() ?? ''),
            _valuesBlock(values),
            _textBlock('Disclaimer', result['disclaimer']?.toString() ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _scoreRow(Map<String, dynamic> result, HealthStatusStyle status) {
    final score = result['score'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.border),
      ),
      child: Text(
        '${result['index_name']} Score: ${score == null ? 'More Data Needed' : score.toString()}',
        style: TextStyle(fontWeight: FontWeight.w700, color: status.text),
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
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
                              color: AppStyles.text, height: 1.3))),
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
              style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _moreDataCard(List<dynamic> items) {
    const status = AppStyles.moreDataStatus;
    return Card(
      color: status.background,
      shape: _softCardShape(status.border),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _softIcon(status.icon, status.accent, status.border),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('More Data Needed',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'More data can improve this screening insight.',
              style: TextStyle(color: AppStyles.muted),
            ),
            const SizedBox(height: 10),
            for (final item in items.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${(item as Map)['index_name']}: ${item['message']}',
                  style: const TextStyle(color: AppStyles.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _generalPatternCard(List<dynamic> pattern) {
    final groups = _patternGroups(pattern);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.spa_outlined, color: AppStyles.primary),
              SizedBox(width: 8),
              Text('General Health Pattern',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 700 ? 3 : 1;
              final width =
                  (constraints.maxWidth - (12 * (columns - 1))) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final title in const [
                    'Lifestyle',
                    'Food Habits',
                    'Environment'
                  ])
                    SizedBox(
                      width: width,
                      child: _contributorCard(title, groups[title] ?? const []),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          const Text('These factors may contribute to risk indicators.',
              style: TextStyle(color: AppStyles.muted)),
        ],
      ),
    );
  }

  Widget _contributorCard(String title, List<String> items) {
    final style = AppStyles.contributorStyle(title);
    final badgeText = items.isEmpty
        ? 'No major items'
        : items.length == 1
            ? '1 item noted'
            : '${items.length} items noted';
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(style.icon, color: style.accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: style.text, fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 10),
          _softBadge(badgeText, style.badgeBackground, style.text),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text('No major pattern highlighted.',
                style: TextStyle(color: style.text, height: 1.3))
          else
            for (final item in items.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(item,
                    style: TextStyle(color: style.text, height: 1.3)),
              ),
        ],
      ),
    );
  }

  Map<String, List<String>> _patternGroups(List<dynamic> pattern) {
    final groups = <String, List<String>>{
      'Lifestyle': [],
      'Food Habits': [],
      'Environment': [],
    };
    for (final item in pattern) {
      final text = item.toString();
      groups[_categoryForPattern(text)]!.add(text);
    }
    return groups;
  }

  String _categoryForPattern(String text) {
    final value = text.toLowerCase();
    if (value.contains('pollution') ||
        value.contains('occupational') ||
        value.contains('dust') ||
        value.contains('chemical') ||
        value.contains('passive') ||
        value.contains('cooking') ||
        value.contains('fuel smoke')) {
      return 'Environment';
    }
    if (value.contains('sugar') ||
        value.contains('salt') ||
        value.contains('fried') ||
        value.contains('processed') ||
        value.contains('fruit') ||
        value.contains('vegetable') ||
        value.contains('food') ||
        value.contains('drink')) {
      return 'Food Habits';
    }
    return 'Lifestyle';
  }

  Widget _aiRecommendationBlock(dynamic aiRecommendation) {
    final rec = Map<String, dynamic>.from(aiRecommendation as Map? ?? {});
    if (rec.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppStyles.softBlue,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppStyles.softBlueBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Recommendation Summary',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(_friendlyStatusText(rec['simple_summary']?.toString() ?? ''),
                style: const TextStyle(color: AppStyles.text, height: 1.35)),
            _compactList('Lifestyle', rec['lifestyle_recommendations']),
            _compactList('Food', rec['food_recommendations']),
            _compactList('Environment', rec['environment_recommendations']),
          ],
        ),
      ),
    );
  }

  Widget _compactList(String title, dynamic items) {
    final list = (items as List<dynamic>?)
            ?.map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .take(3)
            .toList() ??
        [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text('$title: ${list.join('; ')}',
          style: const TextStyle(color: AppStyles.muted, height: 1.3)),
    );
  }

  Widget _riskPill(HealthStatusStyle status) {
    return _softBadge(status.label, status.badgeBackground, status.text);
  }

  Widget _softBadge(String label, Color background, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _softIcon(IconData icon, Color color, Color borderColor) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  ShapeBorder _softCardShape(Color borderColor) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: borderColor),
    );
  }

  String _titleFor(Map<String, dynamic> result) {
    final organ = result['organ']?.toString() ?? 'Health';
    if (organ == 'Heart') return 'Heart Health Screening Insight';
    if (organ == 'Diabetes / Metabolic') return 'Metabolic Screening Insight';
    if (organ == 'Cancer Awareness') return 'Cancer Awareness Indicator';
    return '$organ Screening Insight';
  }

  IconData _organIcon(String? organ) {
    switch (organ) {
      case 'Heart':
        return Icons.favorite_border;
      case 'Diabetes / Metabolic':
        return Icons.bloodtype_outlined;
      case 'Liver':
        return Icons.science_outlined;
      case 'Kidney':
        return Icons.water_drop_outlined;
      case 'Lung':
        return Icons.air_outlined;
      case 'Inflammation':
        return Icons.healing_outlined;
      case 'Pancreas':
        return Icons.biotech_outlined;
      case 'Cancer Awareness':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.monitor_heart_outlined;
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
        .replaceAll('%', '');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
