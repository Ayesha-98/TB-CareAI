import 'dart:typed_data';
import 'dart:io' show File;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestReportScreen extends StatefulWidget {
  const TestReportScreen({super.key});

  @override
  State<TestReportScreen> createState() => _TestReportScreenState();
}

class _TestReportScreenState extends State<TestReportScreen> {
  // Web: Using Uint8List for image bytes (instead of File)
  Uint8List? _imageBytes;
  File? _imageFile;
  bool _isUploading = false;
  late String patientId = "";

  // ☁️ Cloudinary Config
  final String cloudName = "de1oz7jbg";
  final String uploadPreset = "upload_x-ray";

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signin');
      }
      return;
    }

    setState(() {
      patientId = user.uid;
    });
  }

  // 📸 Step 1: Pick Image (Web compatible)
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      if (kIsWeb) {
        // For web: read as bytes
        final bytes = await pickedFile.readAsBytes();

        // Validate file size (max 5MB)
        if (bytes.length > 5 * 1024 * 1024) {
          _showSnackBar("❌ Image size must be less than 5MB");
          return;
        }

        setState(() {
          _imageBytes = bytes;
          _imageFile = null;
        });
      } else {
        // For mobile: use File
        final file = File(pickedFile.path);
        final stat = await file.stat();

        if (stat.size > 5 * 1024 * 1024) {
          _showSnackBar("❌ Image size must be less than 5MB");
          return;
        }

        setState(() {
          _imageFile = file;
          _imageBytes = null;
        });
      }

      _showSnackBar("✅ Image selected successfully!");
    } catch (e) {
      debugPrint("❌ Error picking image: $e");
      _showSnackBar("❌ Failed to pick image: $e");
    }
  }

  // 📤 Upload to Cloudinary & Save to Firestore
  Future<void> _uploadAndSave() async {
    if ((_imageBytes == null && _imageFile == null)) {
      _showSnackBar("⚠ Please select an image first");
      return;
    }

    if (patientId.isEmpty) {
      _showSnackBar("⚠ User not authenticated. Please sign in again.");
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;

      if (kIsWeb && _imageBytes != null) {
        // Web: Upload bytes
        imageUrl = await uploadBytesToCloudinary(
            _imageBytes!,
            uploadPreset,
            "test_report_${DateTime.now().millisecondsSinceEpoch}.jpg"
        );
      } else if (_imageFile != null) {
        // Mobile: Upload file
        imageUrl = await uploadToCloudinary(_imageFile!, uploadPreset);
      }

      if (imageUrl != null) {
        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .collection('testReports')
            .add({
          'testType': 'Sputum Test Report',
          'imageUrl': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Uploaded',
        });

        _showSnackBar("✅ Report saved successfully!");

        // Reset form
        setState(() {
          _imageBytes = null;
          _imageFile = null;
        });
      } else {
        _showSnackBar("❌ Upload failed. Please try again.");
      }
    } catch (e) {
      debugPrint("❌ Upload error: $e");
      _showSnackBar("❌ Error: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ☁️ Upload File to Cloudinary (Mobile)
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
      }
      return null;
    } catch (e) {
      debugPrint("❌ Upload exception: $e");
      return null;
    }
  }

  // ☁️ Upload Bytes to Cloudinary (Web)
  Future<String?> uploadBytesToCloudinary(Uint8List bytes, String preset, String fileName) async {
    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/auto/upload");
      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = preset
        ..files.add(http.MultipartFile.fromBytes("file", bytes, filename: fileName));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);
        return data['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint("❌ Upload exception: $e");
      return null;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains("✅") ? Colors.green :
        message.contains("⚠") ? Colors.orange :
        Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1B4D3E);
    final hasImage = (_imageBytes != null || _imageFile != null);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Test Report"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.assignment, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sputum Test Report",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Upload your laboratory test results",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Image Preview Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: !hasImage
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      "No Image Selected",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "JPG, PNG up to 5MB",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: kIsWeb && _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.contain)
                      : _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.contain)
                      : const SizedBox(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_isUploading)
              const Column(
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 12),
                  Text("Uploading to Cloudinary...", style: TextStyle(color: Colors.grey)),
                ],
              )
            else ...[
              // Select Image Button
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text("Select From Gallery"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Upload Button
              ElevatedButton.icon(
                onPressed: (!hasImage || patientId.isEmpty) ? null : _uploadAndSave,
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Upload & Save to Profile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),

              if (hasImage) ...[
                const SizedBox(height: 12),
                // Clear Image Button
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _imageBytes = null;
                      _imageFile = null;
                    });
                    _showSnackBar("Image cleared");
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text("Clear Selected Image"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 45),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),

            // Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Upload your sputum test report for doctor review. Supported formats: JPG, PNG (Max 5MB)",
                      style: TextStyle(color: Colors.blue[800], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}