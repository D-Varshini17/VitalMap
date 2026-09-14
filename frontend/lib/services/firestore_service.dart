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
        'inputData': profile is Map
            ? Map<String, dynamic>.from(profile)
            : <String, dynamic>{},
        'fullPayload': payload,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    setCurrent(
      'lifestyle',
      lifestyle is Map
          ? Map<String, dynamic>.from(lifestyle)
          : <String, dynamic>{},
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
      'ai': response['ai'],
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

  static Future<List<Map<String, dynamic>>> loadScreeningHistory(
    String uid, {
    int limit = 60,
  }) async {
    final snapshot = await _userDocument(uid)
        .collection('screenings')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return [
      for (final doc in snapshot.docs)
        _screeningRecord(doc.id, doc.data()),
    ];
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
      'timestamp':
          createdAt is Timestamp ? createdAt.toDate().toIso8601String() : null,
    };
  }

  static Future<String> saveLabScan({
    required String uid,
    required String fileName,
    required List<Map<String, dynamic>> fields,
    List<Map<String, dynamic>> extras = const [],
  }) async {
    final ref = _userDocument(uid).collection('lab_scans').doc();
    await ref.set({
      'scanId': ref.id,
      'fileName': fileName,
      'fields': fields,
      'extras': extras,
      'reviewedByUser': true,
      'sourceType': fileName.split('.').last.toLowerCase(),
      'importedAt': FieldValue.serverTimestamp(),
      'provider': 'ollama',
      'localAiOnly': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<int> mergeLabReportFieldsIntoDraft({
    required String uid,
    required List<Map<String, dynamic>> fields,
  }) async {
    final existing = await loadDraft(uid) ?? <String, dynamic>{};
    final payload = _deepCopy(existing);
    final selected = <String>{
      for (final value in (payload['selected_report_sections'] as List? ?? const []))
        value.toString(),
    };

    var mergedCount = 0;
    for (final field in fields) {
      final key = field['key']?.toString() ?? '';
      final section = field['section']?.toString() ?? '';
      final value = _asDouble(field['value']);
      final unit = field['unit']?.toString().trim() ?? '';
      if (key.isEmpty || section.isEmpty || value == null || unit.isEmpty) {
        continue;
      }
      final converted = _canonicalValue(key, value, unit);
      if (converted == null) continue;
      final canonicalValue = converted.$1;
      final canonicalUnit = converted.$2;
      final sectionMap = Map<String, dynamic>.from(
        payload[section] as Map? ?? const <String, dynamic>{},
      );
      sectionMap[key] = canonicalValue;
      sectionMap['${key}_unit'] = canonicalUnit;

      // Existing input UI stores both canonical values and the original
      // entered value/unit for fields that support unit switching.
      if ({
        'triglycerides',
        'hdl',
        'fasting_glucose',
        'albumin',
        'platelets',
        'creatinine',
      }.contains(key)) {
        sectionMap['${key}_input'] = value;
        sectionMap['${key}_input_unit'] = unit;
      }
      payload[section] = sectionMap;
      mergedCount++;
      final reportSection = _reportSectionFor(section);
      if (reportSection != null) selected.add(reportSection);
    }

    payload['selected_report_sections'] = selected.toList()..sort();
    await saveDraft(uid, payload);
    return mergedCount;
  }

  static Future<String> saveSymptomEntry({
    required String uid,
    required List<String> symptoms,
    required int severity,
    required int energy,
    required int sleepQuality,
    required String notes,
  }) async {
    final ref = _userDocument(uid).collection('symptoms').doc();
    await ref.set({
      'entryId': ref.id,
      'symptoms': symptoms,
      'severity': severity.clamp(0, 4),
      'energy': energy.clamp(1, 5),
      'sleepQuality': sleepQuality.clamp(1, 5),
      'notes': notes.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> symptomHistory(
    String uid,
  ) {
    return _userDocument(uid)
        .collection('symptoms')
        .orderBy('createdAt', descending: true)
        .limit(90)
        .snapshots();
  }

  static Future<List<Map<String, dynamic>>> loadSymptomHistory(
    String uid, {
    int limit = 90,
  }) async {
    final snapshot = await _userDocument(uid)
        .collection('symptoms')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return [
      for (final doc in snapshot.docs)
        {
          'id': doc.id,
          ...doc.data(),
          'timestamp': doc.data()['createdAt'] is Timestamp
              ? (doc.data()['createdAt'] as Timestamp)
                  .toDate()
                  .toIso8601String()
              : null,
        },
    ];
  }

  static Future<void> deleteSymptomEntry(String uid, String entryId) async {
    await _userDocument(uid).collection('symptoms').doc(entryId).delete();
  }

  static Map<String, dynamic> _screeningRecord(
    String id,
    Map<String, dynamic> data,
  ) {
    final createdAt = data['createdAt'];
    return {
      'id': id,
      ...data,
      'timestamp':
          createdAt is Timestamp ? createdAt.toDate().toIso8601String() : null,
      'response': data['response'] is Map
          ? Map<String, dynamic>.from(data['response'] as Map)
          : <String, dynamic>{},
      'inputData': data['inputData'] is Map
          ? Map<String, dynamic>.from(data['inputData'] as Map)
          : <String, dynamic>{},
    };
  }

  static Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    dynamic copy(dynamic value) {
      if (value is Map) {
        return <String, dynamic>{
          for (final entry in value.entries) entry.key.toString(): copy(entry.value),
        };
      }
      if (value is List) return value.map(copy).toList();
      return value;
    }

    return Map<String, dynamic>.from(copy(source) as Map);
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static (double, String)? _canonicalValue(
    String key,
    double value,
    String rawUnit,
  ) {
    final unit = rawUnit
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('μ', 'u')
        .replaceAll('µ', 'u');

    if ({'triglycerides', 'hdl'}.contains(key)) {
      if (unit.contains('mmol/l')) {
        final factor = key == 'triglycerides' ? 88.57 : 38.67;
        return (value * factor, 'mg/dL');
      }
      if (unit.contains('mg/dl')) return (value, 'mg/dL');
      return null;
    }
    if (key == 'fasting_glucose') {
      if (unit.contains('mmol/l')) return (value * 18.018, 'mg/dL');
      if (unit.contains('mg/dl')) return (value, 'mg/dL');
      return null;
    }
    if (key == 'creatinine') {
      if (unit.contains('umol/l')) return (value / 88.4, 'mg/dL');
      if (unit.contains('mg/dl')) return (value, 'mg/dL');
      return null;
    }
    if (key == 'albumin') {
      if (unit == 'g/l') return (value / 10.0, 'g/dL');
      if (unit == 'g/dl') return (value, 'g/dL');
      return null;
    }
    if (key == 'platelets') {
      if (unit.contains('10^9/l') ||
          unit.contains('10⁹/l') ||
          unit.contains('x10^9/l') ||
          unit.contains('x10⁹/l') ||
          unit.contains('k/ul') ||
          unit.contains('10^3/ul')) {
        return (value, '10⁹/L');
      }
      return null;
    }
    if ({'ast', 'alt', 'ggt', 'lipase', 'amylase'}.contains(key)) {
      if (unit.contains('u/l') || unit.contains('iu/l')) return (value, 'U/L');
      return null;
    }
    if ({'neutrophils', 'lymphocytes', 'spo2'}.contains(key)) {
      if (unit.contains('%') || (key == 'spo2' && unit.isEmpty)) {
        return (value, '%');
      }
      return null;
    }
    if (key == 'afp') {
      if (unit.contains('ng/ml')) return (value, 'ng/mL');
      return null;
    }
    if ({'ca15_3', 'ca27_29'}.contains(key)) {
      if (unit.contains('u/ml')) return (value, 'U/mL');
      return null;
    }
    return null;
  }

  static String? _reportSectionFor(String section) {
    return switch (section) {
      'lipid_profile' => 'heart',
      'diabetes_profile' => 'diabetes',
      'liver_function' => 'liver',
      'cbc' => 'cbc',
      'kidney_function' => 'kidney',
      'vitals' => 'vitals',
      'pancreatic_enzymes' => 'pancreas',
      'tumor_markers' => 'cancer',
      _ => null,
    };
  }
}
