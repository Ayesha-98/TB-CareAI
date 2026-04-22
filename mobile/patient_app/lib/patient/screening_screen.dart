import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
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

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
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
      // If no user is logged in, redirect to signin
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signin');
      }
      return;
    }

    setState(() {
      patientId = user.uid; // ✅ Set dynamic patient ID from logged in user
    });

    _authAndFetchDoctors();
  }

  Future<void> _authAndFetchDoctors() async {
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
        // Update patientId after anonymous sign-in
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          setState(() {
            patientId = user.uid;
          });
        }
      } catch (e) {
        debugPrint("❌ Auth Failed: $e");
      }
    }
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

      //  Update patient profile with selected doctor
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
  void toggleSymptom(String symptom) {
    setState(() {
      selectedSymptoms.contains(symptom) ? selectedSymptoms.remove(symptom) : selectedSymptoms.add(symptom);
    });
  }

  Future<void> recordCough() async {
    if (kIsWeb) return;
    try {
      if (!_isRecording) {
        if (!await Permission.microphone.request().isGranted) return;
        final dir = await getTemporaryDirectory();
        final filePath = "${dir.path}/cough_${DateTime.now().millisecondsSinceEpoch}.m4a";
        await _recorder.start(const RecordConfig(), path: filePath);
        setState(() => _isRecording = true);
      } else {
        final path = await _recorder.stop();
        setState(() => _isRecording = false);
        if (path != null) {
          final url = await uploadToCloudinary(File(path), coughPreset);
          setState(() => coughAudioUrl = url);
        }
      }
    } catch (e) { setState(() => _isRecording = false); }
  }

  Future<void> pickAndUploadXray() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    _showSnackBar("Uploading to Cloudinary...");
    String? url;
    if (kIsWeb) {
      url = await uploadBytesToCloudinary(await pickedFile.readAsBytes(), xrayPreset, "xray.jpg");
    } else {
      url = await uploadToCloudinary(File(pickedFile.path), xrayPreset);
    }
    setState(() => xrayImageUrl = url);
  }

  Future<String?> uploadToCloudinary(File file, String preset) async {
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/auto/upload");
    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = preset
      ..files.add(await http.MultipartFile.fromPath("file", file.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      return jsonDecode(await response.stream.bytesToString())['secure_url'];
    }
    return null;
  }

  Future<String?> uploadBytesToCloudinary(Uint8List bytes, String preset, String fileName) async {
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/auto/upload");
    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = preset
      ..files.add(http.MultipartFile.fromBytes("file", bytes, filename: fileName));
    final response = await request.send();
    if (response.statusCode == 200) {
      return jsonDecode(await response.stream.bytesToString())['secure_url'];
    }
    return null;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          // --- Added Hovering Button Here ---
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
                const SizedBox(height: 100), // Extra space so button doesn't cover content
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

  // --- Modular UI Builders (Keep your existing UI logic) ---

  Widget _buildDoctorDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Doctor", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: DropdownButton<String>(
            isExpanded: true,
            underline: const SizedBox(),
            value: _selectedDoctorId,
            hint: const Text("Choose a doctor"),
            items: _doctors.map((d) => DropdownMenuItem(value: d['id'], child: Text("Dr. ${d['name']}"))).toList(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text("Cough Audio Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic, size: 50, color: _isRecording ? Colors.red : primaryColor),
            onPressed: recordCough,
          ),
          if (coughAudioUrl != null) const Text("✅ Audio Ready", style: TextStyle(color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildXraySection() {
    return GestureDetector(
      onTap: pickAndUploadXray,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
        child: xrayImageUrl == null
            ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40), Text("Upload X-ray")])
            : ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(xrayImageUrl!, fit: BoxFit.cover)),
      ),
    );
  }

  Widget _buildSymptomSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: symptoms.map((s) => CheckboxListTile(
          title: Text(s),
          value: selectedSymptoms.contains(s),
          onChanged: (_) => toggleSymptom(s),
          activeColor: primaryColor,
        )).toList(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: (patientId.isEmpty || _isSubmitting) ? null : submitScreening,
        child: const Text("Submit & Run AI Analysis", style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }
}