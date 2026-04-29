import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'nearby_hospitals_screen.dart';

// 🎨 Theme colors
const primaryColor = Color(0xFF1B4D3E);
const secondaryColor = Color(0xFFFFFFFF);
const bgColor = Color(0xFFF5F7F6);
const accentColor = Color(0xFF2E8B57);

class ScreeningScreen extends StatefulWidget {
  const ScreeningScreen({super.key});

  @override
  State<ScreeningScreen> createState() => _ScreeningScreenState();
}

class _ScreeningScreenState extends State<ScreeningScreen> {
  late String patientId = ""; // Will be set dynamically from Firebase Auth

  List<Map<String, String>> _doctors = [];
  String? _selectedDoctorId;
  String? _selectedDoctorName;
  bool _isLoadingDoctors = true;
  bool _isSubmitting = false;

  final List<String> symptoms = [
    "Persistent cough", "Fever", "Weight loss", "Night sweats", "Chest pain",
    "Fatigue or weakness", "Blood in cough", "Shortness of breath", "Loss of appetite", "Swollen lymph nodes"
  ];
  List<String> selectedSymptoms = [];

  // Web: Using file upload instead of recording
  bool _isUploadingAudio = false;
  String? coughAudioUrl;
  String? xrayImageUrl;

  // Cloudinary & AI Config
  final String cloudName = "de1oz7jbg";
  final String coughPreset = "unsigned_preset";
  final String xrayPreset = "upload_x-ray";
  final String aiEndpoint = "https://ammarr-x1-tb-detection.hf.space/predict";

  @override
  void initState() {
    super.initState();
    _getUserIdAndInit();
  }

