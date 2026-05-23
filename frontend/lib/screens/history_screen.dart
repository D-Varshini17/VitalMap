import 'package:flutter/material.dart';

import '../core/ui_result_adapter.dart';
import '../storage/local_storage.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/organ_visual.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    this.response,
    this.lastChecked,
    required this.onViewResults,
  });

  final Map<String, dynamic>? response;
  final DateTime? lastChecked;
  final VoidCallback onViewResults;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, dynamic>? response;
  Map<String, dynamic>? payload;
  DateTime? lastChecked;

  @override
  void initState() {
    super.initState();
    response = widget.response;
    lastChecked = widget.lastChecked;
    _loadStored();
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
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
    final metrics = HealthUiAdapter.metricsFromResponse(
      response,
      payload: payload,
    );
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const BrandAppBarTitle(title: 'History'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text(
              'Your past screenings and reports',
              style: TextStyle(color: AppStyles.muted, height: 1.35),
            ),
            const SizedBox(height: 14),
            _filters(),
            const SizedBox(height: 12),
            if (metrics.isEmpty)
              _emptyState()
            else ...[
              for (final metric in metrics)
                _historyCard(metric, lastChecked ?? DateTime.now()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    return Row(
      children: [
        _filterChip(Icons.category_outlined, 'All Categories'),
        const SizedBox(width: 10),
        _filterChip(Icons.sort_outlined, 'Sort by Date'),
      ],
    );
  }

  Widget _filterChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppStyles.border),
          boxShadow: [
            BoxShadow(
              color: AppStyles.primary.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppStyles.primary, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppStyles.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.history, color: AppStyles.primary, size: 42),
          SizedBox(height: 10),
          Text(
            'No history yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Your completed screening summaries will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppStyles.muted),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(HealthMetric metric, DateTime date) {
    final status = AppStyles.statusStyle(metric.rawStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.border),
        boxShadow: [
          BoxShadow(
            color: AppStyles.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onViewResults,
        child: Row(
          children: [
            OrganVisualIcon(organ: metric.organKey, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      color: AppStyles.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric.organName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    metric.indexName,
                    style: const TextStyle(color: AppStyles.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: status.badgeBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    metric.statusLabel,
                    style: TextStyle(
                      color: status.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(Icons.chevron_right, color: AppStyles.muted, size: 20),
              ],
            ),
          ],
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
