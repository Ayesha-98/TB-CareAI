import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/recommendation_model.dart';

class RecommendationService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _uuid = Uuid();

  /// Get current logged-in doctor's ID
  static String? get _currentDoctorId => _auth.currentUser?.uid;

  /// Add a recommendation for the latest screening of a patient
  static Future<void> addRecommendation({
    required String patientId,
    required String doctorId,
    required String medicalAdvice,
    required String lifestyleAdvice,
  }) async {
    final now = DateTime.now();

    // ✅ Use `date` for screenings, not createdAt
    final screeningSnapshot = await _firestore
        .collection('patients')
        .doc(patientId)
        .collection('screenings')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (screeningSnapshot.docs.isEmpty) {
      throw Exception("No active screening found for this patient");
    }

    final screeningId = screeningSnapshot.docs.first.id;
    final recommendationId = _uuid.v4();

    final recommendationRef = _firestore
        .collection('patients')
        .doc(patientId)
        .collection('screenings')
        .doc(screeningId)
        .collection('recommendations')
        .doc(recommendationId);

    final doctorRef = _firestore.collection('doctors').doc(doctorId);

    final batch = _firestore.batch();

    batch.set(recommendationRef, {
      'recommendationId': recommendationId,
      'medicalAdvice': medicalAdvice,
      'lifestyleAdvice': lifestyleAdvice,
      'addedBy': doctorId,
      'approvedBy': doctorId,
      'createdAt': now,
    });

    batch.set(
      doctorRef,
      {
        'totalRecommendationsGiven': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Get the latest screeningId of a patient
  static Future<String?> fetchLatestScreeningId(String patientId) async {
    final snapshot = await _firestore
        .collection('patients')
        .doc(patientId)
        .collection('screenings')
        .orderBy('timestamp', descending: true) // ✅ correct field
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id;
  }

  /// Stream recommendations for a given screening
  static Stream<List<RecommendationModel>> fetchRecommendations(
    String patientId,
    String screeningId,
  ) {
    final doctorId = _currentDoctorId;
    if (doctorId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('patients')
        .doc(patientId)
        .collection('screenings')
        .doc(screeningId)
        .collection('recommendations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          // Verify patient belongs to logged-in doctor
          final patientDoc = await _firestore
              .collection('patients')
              .doc(patientId)
              .get();

          if (!patientDoc.exists) return [];

          final selectedDoctor = patientDoc.data()?['selectedDoctor'];

          if (selectedDoctor != doctorId) {
            return [];
          }

          return snapshot.docs
              .map((doc) => RecommendationModel.fromMap(doc.data()))
              .toList();
        });
  }
}