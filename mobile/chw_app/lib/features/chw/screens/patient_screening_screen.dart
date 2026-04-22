import 'package:flutter/material.dart';
import 'package:tbcare_main/features/chw/models/patient_screening_model.dart';
import 'package:tbcare_main/features/chw/services/patient_screening_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbcare_main/core/app_constants.dart';

class PatientScreeningScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientScreeningScreen({
    Key? key,
    required this.patientId,
    required this.patientName,
  }) : super(key: key);

  @override
  State<PatientScreeningScreen> createState() => _ScreeningScreenState();
}

class _ScreeningScreenState extends State<PatientScreeningScreen> {
  final ScreeningService service = ScreeningService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Doctor Selection Data
  List<Map<String, String>> _doctors = [];
  String? _selectedDoctorId;
  String? _selectedDoctorName;
  bool _isLoadingDoctors = true;

  final List<String> symptoms = [
    "Persistent cough (more than 2 weeks)",
    "Fever",
    "Weight loss (unintentional)",
    "Night sweats",
    "Chest pain",
    "Fatigue or weakness",
    "Blood in cough",
    "Shortness of breath",
    "Loss of appetite",
    "Swollen lymph nodes"
  ];

  List<String> selectedSymptoms = [];
  String? coughAudioUrl;
  String? xrayUrl;
  bool _isLoading = false;
  bool _isAiAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _authAndFetchDoctors();
  }

  /// 🔐 1. Ensure Auth, then 2. Fetch Doctors
  Future<void> _authAndFetchDoctors() async {
    if (_auth.currentUser == null) {
      debugPrint("⚠ No user logged in. Signing in anonymously to fetch doctors...");
      try {
        await _auth.signInAnonymously();
        debugPrint("✅ Signed in Anonymously: ${_auth.currentUser!.uid}");
      } catch (e) {
        debugPrint("❌ Auth Failed: $e");
      }
    }
    _fetchDoctors();
  }

  /// 👨‍⚕ Fetch Doctors from Firestore
  Future<void> _fetchDoctors() async {
    try {
      final snapshot = await _db.collection('doctors').get();
      final doctorsList = snapshot.docs.map((doc) {
        final data = doc.data();
        final name = data['name']?.toString() ?? data['Name']?.toString() ?? 'Unknown Doctor';
        return {
          'id': doc.id,
          'name': name,
          'specialization': data['specialization']?.toString() ?? 'General',
        };
      }).toList();

      setState(() {
        _doctors = doctorsList;
        _isLoadingDoctors = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetching doctors: $e");
      setState(() => _isLoadingDoctors = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error loading doctors: $e")));
      }
    }
  }

  void toggleSymptom(String symptom) {
    setState(() {
      if (selectedSymptoms.contains(symptom)) {
        selectedSymptoms.remove(symptom);
      } else {
        selectedSymptoms.add(symptom);
      }
    });
  }

  Future<void> handleRecord() async {
    try {
      final path = await service.recordCough();

      if (service.isRecording) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎤 Recording started... please ask patient to cough")),
        );
      } else if (path != null) {
        setState(() {
          coughAudioUrl = path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Cough recording saved")),
        );
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Recording error: $e")),
      );
    }
  }

  Future<void> pickXrayFile() async {
    try {
      setState(() => _isLoading = true);
      final url = await service.pickAndUploadXray();
      if (url != null) {
        setState(() => xrayUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ X-ray uploaded successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ X-ray upload failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to upload X-ray: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> handleSubmit() async {
    // Validation
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please select a Doctor for review")),
      );
      return;
    }

    if (selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please select at least one symptom")),
      );
      return;
    }

    if (xrayUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please upload X-ray image")),
      );
      return;
    }

    if (coughAudioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please record cough audio")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isAiAnalyzing = true;
    });

    try {
      // Create screening object with doctor assignment
      final screening = Screening(
        patientId: widget.patientId,
        patientName: widget.patientName,
        chwId: service.chwId,
        symptoms: selectedSymptoms,
        coughAudioPath: coughAudioUrl!,
        media: {
          'coughUrl': '',
          'xrayUrl': xrayUrl!,
        },
        aiPrediction: {'Normal': '0.0', 'TB': '0.0'},
        status: 'pending_analysis',
        timestamp: Timestamp.now(),
        assignedDoctorId: _selectedDoctorId,
        assignedDoctorName: _selectedDoctorName,
      );

      final submittedScreening = await service.submitScreening(screening, xrayUrl: xrayUrl);

      setState(() => _isAiAnalyzing = false);

      // Show AI result
      _showAiResultDialog(submittedScreening);

    } catch (e) {
      setState(() {
        _isLoading = false;
        _isAiAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Screening submission failed: $e")),
      );
    }
  }

  void _showAiResultDialog(Screening screening) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.science, color: primaryColor),
                      const SizedBox(width: 10),
                      const Text(
                        "AI Analysis Complete",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "X-ray Analysis Result:",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: screening.tbProbability > 0.5
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: screening.tbProbability > 0.5 ? Colors.red : Colors.green,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          screening.aiDiagnosis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: screening.tbProbability > 0.5 ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Confidence Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.psychology,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Confidence: ${(screening.aiConfidence ?? 0).toStringAsFixed(2)}%",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // TB Probability Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              screening.tbProbability > 0.5
                                  ? Icons.warning
                                  : Icons.check_circle,
                              size: 16,
                              color: screening.tbProbability > 0.5
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "TB Probability: ${(screening.tbProbability * 100).toStringAsFixed(2)}%",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Doctor Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.medical_services,
                              color: primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Doctor Assignment",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Screening has been assigned to Dr. ${screening.assignedDoctorName} for review.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context); // Go back to previous screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🛠 Helper for Doctor Selection Section
  Widget _buildDoctorSelectionSection() {
    return _buildSectionCard(
      title: "Assign Doctor *",
      icon: Icons.medical_services,
      children: [
        Text(
          "Select a doctor to review this screening:",
          style: TextStyle(color: Colors.grey.shade700),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: _isLoadingDoctors
              ? Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
              : DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDoctorId,
              hint: Text("Choose a reviewing doctor"),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
              items: _doctors.map((doc) {
                return DropdownMenuItem<String>(
                  value: doc['id'],
                  child: Text(
                    "Dr. ${doc['name']} (${doc['specialization']})",
                    style: TextStyle(color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDoctorId = value;
                  _selectedDoctorName = _doctors.firstWhere((doc) => doc['id'] == value)['name'];
                });
              },
            ),
          ),
        ),
        if (_selectedDoctorId == null) ...[
          SizedBox(height: 8),
          Text(
            "⚠️ Doctor selection is required",
            style: TextStyle(color: errorColor, fontSize: 12),
          ),
        ] else ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: successColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: successColor, size: 20),
                SizedBox(width: 8),
                Text("Assigned to Dr. $_selectedDoctorName", style: TextStyle(color: successColor)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text(
              "Screening - ${widget.patientName}",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            backgroundColor: primaryColor,
            iconTheme: IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Info Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryColor,
                          radius: 24,
                          child: Text(
                            widget.patientName[0],
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.patientName,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Patient ID: ${widget.patientId.substring(0, 8)}...',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // 👨‍⚕ Doctor Selection Section
                _buildDoctorSelectionSection(),

                SizedBox(height: 20),

                // Cough Recording Section
                _buildSectionCard(
                  title: "Cough Recording *",
                  icon: Icons.mic,
                  children: [
                    Text(
                      "Record patient's cough for AI analysis (Required)",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: handleRecord,
                        icon: Icon(service.isRecording ? Icons.stop : Icons.mic_none),
                        label: Text(service.isRecording ? "Stop Recording" : "Record Cough Audio"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: service.isRecording ? errorColor : primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (coughAudioUrl != null) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: successColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: successColor, size: 20),
                            SizedBox(width: 8),
                            Text("Cough recording saved", style: TextStyle(color: successColor)),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: 8),
                      Text(
                        "⚠️ Cough recording is required",
                        style: TextStyle(color: errorColor, fontSize: 12),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: 20),

                // Symptoms Section
                _buildSectionCard(
                  title: "TB Symptoms Checklist *",
                  icon: Icons.medical_services,
                  children: [
                    Text(
                      "Select all symptoms the patient is experiencing:",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    SizedBox(height: 12),
                    Column(
                      children: symptoms.map((symptom) => Card(
                        elevation: 1,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: CheckboxListTile(
                          title: Text(symptom, style: TextStyle(fontSize: 14)),
                          value: selectedSymptoms.contains(symptom),
                          onChanged: (_) => toggleSymptom(symptom),
                          activeColor: primaryColor,
                          dense: true,
                        ),
                      )).toList(),
                    ),
                    if (selectedSymptoms.isEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        "⚠️ Please select at least one symptom",
                        style: TextStyle(color: errorColor, fontSize: 12),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: 20),

                // X-ray Section
                _buildSectionCard(
                  title: "X-ray Upload *",
                  icon: Icons.upload_file,
                  children: [
                    Text(
                      "Upload X-ray image for analysis (Required)",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: pickXrayFile,
                        icon: _isLoading
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(Icons.cloud_upload),
                        label: Text(_isLoading ? "Uploading..." :
                        xrayUrl == null ? "Upload X-ray Image" : "X-ray Uploaded"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: xrayUrl == null ? primaryColor : successColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (xrayUrl != null) ...[
                      SizedBox(height: 8),
                      Text(
                        "✓ X-ray successfully uploaded",
                        style: TextStyle(color: successColor, fontSize: 12),
                      ),
                    ] else ...[
                      SizedBox(height: 8),
                      Text(
                        "⚠️ X-ray upload is required",
                        style: TextStyle(color: errorColor, fontSize: 12),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: 32),

                // Submit Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || _isAiAnalyzing ? null : handleSubmit,
                    icon: _isAiAnalyzing
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.analytics),
                    label: Text(_isAiAnalyzing ? "AI Analyzing..." :
                    _isLoading ? "Uploading..." : "Submit for AI Analysis"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // AI Info Box
                if (_isAiAnalyzing)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.science, color: Colors.purple, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "AI Analysis in Progress",
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Our AI model is analyzing the X-ray for TB detection. This may take a few seconds...",
                                style: TextStyle(
                                  color: Colors.purple.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Loading overlay for AI analysis
        if (_isAiAnalyzing)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      SizedBox(height: 20),
                      Text(
                        "AI is analyzing X-ray...",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Please wait while our AI model processes the X-ray image",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 20),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}