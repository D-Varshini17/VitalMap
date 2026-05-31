import 'package:flutter/material.dart';

import '../core/ui_result_adapter.dart';
import '../styles.dart';
import '../widgets/organ_visual.dart';

class IndexDetailScreen extends StatelessWidget {
  const IndexDetailScreen({
    super.key,
    required this.metric,
  });

  final HealthMetric metric;

  @override
  Widget build(BuildContext context) {
    final status = AppStyles.statusStyle(metric.rawStatus);
    
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(metric.indexName),
          backgroundColor: AppStyles.navy,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {},
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            Row(
              children: [
                OrganVisualIcon(organ: metric.organKey, size: 56, iconSize: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    metric.indexName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.navy,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status.badgeBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppStyles.displayStatusLabel(status.label),
                        style: TextStyle(
                          color: status.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      metric.scoreText,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.navy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'What this means',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              metric.summary,
              style: const TextStyle(color: AppStyles.text, fontSize: 14),
            ),
            const SizedBox(height: 24),
            const Text(
              'Values used',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._buildBullets(['Triglycerides: 165 mg/dL', 'Fasting Glucose: 96 mg/dL']),
            const SizedBox(height: 24),
            const Text(
              'Possible contributors',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._buildBullets([
              'High sugar intake',
              'Low physical activity',
              'Frequent processed food intake',
            ]),
            const SizedBox(height: 24),
            const Text(
              'Suggestions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._buildCheckmarks(metric.source),
            const SizedBox(height: 24),
            const Text(
              'Doctor follow-up',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Clinical review is suggested if abnormal values continue or symptoms persist.',
              style: TextStyle(color: AppStyles.text, fontSize: 14),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppStyles.border),
              ),
              child: const Text(
                'For informational purposes only. This app is not a substitute for clinical diagnosis, treatment, or medical advice. Please consult a qualified healthcare professional for medical decisions.',
                style: TextStyle(color: AppStyles.muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBullets(List<String> items) {
    if (items.isEmpty) return [const SizedBox.shrink()];
    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6, right: 8),
              child: Icon(Icons.circle, size: 6, color: AppStyles.navy),
            ),
            Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildCheckmarks(Map<String, dynamic>? source) {
    List<String> items = [];
    if (source != null) {
      if (source['recommendations'] is List) {
        items = List<String>.from(source['recommendations']);
      } else if (source['suggestions'] is List) {
        items = List<String>.from(source['suggestions']);
      }
    }
    if (items.isEmpty) return [const SizedBox.shrink()];
    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2, right: 8),
              child: Icon(Icons.check, size: 16, color: Colors.green),
            ),
            Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
          ],
        ),
      );
    }).toList();
  }
}
