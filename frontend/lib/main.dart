import 'package:flutter/material.dart';
import 'screens/input_screen.dart';
import 'screens/results_screen.dart';
import 'screens/overview_screen.dart';
import 'styles.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalMap',
      theme: AppStyles.theme,
      home: HomeContainer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeContainer extends StatefulWidget {
  @override
  _HomeContainerState createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {
  int _currentIndex = 0;
  final _pages = [InputScreen(), ResultsScreen(), OverviewScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Input'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Results'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
        ],
      ),
    );
  }
}
