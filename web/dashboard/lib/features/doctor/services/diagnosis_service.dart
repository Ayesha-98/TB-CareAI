import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/diagnosis_model.dart';
import '../models/lab_test_model.dart';
import 'doctor_service.dart';

class DiagnosisService {
  static final _firestore = FirebaseFirestore.instance;
  static final _uuid = const Uuid();

  static CollectionReference<Map<String, dynamic>> _patientRef(String patientId) =>
      _firestore.collection('patients').doc(patientId).collection('screenings');

  /// Save doctor’s initial diagnosis (with/without lab test request)
  static Future<void> saveDiagnosisAndLabTest({
    required String patientId,
    required String screeningId,
    required String doctorId,
    required String diagnosis, // TB / Not TB / Needs Lab Test
    String? notes,
    String? requestedTest,
  }) async {
    try {
      final diagnosisId = _uuid.v4();
      final diagnosisRef = _patientRef(patientId)
          .doc(screeningId)
          .collection('diagnosis')
          .doc(diagnosisId);

      final screeningRef = _patientRef(patientId).doc(screeningId);
      final patientRef = _firestore.collection('patients').doc(patientId);

      bool labTestRequested = false;

      await _firestore.runTransaction((transaction) async {
        // Create diagnosis entry
        final diagnosisModel = DiagnosisModel(
          diagnosisId: diagnosisId,
          doctorId: doctorId,
          status: diagnosis == 'Needs Lab Test' ? 'Needs Lab Test' : diagnosis,
          notes: notes,
          requestedTests: requestedTest != null ? [requestedTest] : [],
          reviewable: diagnosis == 'Needs Lab Test',
          verdictGiven: diagnosis != 'Needs Lab Test',
          createdAt: DateTime.now(),
        );
        transaction.set(diagnosisRef, diagnosisModel.toMap());

        // If lab test requested
        if (diagnosis == 'Needs Lab Test' && requestedTest != null) {
          final labTestId = _uuid.v4();
          final labTestRef = screeningRef.collection('labTests').doc(labTestId);

          final labTestModel = LabTestModel(
            labTestId: labTestId,
            testName: requestedTest,
            fileUrl: null,
            status: 'Pending',
            comments: null,
            requestedAt: DateTime.now(),
            uploadedAt: null,
          );
          transaction.set(labTestRef, labTestModel.toMap());
          labTestRequested = true;
        }

        // Update screening
        transaction.update(screeningRef, {
          'status': diagnosis,
          'finalDiagnosis': diagnosis == 'Needs Lab Test' ? null : diagnosis,
          'doctorDiagnosis': diagnosis == 'Needs Lab Test' ? null : diagnosis,
          'diagnosedBy': doctorId,
          'doctorNotes': notes,
        });

        // Update patient status consistently across all levels
        transaction.update(patientRef, {'diagnosisStatus': diagnosis});
      });

      // 🔗 Update doctor stats
      await DoctorService.recordDiagnosis(
        diagnosisId: diagnosisId,
        finalDiagnosis: diagnosis,
        patientId: patientId,
        screeningId: screeningId,
        labTestRequested: labTestRequested,
      );
    } catch (e) {
      debugPrint('❌ Error saving diagnosis: $e');
      rethrow;
    }
  }

  /// Update final verdict after reviewing lab results
  static Future<void> updateFinalVerdict({
    required String patientId,
    required String screeningId,
    required String doctorId,
    required String status, // TB / Not TB
    String? notes,
  }) async {
    try {
      final diagnosisCollection =
          _patientRef(patientId).doc(screeningId).collection('diagnosis');

      final screeningRef = _patientRef(patientId).doc(screeningId);
      final patientRef = _firestore.collection('patients').doc(patientId);
      final doctorRef = _firestore.collection('doctors').doc(doctorId);

      // Query must be performed outside the transaction to get the reference
      final querySnapshot = await diagnosisCollection
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('No diagnosis found to update');
      }

      final diagnosisRef = querySnapshot.docs.first.reference;

      await _firestore.runTransaction((transaction) async {
        // Read Phase: Get the document within the transaction to lock it
        final diagnosisDoc = await transaction.get(diagnosisRef);

        if (!diagnosisDoc.exists) {
          throw Exception('Diagnosis document no longer exists');
        }

        // Write Phase
        // Update diagnosis doc
        transaction.update(diagnosisRef, {
          'status': status,
          'notes': notes,
          'verdictGiven': true,
        });

        // Update screening doc
        transaction.update(screeningRef, {
          'finalDiagnosis': status,
          'doctorDiagnosis': status, // Added as requested
          'status': status,
          'doctorNotes': notes,
        });

        // Update patient
        transaction.update(patientRef, {'diagnosisStatus': status});

        // Update doctor stats: Final verdict counter
        transaction.update(doctorRef, {
          'totalFinalVerdicts': FieldValue.increment(1),
        });
      });

      // Doctor stats updated in transaction
    } catch (e) {
      debugPrint('❌ Error updating final verdict: $e');
      rethrow;
    }
  }
}
