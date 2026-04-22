import 'dart:typed_data';
import 'dart:io' show File;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

// 🎨 Enhanced Color Scheme
const primaryColor = Color(0xFF1B4D3E);
const primaryLightColor = Color(0xFF2A6E5C);
const secondaryColor = Color(0xFF424242);
const bgColor = Color(0xFFF8F9FA);
const cardColor = Color(0xFFFFFFFF);
const textPrimary = Color(0xFF1A1A1A);
const textSecondary = Color(0xFF666666);
const successColor = Color(0xFF4CAF50);
const errorColor = Color(0xFFD32F2F);
const warningColor = Color(0xFFFF9800);

// ============================
// VALIDATION UTILITY CLASS
// ============================
class ProfileValidators {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid number';
    }
    if (age < 1) {
      return 'Age must be at least 1';
    }
    if (age > 120) {
      return 'Please enter a valid age (1-120)';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Pakistani phone number format: 03XXXXXXXXX
    final phoneRegex = RegExp(r'^03\d{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter valid PK number (03XXXXXXXXX)';
    }
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Weight is required';
    }
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid number';
    }
    if (weight < 5) {
      return 'Weight must be at least 5 kg';
    }
    if (weight > 300) {
      return 'Please enter a valid weight (5-300 kg)';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    if (value.length < 10) {
      return 'Address must be at least 10 characters';
    }
    if (value.length > 200) {
      return 'Address must be less than 200 characters';
    }
    final invalidChars = RegExp(r'[<>{}|\\^~\[\]]');
    if (invalidChars.hasMatch(value)) {
      return 'Address contains invalid characters';
    }
    return null;
  }

  static String? validateText(String? value, String fieldName, {int maxLength = 500}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    final scriptRegex = RegExp(r'<script.*?>.*?</script>', caseSensitive: false);
    if (scriptRegex.hasMatch(value)) {
      return 'Invalid content detected';
    }
    return null;
  }

  static String? validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Gender is required';
    }
    final validGenders = ['Male', 'Female', 'Other'];
    if (!validGenders.contains(value)) {
      return 'Please select Male, Female, or Other';
    }
    return null;
  }

  static String? validateAppetite(String? value) {
    if (value == null || value.isEmpty) {
      return 'Appetite level is required';
    }
    final validAppetites = ['Low', 'Medium', 'High', 'Very Low', 'Normal'];
    if (!validAppetites.contains(value)) {
      return 'Please select valid appetite level';
    }
    return null;
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Form Key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final weightController = TextEditingController();
  final symptomsController = TextEditingController();
  final comorbiditiesController = TextEditingController();
  final medicationHistoryController = TextEditingController();

  // State
  String selectedLanguage = 'English';
  String? selectedGender;
  String? selectedAppetite;
  String? _imageUrl;
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  Map<String, dynamic> profileSnapshot = {};

  // Error states
  String? _nameError;
  String? _ageError;
  String? _phoneError;
  String? _weightError;
  String? _addressError;
  String? _genderError;
  String? _appetiteError;
  String? _symptomsError;
  String? _comorbiditiesError;

  late String patientId;
  final List<String> languages = ['English', 'Urdu', 'Punjabi', 'Pashto'];
  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final List<String> appetiteOptions = ['Low', 'Medium', 'High', 'Very Low', 'Normal'];
  StreamSubscription<DocumentSnapshot>? _profileSub;

  final String cloudName = "de1oz7jbg";
  final String profilePreset = "patient_profile";

  // Loading states
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      patientId = user.uid;
    } else {
      patientId = "";
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/signin');
      });
    }

    _listenToProfile();
  }

  void _listenToProfile() {
    _profileSub = FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data()!;
      if (mounted) {
        setState(() {
          nameController.text = data['name'] ?? '';
          ageController.text = data['age']?.toString() ?? '';
          phoneController.text = data['phone'] ?? '';
          addressController.text = data['address'] ?? '';

          // Fix: Ensure gender matches exactly with options
          final genderFromDb = data['gender'] ?? '';
          selectedGender = genderOptions.contains(genderFromDb) ? genderFromDb : null;

          weightController.text = data['weight']?.toString() ?? '';
          symptomsController.text = data['symptoms'] ?? '';

          // Fix: Ensure appetite matches exactly with options
          final appetiteFromDb = data['appetite'] ?? '';
          selectedAppetite = appetiteOptions.contains(appetiteFromDb) ? appetiteFromDb : null;

          comorbiditiesController.text = data['comorbidities'] ?? '';
          medicationHistoryController.text = data['medicationHistory'] ?? '';
          selectedLanguage = data['language'] ?? 'English';
          _imageUrl = data['imageUrl'];
          profileSnapshot = data;
        });
      }
    });
  }

  // ============================
  // INPUT SANITIZATION
  // ============================
  String _sanitizeInput(String input) {
    // Remove script tags
    var sanitized = input.replaceAll(RegExp(r'<script.*?>.*?</script>', caseSensitive: false), '');
    // Remove other dangerous tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    // Escape special characters
    sanitized = sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
    return sanitized;
  }

  // ============================
  // IMAGE UPLOAD WITH SECURITY - MOBILE VERSION
  // ============================
  Future<void> _pickAndUploadImage() async {
    if (_isUploadingImage) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (picked == null) return;

      // Get file size for mobile
      final file = File(picked.path);
      final stat = await file.stat();

      // Security check: File size (max 5MB)
      if (stat.size > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Image size must be less than 5MB"),
            backgroundColor: errorColor,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Security check: File type
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
      final fileName = picked.name.toLowerCase();
      final isValidExtension = allowedExtensions.any((ext) => fileName.endsWith(ext));

      if (!isValidExtension) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Only JPG, PNG, and GIF images are allowed"),
            backgroundColor: errorColor,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      setState(() => _isUploadingImage = true);

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(width: 12),
              Text("Uploading image..."),
            ],
          ),
          duration: Duration(minutes: 1),
          backgroundColor: primaryColor,
        ),
      );

      // Upload to Cloudinary
      String? url;
      url = await uploadToCloudinary(file, profilePreset);

      // Remove loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (url != null) {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .update({'imageUrl': url});

        setState(() {
          _imageUrl = url;
          _selectedImageFile = file;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Profile picture updated"),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ Failed to upload image. Please try again."),
            backgroundColor: warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to upload image"),
          backgroundColor: errorColor,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isUploadingImage = false);
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
      } else {
        debugPrint("❌ Cloudinary upload failed: $resBody");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Upload exception: $e");
      return null;
    }
  }

  Future<String?> uploadBytesToCloudinary(
      Uint8List bytes, String preset, String fileName) async {
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
      } else {
        debugPrint("❌ Cloudinary upload failed: $resBody");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Upload exception: $e");
      return null;
    }
  }

  // ============================
  // AUDIT LOGGING
  // ============================
  Future<void> _logProfileUpdate(Map<String, dynamic> newData) async {
    try {
      await FirebaseFirestore.instance
          .collection('profile_audit_logs')
          .add({
        'patientId': patientId,
        'updatedFields': newData.keys.toList(),
        'timestamp': Timestamp.now(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        'action': 'profile_update',
      });
    } catch (e) {
      debugPrint("❌ Audit log error: $e");
    }
  }

  // ============================
  // SAVE PROFILE WITH VALIDATION
  // ============================
  Future<void> saveProfile() async {
    if (_isSaving) return;

    // Clear previous errors
    setState(() {
      _nameError = ProfileValidators.validateName(nameController.text);
      _ageError = ProfileValidators.validateAge(ageController.text);
      _phoneError = ProfileValidators.validatePhone(phoneController.text);
      _weightError = ProfileValidators.validateWeight(weightController.text);
      _addressError = ProfileValidators.validateAddress(addressController.text);
      _genderError = ProfileValidators.validateGender(selectedGender);
      _appetiteError = ProfileValidators.validateAppetite(selectedAppetite);
      _symptomsError = ProfileValidators.validateText(symptomsController.text, 'Symptoms', maxLength: 200);
      _comorbiditiesError = ProfileValidators.validateText(comorbiditiesController.text, 'Comorbidities', maxLength: 200);
    });

    // Check if any errors exist
    final hasErrors = [
      _nameError, _ageError, _phoneError, _weightError,
      _addressError, _genderError, _appetiteError
    ].any((error) => error != null);

    if (hasErrors) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fix the errors before saving"),
          backgroundColor: errorColor,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Sanitize all inputs
      final sanitizedName = _sanitizeInput(nameController.text);
      final sanitizedAddress = _sanitizeInput(addressController.text);
      final sanitizedSymptoms = _sanitizeInput(symptomsController.text);
      final sanitizedComorbidities = _sanitizeInput(comorbiditiesController.text);
      final sanitizedMedication = _sanitizeInput(medicationHistoryController.text);

      final profileData = {
        'name': sanitizedName.trim(),
        'age': int.tryParse(ageController.text) ?? 0,
        'phone': phoneController.text.trim(),
        'address': sanitizedAddress.trim(),
        'language': selectedLanguage,
        'imageUrl': _imageUrl,
        'gender': selectedGender ?? '',
        'weight': double.tryParse(weightController.text) ?? 0.0,
        'symptoms': sanitizedSymptoms.trim(),
        'appetite': selectedAppetite ?? '',
        'comorbidities': sanitizedComorbidities.trim(),
        'medicationHistory': sanitizedMedication.trim(),
        'updatedAt': Timestamp.now(),
        'lastUpdatedBy': FirebaseAuth.instance.currentUser?.uid,
        'updateTimestamp': DateTime.now().toIso8601String(),
      };

      // Validate data ranges
      final age = profileData['age'] as int;
      final weight = profileData['weight'] as double;

      if (age < 1 || age > 120) {
        throw Exception('Invalid age range');
      }
      if (weight < 5 || weight > 300) {
        throw Exception('Invalid weight range');
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .set(profileData, SetOptions(merge: true));

      // Log the update
      await _logProfileUpdate(profileData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Profile saved successfully!"),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Clear errors on successful save
      setState(() {
        _nameError = null;
        _ageError = null;
        _phoneError = null;
        _weightError = null;
        _addressError = null;
        _genderError = null;
        _appetiteError = null;
        _symptomsError = null;
        _comorbiditiesError = null;
      });
    } catch (e) {
      debugPrint("❌ Save profile error: $e");

      String errorMessage = "Failed to save profile";
      if (e.toString().contains('Invalid age range')) {
        errorMessage = "Age must be between 1-120 years";
      } else if (e.toString().contains('Invalid weight range')) {
        errorMessage = "Weight must be between 5-300 kg";
      } else if (e.toString().contains('permission-denied')) {
        errorMessage = "You don't have permission to update profile";
      } else if (e.toString().contains('network')) {
        errorMessage = "Network error. Please check your connection";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: errorColor,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ============================
  // UI HELPERS
  // ============================
  InputDecoration inputDecoration(String label, IconData icon, {String? errorText}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Container(
        padding: EdgeInsets.all(12),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorText: errorText,
      errorMaxLines: 2,
      errorStyle: TextStyle(fontSize: 12, color: errorColor),
    );
  }

  Widget _buildTextAreaWithCounter(
      TextEditingController controller,
      String label,
      IconData icon,
      String? errorText,
      int maxLength,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: inputDecoration(label, icon, errorText: errorText),
          maxLines: 3,
          maxLength: maxLength,
          onChanged: (value) {
            // Real-time validation for text areas
            if (label == 'Symptoms') {
              setState(() {
                _symptomsError = ProfileValidators.validateText(value, 'Symptoms', maxLength: maxLength);
              });
            } else if (label == 'Comorbidities') {
              setState(() {
                _comorbiditiesError = ProfileValidators.validateText(value, 'Comorbidities', maxLength: maxLength);
              });
            }
          },
        ),
        SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${controller.text.length}/$maxLength',
            style: TextStyle(
              fontSize: 12,
              color: controller.text.length > maxLength * 0.9
                  ? warningColor
                  : textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget profileRow(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    fontSize: 14)),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(value.isEmpty ? "Not set" : value,
                style: TextStyle(color: textSecondary, fontSize: 14),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          SizedBox(width: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary)),
        ],
      ),
    );
  }

  Widget buildProfileSummary() {
    if (profileSnapshot.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 30),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: primaryColor, size: 20),
              ),
              SizedBox(width: 12),
              Text("Profile Overview",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary)),
            ],
          ),
        ),
        SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          elevation: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withOpacity(0.8), primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text("Saved Information",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    profileRow("Name", profileSnapshot['name'] ?? ''),
                    profileRow("Age", profileSnapshot['age']?.toString() ?? ''),
                    profileRow("Phone", profileSnapshot['phone'] ?? ''),
                    profileRow("Address", profileSnapshot['address'] ?? ''),
                    profileRow("Language", profileSnapshot['language'] ?? ''),
                    profileRow("Gender", profileSnapshot['gender'] ?? ''),
                    profileRow("Weight", profileSnapshot['weight']?.toString() ?? ''),
                    profileRow("Symptoms", profileSnapshot['symptoms'] ?? ''),
                    profileRow("Appetite", profileSnapshot['appetite'] ?? ''),
                    profileRow("Comorbidities", profileSnapshot['comorbidities'] ?? ''),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            child: Text("Medication",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                    fontSize: 14)),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                profileSnapshot['medicationHistory']?.isEmpty ?? true
                                    ? "Not set"
                                    : profileSnapshot['medicationHistory'] ?? '',
                                style: TextStyle(color: textSecondary, fontSize: 14),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    nameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    addressController.dispose();
    weightController.dispose();
    symptomsController.dispose();
    comorbiditiesController.dispose();
    medicationHistoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Edit Profile"),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Photo Section
              Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryLightColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: _selectedImageFile != null
                              ? FileImage(_selectedImageFile!)
                              : _selectedImageBytes != null
                              ? MemoryImage(_selectedImageBytes!)
                              : _imageUrl != null
                              ? NetworkImage(_imageUrl!) as ImageProvider
                              : const AssetImage('assets/default_avatar.png'),
                          child: _imageUrl == null &&
                              _selectedImageFile == null &&
                              _selectedImageBytes == null
                              ? Icon(Icons.person, size: 40, color: Colors.grey.shade400)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _isUploadingImage ? null : _pickAndUploadImage,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: _isUploadingImage
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Tap camera to update photo",
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Form Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: Colors.white,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Personal Information Section
                      _buildSectionHeader("Personal Information", Icons.person_outline),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: inputDecoration("Full Name", Icons.person, errorText: _nameError),
                            onChanged: (value) {
                              setState(() {
                                _nameError = ProfileValidators.validateName(value);
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: ageController,
                            decoration: inputDecoration("Age", Icons.cake, errorText: _ageError),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _ageError = ProfileValidators.validateAge(value);
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: phoneController,
                            decoration: inputDecoration("Phone Number (03XXXXXXXXX)", Icons.phone, errorText: _phoneError),
                            keyboardType: TextInputType.phone,
                            onChanged: (value) {
                              setState(() {
                                _phoneError = ProfileValidators.validatePhone(value);
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: addressController,
                            decoration: inputDecoration("Address", Icons.home, errorText: _addressError),
                            maxLines: 2,
                            onChanged: (value) {
                              setState(() {
                                _addressError = ProfileValidators.validateAddress(value);
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            dropdownColor: Colors.white,
                            value: selectedLanguage,
                            decoration: inputDecoration("Preferred Language", Icons.language),
                            items: languages
                                .map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang),
                            ))
                                .toList(),
                            onChanged: (value) => setState(() => selectedLanguage = value!),
                            icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Health Information Section
                      _buildSectionHeader("Health Information", Icons.health_and_safety),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: selectedGender != null && genderOptions.contains(selectedGender) ? selectedGender : null,
                            decoration: inputDecoration("Gender", Icons.wc, errorText: _genderError),
                            items: genderOptions
                                .map((gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedGender = value;
                                _genderError = ProfileValidators.validateGender(value);
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
                            validator: (value) => ProfileValidators.validateGender(value),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: weightController,
                            decoration: inputDecoration("Weight (kg)", Icons.monitor_weight, errorText: _weightError),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _weightError = ProfileValidators.validateWeight(value);
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextAreaWithCounter(
                            symptomsController,
                            "Symptoms",
                            Icons.sick,
                            _symptomsError,
                            200,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedAppetite != null && appetiteOptions.contains(selectedAppetite) ? selectedAppetite : null,
                            decoration: inputDecoration("Appetite Level", Icons.restaurant_menu, errorText: _appetiteError),
                            items: appetiteOptions
                                .map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedAppetite = value;
                                _appetiteError = ProfileValidators.validateAppetite(value);
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
                            validator: (value) => ProfileValidators.validateAppetite(value),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Medical History Section
                      _buildSectionHeader("Medical History", Icons.medical_services),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          _buildTextAreaWithCounter(
                            comorbiditiesController,
                            "Comorbidities",
                            Icons.coronavirus,
                            _comorbiditiesError,
                            200,
                          ),
                          const SizedBox(height: 16),
                          _buildTextAreaWithCounter(
                            medicationHistoryController,
                            "Medication History",
                            Icons.medication,
                            null,
                            500,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: primaryColor.withOpacity(0.3),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 20),
                              SizedBox(width: 8),
                              Text("Save Profile"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Profile Summary
              buildProfileSummary(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}