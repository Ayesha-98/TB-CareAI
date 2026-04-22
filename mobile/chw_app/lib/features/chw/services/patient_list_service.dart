import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbcare_main/features/chw/models/patient_list_model.dart';

class PatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get chwId => _auth.currentUser!.uid;

  /// Stream patients assigned to CHW
  Stream<List<Patient>> getPatients() {
    return _firestore
        .collection("chws")
        .doc(chwId)
        .collection("assigned_patients")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Patient.fromMap(doc.id, doc.data())).toList());
  }

  /// Delete patient and related data
  Future<void> deletePatient(String patientId) async {
    final batch = _firestore.batch();

    // remove from assigned list
    final assignedRef = _firestore
        .collection('chws')
        .doc(chwId)
        .collection('assigned_patients')
        .doc(patientId);
    batch.delete(assignedRef);

    // screenings
    final screenings = await _firestore
        .collection('screenings')
        .where('patientId', isEqualTo: patientId)
        .get();
    for (final doc in screenings.docs) {
      batch.delete(doc.reference);
    }

    // referrals
    final referrals = await _firestore
        .collection('referrals')
        .where('patientId', isEqualTo: patientId)
        .get();
    for (final doc in referrals.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
