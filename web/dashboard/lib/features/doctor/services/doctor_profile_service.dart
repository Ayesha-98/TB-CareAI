import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:tbcare_main/features/doctor/models/doctor_profile_model.dart';

class DoctorProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Create default Doctor object for new doctors
  Doctor _createDefaultDoctor(String uid, String? name, String? phone, String? email) {
    return Doctor(
      uid: uid,
      name: name ?? 'New Doctor',
      phone: phone ?? '',
      specialization: '',
      confirmedTBCount: 0,
      createdAt: DateTime.now(),
      patientsReviewed: [],
      totalDiagnosisMade: 0,
      totalFinalVerdicts: 0,
      totalPatientsReviewed: 0,
      totalRecommendationsGiven: 0,
      totalTestsRequested: 0,
      profileImageUrl: null,
      email: email,
      hospital: null,
      experience: null,
      qualifications: null,
      rating: null,
      reviewCount: null,
    );
  }

  /// Get current doctor profile (one-time fetch)
  Future<Doctor> getCurrentDoctorProfileOnce() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final doctor = await getDoctorById(user.uid);
    if (doctor != null) {
      return doctor;
    }

    String? name = user.displayName;
    String? email = user.email;
    String? phone = user.phoneNumber;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        if (data['name'] != null && data['name'].toString().isNotEmpty) name = data['name'];
        if (data['email'] != null && data['email'].toString().isNotEmpty) email = data['email'];
        if (data['phone'] != null && data['phone'].toString().isNotEmpty) phone = data['phone'];
      }
    } catch (_) {}

    // Return default doctor if document doesn't exist
    return _createDefaultDoctor(user.uid, name, phone, email);
  }

  // Get current doctor profile (stream)
  Stream<Doctor?> getCurrentDoctorProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('doctors')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return Doctor.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Get doctor by ID
  Future<Doctor?> getDoctorById(String doctorId) async {
    try {
      final doc = await _firestore.collection('doctors').doc(doctorId).get();
      if (doc.exists) {
        return Doctor.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get doctor profile: $e');
    }
  }

  // Update doctor profile
  Future<void> updateDoctorProfile(Doctor doctor) async {
    try {
      await _firestore
          .collection('doctors')
          .doc(doctor.uid)
          .set(doctor.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update doctor profile: $e');
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(File imageFile, String doctorId) async {
    try {
      final ref = _storage.ref().child('doctor_profiles').child('$doctorId.jpg');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Update profile image
  Future<void> updateProfileImage(String doctorId, File imageFile) async {
    try {
      final imageUrl = await uploadProfileImage(imageFile, doctorId);
      await _firestore.collection('doctors').doc(doctorId).update({
        'profileImageUrl': imageUrl,
      });
    } catch (e) {
      throw Exception('Failed to update profile image: $e');
    }
  }

  // Get doctor statistics
  Future<Map<String, dynamic>> getDoctorStatistics(String doctorId) async {
    try {
      final doc = await _firestore.collection('doctors').doc(doctorId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'totalPatientsReviewed': data['totalPatientsReviewed'] ?? 0,
          'totalDiagnosisMade': data['totalDiagnosisMade'] ?? 0,
          'totalFinalVerdicts': data['totalFinalVerdicts'] ?? 0,
          'confirmedTBCount': data['confirmedTBCount'] ?? 0,
          'totalRecommendationsGiven': data['totalRecommendationsGiven'] ?? 0,
          'totalTestsRequested': data['totalTestsRequested'] ?? 0,
        };
      }
      return {};
    } catch (e) {
      throw Exception('Failed to get doctor statistics: $e');
    }
  }

  // Get recent diagnoses
  Future<List<Map<String, dynamic>>> getRecentDiagnoses(String doctorId, {int limit = 5}) async {
    try {
      final querySnapshot = await _firestore
          .collection('diagnoses')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('requestedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'diagnosisId': doc.id,
          'patientId': data['patientId'],
          'finalDiagnosis': data['finalDiagnosis'],
          'requestedAt': data['requestedAt'],
          'screeningId': data['screeningId'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get recent diagnoses: $e');
    }
  }

  // Update doctor statistics (called when doctor completes actions)
  Future<void> incrementStatistic(String doctorId, String statisticName) async {
    try {
      await _firestore.collection('doctors').doc(doctorId).update({
        statisticName: FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to update statistic: $e');
    }
  }

  // Get all doctors (for admin or referral purposes)
  Future<List<Doctor>> getAllDoctors() async {
    try {
      final querySnapshot = await _firestore
          .collection('doctors')
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => Doctor.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all doctors: $e');
    }
  }

  // Search doctors by specialization
  Future<List<Doctor>> getDoctorsBySpecialization(String specialization) async {
    try {
      final querySnapshot = await _firestore
          .collection('doctors')
          .where('specialization', isEqualTo: specialization)
          .get();

      return querySnapshot.docs
          .map((doc) => Doctor.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get doctors by specialization: $e');
    }
  }

  // Sign out doctor
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
}