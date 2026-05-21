import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../storage/local_storage.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
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
          title: const BrandAppBarTitle(title: 'Dashboard'),
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
    final groups = _patternGroups(pattern);
    final counts = _contributorCounts();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.spa_outlined, color: AppStyles.primary),
              SizedBox(width: 8),
              Text('General Health Pattern',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                      child: _contributorCard(
                        title,
                        groups[title] ?? const <String>[],
                        counts[title] ?? 0,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'These factors may contribute to risk indicators.',
            style: TextStyle(color: AppStyles.muted),
          ),
        ],
      ),
    );
  }

  Widget _contributorCard(String title, List<String> items, int count) {
    final style = AppStyles.contributorStyle(title);
    final displayCount = count > items.length ? count : items.length;
    final badgeText = displayCount == 0
        ? 'No major items'
        : displayCount == 1
            ? '1 item noted'
            : '$displayCount items noted';
    return Container(
      constraints: const BoxConstraints(minHeight: 154),
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
            for (final item in items.take(2))
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

  Widget _organCard(String organ, List<Map<String, dynamic>> organResults) {
    final rawStatus = _highestRisk(organResults);
    final status = AppStyles.statusStyle(rawStatus);
    final primaryResult = _primaryResult(organResults);
    final indexName =
        primaryResult?['index_name']?.toString() ?? 'More Data Needed';
    final score = primaryResult?['score'];
    final scoreText = score == null ? 'More Data Needed' : score.toString();
    final explanation = _organExplanation(organ, primaryResult, status);

    return Container(
      constraints: const BoxConstraints(minHeight: 248),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _organIconBox(organ, status),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(organ,
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: status.text))),
            ],
          ),
          const SizedBox(height: 10),
          _riskPill(status),
          const SizedBox(height: 12),
          _metricLine('Index', indexName, status),
          const SizedBox(height: 6),
          _metricLine('Score', scoreText, status),
          const SizedBox(height: 8),
          Text(explanation,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: status.text, height: 1.3, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
              'Last checked: ${lastChecked == null ? '-' : _formatDate(lastChecked!)}',
              style: const TextStyle(color: AppStyles.muted, fontSize: 12)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: organResults.isEmpty ? null : widget.onViewResults,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('View details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: status.text,
                side: BorderSide(color: status.border),
              ),
            ),
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
    return _primaryResult(results)?['risk_level']?.toString() ??
        'More Data Needed';
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

  Widget _organIconBox(String organ, HealthStatusStyle status) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.border),
      ),
      child: Icon(_organIcon(organ), color: status.accent, size: 21),
    );
  }

  Widget _metricLine(String label, String value, HealthStatusStyle status) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(color: status.text, fontSize: 12, height: 1.2),
        children: [
          TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: value),
        ],
      ),
    );
  }

  IconData _organIcon(String organ) {
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

  String _organExplanation(
      String organ, Map<String, dynamic>? result, HealthStatusStyle status) {
    if (result == null) return _missingDataExplanation(organ);
    final subject =
        _indicatorSubject(result['index_name']?.toString() ?? '', organ);
    if (status.label == AppStyles.attentionStatus.label) {
      return '$subject needs clinical review if values persist.';
    }
    if (status.label == AppStyles.monitorStatus.label) {
      return '$subject should be monitored over time.';
    }
    if (status.label == AppStyles.lowConcernStatus.label) {
      return '$subject looks reassuring based on available values.';
    }
    return _missingDataExplanation(organ);
  }

  String _indicatorSubject(String indexName, String organ) {
    switch (indexName) {
      case 'AIP':
        return 'Lipid-related risk indicator';
      case 'TyG':
      case 'Metabolic screening insight':
        return 'Glucose-related metabolic indicator';
      case 'APRI':
      case 'FIB-4':
      case 'NAFLD Fibrosis Score':
        return 'Liver fibrosis-related risk indicator';
      case 'FLI':
        return 'Fatty liver-related risk indicator';
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
        return '$organ screening indicator';
    }
  }

  String _missingDataExplanation(String organ) {
    switch (organ) {
      case 'Heart':
        return 'Triglycerides and HDL are needed to calculate the lipid indicator.';
      case 'Diabetes / Metabolic':
        return 'Glucose values are needed to estimate the metabolic pattern.';
      case 'Liver':
        return 'AST, ALT, platelets, and related values help estimate liver indicators.';
      case 'Kidney':
        return 'Creatinine is needed to estimate kidney filtration.';
      case 'Lung':
        return 'SpO2 is needed to review the oxygen screening indicator.';
      case 'Inflammation':
        return 'Neutrophils and lymphocytes are needed for this marker.';
      case 'Pancreas':
        return 'Lipase and amylase are needed for this enzyme ratio.';
      case 'Cancer Awareness':
        return 'Tumor marker values are needed for awareness indicators.';
      default:
        return 'More report values are needed for this screening insight.';
    }
  }

  Map<String, int> _contributorCounts() {
    final general =
        Map<String, dynamic>.from(lastPayload?['general_health'] as Map? ?? {});
    return {
      'Lifestyle': _flagCount([
        general['smoking'] == 'Yes',
        general['alcohol'] == 'Frequent',
        general['physical_activity'] == 'Low',
        general['sleep_duration'] == '<5 hrs',
        general['stress_level'] == 'High',
      ]),
      'Food Habits': _flagCount([
        general['high_sugar_intake'] == 'High',
        general['high_salt_intake'] == 'High',
        general['fried_processed_food'] == 'Frequent',
        general['fruit_veg_intake'] == 'Low',
        general['sugary_drinks'] == 'Frequently',
      ]),
      'Environment': _flagCount([
        general['air_pollution'] == 'High',
        general['occupational_exposure'] == 'Yes',
        general['passive_smoking'] == 'Yes',
        general['cooking_smoke'] == 'Yes',
        general['cooking_fuel_smoke'] == 'Yes',
      ]),
    };
  }

  int _flagCount(List<bool> flags) {
    return flags.where((flag) => flag).length;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
