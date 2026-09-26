import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalmap/screens/input_screen.dart';
import 'package:vitalmap/storage/local_storage.dart';
import 'package:vitalmap/styles.dart';

void main() {
  for (final dark in [false, true]) {
    for (final width in [360.0, 390.0, 430.0, 768.0, 1366.0]) {
      testWidgets('All Input steps and lab fields at $width, dark=$dark',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        await LocalStorage.saveLastPayload({
          'selected_report_sections': [
            'heart',
            'diabetes',
            'liver',
            'cbc',
            'kidney',
            'vitals',
            'pancreas',
            'cancer'
          ],
          'profile': {'age': 45, 'sex': 'Female'},
        });
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          theme: dark ? AppStyles.darkTheme : AppStyles.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(width == 360 ? 1.3 : 1)),
            child: child!,
          ),
          home: InputScreen(onAnalysisComplete: (_) {}),
        ));
        await tester.pumpAndSettle();
        for (final step in [
          'Basic profile',
          'Lifestyle',
          'Environment',
          'Reports'
        ]) {
          final tab = find.text(step).first;
          await tester.ensureVisible(tab);
          await tester.tap(tab);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: step);
          final fields = find.byType(TextFormField).evaluate().toList();
          for (final field in fields) {
            await tester.ensureVisible(find.byWidget(field.widget));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$step field');
          }
          if (step == 'Reports') {
            for (final title in [
              'Heart / Lipid Profile',
              'Diabetes / Glucose Profile',
              'Liver Function Test',
              'CBC / Differential',
              'Kidney Function',
              'Lungs / Vitals',
              'Pancreatic Enzymes',
              'Cancer Awareness'
            ]) {
              expect(find.text(title), findsWidgets);
            }
            expect(fields, isNotEmpty);
          }
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
