import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../storage/local_storage.dart';
import '../styles.dart';
import '../widgets/disclaimer.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({
    super.key,
    this.response,
    this.lastChecked,
    required this.onViewResults,
    required this.onRecalculated,
  });

  final Map<String, dynamic>? response;
  final DateTime? lastChecked;
  final VoidCallback onViewResults;
  final ValueChanged<Map<String, dynamic>> onRecalculated;

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  Map<String, dynamic>? response;
  Map<String, dynamic>? lastPayload;
  DateTime? lastChecked;
  bool recalculating = false;

  static const organs = [
    'Heart',
    'Diabetes / Metabolic',
    'Liver',
    'Kidney',
    'Lung',
    'Inflammation',
    'Pancreas',
    'Cancer Awareness',
  ];

  @override
  void initState() {
    super.initState();
    response = widget.response;
    lastChecked = widget.lastChecked;
    _loadStored();
  }

  @override
  void didUpdateWidget(covariant OverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.response != oldWidget.response ||
        widget.lastChecked != oldWidget.lastChecked) {
      response = widget.response;
      lastChecked = widget.lastChecked;
    }
  }

  Future<void> _loadStored() async {
    final storedResponse = await LocalStorage.loadLastResponse();
    final storedPayload = await LocalStorage.loadLastPayload();
    if (!mounted) return;
    setState(() {
      lastPayload = storedPayload;
      if (response == null && storedResponse != null) {
        response = storedResponse['response'] as Map<String, dynamic>?;
        final timestamp = storedResponse['timestamp'] as String?;
        lastChecked = timestamp == null ? null : DateTime.tryParse(timestamp);
      }
    });
  }

  Future<void> _recalculate() async {
    if (lastPayload == null || recalculating) return;
    setState(() => recalculating = true);
    final updated = await ApiService.analyze(lastPayload!);
    if (!mounted) return;
    setState(() => recalculating = false);
    if (updated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Unable to recalculate right now. Please try again.')),
      );
      return;
    }
    await LocalStorage.saveLastResponse(updated);
    setState(() {
      response = updated;
      lastChecked = DateTime.now();
    });
    widget.onRecalculated(updated);
  }

  @override
  Widget build(BuildContext context) {
    final results = (response?['calculated_results'] as List<dynamic>?) ?? [];
    final pattern =
        (response?['general_health_pattern'] as List<dynamic>?) ?? [];

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.grid_view, color: AppStyles.primary),
              SizedBox(width: 8),
              Text('Overview'),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _generalPatternCard(pattern),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 760
                    ? 4
                    : constraints.maxWidth > 520
                        ? 3
                        : 2;
                final width =
                    (constraints.maxWidth - (12 * (columns - 1))) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final organ in organs)
                      SizedBox(
                        width: width,
                        child:
                            _organCard(organ, _resultsForOrgan(results, organ)),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const DisclaimerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _generalPatternCard(List<dynamic> pattern) {
    final levels = _contributorLevels();
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
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            for (final entry in levels.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _patternBar(entry.key, entry.value),
              ),
            if (pattern.isEmpty)
              const Text('More Data Needed',
                  style: TextStyle(color: AppStyles.muted))
            else
              for (final item in pattern.take(6))
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
            const Text(
              'These factors may contribute to risk indicators.',
              style: TextStyle(color: AppStyles.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _organCard(String organ, List<Map<String, dynamic>> organResults) {
    final status = _highestRisk(organResults);
    final color = _colorForRisk(status);
    final indexNames = organResults
        .map((result) => result['index_name'].toString())
        .join(', ');
    final lastScore = organResults.isEmpty
        ? 'More Data Needed'
        : (organResults.first['score']?.toString() ?? 'More Data Needed');

    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppStyles.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(organ,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: AppStyles.text))),
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 10),
          _riskPill(status, color),
          const SizedBox(height: 10),
          Text(
            organResults.isEmpty
                ? 'Calculated indexes: More Data Needed'
                : 'Calculated indexes: $indexNames',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppStyles.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text('Last score: $lastScore',
              style: const TextStyle(color: AppStyles.muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
              'Last checked: ${lastChecked == null ? '-' : _formatDate(lastChecked!)}',
              style: const TextStyle(color: AppStyles.muted, fontSize: 12)),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: organResults.isEmpty ? null : widget.onViewResults,
                  child: const Text('View result'),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed:
                  lastPayload == null || recalculating ? null : _recalculate,
              icon: recalculating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh, size: 18),
              label: const Text('Recalculate'),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _resultsForOrgan(
      List<dynamic> results, String organ) {
    return results
        .where((result) => (result as Map)['organ'] == organ)
        .map((result) => Map<String, dynamic>.from(result as Map))
        .toList();
  }

  String _highestRisk(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return 'More Data Needed';
    if (results.any((result) =>
        (result['risk_level']?.toString() ?? '').startsWith('High'))) {
      return 'High';
    }
    if (results.any((result) =>
        (result['risk_level']?.toString() ?? '').startsWith('Moderate'))) {
      return 'Moderate';
    }
    if (results.any((result) =>
        (result['risk_level']?.toString() ?? '').startsWith('Low'))) {
      return 'Low';
    }
    return 'More Data Needed';
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

  Color _colorForRisk(String risk) {
    if (risk.startsWith('High')) return const Color(0xFFE34B4B);
    if (risk.startsWith('Moderate')) return const Color(0xFFE5A400);
    if (risk.startsWith('Low')) return const Color(0xFF2E9D64);
    return Colors.grey;
  }

  Widget _patternBar(String title, String level) {
    final color = _colorForRisk(level);
    final widthFactor = level == 'High'
        ? 1.0
        : level == 'Moderate'
            ? 0.66
            : 0.34;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text('$title: $level contributor',
                    style: const TextStyle(
                        color: AppStyles.text, fontWeight: FontWeight.w700))),
            const Text('May contribute to risk indicators.',
                style: TextStyle(color: AppStyles.muted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: widthFactor,
            minHeight: 8,
            backgroundColor: const Color(0xFFEAFBFD),
            color: color,
          ),
        ),
      ],
    );
  }

  Map<String, String> _contributorLevels() {
    final general =
        Map<String, dynamic>.from(lastPayload?['general_health'] as Map? ?? {});
    return {
      'Lifestyle': _levelFor([
        general['smoking'] == 'Yes',
        general['alcohol'] == 'Frequent',
        general['physical_activity'] == 'Low',
        general['sleep_duration'] == '<5 hrs',
        general['stress_level'] == 'High',
      ]),
      'Food habits': _levelFor([
        general['high_sugar_intake'] == 'High',
        general['high_salt_intake'] == 'High',
        general['fried_processed_food'] == 'Frequent',
        general['fruit_veg_intake'] == 'Low',
        general['sugary_drinks'] == 'Frequently',
      ]),
      'Environment': _levelFor([
        general['air_pollution'] == 'High',
        general['occupational_exposure'] == 'Yes',
        general['passive_smoking'] == 'Yes',
        general['cooking_smoke'] == 'Yes',
        general['cooking_fuel_smoke'] == 'Yes',
      ]),
    };
  }

  String _levelFor(List<bool> flags) {
    final count = flags.where((flag) => flag).length;
    if (count >= 3) return 'High';
    if (count >= 1) return 'Moderate';
    return 'Low';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
