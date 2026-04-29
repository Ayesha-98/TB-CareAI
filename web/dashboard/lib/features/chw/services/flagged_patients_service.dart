// flagged_patients_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbcare_main/features/chw/models/patient_screening_model.dart';

class FlaggedPatientsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String chwId = FirebaseAuth.instance.currentUser!.uid;

  /// 🔄 Send patient to doctor (with full info including selectedDoctor)
  Future<void> sendToDoctor(Screening screening) async {
    if (screening.id == null || screening.id!.isEmpty) {
      throw Exception('Missing screening.id for patient ${screening.patientName}');
    }
    if (screening.patientId.isEmpty) {
      throw Exception('Missing patientId for ${screening.patientName}');
    }

    print('📄 Referring patient: chwId=$chwId, patientId=${screening.patientId}, screeningId=${screening.id}');

    try {
      // 🔹 1️⃣ Get full patient data from assigned_patients
      final patientDoc = await _db
          .collection('chws')
          .doc(chwId)
          .collection('assigned_patients')
          .doc(screening.patientId)
          .get();

      if (!patientDoc.exists) {
        throw Exception("Patient ${screening.patientName} not found in assigned_patients");
      }

      final patientData = patientDoc.data()!;
      print("📦 Fetched full patient data: ${patientData['name']}");

      // 🔹 2️⃣ Get the COMPLETE screening data from CHW screenings
      final chwScreeningDoc = await _db
          .collection('chws')
          .doc(chwId)
          .collection('assigned_patients')
          .doc(screening.patientId)
          .collection('screenings')
          .doc(screening.id)
          .get();

      if (!chwScreeningDoc.exists) {
        throw Exception("Screening ${screening.id} not found");
      }

      final chwScreeningData = chwScreeningDoc.data()!;
      print("📊 Fetched full screening data from CHW collection");

      // 🔹 3️⃣ Get assigned doctor (from screening or default)
      String? assignedDoctorId = chwScreeningData['assignedDoctorId']?.toString();
      String? assignedDoctorName = chwScreeningData['assignedDoctorName']?.toString();

      // If no doctor assigned, try to get from patient data
      if (assignedDoctorId == null || assignedDoctorId.isEmpty) {
        assignedDoctorId = patientData['assignedDoctorId']?.toString();
        assignedDoctorName = patientData['assignedDoctorName']?.toString();
      }

      // If still no doctor, assign default or fetch from doctors collection
      if (assignedDoctorId == null || assignedDoctorId.isEmpty) {
        final doctors = await _getAvailableDoctors();
        if (doctors.isNotEmpty) {
          assignedDoctorId = doctors[0]['id'];
          assignedDoctorName = doctors[0]['name'];
          print("👨‍⚕️ Auto-assigned doctor: $assignedDoctorName ($assignedDoctorId)");
        } else {
          assignedDoctorId = 'default_doctor_id';
          assignedDoctorName = 'General Doctor';
        }

        // Update CHW assigned_patients with assigned doctor
        await _db
            .collection('chws')
            .doc(chwId)
            .collection('assigned_patients')
            .doc(screening.patientId)
            .update({
          'assignedDoctorId': assignedDoctorId,
          'assignedDoctorName': assignedDoctorName,
          'selectedDoctor': assignedDoctorId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print("👨‍⚕️ Assigned Doctor: $assignedDoctorName ($assignedDoctorId)");

      // 🔹 4️⃣ Update screening status under CHW assigned_patients
      await chwScreeningDoc.reference.update({
        'status': 'sent_to_doctor',
        'assignedDoctorId': assignedDoctorId,
        'assignedDoctorName': assignedDoctorName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 🔹 5️⃣ Extract AI prediction details
      Map<String, dynamic> aiPredictionData = {};
      String aiClass = "Unknown";
      double aiConfidence = 0.0;
      double normalProbability = 0.0;
      double tbProbability = 0.0;

      // Try to get AI data from prediction field
      if (chwScreeningData['prediction'] is Map) {
        final prediction = chwScreeningData['prediction'] as Map<String, dynamic>;
        aiClass = prediction['class']?.toString() ?? "Unknown";
        aiConfidence = (prediction['confidence'] as num?)?.toDouble() ?? 0.0;
        normalProbability = (prediction['normal_probability'] as num?)?.toDouble() ?? 0.0;
        tbProbability = (prediction['tb_probability'] as num?)?.toDouble() ?? 0.0;
        aiPredictionData = Map<String, dynamic>.from(prediction);
      }
      // Fallback to aiPrediction field
      else if (chwScreeningData['aiPrediction'] is Map) {
        final aiPred = chwScreeningData['aiPrediction'] as Map<String, dynamic>;
        aiPredictionData = Map<String, dynamic>.from(aiPred);

        // Safely extract class
        if (aiPred['class'] != null) {
          aiClass = aiPred['class'].toString();
        } else if (aiPred['Normal'] != null && aiPred['TB'] != null) {
          final normalValue = (aiPred['Normal'] as num?)?.toDouble() ?? 0.0;
          final tbValue = (aiPred['TB'] as num?)?.toDouble() ?? 0.0;
          aiClass = tbValue >= normalValue ? "TB" : "Normal";
        }

        // Safely extract confidence
        if (aiPred['confidence'] != null) {
          aiConfidence = (aiPred['confidence'] as num).toDouble();
        } else if (aiPred[aiClass] != null) {
          aiConfidence = (aiPred[aiClass] as num).toDouble();
        }
      }

      // 🔹 6️⃣ Prepare COMPLETE screening data for /patients collection
      final completeScreeningData = {
        // Basic info
        'screeningId': screening.id,
        'patientId': screening.patientId,
        'patientName': screening.patientName,
        'chwId': chwId,
        'symptoms': chwScreeningData['symptoms'] ?? [],
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Media URLs
        'coughAudio': chwScreeningData['coughAudio']?.toString() ?? '',
        'xrayImage': chwScreeningData['xrayImage']?.toString() ?? '',

        // Doctor assignment
        'assignedDoctorId': assignedDoctorId,
        'assignedDoctorName': assignedDoctorName,

        // AI Structure (NEW format)
        'aiConfidence': aiConfidence,
        'aiPrediction': aiClass,
        'aiRawData': chwScreeningData['aiRawData'],
        'message': chwScreeningData['message']?.toString() ?? 'AI Analysis Complete',
        'prediction': {
          'class': aiClass,
          'class_id': aiClass == "Normal" ? 0 : 1,
          'confidence': aiConfidence,
          'normal_probability': normalProbability,
          'tb_probability': tbProbability,
        },
        'success': chwScreeningData['success'] ?? false,

        // Doctor review fields
        'doctorDiagnosis': null,
        'diagnosedBy': null,
        'testReferred': null,
        'recommendations': null,

        // Status
        'status': 'sent_to_doctor',
        'source': 'chw_app',
      };

      // Remove any null values
      completeScreeningData.removeWhere((key, value) => value == null);

      // 🔹 7️⃣ ✅✅✅ CRITICAL: Update patient document with selectedDoctor
      final patientRef = _db.collection('patients').doc(screening.patientId);

      await patientRef.set({
        // Copy all existing patient data
        ...patientData,

        // ✅✅✅ CRITICAL FIELDS FOR DOCTOR DASHBOARD:
        'selectedDoctor': assignedDoctorId,      // 👈 THIS IS THE KEY FIELD - MAKES PATIENT APPEAR IN DOCTOR DASHBOARD
        'assignedDoctorId': assignedDoctorId,    // 👈 Backup field for doctor reference
        'assignedDoctorName': assignedDoctorName, // 👈 Doctor name for display

        // Additional fields
        'chwId': chwId,
        'lastScreeningDate': FieldValue.serverTimestamp(),
        'lastScreeningStatus': 'sent_to_doctor',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅✅✅ CRITICAL: Patient document updated with selectedDoctor: $assignedDoctorId");
      print("   Path: patients/${screening.patientId}");
      print("   Field: selectedDoctor = $assignedDoctorId");

      // 🔹 8️⃣ Save screening to patients/{patientId}/screenings
      await patientRef.collection('screenings').doc(screening.id).set(
        completeScreeningData,
        SetOptions(merge: true),
      );
      print("✅ Screening saved to patients/${screening.patientId}/screenings/${screening.id}");

      // 🔹 9️⃣ Update status in CHW dashboard (assigned_patients root)
      await _db
          .collection('chws')
          .doc(chwId)
          .collection('assigned_patients')
          .doc(screening.patientId)
          .update({
        'diagnosisStatus': aiClass,
        'result': aiClass,
        'status': 'sent_to_doctor',
        'selectedDoctor': assignedDoctorId,
        'assignedDoctorId': assignedDoctorId,
        'assignedDoctorName': assignedDoctorName,
        'updatedAt': FieldValue.serverTimestamp(),
        'aiPrediction': aiClass,
        'aiConfidence': aiConfidence,
      });
      print("✅ CHW dashboard status updated");

      // 🔹 🔟 Create notification for doctor
      if (assignedDoctorId != null && assignedDoctorId.isNotEmpty) {
        try {
          await _db
              .collection('doctors')
              .doc(assignedDoctorId)
              .collection('notifications')
              .add({
            'screeningId': screening.id,
            'patientId': screening.patientId,
            'patientName': screening.patientName,
            'chwId': chwId,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'new_screening',
            'isRead': false,
            'message': 'New screening from CHW requires your review',
            'priority': 'high',
            'aiPrediction': aiClass,
            'aiConfidence': aiConfidence,
          });
          print("✅ Doctor notification created");
        } catch (notificationError) {
          print("⚠️ Failed to create doctor notification (non-critical): $notificationError");
        }
      }

      // Debug log summary
      print("=" * 60);
      print("✅✅✅ PATIENT REFERRAL COMPLETED SUCCESSFULLY!");
      print("=" * 60);
      print("📋 Patient: ${screening.patientName}");
      print("👨‍⚕️ Assigned to: Dr. $assignedDoctorName ($assignedDoctorId)");
      print("🤖 AI Diagnosis: $aiClass (${(aiConfidence * 100).toStringAsFixed(1)}%)");
      print("📌 Status: sent_to_doctor");
      print("✅ selectedDoctor field: ADDED to /patients/${screening.patientId}");
      print("✅ Doctor will now see this patient in their dashboard!");
      print("=" * 60);

    } catch (e, st) {
      print("❌ Error sending to doctor: $e");
      print(st);
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

      // Fallback to users collection
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

  /// 📋 Get patient's screenings
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