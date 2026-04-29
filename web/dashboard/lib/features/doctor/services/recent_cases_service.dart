import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recent_cases.dart';

class RecentCasesService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _firestore.collection('patients');

  
  static String? get _currentDoctorId => _auth.currentUser?.uid;

  
  static Future<List<RecentCase>> fetchRecentCases({int limit = 5}) async {
    try {
      final doctorId = _currentDoctorId;
      if (doctorId == null) {
        print("⚠️ No logged-in doctor found");
        return [];
      }

      final patientsSnap = await _patientsRef
          .where('selectedDoctor', isEqualTo: doctorId)
          .get();
      
      final List<RecentCase> cases = [];

      for (var patientDoc in patientsSnap.docs) {
        final screeningsSnap = await patientDoc.reference
            .collection('screenings')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (screeningsSnap.docs.isEmpty) continue;

        final screeningDoc = screeningsSnap.docs.first;
        cases.add(
          RecentCase.fromFirestore(
            patientDoc.data(),
            screeningDoc.data(),
            patientDoc.id,
            screeningDoc.id,
          ),
        );
      }

      cases.sort((a, b) => b.date.compareTo(a.date));
      return cases.take(limit).toList();
    } catch (e) {
      print("❌ Error fetching recent cases: $e");
      rethrow;
    }
  }
}