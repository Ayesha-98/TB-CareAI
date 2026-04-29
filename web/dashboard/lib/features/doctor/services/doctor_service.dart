import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor_stats.dart';

class DoctorService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get _doctorId => _auth.currentUser?.uid;

  /// ---------------- READ: Dashboard stats ----------------
  /// ---------------- READ: Dashboard stats ----------------
  static Future<Map<int, int>> fetchWeeklyDiagnoses() async {
    if (_doctorId == null) return {};

    final now = DateTime.now();
    // Start of 7 days ago (to include full 7 days)
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final startOfPeriod = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

    try {
      final snapshot = await _firestore
          .collection('doctors')
          .doc(_doctorId)
          .collection('diagnoses')
          .where('createdAt', isGreaterThanOrEqualTo: startOfPeriod)
          .get();

      // We want to map results to [today-6, today-5, ..., today]
      // 0 = today-6, 6 = today
      final Map<int, int> weeklyCounts = {
        0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          final date = (data['createdAt'] as Timestamp).toDate();
          // Calculate difference in days from the startOfPeriod
          final difference = date.difference(startOfPeriod).inDays;
          if (difference >= 0 && difference < 7) {
            weeklyCounts[difference] = (weeklyCounts[difference] ?? 0) + 1;
          }
        }
      }
      return weeklyCounts;
    } catch (e) {
      debugPrint("❌ Error fetching weekly diagnoses: $e");
      return {};
    }
  }

  /// ---------------- READ: Dashboard stats ----------------
  static Future<List<DoctorStat>> fetchDoctorStats() async {
    if (_doctorId == null) return [];
    try {
      final snapshot =
          await _firestore.collection('doctors').doc(_doctorId).get();

      final data = snapshot.data();
      if (data != null) {
        return [
          DoctorStat(
            label: "Patients",
            value: data['totalPatientsReviewed'] ?? 0,
            icon: "assets/icons/user.svg",
            color: const Color(0xFF007EE5),
          ),
          DoctorStat(
            label: "Screenings",
            value: data['totalDiagnosisMade'] ?? 0,
            icon: "assets/icons/clipboard.svg",
            color: const Color(0xFF26E5FF),
          ),
          DoctorStat(
            label: "Confirmed TB",
            value: data['confirmedTBCount'] ?? 0,
            icon: "assets/icons/check-shield.svg",
            color: const Color(0xFFEE2727),
          ),
          DoctorStat(
            label: "Recommendations",
            value: data['totalRecommendationsGiven'] ?? 0,
            icon: "assets/icons/reports.svg",
            color: const Color(0xFF26C485),
          ),
        ];
      }
    } catch (e) {
      debugPrint("❌ Error fetching doctor stats: $e");
    }
    return [];
  }

  /// ---------------- WRITE: Record diagnosis ----------------
  static Future<void> recordDiagnosis({
    required String diagnosisId,
    required String finalDiagnosis,
    required String patientId,
    required String screeningId,
    bool labTestRequested = false,
  }) async {
    if (_doctorId == null) throw Exception("No logged-in doctor");

    final doctorRef = _firestore.collection('doctors').doc(_doctorId);
    final diagnosisRef = doctorRef.collection('diagnoses').doc(diagnosisId);

    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      // We must perform all reads before any writes
      final doctorSnap = await transaction.get(doctorRef);

      // Write 1: Log every diagnosis under doctor history
      transaction.set(diagnosisRef, {
        'diagnosisId': diagnosisId,
        'finalDiagnosis': finalDiagnosis,
        'patientId': patientId,
        'screeningId': screeningId,
        'createdAt': now,
        'labTestRequested': labTestRequested,
      });

      // Write 2: Increment stats atomically
      final updates = <String, dynamic>{
        'totalDiagnosisMade': FieldValue.increment(1),
        'patientsReviewed': FieldValue.arrayUnion([patientId]),
      };

      if (labTestRequested) {
        updates['totalTestsRequested'] = FieldValue.increment(1);
      }

      if (finalDiagnosis == 'TB') {
        updates['confirmedTBCount'] = FieldValue.increment(1);
      }

      // Calculate totalPatientsReviewed safely within the transaction
      if (doctorSnap.exists) {
        final data = doctorSnap.data() as Map<String, dynamic>;
        final patients = List<String>.from(data['patientsReviewed'] ?? []);
        
        // If patient is new to this doctor, the array length will increase by 1
        int updatedLength = patients.length;
        if (!patients.contains(patientId)) {
          updatedLength += 1;
        }
        
        updates['totalPatientsReviewed'] = updatedLength;
      }

      transaction.set(doctorRef, updates, SetOptions(merge: true));
    });
  }

  /// ---------------- WRITE: Count recommendations ----------------
  static Future<void> incrementRecommendations() async {
    if (_doctorId == null) return;

    final doctorRef = _firestore.collection('doctors').doc(_doctorId);
    await doctorRef.update({
      'totalRecommendationsGiven': FieldValue.increment(1),
    });
  }
}
