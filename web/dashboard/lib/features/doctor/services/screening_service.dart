import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/screening_model.dart';
import '../models/ai_case_model.dart';

class ScreeningService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _firestore.collection('patients');

  /// Get current logged-in doctor's ID
  static String? get _currentDoctorId => _auth.currentUser?.uid;

  /// Verify patient belongs to logged-in doctor
  static Future<bool> _verifyPatientOwnership(String patientId) async {
    final doctorId = _currentDoctorId;
    if (doctorId == null) return false;

    final patientDoc = await _patientsRef.doc(patientId).get();
    if (!patientDoc.exists) return false;

    return patientDoc.data()?['selectedDoctor'] == doctorId;
  }

  /// Fetch all screenings for a specific patient (with ownership check)
  static Future<List<ScreeningModel>> fetchScreeningsForPatient(
    String patientId,
  ) async {
    try {
      // HIPAA: Verify patient belongs to this doctor
      final hasAccess = await _verifyPatientOwnership(patientId);
      if (!hasAccess) {
        debugPrint("⚠️ Access denied: Patient not assigned to this doctor");
        return [];
      }

      final snapshot = await _patientsRef
          .doc(patientId)
          .collection('screenings')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ScreeningModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("❌ Error fetching screenings for $patientId: $e");
      return [];
    }
  }

  /// Fetch AI-flagged cases for doctor dashboard (only assigned patients)
  static Future<List<AiCaseModel>> fetchAiCasesForDoctorDashboard({
    int limitPerPatient = 1,
  }) async {
    final List<AiCaseModel> allCases = [];

    try {
      final doctorId = _currentDoctorId;
      if (doctorId == null) {
        debugPrint("⚠️ No authenticated doctor found");
        return [];
      }

      // HIPAA: Only fetch patients assigned to this doctor
      final patientsSnapshot = await _patientsRef
          .where('selectedDoctor', isEqualTo: doctorId)
          .get();

      // PERFORMANCE OPTIMIZATION:
      // Instead of awaiting each patient's screening sequentially (N+1 bottleneck),
      // we map them to futures and await them all concurrently.
      final futures = patientsSnapshot.docs.map((patientDoc) async {
        final patientId = patientDoc.id;
        final patientName = patientDoc['name'] ?? '';
        final List<AiCaseModel> patientCases = [];

        try {
          final screeningsSnapshot = await patientDoc.reference
              .collection('screenings')
              .orderBy('timestamp', descending: true)
              .limit(limitPerPatient)
              .get();

          for (final screeningDoc in screeningsSnapshot.docs) {
            try {
              final caseModel = AiCaseModel.fromFirestore(
                screeningDoc,
                patientId,
                patientName,
              );
              patientCases.add(caseModel);
            } catch (e) {
              debugPrint("❌ Error parsing screening for $patientId: $e");
            }
          }
        } catch (e) {
          debugPrint("❌ Error fetching screenings for $patientId: $e");
        }
        
        return patientCases;
      });

      // Wait for all patient queries to resolve simultaneously
      final results = await Future.wait(futures);
      
      // Flatten the list of lists
      for (final cases in results) {
        allCases.addAll(cases);
      }

      allCases.sort((a, b) => b.date.compareTo(a.date));
      return allCases;
    } catch (e) {
      debugPrint("❌ Error fetching AI cases: $e");
      return [];
    }
  }

  /// Create a new screening under a patient (with ownership check)
  static Future<bool> createScreening({
    required String patientId,
    required String screeningId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // HIPAA: Verify patient belongs to this doctor
      final hasAccess = await _verifyPatientOwnership(patientId);
      if (!hasAccess) {
        debugPrint("⚠️ Access denied: Patient not assigned to this doctor");
        return false;
      }

      final docRef = _patientsRef
          .doc(patientId)
          .collection('screenings')
          .doc(screeningId);

      await docRef.set({
        ...data,
        'screeningId': screeningId,
        'timestamp': Timestamp.now(),
      });

      return true;
    } catch (e) {
      debugPrint("❌ Error creating screening for $patientId: $e");
      return false;
    }
  }

  /// Fetch latest diagnosis status for a specific screening (with ownership check)
  /// Returns a map with: status, notes, requestedTest
  static Future<Map<String, dynamic>?> fetchLatestDiagnosisStatus({
    required String patientId,
    required String screeningId,
  }) async {
    try {
      // HIPAA: Verify patient belongs to this doctor
      final hasAccess = await _verifyPatientOwnership(patientId);
      if (!hasAccess) {
        debugPrint("⚠️ Access denied: Patient not assigned to this doctor");
        return null;
      }

      final diagnosisSnapshot = await _patientsRef
          .doc(patientId)
          .collection('screenings')
          .doc(screeningId)
          .collection('diagnosis')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (diagnosisSnapshot.docs.isEmpty) {
        return null;
      }

      final data = diagnosisSnapshot.docs.first.data();
      return {
        'status': (data['status'] ?? '') as String,
        'notes': (data['notes'] ?? '') as String?,
        'requestedTest': (data['requestedTest'] ?? '') as String?,
      };
    } catch (e) {
      debugPrint("❌ Error fetching diagnosis status for $patientId/$screeningId: $e");
      return null;
    }
  }
}