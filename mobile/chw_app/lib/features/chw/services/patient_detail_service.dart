import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tbcare_main/features/chw/models/patient_detail_model.dart';

class PatientDetailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Patient?> getPatientDetail(String chwId, String patientId) async {
    final doc = await _firestore
        .collection('chws')
        .doc(chwId)
        .collection('assigned_patients')
        .doc(patientId)
        .get();

    if (!doc.exists) return null;
    return Patient.fromMap(doc.data()!, doc.id);
  }

  Future<void> updatePatientDetail(String chwId, Patient patient) async {
    await _firestore
        .collection('chws')
        .doc(chwId)
        .collection('assigned_patients')
        .doc(patient.id)
        .update(patient.toMap());
  }

}
