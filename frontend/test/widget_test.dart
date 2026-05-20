import 'package:flutter_test/flutter_test.dart';

import 'package:vitalmap/main.dart';

void main() {
  testWidgets('VitalMap input screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    expect(find.text('Input'), findsWidgets);
    expect(find.text('Profile Details'), findsOneWidget);
    expect(find.text('Analyze Available Values'), findsOneWidget);
  });
}
