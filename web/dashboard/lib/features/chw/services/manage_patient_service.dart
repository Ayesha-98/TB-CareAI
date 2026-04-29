import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbcare_main/features/chw/models/manage_patient_model.dart';

class PatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a new patientId (uid)
  String newPatientId(String chwId) {
    return _firestore
        .collection("chws")
        .doc(chwId)
        .collection("assigned_patients")
        .doc()
        .id;
  }

  Future<void> addPatient(Patient patient, String chwId) async {
    try {
      DocumentReference patientRef = _firestore
          .collection("chws")
          .doc(chwId)
          .collection("assigned_patients")
          .doc(patient.id);

      // Convert to map and ensure correct format
      final patientData = patient.toMap();

      // Remove any unwanted fields that might have been added
      final cleanPatientData = {
        "uid": patientData["uid"],
        "name": patientData["name"],
        "age": patientData["age"],
        "gender": patientData["gender"],
        "phone": patientData["phone"],
        "weight": patientData["weight"],
        "comorbidities": patientData["comorbidities"],
        "medicationHistory": patientData["medicationHistory"],
        "appetite": patientData["appetite"],
        "language": patientData["language"],
        "symptoms": patientData["symptoms"], // This should be string "none"
        "imageUrl": patientData["imageUrl"],
        "diagnosisStatus": patientData["diagnosisStatus"],
        "address": patientData["address"],
        "createdAt": patientData["createdAt"],
        "updatedAt": patientData["updatedAt"],
      };

      await patientRef.set(cleanPatientData);

      print("✅ Patient added with correct format");
      print("Patient ID: ${patient.id}");
      print("Symptoms type: ${patientData["symptoms"].runtimeType}"); // Should be String

    } catch (e) {
      print("❌ Error adding patient: $e");
      rethrow;
    }
  }

  // Get CHW name for the current user
  Future<String> getChwName() async {
    try {
      final chwId = _auth.currentUser!.uid;
      final doc = await _firestore.collection("chws").doc(chwId).get();
      return doc.data()?['name'] ?? 'Unknown CHW';
    } catch (e) {
      return 'Unknown CHW';
    }
  }
}