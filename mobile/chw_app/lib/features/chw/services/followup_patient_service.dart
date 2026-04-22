import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbcare_main/features/chw/models/followup_patient_model.dart';

class FollowUpService {
  final FirebaseFirestore _fire = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Stream of follow-ups (sent to doctor) for this CHW
  Stream<List<Screening>> getDoctorFollowUps() {
    return _fire
        .collection('screenings')
        .where('followUpNeeded', isEqualTo: true)
        .where('followUpStatus', isEqualTo: 'sent_to_doctor')
        .where('chwId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => Screening.fromDoc(doc)).toList());
  }

  /// Mark follow-up as completed and send to referral
  Future<void> markCompleted(String screeningId, String patientId, String patientName) async {
    // Update main screenings collection
    await _fire.collection('screenings').doc(screeningId).update({
      'followUpStatus': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'referred': true,
    });

    // Update patient's sub-collection
    await _fire
        .collection('patients')
        .doc(patientId)
        .collection('screenings')
        .doc(screeningId)
        .update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'referred': true,
    });

    // Add to referrals collection
    await _fire.collection('referrals').add({
      'patientId': patientId,
      'patientName': patientName,
      'screeningId': screeningId,
      'status': 'pending',
      'priority': 'normal',
      'timestamp': FieldValue.serverTimestamp(),
      'chwId': currentUserId,
      'referred': true,
    });
  }

  /// Send patient to doctor
  Future<void> sendToDoctor(Screening screening) async {
    final ref = _fire.collection('screenings').doc(screening.id);
    await ref.update({
      'followUpNeeded': true,
      'followUpStatus': 'doctor',
      'sentToDoctorAt': FieldValue.serverTimestamp(),
    });
  }
}
