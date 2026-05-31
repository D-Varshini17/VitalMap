import 'package:flutter/material.dart';

import '../core/ui_result_adapter.dart';
import '../services/api_service.dart';
import '../storage/local_storage.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/disclaimer.dart';
import '../widgets/health_dashboard_widgets.dart';
import '../widgets/organ_visual.dart';
import 'organ_detail_screen.dart';
import 'add_missing_screen.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({
    super.key,
    this.response,
    this.lastChecked,
    required this.onStartAnalysis,
    required this.onViewResults,
    required this.onRecalculated,
  });

  final Map<String, dynamic>? response;
  final DateTime? lastChecked;
  final VoidCallback onStartAnalysis;
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

  static const _organs = [
    _OrganConfig(
      key: 'Heart',
      name: 'Heart',
      background: Color(0xFFFFF0F5),
      accent: Color(0xFFD970A0),
    ),
    _OrganConfig(
      key: 'Liver',
      name: 'Liver',
      background: Color(0xFFFFF7E7),
      accent: Color(0xFFD99D41),
    ),
    _OrganConfig(
      key: 'Kidney',
      name: 'Kidney',
      background: Color(0xFFF5EEFF),
      accent: Color(0xFFA675D6),
    ),
    _OrganConfig(
      key: 'Lung',
      name: 'Lungs',
      background: Color(0xFFEAFBFD),
      accent: Color(0xFF49B6C8),
    ),
    _OrganConfig(
      key: 'Diabetes / Metabolic',
      name: 'Brain / Metabolic',
      background: Color(0xFFFFF2E8),
      accent: Color(0xFFE49A52),
    ),
    _OrganConfig(
      key: 'Inflammation',
      name: 'Inflammation',
      background: Color(0xFFF5F3FA),
      accent: Color(0xFF9C89CD),
    ),
    _OrganConfig(
      key: 'Pancreas',
      name: 'Pancreas',
      background: Color(0xFFFFFAE8),
      accent: Color(0xFFD8A92F),
    ),
    _OrganConfig(
      key: 'Cancer Awareness',
      name: 'Cancer Awareness',
      background: Color(0xFFEAF7FF),
      accent: Color(0xFF4BAFE3),
    ),
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
          content: Text('Unable to recalculate right now. Please try again.'),
        ),
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
    final moreNeeded = (response?['more_data_needed'] as List<dynamic>?) ?? [];
    final pattern =
        (response?['general_health_pattern'] as List<dynamic>?) ?? [];
    final completion = HealthUiAdapter.completionPercent(lastPayload);
    final completedValues = HealthUiAdapter.completedValueCount(lastPayload);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const BrandAppBarTitle(title: 'Overview'),
          actions: [
            IconButton(
              tooltip: 'Refresh overview',
              onPressed:
                  lastPayload == null || recalculating ? null : _recalculate,
              icon: recalculating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            VitalMapHeroCard(
              title: 'Organ Health Snapshot',
              subtitle: 'Track. Understand. Improve.',
              description: '',
              trailing: _completionHeroCard(completion, completedValues),
            ),
            if (results.isEmpty) _emptyInsightCard(),
            _sectionHeader('Organ Insight Grid', 'View All'),
            _organGrid(results, moreNeeded),
            _needMoreDataCard(moreNeeded),
            _generalHealthPatternSection(pattern),
            const SizedBox(height: 16),
            const DisclaimerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _completionHeroCard(int completion, int completedValues) {
    return Container(
      width: 188,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Completion',
            style: TextStyle(
              color: AppStyles.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$completion%',
            style: const TextStyle(
              color: AppStyles.primary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Data completeness',
            style: TextStyle(color: AppStyles.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: completion / 100,
              backgroundColor: AppStyles.border,
              color: AppStyles.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedValues / ${HealthUiAdapter.totalExpectedValues} values',
            style: const TextStyle(
              color: AppStyles.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            lastChecked == null
                ? 'Not checked yet'
                : 'Updated ${_formatDate(lastChecked!)}',
            style: const TextStyle(color: AppStyles.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _emptyInsightCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppStyles.softBlueBorder),
        boxShadow: [
          BoxShadow(
            color: AppStyles.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final copy = const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No screening insights yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 6),
              Text(
                'Complete general questions and add any available report values to generate organ-wise insights.',
                style: TextStyle(color: AppStyles.muted, height: 1.35),
              ),
            ],
          );
          final action = SizedBox(
            width: constraints.maxWidth < 520 ? double.infinity : null,
            child: GradientActionButton(
              onPressed: widget.onStartAnalysis,
              label: 'Start Analysis',
              icon: Icons.edit_note,
            ),
          );
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 12), action],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 14),
              action,
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
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
      ),
    );
  }

  Widget _organGrid(List<dynamic> results, List<dynamic> moreNeeded) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 980
            ? 4
            : constraints.maxWidth > 640
                ? 3
                : 2;
        final width = (constraints.maxWidth - (12 * (columns - 1))) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final organ in _organs)
              SizedBox(
                width: width,
                child: _organCard(
                  organ,
                  _resultsForOrgan(results, organ.key),
                  _moreNeededForOrgan(moreNeeded, organ.key),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _organCard(
    _OrganConfig organ,
    List<Map<String, dynamic>> organResults,
    List<Map<String, dynamic>> moreNeeded,
  ) {
    final primaryResult = _primaryResult(organResults);
    final rawStatus =
        primaryResult?['risk_level']?.toString() ?? 'More Data Needed';
    final status = AppStyles.statusStyle(rawStatus);
    final indexes = organResults
        .map((result) => result['index_name']?.toString() ?? '')
        .where((text) => text.isNotEmpty)
        .toList();
    final score = primaryResult?['score'];
    final scoreText = score == null
        ? 'More Data Needed'
        : '${primaryResult?['index_name']} $score';
    final message = primaryResult == null
        ? _missingDataExplanation(organ.key, moreNeeded)
        : _organExplanation(organ.key, primaryResult, status);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: organResults.isEmpty
          ? widget.onStartAnalysis
          : () => _openOrganDetails(organ.key, organ.name),
      child: Container(
        constraints: const BoxConstraints(minHeight: 154),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppStyles.border),
          boxShadow: [
            BoxShadow(
              color: organ.accent.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrganVisualIcon(organ: organ.key, size: 52),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    organ.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppStyles.text,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppStyles.primary),
              ],
            ),
            const SizedBox(height: 10),
            StatusBadge(status: status),
            const SizedBox(height: 8),
            Text(
              indexes.isEmpty ? scoreText : scoreText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppStyles.text,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppStyles.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _openOrganDetails(String organKey, String organName) {
    final metrics = HealthUiAdapter.metricsFromResponse(
      response,
      payload: lastPayload,
    ).where((metric) => metric.organKey == organKey).toList();
    final missingCount = HealthUiAdapter.moreDataNeeded(response)
        .where((item) => item['organ']?.toString() == organKey)
        .length;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OrganDetailScreen(
          organKey: organKey,
          organName: organName,
          metrics: metrics,
          missingCount: missingCount,
        ),
      ),
    );
  }

  Widget _needMoreDataCard(List<dynamic> moreNeeded) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFEAF7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppStyles.softBlueBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppStyles.softBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(Icons.add_chart_outlined, color: AppStyles.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need to add more data?',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  moreNeeded.isEmpty
                      ? 'Your latest screening has enough values for the current insights.'
                      : 'Fill missing values to unlock deeper and more accurate insight.',
                  style: const TextStyle(color: AppStyles.muted, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddMissingScreen()),
              );
            },
            child: const Text('Add Missing Data'),
          ),
        ],
      ),
    );
  }

  Widget _generalHealthPatternSection(List<dynamic> pattern) {
    final groups = _patternGroups(pattern);
    final counts = _contributorCounts();
    final cards = [
      _PatternConfig(
        title: 'Lifestyle',
        count: counts['Lifestyle'] ?? 0,
        items: groups['Lifestyle'] ?? const [],
        style: AppStyles.lifestyleContributor,
      ),
      _PatternConfig(
        title: 'Food Habits',
        count: counts['Food Habits'] ?? 0,
        items: groups['Food Habits'] ?? const [],
        style: AppStyles.foodContributor,
      ),
      _PatternConfig(
        title: 'Environment',
        count: counts['Environment'] ?? 0,
        items: groups['Environment'] ?? const [],
        style: AppStyles.environmentContributor,
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppStyles.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('General Health Pattern',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text(
            'These factors may contribute to risk indicators.',
            style: TextStyle(color: AppStyles.muted),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 760 ? 3 : 1;
              final width =
                  (constraints.maxWidth - (12 * (columns - 1))) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final card in cards)
                    SizedBox(width: width, child: _patternCard(card)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _patternCard(_PatternConfig config) {
    final level = _contributorLevel(config.count);
    final progress = config.count >= 3
        ? 1.0
        : config.count >= 1
            ? 0.62
            : 0.28;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showPatternDetails(config),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: config.style.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: config.style.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(config.style.icon, color: config.style.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    config.title,
                    style: TextStyle(
                      color: config.style.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Level: $level',
              style: TextStyle(
                color: config.style.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 9,
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.72),
                color: config.style.accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              config.count == 0
                  ? 'No major items noted'
                  : '${config.count} item${config.count == 1 ? '' : 's'} noted',
              style: TextStyle(color: config.style.text, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showPatternDetails(_PatternConfig config) {
    final items = config.items.isEmpty
        ? ['No major items noted in this category.']
        : config.items;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(config.style.icon, color: config.style.accent),
                  const SizedBox(width: 8),
                  Text(config.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'These factors may contribute to risk indicators.',
                style: TextStyle(color: AppStyles.muted),
              ),
              const SizedBox(height: 12),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: config.style.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _resultsForOrgan(
      List<dynamic> results, String organ) {
    return results
        .where((result) => (result as Map)['organ'] == organ)
        .map((result) => Map<String, dynamic>.from(result as Map))
        .toList();
  }

  List<Map<String, dynamic>> _moreNeededForOrgan(
      List<dynamic> moreNeeded, String organ) {
    return moreNeeded
        .where((item) => (item as Map)['organ'] == organ)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
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

  String _organExplanation(
      String organ, Map<String, dynamic>? result, HealthStatusStyle status) {
    if (result == null) return _missingDataExplanation(organ, const []);
    final subject =
        _indicatorSubject(result['index_name']?.toString() ?? '', organ);
    if (status.label == AppStyles.attentionStatus.label) {
      return '$subject needs monitoring if values persist.';
    }
    if (status.label == AppStyles.monitorStatus.label) {
      return '$subject should be reviewed if values persist.';
    }
    if (status.label == AppStyles.lowConcernStatus.label) {
      return '$subject appears within a low concern range.';
    }
    return _missingDataExplanation(organ, const []);
  }

  String _indicatorSubject(String indexName, String organ) {
    switch (indexName) {
      case 'AIP':
        return 'Lipid-related risk indicator';
      case 'TyG':
      case 'Metabolic screening insight':
        return 'Metabolic screening indicator';
      case 'APRI':
      case 'FIB-4':
      case 'NAFLD Fibrosis Score':
      case 'FLI':
        return 'Liver screening indicator';
      case 'eGFR':
        return 'Kidney filtration estimate';
      case 'SpO2':
        return 'Oxygen saturation';
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

  String _missingDataExplanation(
      String organ, List<Map<String, dynamic>> moreNeeded) {
    if (moreNeeded.isNotEmpty) {
      final missing =
          moreNeeded.first['missing_inputs'] as List<dynamic>? ?? [];
      if (missing.isNotEmpty) {
        return 'Add ${_prettyMissing(missing.first.toString())} to improve this insight.';
      }
    }
    switch (organ) {
      case 'Heart':
        return 'Add triglycerides and HDL to estimate lipid-related risk.';
      case 'Diabetes / Metabolic':
        return 'Add glucose values to estimate metabolic pattern.';
      case 'Liver':
        return 'Add AST, ALT, platelets, and related values for liver insights.';
      case 'Kidney':
        return 'Add creatinine to estimate kidney filtration.';
      case 'Lung':
        return 'Add SpO2 to review oxygen saturation.';
      case 'Inflammation':
        return 'Add neutrophils and lymphocytes for this marker.';
      case 'Pancreas':
        return 'Add lipase and amylase for this enzyme ratio.';
      case 'Cancer Awareness':
        return 'Add tumor marker values only if available in your report.';
      default:
        return 'More report values are needed for this screening insight.';
    }
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

  int _flagCount(List<bool> flags) => flags.where((flag) => flag).length;

  String _contributorLevel(int count) {
    if (count >= 3) return 'High';
    if (count >= 1) return 'Moderate';
    return 'Low';
  }

  String _prettyMissing(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _OrganConfig {
  const _OrganConfig({
    required this.key,
    required this.name,
    required this.background,
    required this.accent,
  });

  final String key;
  final String name;
  final Color background;
  final Color accent;
}

class _PatternConfig {
  const _PatternConfig({
    required this.title,
    required this.count,
    required this.items,
    required this.style,
  });

  final String title;
  final int count;
  final List<String> items;
  final ContributorStyle style;
}
