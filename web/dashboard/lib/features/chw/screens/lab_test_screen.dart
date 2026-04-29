import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tbcare_main/features/chw/services/lab_test_service.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class LabTestScreen extends StatefulWidget {
  const LabTestScreen({super.key});

  @override
  State<LabTestScreen> createState() => _LabTestScreenState();
}

class _LabTestScreenState extends State<LabTestScreen> {
  final LabTestService _service = LabTestService();
  final ImagePicker _picker = ImagePicker();

  // File upload state
  File? _pickedFile;
  bool _isUploading = false;
  String? _uploadedFileUrl;
  String _uploadStatus = "Tap to select lab test report";

  // Form fields
  final TextEditingController _testNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Cloudinary config (same as screening screen)
  final String _cloudName = "de1oz7jbg";
  final String _uploadPreset = "upload_tests";

  @override
  void dispose() {
    _testNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // 🔹 Upload file to Cloudinary (similar to screening screen)
  Future<String?> uploadToCloudinary(File file) async {
    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/auto/upload");
      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath("file", file.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);
        return data['secure_url'] as String?;
      } else {
        debugPrint("❌ Cloudinary upload failed: $resBody");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Upload exception: $e");
      return null;
    }
  }

  // 🔹 Upload bytes to Cloudinary (for web)
  Future<String?> uploadBytesToCloudinary(Uint8List bytes, String fileName) async {
    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/auto/upload");
      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(http.MultipartFile.fromBytes("file", bytes, filename: fileName));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);
        return data['secure_url'] as String?;
      } else {
        debugPrint("❌ Cloudinary upload failed: $resBody");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Upload exception: $e");
      return null;
    }
  }

  // 🔹 Pick and upload file (similar to screening screen)
  Future<void> pickAndUploadFile() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
        _uploadStatus = "Uploading file...";
      });

      String? uploadedUrl;

      if (kIsWeb) {
        // For web: read as bytes
        final bytes = await pickedFile.readAsBytes();
        uploadedUrl = await uploadBytesToCloudinary(
          bytes,
          "labtest_${DateTime.now().millisecondsSinceEpoch}.${pickedFile.name.split('.').last}",
        );
      } else {
        // For mobile: upload file directly
        final file = File(pickedFile.path);
        uploadedUrl = await uploadToCloudinary(file);
      }

      if (uploadedUrl != null && mounted) {
        setState(() {
          _uploadedFileUrl = uploadedUrl;
          _isUploading = false;
          _uploadStatus = "File uploaded successfully!";
          _pickedFile = File(pickedFile.path);
        });
        _showSnackBar("✅ Lab test report uploaded successfully!");
      } else {
        throw Exception("Upload failed");
      }
    } catch (e) {
      debugPrint("❌ File upload error: $e");
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = "Upload error. Try again.";
        });
      }
      _showSnackBar("❌ Upload failed: ${e.toString()}");
    }
  }

  // 🔹 Submit lab test data
  Future<void> submitLabTest(String patientId, String screeningId) async {
    // Validate inputs
    if (_testNameController.text.isEmpty) {
      _showSnackBar("⚠ Please enter test name");
      return;
    }

    if (_uploadedFileUrl == null) {
      _showSnackBar("⚠ Please upload lab test report");
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Save to Firestore using the service
      await _service.saveLabTest(
        patientId: patientId,
        screeningId: screeningId,
        testName: _testNameController.text,
        fileUrl: _uploadedFileUrl!,
      );

      _showSnackBar("✅ Lab test results submitted successfully!");

      // Navigate back after successful submission
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("❌ Error submitting lab test: $e");
      _showSnackBar("❌ Submit failed: $e");
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 🔹 Build file upload section (similar to screening screen)
  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.upload_file, color: primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              "Lab Test Report Upload",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: pickAndUploadFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: _uploadedFileUrl != null ? Colors.green : Colors.grey.withOpacity(0.3),
                width: _uploadedFileUrl != null ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Message
                Text(
                  _uploadStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isUploading ? Colors.orange :
                    _uploadedFileUrl != null ? Colors.green : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 15),

                // Upload Icon
                Icon(
                  _isUploading ? Icons.cloud_upload :
                  _uploadedFileUrl != null ? Icons.check_circle : Icons.upload_file,
                  color: _isUploading ? Colors.orange :
                  _uploadedFileUrl != null ? Colors.green : primaryColor,
                  size: 50,
                ),
                const SizedBox(height: 10),

                // File type info
                const Text(
                  "PDF, JPG, PNG up to 10MB",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),

                // Upload button text
                Text(
                  _isUploading ? "Uploading..." :
                  _uploadedFileUrl != null ? "✓ Uploaded" : "Tap to select file",
                  style: TextStyle(
                    color: _isUploading ? Colors.orange :
                    _uploadedFileUrl != null ? Colors.green : primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Loading indicator
                if (_isUploading) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(
                    backgroundColor: Colors.grey,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ],

                // Uploaded info
                if (_uploadedFileUrl != null && _pickedFile != null) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_file, color: Colors.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pickedFile!.path.split('/').last,
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!kIsWeb)
                                Text(
                                  "${(_pickedFile!.lengthSync() / 1024).toStringAsFixed(1)} KB",
                                  style: TextStyle(
                                    color: Colors.green.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() {
                              _pickedFile = null;
                              _uploadedFileUrl = null;
                              _uploadStatus = "Tap to select lab test report";
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get patientId and screeningId passed from CHW Dashboard
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final patientId = args['patientId'] ?? '';
    final screeningId = args['screeningId'] ?? '';
    final patientName = args['patientName'] ?? 'Unnamed Patient';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Lab Test - $patientName"),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _service.getSinglePatientLabTest(patientId, screeningId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          if (snapshot.hasError) {
            return _buildErrorScreen(snapshot.error.toString());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return _buildNoDataScreen(patientName, patientId);
          }

          final data = snapshot.data!;
          final status = (data['status'] ?? '').toString().toLowerCase();
          final isPending = status == 'needs lab test' || status == 'needs_lab_test';

          return _buildMainContent(data, patientId, screeningId, patientName, isPending);
        },
      ),
    );
  }

  Widget _buildMainContent(Map<String, dynamic> data, String patientId,
      String screeningId, String patientName, bool isPending) {

    // If not pending (already completed), show completed view
    if (!isPending) {
      return _buildCompletedView(data);
    }

    // Pending - show upload form
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, color: primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: TextStyle(
                              color: secondaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Patient ID: ${patientId.length > 8 ? '${patientId.substring(0, 8)}...' : patientId}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.medical_information,
                      color: warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Lab Test Status",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "PENDING - NEEDS LAB TEST",
                            style: TextStyle(
                              color: warningColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Test Information Form
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_services, color: primaryColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "Test Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Test Name Field
                TextFormField(
                  controller: _testNameController,
                  decoration: InputDecoration(
                    labelText: "Test Name*",
                    prefixIcon: Icon(Icons.badge, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter test name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Notes Field (Optional)
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Additional Notes (Optional)",
                    prefixIcon: Icon(Icons.note, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // File Upload Section
          _buildFileUploadSection(),

          const SizedBox(height: 30),

          // Requirements Checklist
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Requirements Checklist:",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                _buildChecklistItem("Test name entered", _testNameController.text.isNotEmpty),
                _buildChecklistItem("Lab report uploaded", _uploadedFileUrl != null),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : () => submitLabTest(patientId, screeningId),
              icon: Icon(
                _isUploading ? Icons.upload : Icons.send_rounded,
                color: Colors.white,
              ),
              label: Text(
                _isUploading ? "Submitting..." : "Submit Lab Test Results",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 4,
                shadowColor: primaryColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.circle_outlined,
            color: completed ? Colors.green : Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: completed ? Colors.black : Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedView(Map<String, dynamic> data) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 3),
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 20),
            Text(
              "Lab Test Completed",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "The lab test results have been uploaded and processed.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text("Back to Dashboard"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading, Error, and No Data Screens
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 16),
          Text(
            "Loading Lab Test Information...",
            style: TextStyle(
              color: secondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: errorColor, size: 64),
            const SizedBox(height: 16),
            Text(
              "Error Loading Lab Test Data",
              style: TextStyle(
                color: errorColor,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataScreen(String patientName, String patientId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Lab Test Required",
            style: TextStyle(
              color: secondaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This patient doesn't require lab tests at the moment.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}