import 'package:flutter/material.dart';

import 'screens/input_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/results_screen.dart';
import 'storage/local_storage.dart';
import 'styles.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalMap',
      theme: AppStyles.theme,
      home: const HomeContainer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeContainer extends StatefulWidget {
  const HomeContainer({super.key});

  @override
  State<HomeContainer> createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {
  int _currentIndex = 0;
  Map<String, dynamic>? _lastResponse;
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    _loadLastResult();
  }

  Future<void> _loadLastResult() async {
    final stored = await LocalStorage.loadLastResponse();
    if (!mounted || stored == null) return;
    setState(() {
      _lastResponse = stored['response'] as Map<String, dynamic>?;
      final timestamp = stored['timestamp'] as String?;
      _lastChecked = timestamp == null ? null : DateTime.tryParse(timestamp);
    });
  }

  void _handleAnalysisComplete(Map<String, dynamic> response) {
    setState(() {
      _lastResponse = response;
      _lastChecked = DateTime.now();
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      InputScreen(onAnalysisComplete: _handleAnalysisComplete),
      ResultsScreen(response: _lastResponse, lastChecked: _lastChecked),
      OverviewScreen(
        response: _lastResponse,
        lastChecked: _lastChecked,
        onViewResults: () => setState(() => _currentIndex = 1),
        onRecalculated: _handleAnalysisComplete,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            activeIcon: Icon(Icons.edit_note),
            label: 'Input',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Results',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Overview',
          ),
        ],
      ),
    );
  }
}
