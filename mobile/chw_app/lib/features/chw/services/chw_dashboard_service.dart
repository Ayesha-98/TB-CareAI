import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbcare_main/features/chw/models/chw_dashboard_patient_model.dart';

class CHWDashboardService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User get currentUser => _auth.currentUser!;

  CollectionReference<Map<String, dynamic>> get _chwDoc =>
      _firestore.collection('chws');

  DocumentReference<Map<String, dynamic>> get _meDoc =>
      _chwDoc.doc(currentUser.uid);

  CollectionReference<Map<String, dynamic>> get _assignedPatients =>
      _meDoc.collection('assigned_patients');

  /// 🔥 NEW: Check if lab test is actually uploaded
  Future<bool> _checkLabTestUploaded(String patientId, String screeningId) async {
    try {
      final labTestsRef = _firestore
          .collection('patients')
          .doc(patientId)
          .collection('screenings')
          .doc(screeningId)
          .collection('labTests');

      final labTestsSnap = await labTestsRef.get();

      // Check if any lab test has status "Uploaded"
      for (final labTestDoc in labTestsSnap.docs) {
        final labTestData = labTestDoc.data();
        final status = (labTestData['status'] ?? '').toString().toLowerCase();
        if (status == 'uploaded' || status == 'lab test uploaded') {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('❌ Error checking lab test upload: $e');
      return false;
    }
  }

  ///  Get all assigned patients with their latest screening + updated status
  /// MODIFIED: Now checks for requestedTests in diagnosis
  Stream<List<PatientWithScreening>> getPatientsWithScreenings() {
    return _assignedPatients.snapshots().asyncMap((snapshot) async {
      final List<PatientWithScreening> patients = [];

      for (var patientDoc in snapshot.docs) {
        final patientData = patientDoc.data();
        final patientId = patientDoc.id;

        // 1️⃣ Get CHW’s latest screening
        final chwScreeningSnap = await _assignedPatients
            .doc(patientId)
            .collection('screenings')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        String status = 'not_screened';
        DateTime? lastScreeningDate;
        Map<String, dynamic>? latestScreening;
        String? screeningId;

        if (chwScreeningSnap.docs.isNotEmpty) {
          final firstDoc = chwScreeningSnap.docs.first;
          screeningId = firstDoc.id;
          latestScreening = {
            'screeningId': screeningId,
            'id': screeningId,
            ...firstDoc.data(),
          };
          lastScreeningDate =
              (firstDoc.data()['timestamp'] as Timestamp?)?.toDate();
          status = firstDoc.data()['status'] ?? 'pending_analysis';
        }

        // 2️⃣ 🔥 Check if doctor added requestedTests in diagnosis
        if (screeningId != null && screeningId.isNotEmpty) {
          bool hasRequestedTests = await _checkForRequestedTests(
              patientId,
              screeningId
          );

          if (hasRequestedTests && status != 'lab_test_uploaded') {
            // 🔥 NEW: Check if lab test is actually uploaded
            bool isUploaded = await _checkLabTestUploaded(patientId, screeningId);
            if (isUploaded) {
              status = 'lab_test_uploaded';
            } else {
              status = 'needs_lab_test';
            }

            // 🔥 AUTO-UPDATE: Update status in Firestore
            await _updateLabTestStatus(
                patientId,
                screeningId,
                status
            );
          }
        }

        // 3️⃣ Check if doctor updated status in /patients/{patientId}/screenings/{screeningId}
        if (screeningId != null && screeningId.isNotEmpty) {
          final patientScreeningRef = _firestore
              .collection('patients')
              .doc(patientId)
              .collection('screenings')
              .doc(screeningId);

          final patientScreeningSnap = await patientScreeningRef.get();
          if (patientScreeningSnap.exists) {
            final patientScreeningData = patientScreeningSnap.data();
            if (patientScreeningData?['status'] != null) {
              status = patientScreeningData!['status'];
            }

            // 🔥 Check requestedTests in main screening too
            final requestedTestsMain = patientScreeningData?['requestedTests'];
            if (requestedTestsMain is List &&
                requestedTestsMain.isNotEmpty &&
                status != 'lab_test_uploaded') {
              // 🔥 NEW: Check if lab test is actually uploaded
              bool isUploaded = await _checkLabTestUploaded(patientId, screeningId);
              if (isUploaded) {
                status = 'lab_test_uploaded';
              } else {
                status = 'needs_lab_test';
              }
            }
          }
        }

        // 4️⃣ Still check main /patients/{patientId} doc for top-level status
        final mainPatientDoc =
        await _firestore.collection('patients').doc(patientId).get();
        if (mainPatientDoc.exists &&
            mainPatientDoc.data()?['status'] != null &&
            mainPatientDoc.data()?['status'] != status) {
          status = mainPatientDoc.data()!['status'];
        }

        // 5️⃣ Normalize status and add to list
        status = _normalizeStatus(status);

        patients.add(PatientWithScreening(
          id: patientId,
          name: patientData['name'] ?? 'Unknown',
          age: patientData['age'] ?? 0,
          gender: patientData['gender'] ?? 'Unknown',
          phone: patientData['phone'] ?? '',
          status: status,
          lastScreeningDate: lastScreeningDate,
          latestScreening: latestScreening,
        ));
      }

      // Sort by most recent
      patients.sort((a, b) {
        if (a.lastScreeningDate != null && b.lastScreeningDate != null) {
          return b.lastScreeningDate!.compareTo(a.lastScreeningDate!);
        } else if (a.lastScreeningDate != null) {
          return -1;
        } else if (b.lastScreeningDate != null) {
          return 1;
        } else {
          return a.name.compareTo(b.name);
        }
      });

      return patients;
    });
  }

  /// 🔥 NEW: Check if doctor added requestedTests in diagnosis documents
  Future<bool> _checkForRequestedTests(String patientId, String screeningId) async {
    try {
      final diagnosisRef = _firestore
          .collection('patients')
          .doc(patientId)
          .collection('screenings')
          .doc(screeningId)
          .collection('diagnosis');

      final diagnosisSnap = await diagnosisRef.get();

      for (final diagnosisDoc in diagnosisSnap.docs) {
        final diagnosisData = diagnosisDoc.data();
        final requestedTests = diagnosisData['requestedTests'];

        if (requestedTests is List && requestedTests.isNotEmpty) {
          return true; // Doctor has requested tests
        }
      }

      return false;
    } catch (e) {
      print('❌ Error checking requested tests: $e');
      return false;
    }
  }

  /// 🔥 NEW: Auto-update status when doctor adds requestedTests
  Future<void> _updateLabTestStatus(
      String patientId,
      String screeningId,
      String newStatus
      ) async {
    try {
      final batch = _firestore.batch();
      final chwId = currentUser.uid;

      // 1. Update in main patients collection
      final mainScreeningRef = _firestore
          .collection('patients')
          .doc(patientId)
          .collection('screenings')
          .doc(screeningId);

      batch.update(mainScreeningRef, {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update in CHW's assigned patients copy
      final chwScreeningRef = _firestore
          .collection('chws')
          .doc(chwId)
          .collection('assigned_patients')
          .doc(patientId)
          .collection('screenings')
          .doc(screeningId);

      batch.update(chwScreeningRef, {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update patient's main status
      final patientRef = _firestore.collection('patients').doc(patientId);
      batch.update(patientRef, {
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // 4. Update CHW's assigned_patients status
      final chwPatientRef = _firestore
          .collection('chws')
          .doc(chwId)
          .collection('assigned_patients')
          .doc(patientId);

      batch.update(chwPatientRef, {
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('✅ Auto-updated status to $newStatus for patient $patientId');

    } catch (e) {
      print('❌ Error auto-updating lab test status: $e');
    }
  }

  /// 🕒 Get recent activity - UPDATED
  Stream<List<RecentActivity>> getRecentActivity() {
    return _assignedPatients.snapshots().asyncMap((snapshot) async {
      final List<RecentActivity> activities = [];

      for (var patientDoc in snapshot.docs) {
        final patientData = patientDoc.data();
        final patientId = patientDoc.id;

        final screeningSnapshot = await _assignedPatients
            .doc(patientId)
            .collection('screenings')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        String status = "not_screened";
        DateTime? date;

        if (screeningSnapshot.docs.isNotEmpty) {
          final screeningData = screeningSnapshot.docs.first.data();
          date = (screeningData['timestamp'] as Timestamp?)?.toDate();
          status = screeningData['status'] ?? 'pending_analysis';

          // 🔥 Check for requested tests
          final screeningId = screeningSnapshot.docs.first.id;
          bool hasRequestedTests = await _checkForRequestedTests(
              patientId,
              screeningId
          );

          if (hasRequestedTests) {
            // 🔥 NEW: Check if lab test is actually uploaded
            bool isUploaded = await _checkLabTestUploaded(patientId, screeningId);
            if (isUploaded) {
              status = 'lab_test_uploaded';
            } else {
              status = 'needs_lab_test';
            }
          }
        } else {
          date = (patientData['createdAt'] as Timestamp?)?.toDate();
        }

        status = _normalizeStatus(status);

        activities.add(RecentActivity(
          name: patientData['name'] ?? 'Unknown',
          status: status,
          date: date,
        ));
      }

      // Sort newest first
      activities.sort((a, b) {
        final da = a.date;
        final db = b.date;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

      return activities;
    });
  }

  String _normalizeStatus(String status) {
    final normalized = status.toLowerCase().trim();
    print("🔄 Normalizing status: '$status' -> '$normalized'");

    switch (normalized) {
      case 'needs lab test':
      case 'needs_lab_test':
        return 'needs_lab_test';

      case 'lab test uploaded':
      case 'lab_test_uploaded':
      case 'lab test_uploaded':
        return 'lab_test_uploaded';

      case 'screening_completed':
        return 'pending_analysis';

      case 'pending_referral':
      case 'ai_completed':
        return 'ai_completed';

      case 'under treatment':
        return 'doctor_reviewed';

      case 'completed':
        return 'completed';

      default:
        print("⚠️ Unknown status: '$normalized', returning as-is");
        return normalized;
    }
  }

  /// 🗑️ Delete selected patients + screenings
  Future<void> deleteMultiplePatients(List<String> patientIds) async {
    if (patientIds.isEmpty) return;

    final String chwId = currentUser.uid;
    final firestore = _firestore;

    try {
      for (final patientId in patientIds) {
        // 1️⃣ Delete screenings under patients/{patientId}/screenings
        final patientScreeningsRef = firestore
            .collection('patients')
            .doc(patientId)
            .collection('screenings');

        final patientScreeningsSnap = await patientScreeningsRef.get();
        for (final doc in patientScreeningsSnap.docs) {
          await doc.reference.delete();
        }

        // 2️⃣ Delete screenings under CHW assigned_patients/{patientId}/screenings
        final chwScreeningsRef = firestore
            .collection('chws')
            .doc(chwId)
            .collection('assigned_patients')
            .doc(patientId)
            .collection('screenings');

        final chwScreeningsSnap = await chwScreeningsRef.get();
        for (final doc in chwScreeningsSnap.docs) {
          await doc.reference.delete();
        }

        // 3️⃣ Use batch to delete main patient docs
        final batch = firestore.batch();

        // Delete from patients collection
        final patientRef = firestore.collection('patients').doc(patientId);
        final patientSnap = await patientRef.get();
        if (patientSnap.exists) {
          batch.delete(patientRef);
        }

        // Delete from assigned_patients
        final chwPatientRef = firestore
            .collection('chws')
            .doc(chwId)
            .collection('assigned_patients')
            .doc(patientId);
        batch.delete(chwPatientRef);

        // Commit the batch for this patient
        await batch.commit();
      }

      print('✅ Successfully deleted ${patientIds.length} patient(s) and all related data');
    } catch (e, st) {
      print('❌ Failed to delete patients: $e');
      print(st);
      rethrow;
    }
  }

  /// 🔍 Get single patient by ID
  Future<PatientWithScreening?> getPatientById(String patientId) async {
    try {
      final patientDoc = await _assignedPatients.doc(patientId).get();
      if (!patientDoc.exists) return null;

      final data = patientDoc.data()!;
      final screeningSnapshot = await _assignedPatients
          .doc(patientId)
          .collection('screenings')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      String status = 'not_screened';
      DateTime? lastDate;
      Map<String, dynamic>? latest;
      String? screeningId;

      if (screeningSnapshot.docs.isNotEmpty) {
        final firstDoc = screeningSnapshot.docs.first;
        screeningId = firstDoc.id;
        latest = {
          'screeningId': screeningId,
          'id': screeningId,
          ...firstDoc.data(),
        };
        lastDate = (firstDoc.data()['timestamp'] as Timestamp?)?.toDate();
        status = firstDoc.data()['status'] ?? 'pending_analysis';

        // 🔥 Check for requested tests
        if (screeningId != null) {
          bool hasRequestedTests = await _checkForRequestedTests(
              patientId,
              screeningId
          );

          if (hasRequestedTests) {
            // 🔥 NEW: Check if lab test is actually uploaded
            bool isUploaded = await _checkLabTestUploaded(patientId, screeningId);
            if (isUploaded) {
              status = 'lab_test_uploaded';
            } else {
              status = 'needs_lab_test';
            }
          }
        }
      }

      final mainDoc =
      await _firestore.collection('patients').doc(patientId).get();
      if (mainDoc.exists && mainDoc.data()?['status'] != null) {
        status = mainDoc.data()!['status'];
      }

      status = _normalizeStatus(status);

      return PatientWithScreening(
        id: patientId,
        name: data['name'] ?? 'Unknown',
        age: data['age'] ?? 0,
        gender: data['gender'] ?? 'Unknown',
        phone: data['phone'] ?? '',
        status: status,
        lastScreeningDate: lastDate,
        latestScreening: latest,
      );
    } catch (e) {
      print('⚠️ Error getting patient by ID: $e');
      return null;
    }
  }

  Stream<QuerySnapshot> getAssignedPatientsStream() {
    return _firestore
        .collection('chws')
        .doc(currentUser.uid)
        .collection('assigned_patients')
        .snapshots();
  }

  Stream<QuerySnapshot> getPatientsByStatus(String status) {
    return _firestore
        .collection('chws')
        .doc(currentUser.uid)
        .collection('assigned_patients')
        .where('status', isEqualTo: status)
        .snapshots();
  }
}