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

  /// Get lab test information for a specific patient
  Future<Map<String, dynamic>?> getSinglePatientLabTest(
      String patientId, String screeningId) async {
    try {
      print("🔄 [LabTestService] Getting lab test for patient: $patientId, screening: $screeningId");

      // 1️⃣ Get existing lab tests
      final labTestsRef = _db
          .collection('patients')
          .doc(patientId)
          .collection('screenings')
          .doc(screeningId)
          .collection('labTests');

      final labTestsSnap = await labTestsRef.get();

      bool hasUploadedTests = false;
      final List<Map<String, dynamic>> uploadedTests = [];
      final List<Map<String, dynamic>> pendingTests = [];
      final List<Map<String, dynamic>> allTests = [];

      for (final labTestDoc in labTestsSnap.docs) {
        final labTestData = labTestDoc.data();
        final status = (labTestData['status'] ?? '').toString().toLowerCase();

        final testInfo = {
          'id': labTestDoc.id,
          'docId': labTestDoc.id, // 🔥 ADD THIS: The actual Firestore document ID
          ...labTestData,
        };

        allTests.add(testInfo);

        if (status == 'uploaded' || status.contains('upload')) {
          hasUploadedTests = true;
          uploadedTests.add(testInfo);
        } else if (status == 'pending' || status.contains('needs')) {
          pendingTests.add(testInfo);
        }
      }

      // 2️⃣ Get screening data
      final screeningDoc = await _db
          .collection('patients')
          .doc(patientId)
          .collection('screenings')
          .doc(screeningId)
          .get();

      if (!screeningDoc.exists) {
        print("❌ Screening document doesn't exist");
        return null;
      }

      final screeningData = screeningDoc.data()!;

      // 3️⃣ Get requested tests from diagnosis
      final diagnosisSnapshot = await _db
          .collection('patients')
          .doc(patientId)
          .collection('screenings')
          .doc(screeningId)
          .collection('diagnosis')
          .get();

      final List<String> requestedTests = [];
      final List<String> doctorRequestedTests = [];

      for (final diagnosisDoc in diagnosisSnapshot.docs) {
        final diagnosisData = diagnosisDoc.data();
        final tests = diagnosisData['requestedTests'];

        if (tests is List) {
          for (final test in tests) {
            final testName = test.toString();
            if (testName.isNotEmpty && !doctorRequestedTests.contains(testName)) {
              doctorRequestedTests.add(testName);
            }
          }
        }
      }

      // 4️⃣ Combine doctor requested tests with pending tests
      requestedTests.addAll(doctorRequestedTests);

      for (final pendingTest in pendingTests) {
        final testName = (pendingTest['testName'] ?? '').toString();
        if (testName.isNotEmpty && !requestedTests.contains(testName)) {
          requestedTests.add(testName);
        }
      }

      // 5️⃣ Determine actual status
      String actualStatus;

      if (hasUploadedTests) {
        actualStatus = 'lab_test_uploaded';
        print("✅ Patient has uploaded lab tests");
      } else if (requestedTests.isNotEmpty || pendingTests.isNotEmpty) {
        actualStatus = 'needs_lab_test';
        print("⚠️ Patient needs lab tests but hasn't uploaded yet");
      } else {
        actualStatus = (screeningData['status'] ?? '').toString();
        print("📋 Using screening status: $actualStatus");
      }

      // 6️⃣ Prepare result
      final Map<String, dynamic> resultData = {
        'patientId': patientId,
        'screeningId': screeningId,
        'status': actualStatus,
        'requestedTests': requestedTests,
        'uploadedTests': uploadedTests,
        'pendingTests': pendingTests,
        'allTests': allTests, // 🔥 ADD THIS: Include all tests
        'hasUploadedTests': hasUploadedTests,
        'screeningData': screeningData,
      };

      print("✅ [LabTestService] Returning data with status: $actualStatus");
      print("✅ Requested tests: $requestedTests");
      print("✅ All tests count: ${allTests.length}");
      print("✅ First test docId: ${allTests.isNotEmpty ? allTests.first['docId'] : 'none'}");

      return resultData;

    } catch (e) {
      print("❌ Error in getSinglePatientLabTest: $e");
      return null;
    }
  }

  /// 📂 Pick file
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
    const uploadPreset = 'upload_tests';

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

  /// 💾 Save lab test record in Firestore - FIXED
  Future<void> saveLabTest({
    required String patientId,
    required String screeningId,
    required String testName,
    required String fileUrl,
  }) async {
    final chwId = FirebaseAuth.instance.currentUser!.uid;

    print("🚀 [SAVE LAB TEST] Starting upload...");
    print("   Patient: $patientId");
    print("   Screening: $screeningId");
    print("   Test: $testName");

    // 1️⃣ First, get ALL existing lab tests to find the correct one
    final labTestsRef = _db
        .collection('patients')
        .doc(patientId)
        .collection('screenings')
        .doc(screeningId)
        .collection('labTests');

    final existingLabTestsSnap = await labTestsRef.get();

    print("📊 Found ${existingLabTestsSnap.docs.length} existing lab test documents");

    String existingDocId = '';
    Map<String, dynamic>? existingData;

    // 🔥 CRITICAL FIX: Look for the EXACT document that matches
    for (final doc in existingLabTestsSnap.docs) {
      final data = doc.data();
      final existingTestName = (data['testName'] ?? '').toString();
      final existingStatus = (data['status'] ?? '').toString();
      final labTestId = (data['labTestId'] ?? '').toString();

      print("🔍 Checking doc ${doc.id}:");
      print("   - testName: '$existingTestName'");
      print("   - status: '$existingStatus'");
      print("   - labTestId: '$labTestId'");

      // Check if this is the document we should update
      // Match by test name OR check if status is pending
      if ((existingTestName.toLowerCase() == testName.toLowerCase()) ||
          (existingStatus.toLowerCase() == 'pending' && existingTestName.isNotEmpty)) {
        existingDocId = doc.id;
        existingData = data;
        print("✅ FOUND matching document with ID: $existingDocId");
        break;
      }
    }

    // 2️⃣ Prepare the document ID and data
    String finalDocId;
    Map<String, dynamic> labTestData;

    if (existingDocId.isNotEmpty) {
      // 🔥 UPDATE existing document
      finalDocId = existingDocId;
      print("🔄 Will UPDATE existing document: $finalDocId");

      // Preserve existing data where appropriate
      labTestData = {
        "testName": testName,
        "status": "Uploaded",
        "fileUrl": fileUrl,
        "uploadedAt": FieldValue.serverTimestamp(),
        "comments": "", // Add comments field
      };

      // Keep the original requestedAt if it exists
      if (existingData != null && existingData.containsKey('requestedAt')) {
        labTestData["requestedAt"] = existingData['requestedAt'];
        print("🕒 Keeping original requestedAt");
      } else {
        labTestData["requestedAt"] = FieldValue.serverTimestamp();
      }

      // Keep the original labTestId if it exists
      if (existingData != null && existingData.containsKey('labTestId') &&
          (existingData['labTestId'] ?? '').toString().isNotEmpty) {
        labTestData["labTestId"] = existingData['labTestId'];
        print("🔑 Keeping original labTestId: ${existingData['labTestId']}");
      } else {
        labTestData["labTestId"] = finalDocId;
      }
    } else {
      // CREATE new document (fallback)
      finalDocId = _db.collection('patients').doc().id;
      print("📄 No matching document found. Creating NEW: $finalDocId");

      labTestData = {
        "labTestId": finalDocId,
        "testName": testName,
        "status": "Uploaded",
        "comments": "",
        "fileUrl": fileUrl,
        "requestedAt": FieldValue.serverTimestamp(),
        "uploadedAt": FieldValue.serverTimestamp(),
      };
    }

    // 3️⃣ Save or update the document
    try {
      await labTestsRef.doc(finalDocId).set(labTestData, SetOptions(merge: true));
      print("✅ Document saved/updated successfully!");
    } catch (e) {
      print("❌ Error saving document: $e");
      rethrow;
    }

    // 4️⃣ Update screening status
    try {
      await _db
          .collection('patients')
          .doc(patientId)
          .collection('screenings')
          .doc(screeningId)
          .update({
        "status": "lab_test_uploaded",
        "updatedAt": FieldValue.serverTimestamp(),
      });
      print("✅ Screening status updated");
    } catch (e) {
      print("❌ Error updating screening: $e");
    }

    // 5️⃣ Update patient's main status
    try {
      await _db.collection('patients').doc(patientId).update({
        "status": "lab_test_uploaded",
        "lastUpdated": FieldValue.serverTimestamp(),
      });
      print("✅ Patient status updated");
    } catch (e) {
      print("❌ Error updating patient: $e");
    }

    // 6️⃣ Update CHW's assigned_patients copy
    try {
      await _db
          .collection('chws')
          .doc(chwId)
          .collection('assigned_patients')
          .doc(patientId)
          .update({
        "status": "lab_test_uploaded",
        "lastUpdated": FieldValue.serverTimestamp(),
      });
      print("✅ CHW assigned patients updated");
    } catch (e) {
      print("❌ Error updating CHW: $e");
    }

    print("🎉 Lab test upload completed!");
  }

  /// 🔥 NEW: Method to find the correct document ID to update
  Future<String?> findLabTestDocumentId(
      String patientId, String screeningId, String testName) async {
    try {
      final labTestsRef = _db
          .collection('patients')
          .doc(patientId)
          .collection('screenings')
          .doc(screeningId)
          .collection('labTests');

      final labTestsSnap = await labTestsRef.get();

      // First, try exact match on test name
      for (final doc in labTestsSnap.docs) {
        final data = doc.data();
        final existingTestName = (data['testName'] ?? '').toString();

        if (existingTestName.toLowerCase() == testName.toLowerCase()) {
          print("✅ Found exact match: ${doc.id}");
          return doc.id;
        }
      }

      // If no exact match, try finding any pending test
      for (final doc in labTestsSnap.docs) {
        final data = doc.data();
        final existingStatus = (data['status'] ?? '').toString().toLowerCase();

        if (existingStatus == 'pending') {
          print("✅ Found pending test: ${doc.id}");
          return doc.id;
        }
      }

      print("❌ No matching document found");
      return null;
    } catch (e) {
      print("❌ Error finding document: $e");
      return null;
    }
  }
}