import 'package:flutter/material.dart';
import '../storage/local_storage.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic>? response;

  ResultsScreen({this.response});

  factory ResultsScreen.fromResponse(Map<String, dynamic> resp) {
    return ResultsScreen(response: resp);
  }

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Map<String, dynamic>? resp;

  @override
  void initState() {
    super.initState();
    resp = widget.response;
    if (resp == null) {
      LocalStorage.loadLastResponse().then((v) {
        if (v != null) setState(() => resp = v['response'] as Map<String, dynamic>?);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = resp != null ? resp!['calculated_results'] as List<dynamic> : [];
    final more = resp != null ? resp!['more_data_needed'] as List<dynamic> : [];

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(children: [
            Image.asset('assets/logo.png', width: 36, height: 36, errorBuilder: (c, e, s) => SizedBox(width: 36, height: 36)),
            SizedBox(width: 8),
            Text('Results')
          ]),
        ),
        body: Padding(
          padding: EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Overall Screening Insight', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(resp != null ? resp!['overall_risk'] : 'More Data Needed', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 6),
                  Text(resp != null ? resp!['disclaimer'] : ''),
                ]),
              ),
            ),

            Expanded(
              child: ListView(
                children: [
                  ...results.map((r) => Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text('${r['index_name']} — ${r['organ']}'),
                          subtitle: Text('${r['interpretation']}\nValues used: ${r['values_used'].toString()}'),
                          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(r['score'] != null ? r['score'].toString() : '-'),
                            SizedBox(height: 4),
                            Container(padding: EdgeInsets.all(4), decoration: BoxDecoration(color: _colorFromName(r['color']), borderRadius: BorderRadius.circular(6)), child: Text(r['risk_level'], style: TextStyle(color: Colors.white)))
                          ]),
                        ),
                      )),
                  if (more.isNotEmpty)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('More Data Needed', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...more.map((m) => Text('${m['index_name']}: ${m['message']}'))
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Color _colorFromName(String name) {
    switch (name) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
