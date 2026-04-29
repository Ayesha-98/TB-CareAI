import 'package:flutter/material.dart';
import 'package:tbcare_main/features/chw/models/patient_screening_model.dart';
import 'package:tbcare_main/features/chw/services/patient_screening_service.dart';
import 'package:tbcare_main/features/chw/screens/chw_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientScreeningScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientScreeningScreen({
    Key? key,
    required this.patientId,
    required this.patientName,
  }) : super(key: key);

  @override
  State<PatientScreeningScreen> createState() => _PatientScreeningScreenState();
}

class _PatientScreeningScreenState extends State<PatientScreeningScreen> {
  late ScreeningService service;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Map<String, String>> _doctors = [];
  String? _selectedDoctorId;
  String? _selectedDoctorName;
  bool _isLoadingDoctors = true;
  bool _isLoading = false;
  bool _isUploadingAudio = false; // Track audio upload progress

  // AI Processing State
  bool _isAiAnalyzing = false;
  Map<String, dynamic>? _aiResult;
  String _aiStatus = "";

  // Colors
  static const primaryColor = Color(0xFF1B4D3E);
  static const secondaryColor = Color(0xFF2E7D32);
  static const bgColor = Color(0xFFF8FDF9);
  static const cardColor = Colors.white;

  // Symptoms list
  final List<String> symptoms = [
    "Persistent cough (more than 2 weeks)",
    "Fever",
    "Weight loss",
    "Night sweats",
    "Chest pain",
    "Fatigue",
    "Blood in cough",
    "Shortness of breath",
    "Loss of appetite",
    "Swollen lymph nodes"
  ];

  List<String> selectedSymptoms = [];
  String? coughAudioUrl;
  String? xrayUrl;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    service = ScreeningService();

    // Set up AI callbacks
    service.onAiAnalysisStarted = (isStarted) {
      if (mounted) {
        setState(() {
          _isAiAnalyzing = isStarted;
        });
      }
    };

    service.onAiAnalysisCompleted = (result) {
      if (mounted) {
        setState(() {
          _isAiAnalyzing = false;
          _aiResult = result;
          if (result != null) {
            _aiStatus = "AI Analysis Complete: ${result['class']} (${result['confidence']?.toStringAsFixed(2)}%)";
          } else {
            _aiStatus = "AI Analysis Failed";
          }
        });
      }
    };

