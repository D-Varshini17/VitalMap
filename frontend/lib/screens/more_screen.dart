import 'package:flutter/material.dart';

import '../core/ui_result_adapter.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/disclaimer.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.onStartAnalysis,
    required this.onViewResults,
  });

  final VoidCallback onStartAnalysis;
  final VoidCallback onViewResults;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const BrandAppBarTitle(title: 'More'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _aboutCard(),
            const SizedBox(height: 10),
            _menuItem(
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'Review your saved basic details',
              onTap: onStartAnalysis,
            ),
            _menuItem(
              icon: Icons.health_and_safety_outlined,
              title: 'App Safety Note',
              subtitle: 'How to interpret screening insights safely',
              onTap: () => _showSafetySheet(context),
            ),
            _menuItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy note',
              subtitle: 'Data stays on your device unless analysis is sent',
              onTap: () => _showPrivacySheet(context),
            ),
            _menuItem(
              icon: Icons.info_outline,
              title: 'About VitalMap',
              subtitle: 'Organ Health Risk Indicator',
              onTap: () => _showAboutSheet(context),
            ),
            _menuItem(
              icon: Icons.ios_share_outlined,
              title: 'Export Screening Summary',
              subtitle: 'Create a shareable screening summary',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export screening summary is coming soon.'),
                ),
              ),
            ),
            _menuItem(
              icon: Icons.help_outline,
              title: 'Help',
              subtitle: 'Understand inputs, results, and organ cards',
              onTap: () => _showHelpSheet(context),
            ),
            const SizedBox(height: 10),
            const DisclaimerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _aboutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFEAF7FF)],
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
      child: const Row(
        children: [
          BrandLogoMark(size: 58, glow: true),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VitalMap',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3),
                Text(
                  'Organ Health Risk Indicator',
                  style: TextStyle(
                    color: AppStyles.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppStyles.softBlue,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppStyles.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  void _showSafetySheet(BuildContext context) {
    _showInfoSheet(
      context,
      'App Safety Note',
      HealthUiAdapter.disclaimer,
    );
  }

  void _showPrivacySheet(BuildContext context) {
    _showInfoSheet(
      context,
      'Privacy note',
      'Your last input and result are stored locally on this device for continuity. AI recommendations require sending available screening context to the backend service.',
    );
  }

  void _showAboutSheet(BuildContext context) {
    _showInfoSheet(
      context,
      'About VitalMap',
      'VitalMap helps organize available general health and report values into organ-wise screening insights.',
    );
  }

  void _showHelpSheet(BuildContext context) {
    _showInfoSheet(
      context,
      'Help',
      'Complete compulsory general details, add only the report values you have, then review Results and Overview for organ-wise insights.',
    );
  }

  void _showInfoSheet(BuildContext context, String title, String text) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}
