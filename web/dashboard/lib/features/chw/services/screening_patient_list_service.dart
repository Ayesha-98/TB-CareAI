import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbcare_main/features/chw/models/screening_patient_list_model.dart';

class PatientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  /// Load all assigned patients that have at least one screening
  Future<List<Patient>> getScreenedPatients() async {
    if (uid == null) return [];

    final assignedSnap = await _db
        .collection("chws")
        .doc(uid)
        .collection("assigned_patients")
        .get();

    List<Patient> patients = [];
    for (var doc in assignedSnap.docs) {
      final screenings = await _db
          .collection("screenings")
          .where("patientId", isEqualTo: doc.id)
          .limit(1)
          .get();
      if (screenings.docs.isNotEmpty) {
        patients.add(Patient.fromDoc(doc));
      }
    }

    return patients;
  }

  /// Get screenings for a patient
  Stream<List<Screening>> getScreenings(String patientId) {
    return _db
        .collection('screenings')
        .where('patientId', isEqualTo: patientId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => Screening.fromDoc(doc)).toList());
  }
}
