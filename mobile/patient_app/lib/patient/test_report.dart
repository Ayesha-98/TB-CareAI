import 'dart:io';
import 'dart:convert';
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
  File? _image;
  bool _isUploading = false;
  late String patientId = ""; // Will be set dynamically from Firebase Auth

  // ☁️ Cloudinary Config (Matching your working screening screen)
  final String cloudName = "de1oz7jbg";
  final String uploadPreset = "upload_x-ray"; // Using your existing working preset

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If no user is logged in, redirect to signin
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signin');
      }
      return;
    }

    setState(() {
      patientId = user.uid; // ✅ Set dynamic patient ID from logged in user
    });
  }

  // 📸 Step 1: Pick Image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  // 📤 Step 2: Upload to Cloudinary & Save to Firestore
  Future<void> _uploadAndSave() async {
    if (_image == null) return;

    if (patientId.isEmpty) {
      _showSnackBar("⚠ User not authenticated. Please sign in again.");
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Upload to Cloudinary (Using the same logic as your screening screen)
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/auto/upload");
      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath("file", _image!.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final String imageUrl = jsonDecode(responseData)['secure_url'];

        // 2. Save to Firestore (patients/uid/testReports)
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

        _showSnackBar("✅ Report saved to Firebase successfully!");
        setState(() => _image = null);
      } else {
        _showSnackBar("❌ Cloudinary Error: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("❌ Error: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1B4D3E);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Test Report"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Select a photo of your Sputum Test result",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Image Preview Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                ),
                child: _image == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 70, color: Colors.grey),
                    Text("No Image Selected", style: TextStyle(color: Colors.grey)),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(_image!, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isUploading)
              const CircularProgressIndicator(color: primaryColor)
            else ...[
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Select From Gallery"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: (_image == null || patientId.isEmpty) ? null : _uploadAndSave,
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Upload & Save to Profile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}