import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lab_test_model.dart';

class LabTestService {
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

  static CollectionReference<Map<String, dynamic>> _labTestsRef(
    String patientId,
    String screeningId,
  ) {
    return _patientsRef
        .doc(patientId)
        .collection('screenings')
        .doc(screeningId)
        .collection('labTests');
  }

  /// Create a new lab test document (with ownership check)
  static Future<bool> createLabTest({
    required String patientId,
    required String screeningId,
    required LabTestModel test,
  }) async {
    try {
      // HIPAA: Verify patient belongs to this doctor
      final hasAccess = await _verifyPatientOwnership(patientId);
      if (!hasAccess) {
        print("⚠️ Access denied: Patient not assigned to this doctor");
        return false;
      }

      await _labTestsRef(patientId, screeningId)
          .doc(test.labTestId)
          .set(test.toMap());
      return true;
    } catch (e) {
      print('❌ Error creating lab test: $e');
      rethrow;
    }
  }

  /// Get all lab tests for a given screening (with ownership check)
  static Future<List<LabTestModel>> getLabTests({
    required String patientId,
    required String screeningId,
  }) async {
    try {
      // HIPAA: Verify patient belongs to this doctor
      final hasAccess = await _verifyPatientOwnership(patientId);
      if (!hasAccess) {
        print("⚠️ Access denied: Patient not assigned to this doctor");
        return [];
      }

      final snapshot = await _labTestsRef(patientId, screeningId)
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LabTestModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error fetching lab tests: $e');
      rethrow;
    }
  }

  /// Update the status of a specific lab test (with ownership check)
  static Future<bool> updateLabTestStatus({
    required String patientId,
    required String screeningId,
    required String labTestId,
    required String status, // Pending / Uploaded
    String? fileUrl,
    String? comments,
  }) async {
    try {
      // HIPAA: Verify patient belongs to this doctor
      final hasAccess = await _verifyPatientOwnership(patientId);
      if (!hasAccess) {
        print("⚠️ Access denied: Patient not assigned to this doctor");
        return false;
      }

      final updateData = {
        'status': status,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (comments != null) 'comments': comments,
        if (status == 'Uploaded') 'uploadedAt': Timestamp.now(),
      };

      await _labTestsRef(patientId, screeningId)
          .doc(labTestId)
          .update(updateData);
      return true;
    } catch (e) {
      print('❌ Error updating lab test $labTestId: $e');
      rethrow;
    }
  }
}