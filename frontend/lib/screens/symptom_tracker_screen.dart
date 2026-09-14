import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../services/firestore_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/simple_trend_chart.dart';

class SymptomTrackerScreen extends StatefulWidget {
  const SymptomTrackerScreen({super.key});

  @override
  State<SymptomTrackerScreen> createState() => _SymptomTrackerScreenState();
}

class _SymptomTrackerScreenState extends State<SymptomTrackerScreen> {
  static const _symptomOptions = <String>[
    'Fatigue',
    'Headache',
    'Dizziness',
    'Breathlessness',
    'Digestive discomfort',
    'Muscle / body ache',
    'Poor appetite',
    'Other',
  ];

  final _notesController = TextEditingController();
  final Set<String> _selectedSymptoms = <String>{};
  int _severity = 1;
  int _energy = 3;
  int _sleep = 3;
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final user = Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(title: const BrandAppBarTitle(title: 'Daily Check-in')),
      body: user == null
          ? _message('Sign in to use Daily Check-in.')
          : ResponsivePage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _purposeCard(),
                  const SizedBox(height: 16),
                  _entryCard(user.uid),
                  const SizedBox(height: 22),
                  _historySection(user.uid),
                  const SizedBox(height: 26),
                ],
              ),
            ),
    );
  }

  Widget _purposeCard() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_border, color: colors.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Why Daily Check-in exists', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  'This optional check-in adds day-to-day context between lab screenings. Energy, sleep and selected symptoms appear in History and can be supplied to Local Ollama when it generates wellness guidance. Check-ins never change VitalMap formula scores or risk labels.',
                  style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryCard(String uid) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you feeling today?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Keep it quick. You can leave symptoms empty and record only energy/sleep.', style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(height: 18),
          _scaleSelector(
            title: 'Energy',
            value: _energy,
            max: 5,
            lowLabel: 'Low',
            highLabel: 'High',
            onChanged: (value) => setState(() => _energy = value),
          ),
          const SizedBox(height: 16),
          _scaleSelector(
            title: 'Sleep quality',
            value: _sleep,
            max: 5,
            lowLabel: 'Poor',
            highLabel: 'Restful',
            onChanged: (value) => setState(() => _sleep = value),
          ),
          const SizedBox(height: 18),
          const Text('Symptoms today (optional)', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final symptom in _symptomOptions)
                FilterChip(
                  label: Text(symptom),
                  selected: _selectedSymptoms.contains(symptom),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _selectedSymptoms.add(symptom);
                    } else {
                      _selectedSymptoms.remove(symptom);
                    }
                  }),
                ),
            ],
          ),
          if (_selectedSymptoms.isNotEmpty) ...[
            const SizedBox(height: 16),
            _scaleSelector(
              title: 'Overall symptom intensity',
              value: _severity,
              max: 4,
              lowLabel: 'Mild',
              highLabel: 'Strong',
              onChanged: (value) => setState(() => _severity = value),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'Optional note',
              hintText: 'Anything useful to remember about today',
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : () => _save(uid),
              icon: _saving
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_saving ? 'Saving...' : 'Save today’s check-in'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scaleSelector({
    required String title,
    required int value,
    required int max,
    required String lowLabel,
    required String highLabel,
    required ValueChanged<int> onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
            Text('$value / $max', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 1; i <= max; i++) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ChoiceChip(
                    label: SizedBox(width: double.infinity, child: Text('$i', textAlign: TextAlign.center)),
                    selected: value == i,
                    onSelected: (_) => onChanged(i),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(lowLabel, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
            Text(highLabel, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _historySection(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.symptomHistory(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final records = [
          for (final doc in docs)
            {
              'id': doc.id,
              ...doc.data(),
              'date': (doc.data()['createdAt'] as Timestamp?)?.toDate(),
            },
        ];
        final recent = records.take(14).toList().reversed.toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent pattern', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              records.isEmpty
                  ? 'Save a few check-ins to see energy, sleep and symptom frequency here.'
                  : 'These patterns are context only. They do not change your deterministic screening results.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (records.isEmpty)
              _message('No Daily Check-ins saved yet.')
            else ...[
              _patternSummary(records),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;
                  final energy = _trendCard(
                    'Energy trend',
                    recent,
                    'energy',
                    Icons.bolt_outlined,
                  );
                  final sleep = _trendCard(
                    'Sleep-quality trend',
                    recent,
                    'sleepQuality',
                    Icons.bedtime_outlined,
                  );
                  if (compact) return Column(children: [energy, const SizedBox(height: 10), sleep]);
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: energy), const SizedBox(width: 10), Expanded(child: sleep)]);
                },
              ),
              const SizedBox(height: 18),
              const Text('Recent check-ins', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 8),
              for (final record in records.take(8)) _checkInTile(uid, record),
            ],
          ],
        );
      },
    );
  }

  Widget _patternSummary(List<Map<String, dynamic>> records) {
    final colors = Theme.of(context).colorScheme;
    final seven = records.take(7).toList();
    final avgEnergy = _average(seven, 'energy');
    final avgSleep = _average(seven, 'sleepQuality');
    final symptomCounts = <String, int>{};
    for (final record in seven) {
      for (final symptom in (record['symptoms'] as List? ?? const [])) {
        final key = symptom.toString();
        symptomCounts[key] = (symptomCounts[key] ?? 0) + 1;
      }
    }
    final frequent = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _patternChip(Icons.bolt_outlined, '7-day energy', avgEnergy == null ? '—' : '${avgEnergy.toStringAsFixed(1)} / 5'),
          _patternChip(Icons.bedtime_outlined, '7-day sleep', avgSleep == null ? '—' : '${avgSleep.toStringAsFixed(1)} / 5'),
          _patternChip(
            Icons.notes_outlined,
            'Most logged',
            frequent.isEmpty ? 'No symptoms' : '${frequent.first.key} (${frequent.first.value}×)',
          ),
        ],
      ),
    );
  }

  Widget _patternChip(IconData icon, String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(height: 7),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _trendCard(String title, List<Map<String, dynamic>> records, String key, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    final points = <TrendPoint>[];
    for (final record in records) {
      final value = record[key];
      final date = record['date'];
      if (value is num && date is DateTime) {
        points.add(TrendPoint(label: '${date.day}/${date.month}', value: value.toDouble()));
      }
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: colors.primary), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900))]),
          const SizedBox(height: 8),
          SimpleTrendChart(points: points, height: 180),
        ],
      ),
    );
  }

  Widget _checkInTile(String uid, Map<String, dynamic> record) {
    final colors = Theme.of(context).colorScheme;
    final date = record['date'] as DateTime?;
    final symptoms = (record['symptoms'] as List? ?? const []).map((e) => e.toString()).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(13)),
          child: Icon(Icons.favorite_outline, color: colors.primary),
        ),
        title: Text(date == null ? 'Daily Check-in' : _formatDate(date), style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          'Energy ${record['energy'] ?? '—'}/5 • Sleep ${record['sleepQuality'] ?? '—'}/5${symptoms.isEmpty ? ' • No symptoms selected' : ' • ${symptoms.join(', ')}'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: 'Delete check-in',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => FirestoreService.deleteSymptomEntry(uid, record['id'].toString()),
        ),
      ),
    );
  }

  Future<void> _save(String uid) async {
    setState(() => _saving = true);
    try {
      await FirestoreService.saveSymptomEntry(
        uid: uid,
        symptoms: _selectedSymptoms.toList()..sort(),
        severity: _selectedSymptoms.isEmpty ? 0 : _severity,
        energy: _energy,
        sleepQuality: _sleep,
        notes: _notesController.text,
      );
      if (!mounted) return;
      setState(() {
        _selectedSymptoms.clear();
        _severity = 1;
        _energy = 3;
        _sleep = 3;
        _notesController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily Check-in saved.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save check-in: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double? _average(List<Map<String, dynamic>> records, String key) {
    final values = records.map((e) => e[key]).whereType<num>().map((e) => e.toDouble()).toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Widget _message(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