    _fetchDoctors();
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    try {
      final snapshot = await _db.collection('doctors').get();
      final doctorsList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name']?.toString() ?? data['displayName']?.toString() ?? 'Unknown Doctor',
          'specialization': data['specialization']?.toString() ?? 'General',
          'email': data['email']?.toString() ?? '',
        };
      }).toList();

      setState(() {
        _doctors = doctorsList;
        _isLoadingDoctors = false;
      });
    } catch (e) {
      setState(() => _isLoadingDoctors = false);
      _showSnackBar('Failed to load doctors', isError: true);
    }
  }

  Future<void> _selectAndUploadAudio() async {
    try {
      setState(() {
        _isUploadingAudio = true;
      });

      _showSnackBar('Opening file explorer...');

      final url = await service.pickCoughAudioFile();

      if (url != null) {
        setState(() {
          coughAudioUrl = url;
          _isUploadingAudio = false;
        });
        _showSnackBar('Audio file uploaded successfully');
      } else {
        setState(() {
          _isUploadingAudio = false;
        });
        _showSnackBar('No file selected', isError: true);
      }
    } catch (e) {
      setState(() {
        _isUploadingAudio = false;
      });
      _showSnackBar('Failed to upload audio: $e', isError: true);
    }
  }

  Future<void> _uploadXray() async {
    try {
      final url = await service.pickAndUploadXray();
      if (url != null) {
        setState(() => xrayUrl = url);
        _showSnackBar('X-ray uploaded successfully');
      } else {
        _showSnackBar('X-ray upload failed');
      }
    } catch (e) {
      _showSnackBar('Failed to upload X-ray: $e', isError: true);
    }
  }

  Future<void> _submitScreening() async {
    if (!_validateForm()) {
      _showSnackBar('Please complete all required fields', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isAiAnalyzing = false;
      _aiResult = null;
    });

    try {
      // Get current CHW ID
      final chwId = _auth.currentUser!.uid;

      // Get doctor name from selected doctor
      final selectedDoctor = _doctors.firstWhere(
            (doctor) => doctor['id'] == _selectedDoctorId,
        orElse: () => {'name': 'Unknown Doctor', 'specialization': 'General'},
      );
      final doctorName = selectedDoctor['name'];

      // Show AI analysis starting
      _showSnackBar('Starting AI analysis...');

      final screening = Screening(
        id: null, // Will be generated by Firestore
        patientId: widget.patientId,
        patientName: widget.patientName,
        symptoms: selectedSymptoms,
        media: {
          'coughUrl': coughAudioUrl ?? '',
          'xrayUrl': xrayUrl ?? '',
        },
        aiPrediction: {'Normal': '0.0', 'TB': '0.0'}, // Default
        status: 'pending_analysis',
        timestamp: Timestamp.now(),
        assignedDoctorId: _selectedDoctorId,
        assignedDoctorName: doctorName,
        chwId: chwId,
        coughAudioPath: '', // Update this if needed
      );

      await service.submitScreening(screening, xrayUrl: xrayUrl);

      // Show success message with AI result
      if (_aiResult != null) {
        final aiClass = _aiResult!['class'] ?? 'Unknown';
        final confidence = _aiResult!['confidence'] ?? 0.0;
        _showSuccessDialog(aiClass: aiClass, confidence: confidence);
      } else {
        _showSuccessDialog();
      }

    } catch (e, st) {
      setState(() {
        _isLoading = false;
        _isAiAnalyzing = false;
      });
      print("❌ Error in _submitScreening: $e");
      print(st);
      _showSnackBar('Submission failed: ${e.toString()}', isError: true);
    }
  }

  bool _validateForm() {
    if (_selectedDoctorId == null) {
      _showSnackBar('Please select a doctor', isError: true);
      return false;
    }
    if (coughAudioUrl == null) {
      _showSnackBar('Please upload cough audio', isError: true);
      return false;
    }
    if (selectedSymptoms.isEmpty) {
      _showSnackBar('Please select at least one symptom', isError: true);
      return false;
    }
    if (xrayUrl == null) {
      _showSnackBar('Please upload X-ray', isError: true);
      return false;
    }
    return true;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _showSuccessDialog({String aiClass = 'Unknown', double confidence = 0.0}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Screening Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Screening has been successfully submitted for AI analysis.'),
            const SizedBox(height: 16),
            if (_aiResult != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _aiResult!['class'] == 'TB'
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _aiResult!['class'] == 'TB' ? Icons.warning : Icons.check_circle,
                      color: _aiResult!['class'] == 'TB' ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Analysis Result:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _aiResult!['class'] == 'TB' ? Colors.red : Colors.green,
                            ),
                          ),
                          Text(
                            '${_aiResult!['class']} (${(_aiResult!['confidence'] ?? 0.0).toStringAsFixed(2)}% confidence)',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The results have been sent to Dr. $_selectedDoctorName for review.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CHWDashboard()),
            (route) => false,
      );
    });
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 4,
            decoration: BoxDecoration(
              color: index <= _currentStep ? primaryColor : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Text(
              widget.patientName.isNotEmpty ? widget.patientName[0] : 'P',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${widget.patientId.length > 8 ? '${widget.patientId.substring(0, 8)}...' : widget.patientId}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDoctorSelection();
      case 1:
        return _buildCoughUpload();
      case 2:
        return _buildSymptomsSelection();
      case 3:
        return _buildXrayUpload();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDoctorSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign Doctor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a doctor for review',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoadingDoctors
                  ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
                  : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDoctorId,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Select a doctor'),
                  ),
                  isExpanded: true,
                  menuMaxHeight: 400,
                  itemHeight: 60,
                  items: _doctors.map((doctor) {
                    return DropdownMenuItem<String>(
                      value: doctor['id'],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. ${doctor['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doctor['specialization']!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              doctor['email'] ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDoctorId = value;
                      if (value != null) {
                        final doctor = _doctors.firstWhere(
                              (doc) => doc['id'] == value,
                          orElse: () => {'name': 'Unknown Doctor'},
                        );
                        _selectedDoctorName = doctor['name'];
                        print("👨‍⚕️ Selected Doctor: ${doctor['name']} (ID: $value)");
                      }
                    });
                  },
                ),
              ),
            ),
            if (_selectedDoctorId != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected: Dr. $_selectedDoctorName',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${_selectedDoctorId!.substring(0, 8)}...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoughUpload() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cough Audio Upload',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a clear recording of patient\'s cough',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: coughAudioUrl != null
                    ? Colors.green.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: coughAudioUrl != null
                      ? Colors.green.shade200
                      : Colors.blue.shade200,
                ),
              ),
              child: Column(
                children: [
                  if (_isUploadingAudio)
                    Column(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            strokeWidth: 4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Uploading Audio...',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait while we upload your file',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.upload),
                          label: const Text('Uploading...'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Icon(
                          coughAudioUrl != null
                              ? Icons.check_circle
                              : Icons.audio_file,
                          size: 60,
                          color: coughAudioUrl != null
                              ? Colors.green.shade600
                              : Colors.blue.shade600,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          coughAudioUrl != null
                              ? 'Audio Uploaded'
                              : 'Upload Cough Audio',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          coughAudioUrl != null
                              ? 'Ready for analysis'
                              : 'Select audio file from device',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _selectAndUploadAudio,
                          icon: Icon(coughAudioUrl != null
                              ? Icons.change_circle
                              : Icons.upload_file),
                          label: Text(
                            coughAudioUrl != null
                                ? 'Change Audio File'
                                : 'Select Audio File',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Symptoms',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text('${selectedSymptoms.length} selected'),
                  backgroundColor: primaryColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select all symptoms the patient is experiencing',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Horizontal scrollable symptoms
            SizedBox(
              height: 120, // Fixed height for horizontal list
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: symptoms.length,
                itemBuilder: (context, index) {
                  final symptom = symptoms[index];
                  final isSelected = selectedSymptoms.contains(symptom);

                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 8,
                      right: index == symptoms.length - 1 ? 0 : 8,
                    ),
                    child: Column(
                      children: [
                        // Circular symptom selector
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedSymptoms.remove(symptom);
                              } else {
                                selectedSymptoms.add(symptom);
                              }
                            });
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor.withOpacity(0.2)
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                isSelected ? primaryColor : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                _getSymptomIcon(symptom),
                                size: 28,
                                color: isSelected
                                    ? primaryColor
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Symptom label with limited text
                        SizedBox(
                          width: 80,
                          child: Text(
                            _getShortenedSymptomName(symptom),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? primaryColor
                                  : Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Selected symptoms chips below
            if (selectedSymptoms.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Selected Symptoms:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedSymptoms.map((symptom) {
                  return Chip(
                    label: Text(symptom),
                    backgroundColor: primaryColor.withOpacity(0.1),
                    labelStyle: TextStyle(color: primaryColor, fontSize: 12),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        selectedSymptoms.remove(symptom);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to get icon for each symptom
  IconData _getSymptomIcon(String symptom) {
    if (symptom.toLowerCase().contains('cough')) return Icons.coronavirus;
    if (symptom.toLowerCase().contains('fever')) return Icons.thermostat;
    if (symptom.toLowerCase().contains('weight')) return Icons.monitor_weight;
    if (symptom.toLowerCase().contains('sweat')) return Icons.water_drop;
    if (symptom.toLowerCase().contains('chest')) return Icons.favorite;
    if (symptom.toLowerCase().contains('fatigue')) return Icons.bedtime;
    if (symptom.toLowerCase().contains('blood')) return Icons.bloodtype;
    if (symptom.toLowerCase().contains('breath')) return Icons.air;
    if (symptom.toLowerCase().contains('appetite')) return Icons.restaurant;
    if (symptom.toLowerCase().contains('lymph')) return Icons.health_and_safety;
    return Icons.medical_services;
  }

  // Helper method to shorten symptom names for the horizontal view
  String _getShortenedSymptomName(String symptom) {
    if (symptom.contains('Persistent cough')) return 'Cough';
    if (symptom.contains('Weight loss')) return 'Weight Loss';
    if (symptom.contains('Night sweats')) return 'Night Sweats';
    if (symptom.contains('Chest pain')) return 'Chest Pain';
    if (symptom.contains('Blood in cough')) return 'Blood Cough';
    if (symptom.contains('Shortness of breath')) return 'Breathlessness';
    if (symptom.contains('Loss of appetite')) return 'No Appetite';
    if (symptom.contains('Swollen lymph nodes')) return 'Swollen Nodes';
    return symptom.split(' ').take(2).join(' ');
  }

  Widget _buildXrayUpload() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'X-ray Upload',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload the patient\'s chest X-ray',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: xrayUrl != null
                    ? Colors.green.shade50
                    : Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: xrayUrl != null
                      ? Colors.green.shade200
                      : Colors.purple.shade200,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    xrayUrl != null ? Icons.check_circle : Icons.image,
                    size: 60,
                    color: xrayUrl != null
                        ? Colors.green.shade600
                        : Colors.purple.shade600,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    xrayUrl != null ? 'X-ray Uploaded' : 'Upload X-ray',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    xrayUrl != null
                        ? 'Ready for analysis'
                        : 'Select JPG or PNG file',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _uploadXray,
                    icon: const Icon(Icons.upload_file),
                    label:
                    Text(xrayUrl != null ? 'Change X-ray' : 'Select X-ray File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildReviewSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Review Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildReviewItem('Doctor Assigned', _selectedDoctorId != null),
            _buildReviewItem('Cough Audio Uploaded', coughAudioUrl != null),
            _buildReviewItem('Symptoms Selected', selectedSymptoms.isNotEmpty),
            _buildReviewItem('X-ray Uploaded', xrayUrl != null),

            // Show doctor details if selected
            if (_selectedDoctorId != null && _selectedDoctorName != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Doctor:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Dr. $_selectedDoctorName'),
                    Text(
                      'ID: ${_selectedDoctorId!.substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.circle_outlined,
            color: completed ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: completed ? Colors.black : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('TB Screening'),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPatientInfo(),
                const SizedBox(height: 24),
                _buildStepIndicator(),
                const SizedBox(height: 24),
                _buildStepContent(),
                const SizedBox(height: 24),
                if (_currentStep == 3) ...[
                  _buildReviewSummary(),
                  const SizedBox(height: 24),
                ],

                // AI Status Indicator
                if (_isAiAnalyzing)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Analysis in Progress',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Analyzing X-ray for TB detection...',
                                style: TextStyle(
                                  color: Colors.blue.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isAiAnalyzing ? null : () {
                            if (_currentStep > 0) {
                              setState(() => _currentStep--);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: primaryColor),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: _currentStep > 0 ? 2 : 1,
                      child: ElevatedButton(
                        onPressed: _isAiAnalyzing ? null : () {
                          if (_currentStep < 3) {
                            setState(() => _currentStep++);
                          } else {
                            _submitScreening();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          _currentStep < 3 ? 'Continue' : 'Submit & Run AI Analysis',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // AI Loading Overlay
          if (_isAiAnalyzing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: primaryColor),
                        const SizedBox(height: 20),
                        const Text(
                          'AI Analysis in Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Our AI model is analyzing the X-ray image\nfor TB detection. This may take a few seconds...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}