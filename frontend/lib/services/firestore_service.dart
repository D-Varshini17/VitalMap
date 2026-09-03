import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _userDocument(String uid) =>
      _db.collection('users').doc(uid);

  static Future<void> ensureUserProfile(
    User user, {
    String? fullName,
  }) async {
    final ref = _userDocument(user.uid);
    final existing = await ref.get();
    final data = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'emailVerified': user.emailVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!existing.exists) {
      data.addAll({
        'fullName': (fullName ?? user.displayName ?? '').trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingCompleted': false,
        'notificationEnabled': false,
        'profileCompleted': false,
      });
    }
    await ref.set(data, SetOptions(merge: true));
  }

  static Future<void> saveDraft(
    String uid,
    Map<String, dynamic> payload,
  ) async {
    final user = _userDocument(uid);
    final batch = _db.batch();
    final profile = payload['profile'];
    final lifestyle = payload['general_health'];
    final reports = <String, dynamic>{};
    for (final entry in payload.entries) {
      if (!{
        'selected_report_sections',
        'profile',
        'general_health',
      }.contains(entry.key)) {
        reports[entry.key] = entry.value;
      }
    }
    final environment = lifestyle is Map
        ? <String, dynamic>{
            for (final key in [
              'air_pollution',
              'occupational_exposure',
              'passive_smoking',
              'cooking_smoke',
              'cooking_fuel_smoke',
              'location_type',
            ])
              if (lifestyle[key] != null) key: lifestyle[key],
          }
        : <String, dynamic>{};

    void setCurrent(String collection, Map<String, dynamic> data) {
      batch.set(
        user.collection(collection).doc('current'),
        {
          'inputData': data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    batch.set(
      user.collection('health_profile').doc('current'),
      {
        'inputData':
            profile is Map ? Map<String, dynamic>.from(profile) : <String, dynamic>{},
        'fullPayload': payload,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    setCurrent(
      'lifestyle',
      lifestyle is Map ? Map<String, dynamic>.from(lifestyle) : <String, dynamic>{},
    );
    setCurrent('environment', environment);
    setCurrent('reports', {
      'selected_report_sections': payload['selected_report_sections'],
      ...reports,
    });
    await batch.commit();
  }

  static Future<Map<String, dynamic>?> loadDraft(String uid) async {
    final snapshot = await _userDocument(uid)
        .collection('health_profile')
        .doc('current')
        .get();
    final document = snapshot.data();
    final data = document?['fullPayload'] ?? document?['inputData'];
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static Future<String> saveScreening({
    required String uid,
    required Map<String, dynamic> payload,
    required Map<String, dynamic> response,
  }) async {
    final ref = _userDocument(uid).collection('screenings').doc();
    await ref.set({
      'screeningId': ref.id,
      'inputData': payload,
      'resultData': response,
      'calculatedValues': response['calculated_results'],
      'organScores': response['organ_scores'],
      'riskLevels': response['risk_levels'],
      'overallRisk': response['overall_risk'],
      'explanations': response['explanations'],
      'recommendationSummary': response['recommendation'],
      'warningFlags': response['warning_flags'],
      'response': response,
      'algorithmVersion': 'v1',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> screeningHistory(
    String uid,
  ) {
    return _userDocument(uid)
        .collection('screenings')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<Map<String, dynamic>?> loadLatestScreening(String uid) async {
    final snapshot = await _userDocument(uid)
        .collection('screenings')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final data = snapshot.docs.first.data();
    final response = data['response'];
    if (response is! Map) return null;
    final createdAt = data['createdAt'];
    return {
      'response': Map<String, dynamic>.from(response),
      'payload': data['inputData'],
      'timestamp': createdAt is Timestamp
          ? createdAt.toDate().toIso8601String()
          : null,
    };
  }
}
