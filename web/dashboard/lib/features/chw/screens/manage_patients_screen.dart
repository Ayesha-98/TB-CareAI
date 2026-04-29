import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:tbcare_main/features/chw/models/manage_patient_model.dart';
import 'package:tbcare_main/features/chw/services/manage_patient_service.dart';
import 'package:tbcare_main/features/chw/screens/patient_screening_screen.dart';

class ManagePatientsScreen extends StatefulWidget {
  const ManagePatientsScreen({Key? key}) : super(key: key);

  @override
  _ManagePatientsScreenState createState() => _ManagePatientsScreenState();
}

class _ManagePatientsScreenState extends State<ManagePatientsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _comorbiditiesController = TextEditingController();
  final TextEditingController _medicationHistoryController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedGender = "Male";
  String _selectedAppetite = "Normal";
  bool _isLoading = false;
  bool _isButtonDisabled = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PatientService _patientService = PatientService();

  final _formKey = GlobalKey<FormState>();

  // Colors for web dashboard
  static const primaryColor = Color(0xFF1B4D3E);
  static const secondaryColor = Color(0xFF2E7D32);
  static const accentColor = Color(0xFF4CAF50);
  static const bgColor = Color(0xFFF8FDF9);
  static const cardColor = Colors.white;
  static const textColor = Color(0xFF333333);
  static const lightTextColor = Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  void _checkAuthentication() {
    if (_auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/signin');
      });
    }
  }

  Future<void> _addPatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isButtonDisabled = true;
    });

    try {
      final chwId = _auth.currentUser!.uid;
      if (chwId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final newPatientId = _patientService.newPatientId(chwId);
      final phoneNumber = '+92${_phoneController.text.trim()}';

      final patient = Patient(
        id: newPatientId,
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        gender: _selectedGender,
        phone: phoneNumber,
        weight: int.tryParse(_weightController.text.trim()) ?? 0,
        comorbidities: _comorbiditiesController.text.trim().isEmpty
            ? "none"
            : _comorbiditiesController.text.trim(),
        medicationHistory: _medicationHistoryController.text.trim().isEmpty
            ? "none"
            : _medicationHistoryController.text.trim(),
        appetite: _selectedAppetite,
        address: _addressController.text.trim(),
        createdAt: now,
        updatedAt: now,
        language: "English",
        symptoms: "none",
        imageUrl: null,
        diagnosisStatus: "Pending",
      );

      await _patientService.addPatient(patient, chwId);

      _showSuccessMessage('Patient added successfully!');
      _clearForm();

      // Navigate to screening screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientScreeningScreen(
            patientId: newPatientId,
            patientName: patient.name,
          ),
        ),
      );

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'permission-denied':
          errorMessage = 'You do not have permission to add patients';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection';
          break;
        default:
          errorMessage = 'Authentication error: ${e.message}';
      }
      _showErrorMessage(errorMessage);
    } on Exception catch (e) {
      _showErrorMessage('Error adding patient: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isButtonDisabled = false;
        });
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _ageController.clear();
    _phoneController.clear();
    _weightController.clear();
    _comorbiditiesController.clear();
    _medicationHistoryController.clear();
    _addressController.clear();

    setState(() {
      _selectedGender = "Male";
      _selectedAppetite = "Normal";
    });

    _formKey.currentState?.reset();
  }

  void _showSuccessMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Add New Patient",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Web Header
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person_add_alt_1, size: 48, color: Colors.white),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Register New Patient",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Add a new patient to start TB screening process. All fields marked with * are required.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Main Form
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Two Column Layout for Web
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column - Personal Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle("Personal Information", Icons.person_outline),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  _nameController,
                                  "Patient Name *",
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter patient name';
                                    }
                                    if (value.trim().length < 2) {
                                      return 'Name must be at least 2 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        _ageController,
                                        "Age *",
                                        inputType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Please enter age';
                                          }
                                          final age = int.tryParse(value);
                                          if (age == null) {
                                            return 'Enter a valid number';
                                          }
                                          if (age < 1 || age > 120) {
                                            return 'Age must be 1-120 years';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _buildDropdown(
                                        "Gender *",
                                        ["Male", "Female", "Other"],
                                        _selectedGender,
                                            (val) => setState(() => _selectedGender = val!),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  _weightController,
                                  "Weight (kg)",
                                  inputType: TextInputType.number,
                                  validator: (value) {
                                    if (value != null && value.trim().isNotEmpty) {
                                      final weight = double.tryParse(value);
                                      if (weight == null) {
                                        return 'Enter a valid number';
                                      }
                                      if (weight < 2 || weight > 300) {
                                        return 'Weight must be 2-300 kg';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),

                          // Right Column - Contact & Medical Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle("Contact Details", Icons.phone_outlined),
                                const SizedBox(height: 20),
                                _buildPhoneField(
                                  _phoneController,
                                  "Phone Number *",
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter phone number';
                                    }
                                    if (value.length != 10) {
                                      return 'Must be exactly 10 digits';
                                    }
                                    if (!RegExp(r'^3[0-9]{9}$').hasMatch(value)) {
                                      return 'Must start with 3 (e.g., 3XXXXXXXXX)';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  _addressController,
                                  "Address",
                                  maxLines: 2,
                                  validator: (value) {
                                    if (value != null && value.trim().length > 500) {
                                      return 'Address too long (max 500 chars)';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Medical History Section
                      _buildSectionTitle("Medical History", Icons.medical_services_outlined),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _comorbiditiesController,
                              "Comorbidities (if any)",
                              maxLines: 3,
                              validator: (value) {
                                if (value != null && value.trim().length > 1000) {
                                  return 'Too long (max 1000 characters)';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                _buildTextField(
                                  _medicationHistoryController,
                                  "Current Medications",
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value != null && value.trim().length > 1000) {
                                      return 'Too long (max 1000 characters)';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildDropdown(
                                  "Appetite Level",
                                  ["Low", "Normal", "High"],
                                  _selectedAppetite,
                                      (val) => setState(() => _selectedAppetite = val!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Action Buttons
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Ready to Submit",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Patient will be taken directly to screening after registration",
                                      style: TextStyle(
                                        color: lightTextColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  OutlinedButton(
                                    onPressed: _clearForm,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                      side: BorderSide(color: primaryColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      "Clear Form",
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  _isLoading
                                      ? _buildLoadingButton()
                                      : _buildSubmitButton(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Form Guidelines
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 8,

                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }


  Widget _buildPhoneField(
      TextEditingController controller,
      String label, {
        String? Function(String?)? validator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,

          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Text(
                "+92",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: validator,
                style: const TextStyle(color: textColor, fontSize: 16),
                cursorColor: primaryColor,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "3XXXXXXXXX",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        TextInputType inputType = TextInputType.text,
        int maxLines = 1,
        String? Function(String?)? validator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,

          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: textColor, fontSize: 16),
          cursorColor: primaryColor,
          inputFormatters: inputType == TextInputType.number
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
      String label,
      List<String> items,
      String value,
      Function(String?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,

          ),
        ),
        DropdownButtonFormField<String>(
          value: value,
          style: const TextStyle(color: textColor, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
          ),
          dropdownColor: Colors.white,
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item, style: const TextStyle(color: textColor)),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isButtonDisabled ? null : _addPatient,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_add, size: 22),
          const SizedBox(width: 12),
          Text(
            "Add Patient & Start Screening",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingButton() {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor.withOpacity(0.7),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Adding Patient...",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _comorbiditiesController.dispose();
    _medicationHistoryController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}