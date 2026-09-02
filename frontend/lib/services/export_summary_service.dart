
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/ui_result_adapter.dart';
import '../storage/local_storage.dart';
import '../styles.dart';

class ExportSummaryResult {
  const ExportSummaryResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class ExportSummaryService {
  static const _disclaimer = HealthUiAdapter.disclaimer;

  static Future<ExportSummaryResult> exportLastSummary() async {
    final storedResponse = await LocalStorage.loadLastResponse();
    final payload = await LocalStorage.loadLastPayload();
    final response = Map<String, dynamic>.from(
      storedResponse?['response'] as Map? ?? const {},
    );
    if (response.isEmpty) {
      return const ExportSummaryResult(
        success: false,
        message:
            'Please analyze your available values before exporting a screening summary.',
      );
    }

    final timestamp = storedResponse?['timestamp']?.toString();
    final checkedAt = timestamp == null
        ? DateTime.now()
        : DateTime.tryParse(timestamp) ?? DateTime.now();
    final bytes = await _buildPdf(
      payload: payload ?? const <String, dynamic>{},
      response: response,
      checkedAt: checkedAt,
    );
    final fileName =
        'VitalMap_Screening_Summary_${_fileDate(DateTime.now())}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: fileName);
    return const ExportSummaryResult(
      success: true,
      message: 'Screening summary PDF is ready.',
    );
  }

  static Future<Uint8List> _buildPdf({
    required Map<String, dynamic> payload,
    required Map<String, dynamic> response,
    required DateTime checkedAt,
  }) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();
    final metrics = HealthUiAdapter.metricsFromResponse(
      response,
      payload: payload,
    );
    final moreData = HealthUiAdapter.moreDataNeeded(response);
    final snapshots = HealthUiAdapter.organSnapshots(
      response,
      payload: payload,
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          _header(logo, checkedAt),
          _section('Basic profile summary', _profileLines(payload)),
          _section(
              'General health answers summary', _generalHealthLines(payload)),
          _section('Entered report values', _reportValueLines(payload)),
          _section('Calculated indicators', _indicatorLines(metrics)),
          _section('Organ-wise status', _organLines(snapshots)),
          _section(
            'Personalized recommendations',
            _recommendationLines(metrics),
          ),
          _section(
            'More data needed',
            moreData.isEmpty
                ? ['No additional values are required for the current insight.']
                : moreData.map(HealthUiAdapter.missingActionText).toList(),
          ),
          _disclaimerBlock(),
        ],
      ),
    );
    return pdf.save();
  }

  static Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final data = await rootBundle.load(AppStyles.logoAsset);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _header(pw.MemoryImage? logo, DateTime checkedAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FBFF'),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColor.fromHex('#D9E5EA')),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Container(
              width: 48,
              height: 48,
              padding: const pw.EdgeInsets.all(7),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          if (logo != null) pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'VitalMap',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#062B5F'),
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Organ Health Risk Indicator',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#6B7280'),
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Screening Summary',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#0B63CE'),
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            _safe('Date/time: ${_formatDateTime(checkedAt)}'),
            style: pw.TextStyle(
              color: PdfColor.fromHex('#64748B'),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _section(String title, List<String> lines) {
    final visibleLines = lines.where((line) => line.trim().isNotEmpty).toList();
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#D9E5EA')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _safe(title),
            style: pw.TextStyle(
              color: PdfColor.fromHex('#1F2937'),
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          for (final line in visibleLines.isEmpty
              ? ['No information available for this section.']
              : visibleLines)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Text(
                _safe('• $line'),
                style: pw.TextStyle(
                  color: PdfColor.fromHex('#1F2937'),
                  fontSize: 10.5,
                  lineSpacing: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _disclaimerBlock() {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F7FAFD'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#D9E5EA')),
      ),
      child: pw.Text(
        _safe(_disclaimer),
        style: pw.TextStyle(
          color: PdfColor.fromHex('#6B7280'),
          fontSize: 10.5,
          lineSpacing: 2,
        ),
      ),
    );
  }

  static List<String> _profileLines(Map<String, dynamic> payload) {
    final profile = _map(payload['profile']);
    return [
      _line('Age', _withUnit(profile['age'], 'years')),
      _line('Sex', profile['sex']),
      _line('Height', _height(profile)),
      _line(
          'Weight', _withUnit(profile['weight_input'], profile['weight_unit'])),
      _line(
        'Waist circumference',
        _withUnit(profile['waist_input'], profile['waist_unit']),
      ),
    ].whereType<String>().toList();
  }

  static List<String> _generalHealthLines(Map<String, dynamic> payload) {
    final general = _map(payload['general_health']);
    const labels = {
      'smoking': 'Smoking',
      'alcohol': 'Alcohol',
      'physical_activity': 'Physical activity',
      'sleep_duration': 'Sleep duration',
      'stress_level': 'Stress level',
      'family_history': 'Family history',
      'diet_type': 'Diet type',
      'high_sugar_intake': 'High sugar intake',
      'high_salt_intake': 'High salt intake',
      'fried_processed_food': 'Fried/processed food',
      'fruit_veg_intake': 'Fruit/vegetable intake',
      'sugary_drinks': 'Sugary drinks',
      'air_pollution': 'Air pollution exposure',
      'occupational_exposure': 'Dust/chemical exposure',
      'passive_smoking': 'Passive smoking',
      'cooking_smoke': 'Cooking smoke',
      'cooking_fuel_smoke': 'Cooking fuel smoke',
      'location_type': 'Location type',
    };
    return [
      for (final entry in labels.entries)
        _line(entry.value, general[entry.key]),
    ].whereType<String>().toList();
  }

  static List<String> _reportValueLines(Map<String, dynamic> payload) {
    final lipids = _map(payload['lipid_profile']);
    final diabetes = _map(payload['diabetes_profile']);
    final liver = _map(payload['liver_function']);
    final cbc = _map(payload['cbc']);
    final kidney = _map(payload['kidney_function']);
    final vitals = _map(payload['vitals']);
    final pancreas = _map(payload['pancreatic_enzymes']);
    final markers = _map(payload['tumor_markers']);
    return [
      _line(
        'Triglycerides',
        _withUnit(lipids['triglycerides_input'] ?? lipids['triglycerides'],
            lipids['triglycerides_input_unit'] ?? lipids['triglycerides_unit']),
      ),
      _line(
        'HDL cholesterol',
        _withUnit(
          lipids['hdl_input'] ?? lipids['hdl'],
          lipids['hdl_input_unit'] ?? lipids['hdl_unit'],
        ),
      ),
      _line(
        'Fasting glucose',
        _withUnit(
          diabetes['fasting_glucose_input'] ?? diabetes['fasting_glucose'],
          diabetes['fasting_glucose_input_unit'] ??
              diabetes['fasting_glucose_unit'],
        ),
      ),
      _line('AST / SGOT', _withUnit(liver['ast'], liver['ast_unit'])),
      _line('ALT / SGPT', _withUnit(liver['alt'], liver['alt_unit'])),
      _line('GGT', _withUnit(liver['ggt'], liver['ggt_unit'])),
      _line(
        'Albumin',
        _withUnit(
          liver['albumin_input'] ?? liver['albumin'],
          liver['albumin_input_unit'] ?? liver['albumin_unit'],
        ),
      ),
      _line(
        'Platelets',
        _withUnit(
          cbc['platelets_input'] ?? cbc['platelets'],
          cbc['platelets_input_unit'] ?? cbc['platelets_unit'],
        ),
      ),
      _line('Neutrophils',
          _withUnit(cbc['neutrophils'], cbc['neutrophils_unit'])),
      _line('Lymphocytes',
          _withUnit(cbc['lymphocytes'], cbc['lymphocytes_unit'])),
      _line(
        'Creatinine',
        _withUnit(
          kidney['creatinine_input'] ?? kidney['creatinine'],
          kidney['creatinine_input_unit'] ?? kidney['creatinine_unit'],
        ),
      ),
      _line('SpO2', _withUnit(vitals['spo2'], vitals['spo2_unit'])),
      _line('Lipase', _withUnit(pancreas['lipase'], pancreas['lipase_unit'])),
      _line(
          'Amylase', _withUnit(pancreas['amylase'], pancreas['amylase_unit'])),
      _line('AFP', _withUnit(markers['afp'], markers['afp_unit'])),
      _line('CA 15-3', _withUnit(markers['ca15_3'], markers['ca15_3_unit'])),
      _line('CA 27.29', _withUnit(markers['ca27_29'], markers['ca27_29_unit'])),
    ].whereType<String>().toList();
  }

  static List<String> _indicatorLines(List<HealthMetric> metrics) {
    if (metrics.isEmpty) return ['No indicators calculated yet.'];
    return [
      for (final metric in metrics)
        '${metric.indexName}: ${metric.scoreText}${metric.unit.isEmpty ? '' : ' ${metric.unit}'} - ${metric.statusLabel}',
    ];
  }

  static List<String> _organLines(List<OrganSnapshot> snapshots) {
    return [
      for (final organ in snapshots)
        '${organ.name}: ${organ.statusLabel} (${organ.primaryText})',
    ];
  }

  static List<String> _recommendationLines(List<HealthMetric> metrics) {
    final output = <String>{};
    for (final metric in metrics) {
      final source = metric.source ?? const <String, dynamic>{};
      final ai = source['ai_recommendation'] is Map
          ? Map<String, dynamic>.from(source['ai_recommendation'] as Map)
          : const <String, dynamic>{};
      for (final key in [
        'simple_summary',
        'doctor_followup',
      ]) {
        final text = (ai[key] ?? source[key])?.toString().trim();
        if (text != null && text.isNotEmpty) output.add(text);
      }
      for (final key in [
        'lifestyle_recommendations',
        'food_recommendations',
        'environment_recommendations',
        'lifestyle_improvement',
        'food_recommendations',
        'environment_recommendations',
        'suggestions',
      ]) {
        final raw = ai[key] ?? source[key];
        if (raw is List) {
          for (final item in raw) {
            final text = item.toString().trim();
            if (text.isNotEmpty) output.add(text);
          }
        }
      }
    }
    if (output.isEmpty) {
      output.add(
        'Maintain balanced meals, regular activity, good sleep, and routine clinical review for persistent abnormal values.',
      );
    }
    return output.take(10).toList();
  }

  static String? _line(String label, dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return null;
    return '$label: $text';
  }

  static String? _withUnit(dynamic value, dynamic unit) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return null;
    final unitText = unit?.toString().trim() ?? '';
    return unitText.isEmpty ? text : '$text $unitText';
  }

  static String? _height(Map<String, dynamic> profile) {
    final unit = profile['height_unit']?.toString();
    if (unit == 'ft-in') {
      final feet = profile['height_feet']?.toString();
      final inches = profile['height_inches']?.toString();
      final parts = [
        if (feet != null && feet.isNotEmpty) '$feet ft',
        if (inches != null && inches.isNotEmpty) '$inches in',
      ];
      return parts.isEmpty ? null : parts.join(' ');
    }
    return _withUnit(profile['height_input'] ?? profile['height_cm'], unit);
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static String _fileDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}${local.month.toString().padLeft(2, '0')}'
        '${local.day.toString().padLeft(2, '0')}_'
        '${local.hour.toString().padLeft(2, '0')}'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static String _safe(String text) {
    return text
        .replaceAll('•', '-')
        .replaceAll('₂', '2')
        .replaceAll('⁹', '^9')
        .replaceAll('µ', 'u')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('’', "'")
        .replaceAll('°', ' degrees');
  }
}
