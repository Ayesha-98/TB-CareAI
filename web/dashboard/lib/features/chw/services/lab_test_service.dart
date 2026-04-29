import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class LabTestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Get patients needing lab test
  Future<Map<String, dynamic>?> getSinglePatientLabTest(
      String patientId, String screeningId) async {
    // 🔹 Fetch from the main patients collection instead of CHW’s copy
    final screeningDoc = await _db
        .collection('patients')
        .doc(patientId)
        .collection('screenings')
        .doc(screeningId)
        .get();

    if (!screeningDoc.exists) return null;

    final data = screeningDoc.data()!;
    final status = (data['status'] ?? '').toString().toLowerCase().trim();

    print("🧩 [LabTest] Patient $patientId screening status → $status");

    // 🔹 Match lowercase variants
    if (status == 'needs lab test' || status == 'needs_lab_test') {
      return data;
    }

    return null;
  }



  /// 📂 Pick file (Ali style - using image picker)
  Future<File?> pickFile() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print("❌ File pick error: $e");
    }
    return null;
  }

  /// ☁️ Upload file to Cloudinary
  Future<String> uploadToCloudinary(File file) async {
    const cloudName = 'de1oz7jbg';
    const uploadPreset = 'upload_tests'; // 🔹 Make sure this exists in Cloudinary

    final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/auto/upload");

    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await request.send();
    final resStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonRes = jsonDecode(resStr);
      return jsonRes["secure_url"];
    } else {
      throw Exception("Cloudinary upload failed: $resStr");
    }
  }

  /// 💾 Save lab test record in Firestore
  Future<void> saveLabTest({
    required String patientId,
    required String screeningId,
    required String testName,
    required String fileUrl,
  }) async {
    final labTestId = _db
        .collection('patients')
        .doc()
        .id;
    final chwId = FirebaseAuth.instance.currentUser!.uid;

    final labTestData = {
      "labTestId": labTestId,
      "testName": testName,
      "status": "Uploaded",
      "comments": "",
      "fileUrl": fileUrl,
      "requestedAt": FieldValue.serverTimestamp(),
      "uploadedAt": FieldValue.serverTimestamp(),
    };

    // 🔹 Save lab test under screenings
    await _db
        .collection('patients')
        .doc(patientId)
        .collection('screenings')
        .doc(screeningId)
        .collection('labTests')
        .doc(labTestId)
        .set(labTestData);

    // 🔹 Update main patient status
    await _db.collection('patients').doc(patientId).update({
      "status": "lab test uploaded",
      "lastUpdated": FieldValue.serverTimestamp(),
    });

    // 🔹 Update CHW’s assigned_patients copy (for dashboard refresh)
    await _db
        .collection('chws')
        .doc(chwId)
        .collection('assigned_patients')
        .doc(patientId)
        .update({
      "status": "lab test uploaded",
      "lastUpdated": FieldValue.serverTimestamp(),
    });
  }
}
