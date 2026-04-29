import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart'; // Add this for web support

class DoctorQualificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 📤 Upload file to Cloudinary (WORKS FOR BOTH WEB & MOBILE)
  Future<String> uploadToCloudinary(dynamic file) async {
    const cloudName = 'de1oz7jbg';
    const uploadPreset = 'doctor_documents';

    final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/auto/upload");
    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = uploadPreset;

    // 🔥 Handle WEB uploads
    if (kIsWeb) {
      if (file is PlatformFile) {
        final bytes = file.bytes!;
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        );
        request.files.add(multipartFile);
      } else {
        throw Exception('Invalid file type for web upload');
      }
    }
    // 📱 Handle MOBILE uploads
    else {
      if (file is File) {
        request.files.add(await http.MultipartFile.fromPath(
          "file",
          file.path,
          filename: file.path.split('/').last,
        ));
      } else {
        throw Exception('Invalid file type for mobile upload');
      }
    }

    try {
      final response = await request.send();
      final resStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonRes = jsonDecode(resStr);
        return jsonRes["secure_url"];
      } else {
        throw Exception("Cloudinary upload failed: $resStr");
      }
    } catch (e) {
      print("❌ Cloudinary upload error: $e");
      rethrow;
    }
  }

  /// 📂 Pick file (WORKS FOR BOTH WEB & MOBILE)
  Future<dynamic> pickFile() async {
    try {
      if (kIsWeb) {
        // 🔥 WEB: Use file_picker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
          withData: true, // IMPORTANT: Get file bytes for web
        );

        if (result != null && result.files.isNotEmpty) {
          return result.files.first; // Returns PlatformFile
        }
      } else {
        // 📱 MOBILE: Use image_picker
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          return File(pickedFile.path);
        }
      }
    } catch (e) {
      print("❌ File pick error: $e");
    }
    return null;
  }

  /// 💾 Save doctor qualifications to Firestore
  Future<void> saveDoctorQualifications({
    required String doctorId,
    required String name,
    required String email,
    required String qualifications,
    required String licenseNumber,
    required int experienceYears,
    required String hospital,
    required List<String> documents,
    required String password,
  }) async {
    await _db.collection('doctor_applications').doc(doctorId).set({
      'doctorId': doctorId,
      'name': name,
      'email': email,
      'qualifications': qualifications,
      'licenseNumber': licenseNumber,
      'specialization': 'TB Specialist',
      'experienceYears': experienceYears,
      'hospital': hospital,
      'documents': documents,
      'submittedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    }, SetOptions(merge: true));
  }
}