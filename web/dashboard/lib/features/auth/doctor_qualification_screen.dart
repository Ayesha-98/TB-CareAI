import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/auth/services/doctor_qualification_service.dart';

class DoctorQualificationScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String doctorId;

  const DoctorQualificationScreen({
    Key? key,
    required this.doctorId,
    required this.name,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  State<DoctorQualificationScreen> createState() =>
      _DoctorQualificationScreenState();
}

class _DoctorQualificationScreenState
    extends State<DoctorQualificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qualificationsController = TextEditingController();
  final _licenseController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hospitalController = TextEditingController();

  final DoctorQualificationService _doctorService = DoctorQualificationService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = false;
  List<dynamic> _uploadedFiles = []; // Changed from List<File>
  List<String> _uploadedFileNames = [];
  List<String> _uploadedDocumentUrls = [];

  bool _medicalLicenseUploaded = false;
  bool _degreeCertificateUploaded = false;
  bool _idProofUploaded = false;

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Container(
        margin: const EdgeInsets.only(left: 16, right: 12),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      hintText: hint,
      filled: true,
      fillColor: secondaryColor.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
    );
  }

  /// 📤 Upload a document
  Future<void> _uploadDocument(String documentType) async {
    final file = await _doctorService.pickFile();
    if (file != null) {
      setState(() => _isLoading = true);

      try {
        final url = await _doctorService.uploadToCloudinary(file);

        _uploadedFiles.add(file);

        // Handle both web (PlatformFile) and mobile (File) file naming
        if (file is File) {
          // Mobile file
          _uploadedFileNames.add("$documentType - ${file.path.split('/').last}");
        } else {
          // Web PlatformFile (import 'package:file_picker/file_picker.dart')
          _uploadedFileNames.add("$documentType - ${file.name}");
        }

        _uploadedDocumentUrls.add(url);

        if (documentType == "Medical License") _medicalLicenseUploaded = true;
        if (documentType == "Degree Certificate") _degreeCertificateUploaded = true;
        if (documentType == "ID Proof") _idProofUploaded = true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ $documentType uploaded successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to upload $documentType: $e")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 💾 Submit doctor qualification to Firestore (doctor_applications)
  Future<void> _submitDoctorApplication() async {
    // Form Validation Check
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Document Upload Check
    if (!_medicalLicenseUploaded || !_degreeCertificateUploaded || !_idProofUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload all required documents")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save to doctor_applications
      await _doctorService.saveDoctorQualifications(
        doctorId: widget.doctorId,
        name: widget.name,
        email: widget.email,
        password: widget.password,
        qualifications: _qualificationsController.text.trim(),
        licenseNumber: _licenseController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text.trim()) ?? 0,
        hospital: _hospitalController.text.trim(),
        documents: _uploadedDocumentUrls,
      );

      // Update user status
      await _db.collection('users').doc(widget.doctorId).update({
        'status': 'Pending Approval',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Application submitted successfully! Await admin approval."),
        ),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to submit application: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDocumentUpload(
      String title,
      String description,
      bool isUploaded,
      String documentType,
      ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isUploaded ? Icons.check_circle : Icons.upload_file,
              color: isUploaded ? Colors.green : primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _uploadDocument(documentType),
              style: ElevatedButton.styleFrom(
                backgroundColor: isUploaded ? Colors.green : primaryColor,
              ),
              child: Text(
                isUploaded ? "Uploaded" : "Upload",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Doctor Qualifications"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Professional Information",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _qualificationsController,
                decoration: _inputDecoration(
                    'Medical Qualifications (MBBS, MD, etc.)', Icons.school),
                validator: (v) =>
                v?.isEmpty ?? true ? 'Qualifications are required' : null,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _licenseController,
                decoration:
                _inputDecoration('Medical License Number', Icons.badge),
                validator: (v) =>
                v?.isEmpty ?? true ? 'License number is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _experienceController,
                decoration:
                _inputDecoration('Years of Experience', Icons.work),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Experience is required';
                  final years = int.tryParse(v!);
                  if (years == null || years <= 0) {
                    return 'Enter valid experience years';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _hospitalController,
                decoration: _inputDecoration(
                    'Hospital/Clinic Name', Icons.local_hospital),
                validator: (v) =>
                v?.isEmpty ?? true ? 'Hospital/Clinic name is required' : null,
              ),
              const SizedBox(height: 24),

              const Text(
                "Required Documents",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),

              _buildDocumentUpload(
                  "Medical License",
                  "Upload your valid medical practice license",
                  _medicalLicenseUploaded,
                  "Medical License"),
              _buildDocumentUpload(
                  "Degree Certificate",
                  "Upload your medical degree certificate",
                  _degreeCertificateUploaded,
                  "Degree Certificate"),
              _buildDocumentUpload(
                  "ID Proof",
                  "Upload government issued ID proof",
                  _idProofUploaded,
                  "ID Proof"),

              const SizedBox(height: 24),

              if (_uploadedFileNames.isNotEmpty) ...[
                const Text("Uploaded Documents:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ..._uploadedFileNames.map(
                      (fileName) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text("• $fileName",
                        style: TextStyle(color: Colors.green[700])),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDoctorApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Submit Application',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _qualificationsController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }
}