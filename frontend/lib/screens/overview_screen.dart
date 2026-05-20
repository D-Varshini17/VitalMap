import 'package:flutter/material.dart';
import '../storage/local_storage.dart';
import '../services/api_service.dart';
import '../widgets/status_card.dart';

class OverviewScreen extends StatefulWidget {
  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  Map<String, dynamic>? lastRespWithMeta;
  Map<String, dynamic>? lastPayload;
  bool recalculating = false;

  @override
  void initState() {
    super.initState();
    LocalStorage.loadLastResponse().then((v) {
      if (v != null) setState(() => lastRespWithMeta = v);
    });
    LocalStorage.loadLastPayload().then((p) {
      if (p != null) setState(() => lastPayload = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final response = lastRespWithMeta != null
        ? lastRespWithMeta!['response'] as Map<String, dynamic>
        : null;
    final results =
        response != null ? response['calculated_results'] as List<dynamic> : [];
    // organs to show
    final organs = [
      'Heart',
      'Kidney',
      'Liver',
      'Lung',
      'Brain / Metabolic',
      'Pancreas',
      'Inflammation',
      'Cancer Awareness'
    ];

    List<Widget> cards = organs.map((organ) {
      final orgResults = results.where((r) => r['organ'] == organ).toList();
      String status = 'More data needed';
      Color color = Colors.grey;
      if (orgResults.isNotEmpty) {
        // find highest severity
        if (orgResults.any((r) => r['risk_level'] == 'High')) {
          status = 'High';
          color = Colors.red;
        } else if (orgResults.any((r) =>
            r['risk_level'] == 'Moderate' ||
            r['risk_level'] == 'Moderate monitoring suggested')) {
          status = 'Moderate';
          color = Colors.orange;
        } else if (orgResults.any((r) =>
            r['risk_level'] == 'Low' || r['risk_level'] == 'Low concern')) {
          status = 'Low';
          color = Colors.green;
        } else {
          status = orgResults.map((r) => r['risk_level']).join(', ');
          color = Colors.grey;
        }
      }
      return StatusCard(
        title: organ,
        subtitle: orgResults.isNotEmpty
            ? orgResults.map((r) => r['index_name']).take(2).join(', ')
            : 'No data available',
        color: color,
        status: status,
        trailing: ElevatedButton(
          onPressed: (lastPayload == null || recalculating)
              ? null
              : () async {
                  setState(() {
                    recalculating = true;
                  });
                  final resp = await ApiService.analyze(lastPayload!);
                  if (resp != null) {
                    await LocalStorage.saveLastResponse(resp);
                    final v = await LocalStorage.loadLastResponse();
                    setState(() {
                      lastRespWithMeta = v;
                      recalculating = false;
                    });
                  } else {
                    setState(() {
                      recalculating = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Unable to recalculate. Check connection.')));
                  }
                },
          child: recalculating
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text('Recalculate'),
        ),
      );
    }).toList();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(children: [
            Icon(Icons.health_and_safety, size: 32),
            SizedBox(width: 8),
            Text('Overview')
          ]),
        ),
        body: Padding(
          padding: EdgeInsets.all(12),
          child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: cards),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
              'For informational purposes only. This app is not a substitute for clinical diagnosis.',
              textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
