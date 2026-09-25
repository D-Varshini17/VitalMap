import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/ui_result_adapter.dart';
import '../services/backend_analysis_service.dart';
import '../services/firestore_service.dart';
import '../storage/local_storage.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/organ_visual.dart';

class LabReportScannerScreen extends StatefulWidget {
  const LabReportScannerScreen({super.key});

  @override
  State<LabReportScannerScreen> createState() => _LabReportScannerScreenState();
}

class _LabReportScannerScreenState extends State<LabReportScannerScreen> {
  Uint8List? _bytes;
  String? _fileName;
  bool _scanning = false;
  bool _saving = false;
  bool _analyzing = false;
  List<Map<String, dynamic>> _fields = [];
  List<Map<String, dynamic>> _extras = [];
  List<String> _warnings = [];
  Set<int> _included = <int>{};
  Map<String, dynamic>? _analysisResponse;
  Map<String, dynamic>? _guidance;
  Map<String, dynamic>? _draftUsed;
  String? _error;
  String? _mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const BrandAppBarTitle(title: 'Import Lab Report')),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepHeader(),
            const SizedBox(height: 14),
            _localOnlyBanner(),
            const SizedBox(height: 14),
            _pickCard(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _errorCard(_error!),
            ],
            if (_fields.isNotEmpty || _extras.isNotEmpty) ...[
              const SizedBox(height: 18),
              _extractionSummary(),
              const SizedBox(height: 12),
              _reviewHeader(),
              const SizedBox(height: 10),
              for (var i = 0; i < _fields.length; i++) ...[
                _fieldCard(i),
                const SizedBox(height: 8),
              ],
              if (_extras.isNotEmpty) ...[
                const SizedBox(height: 12),
                _extrasCard(),
              ],
              if (_warnings.isNotEmpty) ...[
                const SizedBox(height: 10),
                _warningCard(),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving || _analyzing ? null : _saveAndAnalyse,
                  icon: _saving || _analyzing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_graph_outlined),
                  label: Text(_saving
                      ? 'Saving reviewed values...'
                      : _analyzing
                          ? 'Running VitalMap analysis...'
                          : 'Save reviewed values & analyse'),
                ),
              ),
            ],
            if (_analysisResponse != null) ...[
              const SizedBox(height: 18),
              _reportIntelligenceCard(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.edit_note_outlined),
                  label: const Text('Return to Input with imported values'),
                ),
              ),
            ],
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }

  Widget _stepHeader() {
    final step = _analysisResponse != null
        ? 3
        : _fields.isNotEmpty
            ? 2
            : 1;
    return Row(
      children: [
        _stepChip(1, 'Choose', step >= 1),
        _stepLine(step >= 2),
        _stepChip(2, 'Review', step >= 2),
        _stepLine(step >= 3),
        _stepChip(3, 'Insights', step >= 3),
      ],
    );
  }

  Widget _stepChip(int number, String label, bool active) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? scheme.primary : scheme.surfaceContainer,
            shape: BoxShape.circle,
            border: Border.all(
                color: active ? scheme.primary : scheme.outlineVariant),
          ),
          child: Text('$number',
              style: TextStyle(
                  color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: active ? scheme.primary : scheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _stepLine(bool active) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 18),
        color: active ? scheme.primary : scheme.outlineVariant,
      ),
    );
  }

  Widget _localOnlyBanner() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.computer_outlined, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Local report processing',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  'Reports are read on your laptop using Ollama. ${BackendAnalysisService.reportConnectionHelp} Review every extracted value and unit before saving.',
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickCard() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.document_scanner_outlined, color: scheme.primary),
              const SizedBox(width: 10),
              const Expanded(
                  child: Text('Upload a lab report',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _fileName == null
                ? 'PDF, scanned PDF, PNG, JPG, WEBP, TXT or CSV • maximum 12 MB'
                : 'Selected: $_fileName${_mode == null ? '' : ' • ${_modeLabel(_mode!)}'}',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _scanning ? null : _pickFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                    _fileName == null ? 'Choose report' : 'Choose another'),
              ),
              FilledButton.icon(
                onPressed: _bytes == null || _scanning ? null : _scan,
                icon: _scanning
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.manage_search_outlined),
                label: Text(
                    _scanning ? 'Reading locally...' : 'Extract report values'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _extractionSummary() {
    final scheme = Theme.of(context).colorScheme;
    final highConfidence = _fields
        .where((item) => item['confidence']?.toString() == 'high')
        .length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant)),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _summaryChip(
              Icons.fact_check_outlined, '${_fields.length} VitalMap values'),
          _summaryChip(
              Icons.verified_outlined, '$highConfidence high-confidence'),
          _summaryChip(Icons.inventory_2_outlined,
              '${_extras.length} other report values'),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))
      ]),
    );
  }

  Widget _reviewHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review before analysis',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(
            'Only checked rows are merged into Input. Correct any value or unit that does not exactly match the report.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _fieldCard(int index) {
    final field = _fields[index];
    final included = _included.contains(index);
    final scheme = Theme.of(context).colorScheme;
    final range = field['reference_range']?.toString().trim() ?? '';
    final confidence = field['confidence']?.toString() ?? 'review';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: confidence == 'low'
                ? scheme.error
                : included
                    ? scheme.primary.withValues(alpha: 0.55)
                    : scheme.outlineVariant),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: included,
            onChanged: (value) => setState(() {
              if (value == true) {
                _included.add(index);
              } else {
                _included.remove(index);
              }
              _analysisResponse = null;
              _guidance = null;
            }),
            title: Text(
                field['label']?.toString() ??
                    field['key']?.toString() ??
                    'Value',
                style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(
                '${field['section'] ?? ''} • confidence: $confidence${range.isEmpty ? '' : ' • printed range: $range'}'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: field['value']?.toString() ?? '',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Value'),
                  onChanged: (value) {
                    final parsed = double.tryParse(value.trim());
                    field['value'] =
                        parsed != null && parsed.isFinite ? parsed : null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: field['unit']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Unit'),
                  onChanged: (value) {
                    field['unit'] = value.trim();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _extrasCard() {
    final scheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant)),
      title: Text('Other report values (${_extras.length})',
          style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: const Text(
          'Shown for review only; not mapped into current VitalMap formulas.'),
      children: [
        for (final extra in _extras)
          ListTile(
            title: Text(extra['label']?.toString() ?? 'Report value'),
            subtitle: Text(
                '${extra['value'] ?? ''} ${extra['unit'] ?? ''}${(extra['reference_range']?.toString().trim() ?? '').isEmpty ? '' : ' • printed range: ${extra['reference_range']}'}'),
          ),
      ],
    );
  }

  Widget _warningCard() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Scanner notes',
              style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          for (final warning in _warnings)
            Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $warning')),
        ],
      ),
    );
  }

  Widget _reportIntelligenceCard() {
    final scheme = Theme.of(context).colorScheme;
    final response = _analysisResponse!;
    final draft = _draftUsed ?? const <String, dynamic>{};
    final metrics =
        HealthUiAdapter.metricsFromResponse(response, payload: draft);
    final missing = HealthUiAdapter.moreDataNeeded(response);
    final score = HealthUiAdapter.healthScore(metrics, missing);
    final overall = HealthUiAdapter.overallStatus(metrics);
    final style = AppStyles.themedStatusStyle(context, overall);
    final sorted = [...metrics]..sort((a, b) =>
        AppStyles.statusRank(b.rawStatus)
            .compareTo(AppStyles.statusRank(a.rawStatus)));
    final guidance = _guidance ?? const <String, dynamic>{};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_outlined, color: scheme.primary),
              const SizedBox(width: 9),
              const Expanded(
                  child: Text('Report Health Intelligence',
                      style: TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final scoreTile = Container(
                width: compact ? double.infinity : 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: style.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: style.border)),
                child: Column(children: [
                  Text('$score',
                      style: TextStyle(
                          color: style.text,
                          fontSize: 28,
                          fontWeight: FontWeight.w900)),
                  Text('Health score',
                      style: TextStyle(
                          color: style.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w800))
                ]),
              );
              final summary = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${metrics.length} calculated indicator${metrics.length == 1 ? '' : 's'} • ${missing.length} data item${missing.length == 1 ? '' : 's'} still needed',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(
                      'Result label: ${AppStyles.displayStatusLabel(style.label)}',
                      style: TextStyle(
                          color: style.accent, fontWeight: FontWeight.w800)),
                ],
              );
              if (compact) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [summary, const SizedBox(height: 10), scoreTile]);
              }
              return Row(children: [
                Expanded(child: summary),
                const SizedBox(width: 12),
                scoreTile
              ]);
            },
          ),
          if (sorted.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Highest-priority calculated indicators',
                style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            for (final metric in sorted.take(4))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: OrganVisualIcon(organ: metric.organKey, size: 38),
                title: Text(metric.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(metric.statusLabel),
                trailing: Text(
                    '${metric.scoreText}${metric.unit.isEmpty ? '' : ' ${metric.unit}'}'),
              ),
          ],
          const SizedBox(height: 10),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('Local AI wellness guidance',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(999)),
                child: const Text('Ollama • local',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if ((guidance['summary']?.toString().trim() ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(guidance['summary'].toString(),
                style:
                    const TextStyle(height: 1.4, fontWeight: FontWeight.w600)),
          ],
          _guidanceGroup('Food habits', Icons.restaurant_outlined,
              _asList(guidance['food'])),
          _guidanceGroup('Activity', Icons.directions_walk_outlined,
              _asList(guidance['exercise'])),
          _guidanceGroup('Lifestyle', Icons.self_improvement_outlined,
              _asList(guidance['lifestyle'])),
          _guidanceGroup('Risk factors to review', Icons.fact_check_outlined,
              _asList(guidance['risk_factors'])),
          _guidanceGroup('What to monitor next', Icons.monitor_heart_outlined,
              _asList(guidance['monitor_next'])),
          const SizedBox(height: 10),
          Text(
            guidance['safety_note']?.toString() ??
                'General wellness guidance only. Local AI does not change VitalMap calculations, diagnose conditions or prescribe treatment.',
            style: TextStyle(
                color: scheme.onSurfaceVariant, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _guidanceGroup(String title, IconData icon, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 19, color: scheme.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900))
          ]),
          const SizedBox(height: 7),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check_circle_outline,
                    size: 16, color: scheme.primary),
                const SizedBox(width: 7),
                Expanded(
                    child: Text(item, style: const TextStyle(height: 1.35)))
              ]),
            ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(14)),
        child: Text(message, style: TextStyle(color: scheme.onErrorContainer)));
  }

  Future<void> _pickFile() async {
    setState(() => _error = null);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'png',
          'jpg',
          'jpeg',
          'webp',
          'txt',
          'csv'
        ],
      );
      if (file == null || !mounted) return;
      final length = await file.length();
      if (!mounted) return;
      if (length > 12 * 1024 * 1024) {
        setState(() => _error = 'Report must be 12 MB or smaller.');
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _fileName = file.name;
        _fields = [];
        _extras = [];
        _warnings = [];
        _included = <int>{};
        _analysisResponse = null;
        _guidance = null;
        _draftUsed = null;
        _mode = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Could not open that file. Download it to your device and choose it again.');
      }
    }
  }

  Future<void> _scan() async {
    final bytes = _bytes;
    final fileName = _fileName;
    if (bytes == null || fileName == null) return;
    setState(() {
      _scanning = true;
      _error = null;
      _fields = [];
      _extras = [];
      _warnings = [];
      _included = <int>{};
      _analysisResponse = null;
      _guidance = null;
    });
    try {
      final response = await BackendAnalysisService.scanLabReport(
          fileName: fileName, bytes: bytes);
      final fields = (response['fields'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final extras = (response['extras'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final warnings = (response['warnings'] as List? ?? const [])
          .map((item) => item.toString())
          .toList();
      if (!mounted) return;
      setState(() {
        _fields = fields;
        _extras = extras;
        _warnings = warnings;
        _included = {
          for (var index = 0; index < fields.length; index++)
            if ((fields[index]['confidence']?.toString() ?? '').toLowerCase() ==
                'high')
              index,
        };
        _mode = response['mode']?.toString();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _saveAndAnalyse() async {
    if (_saving || _analyzing) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Sign in to save reviewed report values.');
      return;
    }
    final selected = <Map<String, dynamic>>[
      for (var i = 0; i < _fields.length; i++)
        if (_included.contains(i)) Map<String, dynamic>.from(_fields[i]),
    ];
    if (selected.isEmpty) {
      setState(() => _error = 'Select at least one reviewed value to save.');
      return;
    }
    if (selected.any((field) =>
        field['value'] is! num ||
        !(field['value'] as num).isFinite ||
        (field['unit']?.toString().trim() ?? '').isEmpty)) {
      setState(() =>
          _error = 'Enter a valid value and unit for every selected row.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _analysisResponse = null;
      _guidance = null;
    });
    try {
      await FirestoreService.saveLabScan(
          uid: user.uid,
          fileName: _fileName ?? 'report',
          fields: selected,
          extras: _extras);
      final mergedCount = await FirestoreService.mergeLabReportFieldsIntoDraft(
          uid: user.uid, fields: selected);
      if (mergedCount == 0) {
        throw Exception(
            'None of the selected rows could be mapped into VitalMap. Check each printed unit and select supported rows only.');
      }
      setState(() {
        _saving = false;
        _analyzing = true;
      });

      final draft = await FirestoreService.loadDraft(user.uid);
      if (draft == null || draft.isEmpty) {
        throw Exception(
            'The imported VitalMap input draft could not be loaded.');
      }
      final analysis = await BackendAnalysisService.analyze(draft);
      if (analysis == null || analysis.isEmpty) {
        throw Exception('VitalMap analysis did not return a result.');
      }

      await LocalStorage.saveLastPayload(draft);
      await LocalStorage.saveLastResponse(analysis);
      await FirestoreService.saveScreening(
          uid: user.uid, payload: draft, response: analysis);

      if (!mounted) return;
      setState(() {
        _draftUsed = draft;
        _analysisResponse = analysis;
      });

      Map<String, dynamic>? guidance;
      try {
        guidance = await BackendAnalysisService.reportGuidance(
          analysis: analysis,
          generalHealth: Map<String, dynamic>.from(
              draft['general_health'] as Map? ?? const {}),
        );
      } catch (error) {
        guidance = {
          'summary':
              'VitalMap analysis completed. Local AI guidance is unavailable right now: ${error.toString().replaceFirst('Exception: ', '')}',
          'food': <String>[],
          'exercise': <String>[],
          'lifestyle': <String>[],
          'risk_factors': <String>[],
          'safety_note':
              'The deterministic VitalMap results remain available even when local Ollama is offline.',
        };
      }
      if (!mounted) return;
      setState(() {
        _draftUsed = draft;
        _analysisResponse = analysis;
        _guidance = guidance;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Reviewed report values were saved and analysed.')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error =
          'Could not complete report analysis: ${error.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _analyzing = false;
        });
      }
    }
  }

  List<String> _asList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _modeLabel(String mode) => switch (mode) {
        'pdf_text' => 'PDF text',
        'pdf_vision' => 'scanned PDF vision',
        'vision' => 'image vision',
        'text' => 'text report',
        'local_ocr' => 'report text',
        _ => mode,
      };
}
