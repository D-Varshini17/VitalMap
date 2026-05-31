import 'package:flutter/material.dart';

import '../styles.dart';
import '../widgets/organ_visual.dart';
import '../widgets/health_dashboard_widgets.dart';
import '../widgets/disclaimer.dart';

class AddMissingScreen extends StatelessWidget {
  const AddMissingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MissingRowConfig(
          'Kidney', 'Creatinine', 'Adds eGFR estimate', Icons.opacity_outlined),
      _MissingRowConfig('Inflammation', 'Neutrophils & Lymphocytes', 'Adds NLR',
          Icons.bloodtype_outlined),
      _MissingRowConfig('Liver', 'GGT', 'Improves liver indices',
          Icons.monitor_heart_outlined),
      _MissingRowConfig('Cancer Awareness', 'AFP, CA 15-3, CA 27.29',
          'Only if available', Icons.health_and_safety_outlined),
      _MissingRowConfig('Pancreas', 'Lipase & Amylase', 'Adds enzyme ratio',
          Icons.science_outlined),
    ];

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Missing Data'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const VitalMapHeroCard(
              title: 'Add Missing Data',
              subtitle:
                  'Adding these values will help generate deeper organ-wise insights.',
              description: '',
              compact: true,
            ),
            const SizedBox(height: 12),
            for (final item in items) _missingRow(item, context),
            const SizedBox(height: 18),
            const DisclaimerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _missingRow(_MissingRowConfig cfg, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppStyles.border),
      ),
      child: Row(
        children: [
          OrganVisualIcon(organ: cfg.organ, size: 48, iconSize: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cfg.name,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(cfg.help, style: const TextStyle(color: AppStyles.muted)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Open the Input page and add the requested values.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.primary,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _MissingRowConfig {
  final String organ;
  final String name;
  final String help;
  final IconData icon;
  const _MissingRowConfig(this.organ, this.name, this.help, this.icon);
}
