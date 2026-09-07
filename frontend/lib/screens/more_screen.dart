import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/ui_result_adapter.dart';
import '../services/backend_analysis_service.dart';
import '../services/export_summary_service.dart';
import '../storage/local_storage.dart';
import '../widgets/brand_logo.dart';
import '../widgets/disclaimer.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({
    super.key,
    required this.onStartAnalysis,
    required this.onViewResults,
    required this.onSignOut,
    required this.userEmail,
    required this.themeMode,
    required this.onThemeModeChanged,
    this.onDataCleared,
  });

  final VoidCallback onStartAnalysis;
  final VoidCallback onViewResults;
  final VoidCallback onSignOut;
  final String? userEmail;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback? onDataCleared;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _exporting = false;
  Map<String, dynamic>? _payload;
  Map<String, dynamic>? _response;
  DateTime? _lastChecked;
  bool _checkingAi = false;
  Map<String, dynamic>? _aiStatus;

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
                  subtitle: 'Understand on-device calculations and sync',
                  onTap: () => _showInfoSheet(
                    context,
                    'Privacy & Data Safety',
                    "VitalMap's health-index calculations are performed directly on your device. Firebase may be used for account authentication and optional screening-history synchronization. When offline, local calculations and saved results remain available.",
                  ),
                ),
                _menuItem(
                  icon: Icons.settings_outlined,
                  title: 'App Settings',
                  subtitle: 'Manage appearance and app preferences',
                  onTap: () => _showInfoSheet(
                    context,
                    'App Settings',
                    'Use Appearance to choose your theme, the input page to change units, and Clear Saved Data to remove the local draft and latest result.',
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
            _localAiCard(),
            const SizedBox(height: 18),
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
                  title: 'Appearance',
                  subtitle: _themeModeLabel(widget.themeMode),
                  onTap: () => _showThemeModeSheet(context),
                  trailing: const Icon(Icons.chevron_right),
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
                  subtitle: 'Project support and issue reporting',
                  onTap: () => _showInfoSheet(
                    context,
                    'Contact Support',
                    'Report technical issues at https://github.com/D-Varshini17/VitalMap/issues. Include the platform and steps to reproduce. Do not include personal medical information.',
                  ),
                ),
                _menuItem(
                  icon: Icons.feedback_outlined,
                  title: 'Feedback',
                  subtitle: 'Share product feedback and report issues',
                  onTap: () => _showInfoSheet(
                    context,
                    'Feedback',
                    'Share product feedback at https://github.com/D-Varshini17/VitalMap/issues. Describe the improvement you would like to see.',
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  for (final item in items) ...[
                    item,
                    const SizedBox(height: 6),
                  ],
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _localAiCard() {
    final configured = BackendAnalysisService.isConfigured;
    final connected = _aiStatus?['connected'] == true;
    final status = _aiStatus?['status']?.toString() ??
        (configured ? 'Not tested' : 'Backend URL not configured');
    final model = _aiStatus?['model']?.toString() ?? 'qwen3:1.7b';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome_outlined,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Local AI',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  'Status: ${connected ? 'Connected' : status}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: !configured || _checkingAi ? null : _testLocalAi,
            icon: _checkingAi
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering_outlined, size: 18),
            label: const Text('Test Local AI'),
          ),
        ]),
        const SizedBox(height: 10),
        _aiInfoRow('Model', model),
        _aiInfoRow('Processing', 'Local Device / Local Computer'),
        _aiInfoRow('Cloud AI', 'Disabled'),
        if (!configured) ...[
          const SizedBox(height: 8),
          Text(
            'Start the FastAPI backend and pass --dart-define=VITALMAP_BACKEND_URL=http://127.0.0.1:8000 to enable local AI recommendations.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.35),
          ),
        ],
      ]),
    );
  }

  Widget _aiInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(
          width: 92,
          child: Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  Future<void> _testLocalAi() async {
    setState(() => _checkingAi = true);
    try {
      final status = await BackendAnalysisService.localAiStatus();
      if (!mounted) return;
      setState(() => _aiStatus = status);
    } catch (error) {
      if (!mounted) return;
      setState(() => _aiStatus = {
            'connected': false,
            'status': 'unavailable',
            'model': 'qwen3:1.7b',
            'error': error.toString(),
          });
    } finally {
      if (mounted) setState(() => _checkingAi = false);
    }
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
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
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Icon(Icons.person_outline,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Profile',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      userLabel.isEmpty ? 'Complete your profile' : userLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        enabled: onTap != null,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.dark => 'Dark theme selected',
      ThemeMode.light => 'Light theme selected',
      ThemeMode.system => 'Using device appearance',
    };
  }

  Future<void> _showThemeModeSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in [
              (
                ThemeMode.system,
                'System Default',
                Icons.brightness_auto_outlined
              ),
              (ThemeMode.light, 'Light', Icons.light_mode_outlined),
              (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
            ])
              ListTile(
                leading: Icon(option.$3),
                title: Text(option.$2),
                trailing: option.$1 == widget.themeMode
                    ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(option.$1),
              ),
          ],
        ),
      ),
    );
    if (selected != null) widget.onThemeModeChanged(selected);
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
    widget.onDataCleared?.call();
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
      builder: (context) => SafeArea(
          child: SingleChildScrollView(
              child: Padding(
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
            SelectableText(text, style: const TextStyle(height: 1.4)),
          ],
        ),
      ))),
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
