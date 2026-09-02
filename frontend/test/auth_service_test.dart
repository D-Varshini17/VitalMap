import 'package:flutter_test/flutter_test.dart';

import 'package:vitalmap/services/auth_service.dart';

void main() {
  test('uses the Android emulator host for local backend requests', () {
    expect(
      AuthService.resolveBaseUrlForPlatform(isAndroid: true),
      'http://10.0.2.2:5000',
    );
  });

  test('keeps localhost for non-Android platforms', () {
    expect(
      AuthService.resolveBaseUrlForPlatform(isAndroid: false),
      'http://127.0.0.1:5000',
    );
  });
}
