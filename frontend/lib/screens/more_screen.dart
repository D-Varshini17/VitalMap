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
          title: const BrandAppBarTitle(title: 'VitalMap'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _aboutCard(),
            const SizedBox(height: 16),
            _sectionTitle('Profile & Health'),
            _menuItem(icon: Icons.person_outline, title: 'My Profile', onTap: onStartAnalysis),
            _menuItem(icon: Icons.health_and_safety_outlined, title: 'Edit General Health Questions', onTap: onStartAnalysis),
            _menuItem(icon: Icons.fact_check_outlined, title: 'Saved Report Values', onTap: onStartAnalysis),
            const SizedBox(height: 16),
            _sectionTitle('Reports & Export'),
            _menuItem(icon: Icons.picture_as_pdf_outlined, title: 'Export Screening Summary PDF', onTap: () => _comingSoon(context)),
            _menuItem(icon: Icons.share_outlined, title: 'Share Result Summary', onTap: () => _comingSoon(context)),
            _menuItem(icon: Icons.download_outlined, title: 'Download Last Result', onTap: () => _comingSoon(context)),
            const SizedBox(height: 16),
            _sectionTitle('App Safety'),
            _menuItem(icon: Icons.gavel_outlined, title: 'Disclaimer', onTap: () => _showDisclaimerSheet(context)),
            _menuItem(icon: Icons.privacy_tip_outlined, title: 'Privacy & Data Safety', onTap: () => _showPrivacySheet(context)),
            _menuItem(icon: Icons.medical_information_outlined, title: 'Medical Safety Note', onTap: () => _showSafetySheet(context)),
            const SizedBox(height: 16),
            _sectionTitle('Settings'),
            _menuItem(icon: Icons.settings_outlined, title: 'Units Preference', onTap: () => _comingSoon(context)),
            _menuItem(icon: Icons.delete_outline, title: 'Clear Saved Data', onTap: () => _comingSoon(context)),
            const SizedBox(height: 16),
            _sectionTitle('Support'),
            _menuItem(icon: Icons.help_outline, title: 'Help & FAQ', onTap: () => _showHelpSheet(context)),
            _menuItem(icon: Icons.support_agent_outlined, title: 'Contact Support', onTap: () => _comingSoon(context)),
            _menuItem(icon: Icons.info_outline, title: 'About VitalMap', onTap: () => _showAboutSheet(context)),
            _menuItem(icon: Icons.update_outlined, title: 'App Version', subtitle: '1.0.0', onTap: () {}),
            const SizedBox(height: 24),
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
        color: AppStyles.navy,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppStyles.navy.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          BrandLogoMark(size: 58, glow: false),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VitalMap',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 3),
                Text(
                  'Organ Health Risk Indicator',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppStyles.muted),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyles.border),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(icon, color: AppStyles.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppStyles.text)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: AppStyles.muted)) : null,
        trailing: subtitle != null ? null : const Icon(Icons.chevron_right, color: AppStyles.muted),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feature coming soon.')),
    );
  }

  void _showDisclaimerSheet(BuildContext context) {
    _showInfoSheet(context, 'Disclaimer', HealthUiAdapter.disclaimer);
  }

  void _showSafetySheet(BuildContext context) {
    _showInfoSheet(
      context,
      'Medical Safety Note',
      'The information provided by VitalMap is for awareness and educational purposes only. It does not replace professional medical advice, diagnosis, or treatment.',
    );
  }

  void _showPrivacySheet(BuildContext context) {
    _showInfoSheet(
      context,
      'Privacy & Data Safety',
      'Your last input and result are stored locally on this device for continuity. AI recommendations require sending available screening context to the backend service. We do not store your data remotely.',
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
      'Help & FAQ',
      'Complete compulsory general details, add only the report values you have, then review Results and Insight for organ-wise knowledge.',
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
            Text(text, style: const TextStyle(height: 1.4, color: AppStyles.text)),
          ],
        ),
      ),
    );
  }
}
