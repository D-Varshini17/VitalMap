import 'package:flutter/material.dart';

import '../storage/local_storage.dart';
import '../styles.dart';
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
          title: const Row(
            children: [
              Icon(Icons.insights, color: AppStyles.primary),
              SizedBox(width: 8),
              Text('Results'),
            ],
          ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overall Screening Insight',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 10),
            Row(
              children: [
                _riskPill(overallRisk, _colorForRisk(overallRisk)),
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
    final color = _colorForName(result['color']?.toString(), risk);
    final values =
        Map<String, dynamic>.from(result['values_used'] as Map? ?? {});
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                _riskPill(risk, color),
              ],
            ),
            const SizedBox(height: 14),
            _scoreRow(result),
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

  Widget _scoreRow(Map<String, dynamic> result) {
    final score = result['score'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAFBFD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppStyles.border),
      ),
      child: Text(
        '${result['index_name']} Score: ${score == null ? 'More Data Needed' : score.toString()}',
        style:
            const TextStyle(fontWeight: FontWeight.w700, color: AppStyles.text),
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
          Text(text,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.grey),
                SizedBox(width: 8),
                Text('More Data Needed',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.spa_outlined, color: AppStyles.primary),
                SizedBox(width: 8),
                Text('General Health Pattern',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 10),
            if (pattern.isEmpty)
              const Text('No major contributor pattern highlighted.',
                  style: TextStyle(color: AppStyles.muted))
            else
              for (final item in pattern)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('- ',
                          style: TextStyle(color: AppStyles.primary)),
                      Expanded(
                          child: Text(item.toString(),
                              style: const TextStyle(color: AppStyles.text))),
                    ],
                  ),
                ),
            const SizedBox(height: 8),
            const Text('These factors may contribute to risk indicators.',
                style: TextStyle(color: AppStyles.muted)),
          ],
        ),
      ),
    );
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
          gradient: const LinearGradient(
            colors: [Color(0xFFEAFBFD), Color(0xFFFFFFFF)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppStyles.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Recommendation Summary',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(rec['simple_summary']?.toString() ?? '',
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

  Widget _riskPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  String _titleFor(Map<String, dynamic> result) {
    final organ = result['organ']?.toString() ?? 'Health';
    if (organ == 'Heart') return 'Heart Health Screening Insight';
    if (organ == 'Diabetes / Metabolic') return 'Metabolic Screening Insight';
    if (organ == 'Cancer Awareness') return 'Cancer Awareness Indicator';
    return '$organ Screening Insight';
  }

  Color _colorForRisk(String risk) {
    if (risk.startsWith('High')) return const Color(0xFFE34B4B);
    if (risk.startsWith('Moderate')) return const Color(0xFFE5A400);
    if (risk.startsWith('Low')) return const Color(0xFF2E9D64);
    return Colors.grey;
  }

  Color _colorForName(String? name, String risk) {
    switch (name) {
      case 'green':
        return const Color(0xFF2E9D64);
      case 'yellow':
        return const Color(0xFFE5A400);
      case 'red':
        return const Color(0xFFE34B4B);
      default:
        return _colorForRisk(risk);
    }
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
