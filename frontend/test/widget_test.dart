import 'package:flutter_test/flutter_test.dart';

import 'package:vitalmap/main.dart';

void main() {
  testWidgets('VitalMap input screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 3800));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Input'), findsWidgets);
    expect(find.text('Basic Profile'), findsOneWidget);
    expect(find.text('Analyze Available Values'), findsOneWidget);
  });
}