  Future<void> _getUserIdAndInit() async {
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

    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('doctors').get();
      final doctorsList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name']?.toString() ?? 'Unknown Doctor',
          'specialization': data['specialization']?.toString() ?? 'General',
        };
      }).toList();

      setState(() {
        _doctors = doctorsList;
        _isLoadingDoctors = false;
      });
    } catch (e) {
      setState(() => _isLoadingDoctors = false);
      debugPrint("❌ Error fetching doctors: $e");
    }
  }

  /// 🧠 Step 1: Get AI Prediction from Hugging Face
  Future<Map<String, dynamic>?> _getAiPrediction(String imageUrl) async {
    try {
      final imgResponse = await http.get(Uri.parse(imageUrl));
      if (imgResponse.statusCode != 200) return null;

      var request = http.MultipartRequest("POST", Uri.parse(aiEndpoint));
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imgResponse.bodyBytes,
        filename: 'xray_analysis.jpg',
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        return jsonDecode(respStr);
      }
      return null;
    } catch (e) {
      debugPrint("AI Error: $e");
      return null;
    }
  }

  /// 🎤 Upload Cough Audio (Web compatible)
  Future<void> uploadCoughAudio() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      setState(() => _isUploadingAudio = true);
      _showSnackBar("Uploading audio file...");

      String? uploadedUrl;
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        uploadedUrl = await uploadBytesToCloudinary(
            bytes,
            coughPreset,
            "cough_${DateTime.now().millisecondsSinceEpoch}.mp3"
        );
      } else {
        final file = File(pickedFile.path);
        uploadedUrl = await uploadToCloudinary(file, coughPreset);
      }

      if (uploadedUrl != null && mounted) {
        setState(() {
          coughAudioUrl = uploadedUrl;
          _isUploadingAudio = false;
        });
        _showSnackBar("✅ Cough audio uploaded successfully!");
      } else {
        throw Exception("Upload failed");
      }
    } catch (e) {
      debugPrint("❌ Audio upload error: $e");
      if (mounted) {
        setState(() => _isUploadingAudio = false);
      }
      _showSnackBar("❌ Upload failed: ${e.toString()}");
    }
  }

  /// 🩻 Pick & upload X-ray
  Future<void> pickAndUploadXray() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    _showSnackBar("Uploading X-ray...");
    String? url;
    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      url = await uploadBytesToCloudinary(bytes, xrayPreset, "xray_${DateTime.now().millisecondsSinceEpoch}.jpg");
    } else {
      url = await uploadToCloudinary(File(pickedFile.path), xrayPreset);
    }
    setState(() => xrayImageUrl = url);
    if (url != null) {
      _showSnackBar("✅ X-ray uploaded successfully!");
    } else {
      _showSnackBar("❌ X-ray upload failed.");
    }
  }

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

  void toggleSymptom(String symptom) {
    setState(() {
      selectedSymptoms.contains(symptom)
          ? selectedSymptoms.remove(symptom)
          : selectedSymptoms.add(symptom);
    });
  }

  /// 📤 Final Submission Logic
  Future<void> submitScreening() async {
    if (patientId.isEmpty) {
      _showSnackBar("⚠ User not authenticated. Please sign in again.");
      return;
    }

    if (_selectedDoctorId == null || coughAudioUrl == null || xrayImageUrl == null || selectedSymptoms.isEmpty) {
      _showSnackBar("⚠ Please complete all fields, audio, and X-ray.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final aiResponse = await _getAiPrediction(xrayImageUrl!);

      String aiStatus = "Analysis Failed";
      double confidence = 0.0;

      if (aiResponse != null && aiResponse['success'] == true) {
        aiStatus = aiResponse['prediction']['class'];
        confidence = (aiResponse['prediction']['confidence'] as num).toDouble();
      }

      final screeningData = {
        'assignedDoctorId': _selectedDoctorId,
        'assignedDoctorName': _selectedDoctorName,
        'symptoms': selectedSymptoms,
        'timestamp': FieldValue.serverTimestamp(),
        'coughAudio': coughAudioUrl,
        'xrayImage': xrayImageUrl,
        'status': 'pending',
        'aiPrediction': aiStatus,
        'aiConfidence': confidence,
        'aiRawData': aiResponse,
        'doctorDiagnosis': null,
        'diagnosedBy': null,
        'testReferred': null,
        'recommendations': null,
      };

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final existing = await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .collection('screenings')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update(screeningData);
      } else {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .collection('screenings')
            .add(screeningData);
      }

      // Update patient profile with selected doctor
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .update({
        'selectedDoctor': _selectedDoctorId,
        'lastScreeningDate': FieldValue.serverTimestamp(),
      });

      _showSnackBar("✅ Screening submitted! AI Result: $aiStatus (${confidence.toStringAsFixed(1)}%)");

      setState(() {
        selectedSymptoms.clear();
        coughAudioUrl = null;
        xrayImageUrl = null;
        _isSubmitting = false;
      });

    } catch (e) {
      setState(() => _isSubmitting = false);
      _showSnackBar("❌ Submit failed: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: primaryColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text("TB Screening", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: primaryColor,
            centerTitle: true,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NearbyHospitalsScreen()),
              );
            },
            backgroundColor: accentColor,
            icon: const Icon(Icons.local_hospital, color: Colors.white),
            label: const Text("Nearby Hospitals", style: TextStyle(color: Colors.white)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDoctorDropdown(),
                const SizedBox(height: 25),
                _buildAudioSection(),
                const SizedBox(height: 25),
                _buildXraySection(),
                const SizedBox(height: 25),
                _buildSymptomSection(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        if (_isSubmitting)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      SizedBox(height: 15),
                      Text("AI is analyzing your X-ray...", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ================= UI BUILDERS =================

  Widget _buildDoctorDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Doctor", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: _isLoadingDoctors
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          )
              : DropdownButton<String>(
            isExpanded: true,
            underline: const SizedBox(),
            value: _selectedDoctorId,
            hint: const Text("Choose a doctor"),
            items: _doctors.map((d) => DropdownMenuItem(
                value: d['id'],
                child: Text("Dr. ${d['name']}")
            )).toList(),
            onChanged: (v) => setState(() {
              _selectedDoctorId = v;
              _selectedDoctorName = _doctors.firstWhere((d) => d['id'] == v)['name'];
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text("Cough Audio Analysis", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isUploadingAudio ? null : uploadCoughAudio,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: coughAudioUrl != null ? Colors.green.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: coughAudioUrl != null ? Colors.green : primaryColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isUploadingAudio ? Icons.cloud_upload :
                    coughAudioUrl != null ? Icons.check_circle : Icons.upload_file,
                    color: _isUploadingAudio ? Colors.orange :
                    coughAudioUrl != null ? Colors.green : primaryColor,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isUploadingAudio ? "Uploading..." :
                      coughAudioUrl != null ? "Audio Uploaded ✓" : "Tap to upload cough audio",
                      style: TextStyle(
                        color: _isUploadingAudio ? Colors.orange :
                        coughAudioUrl != null ? Colors.green : primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (coughAudioUrl != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 6),
                  Text("Audio Ready", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildXraySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("X-ray Analysis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: pickAndUploadXray,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: xrayImageUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(xrayImageUrl!, fit: BoxFit.cover),
                  Container(color: Colors.black38),
                  const Center(child: Icon(Icons.check_circle, color: Colors.white, size: 50)),
                ],
              ),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 12),
                const Text("Tap to upload X-ray Image", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text("PNG, JPG supported", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
        ),
        if (xrayImageUrl != null) ...[
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 6),
                  Text("X-ray Uploaded", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSymptomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Symptoms", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: symptoms.map((symptom) {
              final isSelected = selectedSymptoms.contains(symptom);
              return Column(
                children: [
                  CheckboxListTile(
                    activeColor: primaryColor,
                    checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    title: Text(
                      symptom,
                      style: TextStyle(
                        color: isSelected ? primaryColor : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                    value: isSelected,
                    onChanged: (_) => toggleSymptom(symptom),
                  ),
                  if (symptom != symptoms.last)
                    Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.withOpacity(0.1)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: (patientId.isEmpty || _isSubmitting) ? null : submitScreening,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSubmitting
            ? const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            SizedBox(width: 12),
            Text("Processing...", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        )
            : const Text(
          "Submit & Run AI Analysis",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}