import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vitalmap/core/responsive.dart';
import 'package:vitalmap/main.dart';

void main() {
  test('responsive breakpoints classify phone, tablet, and desktop widths', () {
    expect(Responsive.sizeForWidth(390), ResponsiveSize.mobile);
    expect(Responsive.sizeForWidth(800), ResponsiveSize.tablet);
    expect(Responsive.sizeForWidth(1440), ResponsiveSize.desktop);
  });

  testWidgets('VitalMap input screen loads', (WidgetTester tester) async {
    await _openApp(tester);

    expect(find.text('Input'), findsWidgets);
    expect(find.text('Basic Profile'), findsWidgets);
    expect(find.text('Analyze Available Values'), findsOneWidget);
  });

  testWidgets('desktop input screen uses the two-column workspace',
      (WidgetTester tester) async {
    await _setViewport(tester, const Size(1440, 1000));
    await _openApp(tester);

    expect(find.byKey(const ValueKey('desktop-input-columns')), findsOneWidget);
  });

  testWidgets('phone input screen keeps the stacked workspace',
      (WidgetTester tester) async {
    await _setViewport(tester, const Size(390, 844));
    await _openApp(tester);

    expect(find.byKey(const ValueKey('desktop-input-columns')), findsNothing);
  });
}

Future<void> _openApp(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pump(const Duration(milliseconds: 3800));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
