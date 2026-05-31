import 'package:flutter/material.dart';

import '../core/ui_result_adapter.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/disclaimer.dart';
import '../widgets/organ_visual.dart';
import 'organ_detail_screen.dart';

class InsightScreen extends StatelessWidget {
  const InsightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const BrandAppBarTitle(title: 'Insight'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _headerCard(),
            const SizedBox(height: 12),
            for (final key in HealthUiAdapter.organOrder)
              _organTile(context, key),
            const SizedBox(height: 18),
            const DisclaimerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.border),
      ),
      child: Row(
        children: const [
          BrandLogoMark(size: 48, glow: false),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Insight',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text(
                    'Learn about organ-wise screening and what common indicators mean.',
                    style: TextStyle(color: AppStyles.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _organTile(BuildContext context, String key) {
    final name = HealthUiAdapter.organName(key);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppStyles.border),
        ),
        child: ListTile(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OrganDetailScreen(
                organKey: key,
                organName: name,
                metrics: const [],
                missingCount: 0,
              ),
            ));
          },
          leading: OrganVisualIcon(organ: key, size: 44, iconSize: 22),
          title:
              Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: const Text('Educational content and screening context.'),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
