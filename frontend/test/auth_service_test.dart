import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vitalmap/services/auth_service.dart';

void main() {
  test('maps invalid credentials to a useful message', () {
    expect(
      AuthService.messageFor(
        FirebaseAuthException(code: 'invalid-credential'),
      ),
      'The email or password is incorrect.',
    );
  });

  test('maps duplicate accounts to a useful message', () {
    expect(
      AuthService.messageFor(
        FirebaseAuthException(code: 'email-already-in-use'),
      ),
      'An account already exists for this email.',
    );
  });
}
