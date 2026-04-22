import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:record/record.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tbcare_main/features/chw/models/patient_screening_model.dart';

class ScreeningService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioRecorder _recorder = AudioRecorder();

  // 🔹 Cloudinary config
  final String cloudName = "de1oz7jbg";
  final String coughPreset = "unsigned_preset";
  final String xrayPreset = "upload_x-ray";

  // 🔹 AI Config
  final String aiEndpoint = "https://ammarr-x1-tb-detection.hf.space/predict";

  String get chwId => _auth.currentUser!.uid;

  bool isRecording = false;
  String? _lastRecordedFilePath;

  /// 🎤 Start/Stop recording with single toggle
  Future<String?> recordCough() async {
    try {
      if (!isRecording) {
        final micStatus = await Permission.microphone.request();
        if (!micStatus.isGranted) throw Exception(
            "Microphone permission not granted");

        final hasPermission = await _recorder.hasPermission();
        if (!hasPermission) throw Exception("No recorder permission");

        final dir = await getApplicationDocumentsDirectory();
        final path = "${dir.path}/cough_${DateTime
            .now()
            .millisecondsSinceEpoch}.m4a";

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        isRecording = true;
        _lastRecordedFilePath = path;
        return null;
      } else {
        final path = await _recorder.stop();
        isRecording = false;
        _lastRecordedFilePath = path;
        return path;
      }
    } catch (e) {
      print("❌ Recording error: $e");
      rethrow;
    }
  }

  /// ☁️ Upload file to Cloudinary
  Future<String?> uploadToCloudinary(File file, String preset) async {
    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/auto/upload");
      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = preset
        ..files.add(await http.MultipartFile.fromPath("file", file.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);
        return data['secure_url'] as String?;
      } else {
        print("❌ Cloudinary upload failed: $resBody");
        return null;
      }
    } catch (e) {
      print("❌ Upload exception: $e");
      return null;
    }
  }

  /// ☁️ Upload cough to Cloudinary
  Future<String?> uploadCough(String patientId) async {
    try {
      if (_lastRecordedFilePath == null) return null;

      final file = File(_lastRecordedFilePath!);
      if (!await file.exists()) return null;

      final uploadedUrl = await uploadToCloudinary(file, coughPreset);

      if (uploadedUrl != null) {
        print("✅ Cough uploaded: $uploadedUrl");
        return uploadedUrl;
      } else {
        print("❌ Cough upload failed");
        return null;
      }
    } catch (e) {
      print("❌ Upload failed: $e");
      return null;
    }
  }

  /// ☁️ Upload X-ray (image) to Cloudinary
  Future<String?> pickAndUploadXray() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return null;

      final file = File(pickedFile.path);
      final uploadedUrl = await uploadToCloudinary(file, xrayPreset);

      if (uploadedUrl != null) {
        print("✅ X-ray uploaded: $uploadedUrl");
        return uploadedUrl;
      } else {
        print("❌ X-ray upload failed");
        return null;
      }
    } catch (e) {
      print("❌ X-ray upload error: $e");
      return null;
    }
  }

  /// 🧠 Get AI Prediction from Hugging Face
  Future<Map<String, dynamic>?> _getAiPrediction(String imageUrl) async {
    try {
      print("🤖 Sending X-ray to AI model: $imageUrl");

      // Fetch image bytes from Cloudinary URL
      final imgResponse = await http.get(Uri.parse(imageUrl));
      if (imgResponse.statusCode != 200) {
        print("❌ Failed to fetch image from Cloudinary: ${imgResponse.statusCode}");
        return null;
      }

      print("✅ Image fetched, size: ${imgResponse.bodyBytes.length} bytes");

      var request = http.MultipartRequest("POST", Uri.parse(aiEndpoint));
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imgResponse.bodyBytes,
        filename: 'xray_analysis.jpg',
      ));

      print("📤 Sending request to AI endpoint...");
      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        print("✅ AI response received: ${respStr.length} characters");

        final result = jsonDecode(respStr);
        print("🤖 AI Result: ${result['prediction']?['class']} (${result['prediction']?['confidence']}%)");

        return result;
      } else {
        print("❌ AI request failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ AI Error: $e");
      return null;
    }
  }

  /// 📤 Submit screening and save ONLY in CHW collection
  Future<Screening> submitScreening(Screening screening, {String? xrayUrl}) async {
    try {
      print("▶️ Starting submission for patient: ${screening.patientId}");
      print("💾 Saving ONLY in CHW collection: chws/$chwId/assigned_patients/${screening.patientId}/screenings");

      // 1. Upload cough audio
      final coughUrl = await uploadCough(screening.patientId);
      if (coughUrl == null) throw Exception("Cough audio upload failed");

      // 2. Get AI Prediction if xray exists
      Map<String, dynamic>? aiResponse;
      String aiClass = "Analysis Failed";
      double confidence = 0.0;
      double normalProbability = 0.0;
      double tbProbability = 0.0;
      bool success = false;
      String message = "AI Analysis Failed";

      if (xrayUrl != null && xrayUrl!.isNotEmpty) {
        aiResponse = await _getAiPrediction(xrayUrl!);

        if (aiResponse != null && aiResponse['success'] == true) {
          final prediction = aiResponse['prediction'] as Map<String, dynamic>;
          aiClass = prediction['class']?.toString() ?? "Unknown";
          confidence = (prediction['confidence'] as num).toDouble();
          normalProbability = (prediction['normal_probability'] as num).toDouble();
          tbProbability = (prediction['tb_probability'] as num).toDouble();
          success = true;
          message = "Diagnosis: $aiClass (${confidence.toStringAsFixed(2)}%)";

          print("✅ AI Analysis Complete: $aiClass ($confidence%)");
        } else {
          print("⚠ AI Analysis failed or returned invalid response");
        }
      }

      // 3. Prepare screening data with proper AI structure
      final screeningData = {
        'screeningId': '', // Will be set after document creation
        'patientId': screening.patientId,
        'patientName': screening.patientName,
        'chwId': chwId,
        'symptoms': screening.symptoms,
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Media URLs
        'coughAudio': coughUrl,
        'xrayImage': xrayUrl ?? '',

        // Doctor assignment
        'assignedDoctorId': screening.assignedDoctorId,
        'assignedDoctorName': screening.assignedDoctorName,

        // AI Integration Fields - NEW STRUCTURE
        'aiConfidence': confidence,
        'aiPrediction': aiClass,
        'aiRawData': aiResponse, // Storing full JSON response
        'message': message,
        'prediction': {
          'class': aiClass,
          'class_id': aiClass == "Normal" ? 0 : 1,
          'confidence': confidence,
          'normal_probability': normalProbability,
          'tb_probability': tbProbability,
        },
        'success': success,

        // Doctor review fields
        'doctorDiagnosis': null,
        'diagnosedBy': null,
        'testReferred': null,
        'recommendations': null,

        // Status
        'status': success ? 'ai_completed' : 'pending_analysis',
        'isFlagged': false, // Will be true when CHW sends to doctor
        'flaggedAt': null,
      };

      // 4. Save ONLY to CHW's assigned patients collection
      final chwRef = _db.collection('chws').doc(chwId);
      final patientRef = chwRef.collection('assigned_patients').doc(screening.patientId);
      final screeningRef = patientRef.collection('screenings').doc();

      // Update screening ID in data
      screeningData['screeningId'] = screeningRef.id;

      // Save the screening
      await screeningRef.set(screeningData);

      // 5. Update patient info in CHW collection with last screening details
      await patientRef.set({
        'patientId': screening.patientId,
        'patientName': screening.patientName,
        'lastScreeningDate': FieldValue.serverTimestamp(),
        'lastScreeningId': screeningRef.id,
        'lastScreeningStatus': screeningData['status'],
        'assignedDoctorId': screening.assignedDoctorId,
        'assignedDoctorName': screening.assignedDoctorName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ Screening saved ONLY in CHW collection with status = ${screeningData['status']}");
      print("📁 Path: chws/$chwId/assigned_patients/${screening.patientId}/screenings/${screeningRef.id}");

      // ✅ Return updated Screening with proper AI data
      return screening.copyWith(
        id: screeningRef.id,
        coughAudioPath: coughUrl,
        media: {
          'coughUrl': coughUrl,
          'xrayUrl': xrayUrl ?? '',
        },
        aiPrediction: {
          'Normal': normalProbability.toStringAsFixed(2),
          'TB': tbProbability.toStringAsFixed(2),
        },
        aiConfidence: confidence,
        aiRawData: aiResponse,
        message: message,
        prediction: {
          'class': aiClass,
          'class_id': aiClass == "Normal" ? 0 : 1,
          'confidence': confidence,
          'normal_probability': normalProbability,
          'tb_probability': tbProbability,
        },
        success: success,
        status: screeningData['status'] as String,
      );
    } catch (e, st) {
      print("❌ Error submitting screening: $e");
      print(st);
      rethrow;
    }
  }

  /// 📋 Get patient's screenings history (from CHW collection only)
  Stream<List<Screening>> getPatientScreenings(String patientId) {
    return _db
        .collection('chws')
        .doc(chwId)
        .collection('assigned_patients')
        .doc(patientId)
        .collection('screenings')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Screening.fromMap(doc.data()))
        .toList());
  }
}