import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/ui_result_adapter.dart';
import '../services/export_summary_service.dart';
import '../storage/local_storage.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/disclaimer.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({
    super.key,
    required this.onStartAnalysis,
    required this.onViewResults,
    required this.onSignOut,
    required this.userEmail,
  });

  final VoidCallback onStartAnalysis;
  final VoidCallback onViewResults;
  final VoidCallback onSignOut;
  final String? userEmail;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _exporting = false;
  bool _darkMode = false;
  Map<String, dynamic>? _payload;
  Map<String, dynamic>? _response;
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    final payload = await LocalStorage.loadLastPayload();
    final storedResponse = await LocalStorage.loadLastResponse();
    if (!mounted) return;
    final rawResponse = storedResponse?['response'];
    setState(() {
      _payload = payload;
      _response =
          rawResponse is Map ? Map<String, dynamic>.from(rawResponse) : null;
      final timestamp = storedResponse?['timestamp']?.toString();
      _lastChecked = timestamp == null ? null : DateTime.tryParse(timestamp);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(title: const BrandAppBarTitle(title: 'More')),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _aboutCard(),
            const SizedBox(height: 14),
            _profileStatsCard(),
            const SizedBox(height: 18),
            _menuSection(
              context,
              'Profile & Health',
              [
                _menuItem(
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  subtitle: 'Review your saved basic details',
                  onTap: widget.onStartAnalysis,
                ),
                _menuItem(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Health Stats',
                  subtitle:
                      'Review completion, screening count, and latest results',
                  onTap: widget.onViewResults,
                ),
                _menuItem(
                  icon: Icons.edit_note_outlined,
                  title: 'Edit General Health Questions',
                  subtitle: 'Update lifestyle, food, and environment answers',
                  onTap: widget.onStartAnalysis,
                ),
                _menuItem(
                  icon: Icons.fact_check_outlined,
                  title: 'Saved Report Values',
                  subtitle: 'Open entered report values on the input page',
                  onTap: widget.onStartAnalysis,
                ),
              ],
            ),
            _menuSection(
              context,
              'Reports & Export',
              [
                _menuItem(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'Export Screening Summary PDF',
                  subtitle: _exporting
                      ? 'Preparing your screening summary'
                      : 'Generate a shareable PDF summary',
                  onTap: _exporting ? null : _exportSummary,
                  trailing: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                _menuItem(
                  icon: Icons.ios_share_outlined,
                  title: 'Share Result Summary',
                  subtitle: 'Share the latest screening summary PDF',
                  onTap: _exporting ? null : _exportSummary,
                ),
                _menuItem(
                  icon: Icons.download_outlined,
                  title: 'Download Last Result',
                  subtitle: 'Download the most recent screening summary',
                  onTap: _exporting ? null : _exportSummary,
                ),
                _menuItem(
                  icon: Icons.history_outlined,
                  title: 'Saved Results',
                  subtitle: 'View the latest saved result',
                  onTap: widget.onViewResults,
                ),
                _menuItem(
                  icon: Icons.summarize_outlined,
                  title: 'Past Screening Summaries',
                  subtitle: 'Open your latest locally saved screening summary',
                  onTap: widget.onViewResults,
                ),
              ],
            ),
            _menuSection(
              context,
              'App Safety',
              [
                _menuItem(
                  icon: Icons.shield_outlined,
                  title: 'Disclaimer',
                  subtitle: 'Read the informational-use safety note',
                  onTap: () => _showInfoSheet(
                    context,
                    'Disclaimer',
                    HealthUiAdapter.disclaimer,
                  ),
                ),
                _menuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Settings',
                  subtitle: 'Understand local storage and backend analysis',
                  onTap: () => _showInfoSheet(
                    context,
                    'Privacy & Data Safety',
                    'Your last input and result are stored locally on this device for continuity. Analysis may be sent to the configured backend to calculate indicators and generate personalized informational recommendations. API keys are not stored in the app.',
                  ),
                ),
                _menuItem(
                  icon: Icons.settings_outlined,
                  title: 'App Settings',
                  subtitle: 'Manage appearance and app preferences',
                  onTap: () => _showInfoSheet(
                    context,
                    'App Settings',
                    'VitalMap stores only the latest local draft and result on this device. Release builds can connect these settings to account, notification, and cloud sync preferences.',
                  ),
                ),
                _menuItem(
                  icon: Icons.medical_information_outlined,
                  title: 'Medical Safety Note',
                  subtitle: 'How to interpret screening insights safely',
                  onTap: () => _showInfoSheet(
                    context,
                    'Medical Safety Note',
                    'VitalMap provides screening indicators only. It does not diagnose, confirm disease, prescribe medicine, or replace clinical evaluation.',
                  ),
                ),
              ],
            ),
            _menuSection(
              context,
              'Settings',
              [
                _menuItem(
                  icon: Icons.straighten_outlined,
                  title: 'Units Preference',
                  subtitle: 'Units are selected beside each input value',
                  onTap: () => _showInfoSheet(
                    context,
                    'Units Preference',
                    'Choose units directly beside each report value. VitalMap stores the selected units with your saved draft.',
                  ),
                ),
                _menuItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: _darkMode
                      ? 'Dark mode preference enabled'
                      : 'Light mode active',
                  onTap: () => setState(() => _darkMode = !_darkMode),
                  trailing: Switch(
                    value: _darkMode,
                    onChanged: (value) => setState(() => _darkMode = value),
                  ),
                ),
                _menuItem(
                  icon: Icons.delete_outline,
                  title: 'Clear Saved Data',
                  subtitle:
                      'Remove saved draft and latest result from this device',
                  onTap: _confirmClearData,
                ),
              ],
            ),
            _menuSection(
              context,
              'Support',
              [
                _menuItem(
                  icon: Icons.help_outline,
                  title: 'Help & FAQ',
                  subtitle:
                      'Understand inputs, results, insight cards, and safety notes',
                  onTap: () => _showInfoSheet(
                    context,
                    'Help & FAQ',
                    'Complete the compulsory general details, add only report values you have, then open Result for organ-wise screening insights and Insight for educational notes.',
                  ),
                ),
                _menuItem(
                  icon: Icons.support_agent_outlined,
                  title: 'Support',
                  subtitle: 'Support details for release builds',
                  onTap: () => _showInfoSheet(
                    context,
                    'Contact Support',
                    'For support, use the contact email configured for the Play Store listing or your organization support channel.',
                  ),
                ),
                _menuItem(
                  icon: Icons.feedback_outlined,
                  title: 'Feedback',
                  subtitle: 'Share product feedback and report issues',
                  onTap: () => _showInfoSheet(
                    context,
                    'Feedback',
                    'Release builds should connect this action to your support email, issue tracker, or in-app feedback provider.',
                  ),
                ),
                _menuItem(
                  icon: Icons.info_outline,
                  title: 'About VitalMap',
                  subtitle: 'Organ Health Risk Indicator',
                  onTap: () => _showInfoSheet(
                    context,
                    'About VitalMap',
                    'VitalMap helps organize available general health and report values into organ-wise screening insights for informational use.',
                  ),
                ),
                _menuItem(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: 'VitalMap 0.1.1',
                  onTap: () => _showInfoSheet(
                    context,
                    'App Version',
                    'VitalMap 0.1.1\nOrgan Health Risk Indicator',
                  ),
                ),
                _menuItem(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  subtitle: 'Sign out of VitalMap and return to login',
                  onTap: widget.onSignOut,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const DisclaimerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _menuSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppStyles.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = Responsive.isDesktop(context) ? 2 : 1;
              final width =
                  (constraints.maxWidth - (12 * (columns - 1))) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final item in items) SizedBox(width: width, child: item),
                ],
              );
            },
          ),
        ],
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

  Widget _profileStatsCard() {
    final profile =
        Map<String, dynamic>.from(_payload?['profile'] as Map? ?? const {});
    final age = profile['age']?.toString();
    final sex = profile['sex']?.toString();
    final metrics = HealthUiAdapter.metricsFromResponse(
      _response,
      payload: _payload,
    );
    final completion = HealthUiAdapter.completionPercent(_payload);
    final userLabel = [
      if (sex != null && sex.isNotEmpty) sex,
      if (age != null && age.isNotEmpty) '$age yrs',
    ].join(' - ');
    final lastAssessment =
        _lastChecked == null ? 'Not assessed yet' : _formatDate(_lastChecked!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppStyles.border),
        boxShadow: [
          BoxShadow(
            color: AppStyles.navy.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppStyles.softBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppStyles.softBlueBorder),
                ),
                child:
                    const Icon(Icons.person_outline, color: AppStyles.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Profile',
                      style: TextStyle(
                        color: AppStyles.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      userLabel.isEmpty ? 'Complete your profile' : userLabel,
                      style: const TextStyle(
                        color: AppStyles.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 4 : 2;
              final width =
                  (constraints.maxWidth - (10 * (columns - 1))) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: width,
                    child: _statTile(
                      'Screenings',
                      _response == null ? '0' : '1',
                      Icons.fact_check_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _statTile(
                      'Completion',
                      '$completion%',
                      Icons.donut_large_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _statTile(
                      'Indexes',
                      metrics.length.toString(),
                      Icons.insights_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _statTile(
                      'Last Assessment',
                      lastAssessment,
                      Icons.event_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FBFF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppStyles.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppStyles.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppStyles.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppStyles.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppStyles.border),
      ),
      child: ListTile(
        onTap: onTap,
        enabled: onTap != null,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppStyles.softBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppStyles.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }

  Future<void> _exportSummary() async {
    setState(() => _exporting = true);
    final result = await ExportSummaryService.exportLastSummary();
    if (!mounted) return;
    setState(() => _exporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> _confirmClearData() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Saved Data'),
        content: const Text(
          'This removes your saved draft and latest screening result from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (clear != true) return;
    await LocalStorage.clearAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved data cleared.')),
    );
    await _loadOverview();
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
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
