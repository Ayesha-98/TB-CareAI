import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbcare_main/features/chw/models/patient_screening_model.dart';

class FlaggedPatientsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String chwId = FirebaseAuth.instance.currentUser!.uid;

  /// 🔄 Send patient to doctor (with NEW AI structure)
  Future<void> sendToDoctor(Screening screening) async {
    if (screening.id == null || screening.id!.isEmpty) {
      throw Exception('Missing screening.id for patient ${screening.patientName}');
    }
    if (screening.patientId.isEmpty) {
      throw Exception('Missing patientId for ${screening.patientName}');
    }

    print('📄 Referring patient: chwId=$chwId, patientId=${screening.patientId}, screeningId=${screening.id}');

    try {
      // 🔹 1️⃣ Get COMPLETE screening data from CHW collection
      final screeningDoc = await _db
          .collection('chws')
          .doc(chwId)
          .collection('assigned_patients')
          .doc(screening.patientId)
          .collection('screenings')
          .doc(screening.id)
          .get();

      if (!screeningDoc.exists) {
        throw Exception("Screening ${screening.id} not found in CHW collection");
      }

      final screeningData = screeningDoc.data()!;
      print("📦 Fetched complete screening data from CHW collection");

      // Get other essential data
      final patientDoc = await _db
          .collection('chws')
          .doc(chwId)
          .collection('assigned_patients')
          .doc(screening.patientId)
          .get();
      final patientData = patientDoc.data() ?? {};

      final mainPatientDoc = await _db.collection('patients').doc(screening.patientId).get();
      final patientEmail = mainPatientDoc.data()?['email']?.toString() ?? '';

      // 🔹 Assign doctor if not already assigned
      String? assignedDoctorId = screeningData['assignedDoctorId']?.toString();
      String? assignedDoctorName = screeningData['assignedDoctorName']?.toString();

      if (assignedDoctorId == null || assignedDoctorId.isEmpty) {
        final doctors = await _getAvailableDoctors();
        if (doctors.isNotEmpty) {
          assignedDoctorId = doctors[0]['id'];
          assignedDoctorName = doctors[0]['name'];

          await _db
              .collection('chws')
              .doc(chwId)
              .collection('assigned_patients')
              .doc(screening.patientId)
              .update({
            'assignedDoctorId': assignedDoctorId,
            'assignedDoctorName': assignedDoctorName,
            'selectedDoctor': assignedDoctorId, // For consistency in CHW collection
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          assignedDoctorId = 'default_doctor_id';
          assignedDoctorName = 'General Doctor';
        }
      }

      print("👨‍⚕️ Assigned Doctor: $assignedDoctorName ($assignedDoctorId)");

      // 🔹 2️⃣ Clean up the structure for patients collection
      final prediction = screeningData['prediction'] ?? {};
      final aiPredictionStr = screeningData['aiPrediction']?.toString() ?? '';

      // Create proper prediction structure
      final cleanedPrediction = {
        'class': prediction['class']?.toString() ??
            (aiPredictionStr.isNotEmpty ? aiPredictionStr : 'Unknown'),
        'class_id': prediction['class_id'] ??
            ((prediction['class']?.toString() ?? aiPredictionStr).toLowerCase() == 'normal' ? 0 : 1),
        'confidence': prediction['confidence'] ?? screeningData['aiConfidence'] ?? 0.0,
        'normal_probability': prediction['normal_probability'] ??
            (1 - ((prediction['tb_probability'] as num?)?.toDouble() ?? 0.0)),
        'tb_probability': prediction['tb_probability'] ??
            ((prediction['class']?.toString() ?? aiPredictionStr).toLowerCase() == 'tb' ? 1.0 : 0.0),
      };

      // 🔹 3️⃣ Prepare CORRECT structure for patients collection
      final patientsScreeningData = {
        'screeningId': screening.id,
        'patientId': screening.patientId,
        'patientName': screening.patientName,
        'chwId': chwId,
        'symptoms': screeningData['symptoms'] ?? [],
        'timestamp': screeningData['timestamp'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Media URLs
        'coughAudio': screeningData['coughAudio']?.toString() ?? '',
        'xrayImage': screeningData['xrayImage']?.toString() ?? '',

        // Doctor assignment
        'assignedDoctorId': assignedDoctorId,
        'assignedDoctorName': assignedDoctorName,

        // AI Structure
        'aiConfidence': screeningData['aiConfidence'] ?? cleanedPrediction['confidence'],
        'aiPrediction': aiPredictionStr.isNotEmpty ? aiPredictionStr : cleanedPrediction['class'],
        'aiRawData': screeningData['aiRawData'],
        'message': screeningData['message']?.toString() ?? 'AI Analysis Complete',
        'prediction': cleanedPrediction,
        'success': screeningData['success'] ?? false,

        // Doctor review fields
        'doctorDiagnosis': null,
        'diagnosedBy': null,
        'testReferred': null,
        'recommendations': null,

        // Status
        'status': 'sent_to_doctor',
        'source': 'chw_app',
        'patientEmail': patientEmail,
      };

      print("✅ Prepared CORRECT structure for patients collection:");
      print("   aiPrediction: ${patientsScreeningData['aiPrediction']}");
      print("   prediction.class: ${cleanedPrediction['class']}");
      print("   aiConfidence: ${patientsScreeningData['aiConfidence']}");

      // 🔹 4️⃣ Update CHW screening status
      final chwScreeningRef = _db
          .collection('chws')
          .doc(chwId)
          .collection('assigned_patients')
          .doc(screening.patientId)
          .collection('screenings')
          .doc(screening.id);

      await chwScreeningRef.update({
        'status': 'sent_to_doctor',
        'assignedDoctorId': assignedDoctorId,
        'assignedDoctorName': assignedDoctorName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("✅ CHW screening status updated to 'sent_to_doctor'");

      // 🔹 5️⃣ ✅✅✅ CRITICAL FIX: Update patient document with selectedDoctor
      final patientRef = _db.collection('patients').doc(screening.patientId);

      await patientRef.set({
        ...patientData,
        'selectedDoctor': assignedDoctorId, // ✅ CRITICAL: This makes patients appear in doctor dashboard
        'assignedDoctorId': assignedDoctorId,
        'assignedDoctorName': assignedDoctorName,
        'chwId': chwId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("✅ Patient document updated with selectedDoctor: $assignedDoctorId");

      // Save screening to patients collection
      await patientRef.collection('screenings').doc(screening.id).set(patientsScreeningData);
      print("✅ Saved CORRECT structure to patients/screenings");

      // 🔹 6️⃣ Add to global screenings collection
      try {
        await _db.collection('screenings').doc(screening.id).set({
          ...patientsScreeningData,
          'followUpNeeded': true,
          'followUpStatus': 'sent_to_doctor',
          'sentToDoctorAt': FieldValue.serverTimestamp(),
        });
        print("✅ Added to global screenings collection");
      } catch (globalScreeningError) {
        print("⚠️ Failed to add to global screenings (non-critical): $globalScreeningError");
        // Continue - this is not critical for the main operation
      }

      // 🔹 7️⃣ Update CHW dashboard status (also add selectedDoctor here)
      await _db
          .collection('chws')
          .doc(chwId)
          .collection('assigned_patients')
          .doc(screening.patientId)
          .update({
        'diagnosisStatus': (cleanedPrediction['class']?.toString() ?? 'Unknown').toLowerCase() == 'tb' ? 'TB' : 'Normal',
        'status': 'sent_to_doctor',
        'selectedDoctor': assignedDoctorId, // For consistency
        'assignedDoctorId': assignedDoctorId,
        'assignedDoctorName': assignedDoctorName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("✅ CHW dashboard status updated");

      // 🔹 8️⃣ Create notification for doctor (WITH GRACEFUL ERROR HANDLING)
      if (assignedDoctorId != null && assignedDoctorId.isNotEmpty) {
        try {
          await _db
              .collection('doctors')
              .doc(assignedDoctorId)
              .collection('notifications')
              .doc(screening.id)
              .set({
            'screeningId': screening.id,
            'patientId': screening.patientId,
            'patientName': screening.patientName,
            'chwId': chwId,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'new_screening',
            'isRead': false,
            'message': 'New screening from CHW requires your review',
            'priority': 'high',
          });
          print("✅ Doctor notification created successfully");
        } catch (notificationError) {
          print("⚠️ Failed to create doctor notification (non-critical): $notificationError");
          print("   The patient was successfully sent to doctor, but notification failed.");
          print("   This is likely a Firestore rules issue for doctors/notifications collection.");
          print("   The main operation (sending patient) was successful!");
          // DO NOT rethrow - this is a non-critical operation
          // The patient referral was successful even without notification
        }
      }

      print("✅✅✅ PATIENT REFERRAL COMPLETED SUCCESSFULLY!");
      print("   Patient: ${screening.patientName}");
      print("   Assigned to: Dr. $assignedDoctorName ($assignedDoctorId)");
      print("   Status: sent_to_doctor");
      print("   SelectedDoctor field: ✅ ADDED to patients collection");
      print("   Doctor will now see this patient in their dashboard!");

    } catch (e, st) {
      print("❌❌❌ CRITICAL ERROR in patient referral:");
      print("Error: $e");
      print("Stack trace: $st");

      // Check if it's a permission error
      if (e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('permission') ||
          e.toString().contains('not authorized')) {
        print("🔒 PERMISSION ERROR DETECTED!");
        print("Current CHW UID: $chwId");
        print("Check Firestore rules for:");
        print("  1. patients collection write access for CHW");
        print("  2. chws collection write access for CHW");
        print("  3. screenings collection write access for CHW");
      }

      rethrow;
    }
  }

  /// 🔍 Get available doctors from the database
  Future<List<Map<String, dynamic>>> _getAvailableDoctors() async {
    try {
      final doctorsSnapshot = await _db
          .collection('doctors')
          .where('status', isEqualTo: 'active')
          .limit(10)
          .get();

      if (doctorsSnapshot.docs.isNotEmpty) {
        return doctorsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name']?.toString() ?? 'Unknown Doctor',
            'specialization': data['specialization']?.toString() ?? 'General',
          };
        }).toList();
      }

      // If no doctors in 'doctors' collection, check 'users' collection
      final usersSnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'Doctor')
          .where('status', isEqualTo: 'Active')
          .limit(10)
          .get();

      if (usersSnapshot.docs.isNotEmpty) {
        return usersSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name']?.toString() ?? 'Unknown Doctor',
            'specialization': data['specialization']?.toString() ?? 'General',
          };
        }).toList();
      }

      return [];
    } catch (e) {
      print("⚠️ Error fetching doctors: $e");
      return [];
    }
  }

  /// 📋 Get patient's screenings with NEW AI structure
  Stream<List<Screening>> getPatientScreenings(String patientId) {
    return _db
        .collection('chws')
        .doc(chwId)
        .collection('assigned_patients')
        .doc(patientId)
        .collection('screenings')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Screening.fromMap(doc.data()))
        .toList());
  }
}