import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return {'success': true, 'message': 'Signed in successfully.'};
    } on FirebaseAuthException catch (error) {
      return {'success': false, 'message': messageFor(error)};
    } catch (_) {
      return {'success': false, 'message': 'Firebase is unavailable right now.'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final createdUser = credential.user;
      await createdUser?.updateDisplayName(fullName.trim());
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirestoreService.ensureUserProfile(user, fullName: fullName);
        } on FirebaseException catch (error) {
          return {
            'success': false,
            'message': 'Account created, but your profile could not be saved: ${firestoreMessageFor(error)}',
          };
        }
      }
      return {'success': true, 'message': 'Account created successfully.'};
    } on FirebaseAuthException catch (error) {
      return {'success': false, 'message': messageFor(error)};
    } on FirebaseException catch (error) {
      return {'success': false, 'message': firestoreMessageFor(error)};
    } catch (_) {
      return {'success': false, 'message': 'Unable to create your account right now.'};
    }
  }

  static Future<Map<String, dynamic>> sendPasswordResetEmail(
    String email,
  ) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Password reset email sent.'};
    } on FirebaseAuthException catch (error) {
      return {'success': false, 'message': messageFor(error)};
    } catch (_) {
      return {'success': false, 'message': 'Firebase is unavailable right now.'};
    }
  }

  static Future<void> signOut() => FirebaseAuth.instance.signOut();

  static String messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'The email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  static String firestoreMessageFor(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firestore rejected the profile write. Deploy firestore.rules and check that you are signed in.';
      case 'failed-precondition':
        return 'Firestore is not enabled for this Firebase project.';
      case 'unavailable':
        return 'Firestore is temporarily unavailable. Check your internet connection.';
      default:
        return error.message ?? 'Firestore could not save your profile.';
    }
  }
}
