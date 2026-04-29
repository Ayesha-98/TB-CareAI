import 'dart:typed_data'; // For web image bytes
import 'dart:io' show File; // For mobile/desktop only
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
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
const errorColor = Color(0xFFF44336);
const warningColor = Color(0xFFFF9800);

// ============================
// VALIDATION UTILITY CLASS (Same as mobile)
// ============================
class ProfileValidators {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    if (value.length > 50) return 'Name must be less than 50 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Age is required';
    final age = int.tryParse(value);
    if (age == null) return 'Please enter a valid number';
    if (age < 1) return 'Age must be at least 1';
    if (age > 120) return 'Please enter a valid age (1-120)';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final phoneRegex = RegExp(r'^03\d{9}$');
    if (!phoneRegex.hasMatch(value)) return 'Enter valid PK number (03XXXXXXXXX)';
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) return 'Weight is required';
    final weight = double.tryParse(value);
    if (weight == null) return 'Please enter a valid number';
    if (weight < 5) return 'Weight must be at least 5 kg';
    if (weight > 300) return 'Please enter a valid weight (5-300 kg)';
    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) return 'Address is required';
    if (value.length < 10) return 'Address must be at least 10 characters';
    if (value.length > 200) return 'Address must be less than 200 characters';
    final invalidChars = RegExp(r'[<>{}|\\^~\[\]]');
    if (invalidChars.hasMatch(value)) return 'Address contains invalid characters';
    return null;
  }

  static String? validateText(String? value, String fieldName, {int maxLength = 500}) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    if (value.length > maxLength) return '$fieldName must be less than $maxLength characters';
    return null;
  }

  static String? validateGender(String? value) {
    if (value == null || value.isEmpty) return 'Gender is required';
    final validGenders = ['Male', 'Female', 'Other'];
    if (!validGenders.contains(value)) return 'Please select Male, Female, or Other';
    return null;
  }

  static String? validateAppetite(String? value) {
    if (value == null || value.isEmpty) return 'Appetite level is required';
    final validAppetites = ['Low', 'Medium', 'High', 'Very Low', 'Normal'];
    if (!validAppetites.contains(value)) return 'Please select valid appetite level';
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

  // State (Using proper dropdown variables - FIXED)
  String selectedLanguage = 'English';
  String? selectedGender;      // ✅ Changed from TextEditingController
  String? selectedAppetite;    // ✅ Changed from TextEditingController
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
    var sanitized = input.replaceAll(RegExp(r'<script.*?>.*?</script>', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    sanitized = sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
    return sanitized;
  }

  // ============================
  // IMAGE UPLOAD (Web Compatible)
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

      setState(() => _isUploadingImage = true);

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 12),
              Text("Uploading image..."),
            ],
          ),
          duration: Duration(minutes: 1),
        ),
      );

      String? url;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Image size must be less than 5MB")),
          );
          return;
        }
        url = await uploadBytesToCloudinary(
            bytes,
            profilePreset,
            "profile_${DateTime.now().millisecondsSinceEpoch}.jpg"
        );
        if (url != null) {
          setState(() {
            _selectedImageBytes = bytes;
            _imageUrl = url;
          });
        }
      } else {
        final file = File(picked.path);
        final stat = await file.stat();
        if (stat.size > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Image size must be less than 5MB")),
          );
          return;
        }
        url = await uploadToCloudinary(file, profilePreset);
        if (url != null) {
          setState(() {
            _selectedImageFile = file;
            _imageUrl = url;
          });
        }
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (url != null) {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .update({'imageUrl': url});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profile picture updated")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Failed to upload image")),
        );
      }
    } catch (e) {
      debugPrint("❌ Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to upload image")),
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

  // ============================
  // SAVE PROFILE
  // ============================
  Future<void> saveProfile() async {
    if (_isSaving) return;

    // Validate all fields
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

    final hasErrors = [
      _nameError, _ageError, _phoneError, _weightError,
      _addressError, _genderError, _appetiteError
    ].any((error) => error != null);

    if (hasErrors) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fix the errors before saving")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profileData = {
        'name': _sanitizeInput(nameController.text).trim(),
        'age': int.tryParse(ageController.text) ?? 0,
        'phone': phoneController.text.trim(),
        'address': _sanitizeInput(addressController.text).trim(),
        'language': selectedLanguage,
        'imageUrl': _imageUrl,
        'gender': selectedGender ?? '',
        'weight': double.tryParse(weightController.text) ?? 0.0,
        'symptoms': _sanitizeInput(symptomsController.text).trim(),
        'appetite': selectedAppetite ?? '',
        'comorbidities': _sanitizeInput(comorbiditiesController.text).trim(),
        'medicationHistory': _sanitizeInput(medicationHistoryController.text).trim(),
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .set(profileData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profile saved successfully!")),
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to save profile: $e")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ============================
  // UI WIDGETS
  // ============================
  InputDecoration inputDecoration(String label, IconData icon, {String? errorText}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      filled: true,
      fillColor: Colors.white,
      errorText: errorText,
      errorMaxLines: 2,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      decoration: inputDecoration("Gender *", Icons.wc, errorText: _genderError),
      items: genderOptions.map((gender) {
        return DropdownMenuItem(
          value: gender,
          child: Text(gender),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedGender = value;
          _genderError = ProfileValidators.validateGender(value);
        });
      },
      validator: (value) => ProfileValidators.validateGender(value),
    );
  }

  Widget _buildAppetiteDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedAppetite,
      decoration: inputDecoration("Appetite Level *", Icons.restaurant_menu, errorText: _appetiteError),
      items: appetiteOptions.map((appetite) {
        return DropdownMenuItem(
          value: appetite,
          child: Text(appetite),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedAppetite = value;
          _appetiteError = ProfileValidators.validateAppetite(value);
        });
      },
      validator: (value) => ProfileValidators.validateAppetite(value),
    );
  }

  Widget _buildTextArea(String label, IconData icon, TextEditingController controller, String? errorText, int maxLines) {
    return TextFormField(
      controller: controller,
      decoration: inputDecoration(label, icon, errorText: errorText),
      maxLines: maxLines,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
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
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Photo Section
              Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: _selectedImageFile != null
                            ? FileImage(_selectedImageFile!)
                            : _selectedImageBytes != null
                            ? MemoryImage(_selectedImageBytes!)
                            : _imageUrl != null
                            ? NetworkImage(_imageUrl!)
                            : AssetImage('assets/default_avatar.png') as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingImage ? null : _pickAndUploadImage,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: _isUploadingImage
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text("Tap camera to update photo (Max 5MB)", style: TextStyle(color: textSecondary)),
                ],
              ),

              SizedBox(height: 32),

              // Form Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: Colors.white,
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildSectionHeader("Personal Information", Icons.person_outline),
                      SizedBox(height: 20),

                      TextFormField(
                        controller: nameController,
                        decoration: inputDecoration("Full Name *", Icons.person, errorText: _nameError),
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: ageController,
                        decoration: inputDecoration("Age *", Icons.cake, errorText: _ageError),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: phoneController,
                        decoration: inputDecoration("Phone Number *", Icons.phone, errorText: _phoneError),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: addressController,
                        decoration: inputDecoration("Address *", Icons.home, errorText: _addressError),
                        maxLines: 2,
                      ),
                      SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: selectedLanguage,
                        decoration: inputDecoration("Preferred Language", Icons.language),
                        items: languages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                        onChanged: (value) => setState(() => selectedLanguage = value!),
                      ),

                      SizedBox(height: 32),
                      _buildSectionHeader("Health Information", Icons.health_and_safety),
                      SizedBox(height: 20),

                      _buildGenderDropdown(),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: weightController,
                        decoration: inputDecoration("Weight (kg) *", Icons.monitor_weight, errorText: _weightError),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),

                      _buildTextArea("Symptoms *", Icons.sick, symptomsController, _symptomsError, 3),
                      SizedBox(height: 16),

                      _buildAppetiteDropdown(),

                      SizedBox(height: 32),
                      _buildSectionHeader("Medical History", Icons.medical_services),
                      SizedBox(height: 20),

                      _buildTextArea("Comorbidities", Icons.coronavirus, comorbiditiesController, _comorbiditiesError, 2),
                      SizedBox(height: 16),

                      _buildTextArea("Medication History", Icons.medication, medicationHistoryController, null, 2),

                      SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text("Save Profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}