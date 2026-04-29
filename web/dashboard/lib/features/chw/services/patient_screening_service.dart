import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:tbcare_main/features/chw/models/patient_screening_model.dart';

class ScreeningService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // AI Model Configuration
  static const String _aiEndpoint = "https://ammarr-x1-tb-detection.hf.space/predict";
  static const String _cloudName = "de1oz7jbg";
  static const String _coughPreset = "unsigned_preset";
  static const String _xrayPreset = "upload_x-ray";

  String get chwId => _auth.currentUser!.uid;

  // 🔹 Recording Variables
  AudioRecorder? _audioRecorder;
  bool isRecording = false;
  bool _isUploadingAudio = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String _recordingStatus = "Tap to record cough";

  // Callback for UI updates
  Function(void)? onRecordingStateChanged;
  Function(String)? onRecordingStatusChanged;

  // AI Analysis Callback
  Function(bool)? onAiAnalysisStarted;
  Function(Map<String, dynamic>?)? onAiAnalysisCompleted;

  /// 🧠 Get AI Prediction from the deployed model
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

      // Send request to AI endpoint
      var request = http.MultipartRequest("POST", Uri.parse(_aiEndpoint));
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

  /// 🎤 Simple method to pick audio file
  Future<String?> pickCoughAudioFile() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();
      return await _uploadBytesToCloudinary(
          bytes,
          _coughPreset,
          "cough_${DateTime.now().millisecondsSinceEpoch}.mp3"
      );
    } catch (e) {
      print("❌ Audio file pick error: $e");
      throw Exception("Failed to pick audio file: $e");
    }
  }

  /// 📸 Pick and upload X-ray
  Future<String?> pickAndUploadXray() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return null;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        return await _uploadBytesToCloudinary(
            bytes,
            _xrayPreset,
            "xray_${DateTime.now().millisecondsSinceEpoch}.png"
        );
      } else {
        File file = File(pickedFile.path);
        return await _uploadToCloudinary(file, _xrayPreset, "image");
      }
    } catch (e) {
      print("❌ X-ray upload error: $e");
      return null;
    }
  }

  /// 📤 Submit screening with REAL AI analysis
  Future<Screening> submitScreening(Screening screening, {String? xrayUrl}) async {
    try {
      print("▶️ Starting submission for patient: ${screening.patientId}");

      // Validate required fields
      final coughUrl = screening.media?['coughUrl'];
      if (coughUrl == null || coughUrl.isEmpty) {
        throw Exception("Cough audio URL is missing. Please record cough first.");
      }

      if (xrayUrl == null || xrayUrl.isEmpty) {
        throw Exception("X-ray URL is missing. Please upload X-ray first.");
      }

      final chwRef = _db.collection('chws').doc(chwId);
      final patientRef = chwRef.collection('assigned_patients').doc(screening.patientId);
      final screeningRef = patientRef.collection('screenings').doc();

      // Create initial screening data
      final screeningData = {
        'screeningId': screeningRef.id,
        'patientId': screening.patientId,
        'patientName': screening.patientName,
        'chwId': chwId,
        'symptoms': screening.symptoms,
        'media': {
          'coughUrl': coughUrl,
          'xrayUrl': xrayUrl,
        },
        'aiPrediction': null,
        'aiRawData': null,
        'aiConfidence': null,
        'status': 'ai_processing', // New status for AI processing
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'assignedDoctorId': screening.assignedDoctorId,
        'assignedDoctorName': screening.assignedDoctorName,
      };

      // Save initial screening data
      await screeningRef.set(screeningData);
      print("✅ Screening saved with status = ai_processing");

      // Notify UI that AI analysis has started
      if (onAiAnalysisStarted != null) {
        onAiAnalysisStarted!(true);
      }

      // Get AI Prediction from real model
      print("🚀 Starting AI analysis for X-ray...");
      final aiResponse = await _getAiPrediction(xrayUrl);

      // Prepare AI result data
      Map<String, dynamic> aiPredictionData;
      String aiStatus = 'ai_completed';

      if (aiResponse != null && aiResponse['success'] == true) {
        final prediction = aiResponse['prediction'] as Map<String, dynamic>;
        final aiClass = prediction['class']?.toString() ?? "Unknown";
        final confidence = (prediction['confidence'] as num).toDouble();
        final normalProb = (prediction['normal_probability'] as num).toDouble();
        final tbProb = (prediction['tb_probability'] as num).toDouble();

        aiPredictionData = {
          'class': aiClass,
          'confidence': confidence,
          'normal_probability': normalProb,
          'tb_probability': tbProb,
        };

        print("✅ AI Analysis Complete: $aiClass ($confidence%)");

        // Update screening with AI results
        await screeningRef.update({
          'aiPrediction': aiPredictionData,
          'aiRawData': aiResponse,
          'aiConfidence': confidence,
          'status': aiStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print("✅ AI results saved — status = ai_completed");

        // Notify UI that AI analysis is complete
        if (onAiAnalysisCompleted != null) {
          onAiAnalysisCompleted!(aiPredictionData);
        }

        // Return updated Screening
        return screening.copyWith(
          id: screeningRef.id,
          aiPrediction: aiPredictionData,
          status: aiStatus,
          media: {
            'coughUrl': coughUrl,
            'xrayUrl': xrayUrl,
          },
        );
      } else {
        // AI analysis failed
        print("⚠ AI Analysis failed or returned invalid response");

        aiPredictionData = {
          'class': 'Analysis Failed',
          'confidence': 0.0,
          'normal_probability': 0.0,
          'tb_probability': 0.0,
          'message': 'AI analysis failed. Please try again or consult doctor directly.',
        };

        await screeningRef.update({
          'aiPrediction': aiPredictionData,
          'status': 'ai_failed',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print("⚠ Screening saved with ai_failed status");

        if (onAiAnalysisCompleted != null) {
          onAiAnalysisCompleted!(null);
        }

        return screening.copyWith(
          id: screeningRef.id,
          aiPrediction: aiPredictionData,
          status: 'ai_failed',
          media: {
            'coughUrl': coughUrl,
            'xrayUrl': xrayUrl,
          },
        );
      }

    } catch (e, st) {
      print("❌ Error submitting screening: $e");
      print(st);

      // Notify UI of failure
      if (onAiAnalysisCompleted != null) {
        onAiAnalysisCompleted!(null);
      }

      rethrow;
    }
  }

  /// ☁️ Upload bytes to Cloudinary
  Future<String?> _uploadBytesToCloudinary(Uint8List bytes, String preset, String fileName) async {
    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/auto/upload");
      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = preset
        ..files.add(http.MultipartFile.fromBytes("file", bytes, filename: fileName));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);
        return data['secure_url'] as String?;
      } else {
        throw Exception("Cloudinary upload failed: $resBody");
      }
    } catch (e) {
      print("❌ Upload exception: $e");
      throw Exception("Upload exception: $e");
    }
  }

  /// ☁️ Upload file to Cloudinary
  Future<String?> _uploadToCloudinary(File file, String preset, String resourceType) async {
    try {
      final url = Uri.parse(
          "https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload"
      );

      final request = http.MultipartRequest("POST", url)
        ..fields["upload_preset"] = preset
        ..files.add(await http.MultipartFile.fromPath("file", file.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);
        print("✅ File uploaded: ${data["secure_url"]}");
        return data["secure_url"] as String?;
      } else {
        print("❌ Upload failed: $resBody");
        return null;
      }
    } catch (e) {
      print("❌ Upload failed: $e");
      return null;
    }
  }

  /// 📤 Get recording status for UI
  String get recordingStatus => _recordingStatus;

  /// ⏱ Get recording duration for UI
  Duration get recordingDuration => _recordingDuration;

  /// 📤 Get uploading status for UI
  bool get isUploadingAudio => _isUploadingAudio;

  /// 🧹 Clean up resources
  void dispose() {
    _audioRecorder?.dispose();
    _recordingTimer?.cancel();
  }
}