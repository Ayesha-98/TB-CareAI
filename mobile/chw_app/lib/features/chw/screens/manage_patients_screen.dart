import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:tbcare_main/features/chw/models/manage_patient_model.dart';
import 'package:tbcare_main/features/chw/services/manage_patient_service.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'patient_screening_screen.dart';

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
  final PatientService _patientService = PatientService();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Rate limiting variables
  DateTime? _lastPatientAddedTime;
  static const Duration _rateLimitDuration = Duration(minutes: 1);

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

  // Enhanced validation method
  Map<String, String?> _validateAllFields() {
    final errors = <String, String?>{};

    // Name validation
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      errors['name'] = 'Patient name is required';
    } else if (name.length < 2) {
      errors['name'] = 'Name must be at least 2 characters';
    } else if (name.length > 100) {
      errors['name'] = 'Name is too long (max 100 characters)';
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      errors['name'] = 'Name should contain only letters and spaces';
    }

    // Age validation
    final ageStr = _ageController.text.trim();
    if (ageStr.isEmpty) {
      errors['age'] = 'Age is required';
    } else {
      final age = int.tryParse(ageStr);
      if (age == null) {
        errors['age'] = 'Please enter a valid number';
      } else if (age < 1 || age > 120) {
        errors['age'] = 'Age must be between 1 and 120 years';
      }
    }

    // Phone validation
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      errors['phone'] = 'Phone number is required';
    } else if (phone.length != 10) {
      errors['phone'] = 'Phone number must be 10 digits';
    } else if (!RegExp(r'^3[0-9]{9}$').hasMatch(phone)) {
      errors['phone'] = 'Must start with 3 and contain only numbers';
    }

    // Weight validation
    final weightStr = _weightController.text.trim();
    if (weightStr.isNotEmpty) {
      final weight = double.tryParse(weightStr);
      if (weight == null) {
        errors['weight'] = 'Please enter a valid weight';
      } else if (weight < 2 || weight > 300) {
        errors['weight'] = 'Weight must be between 2 and 300 kg';
      }
    }

    // Address validation
    final address = _addressController.text.trim();
    if (address.isNotEmpty && address.length > 500) {
      errors['address'] = 'Address is too long (max 500 characters)';
    }

    // Comorbidities validation
    final comorbidities = _comorbiditiesController.text.trim();
    if (comorbidities.isNotEmpty && comorbidities.length > 1000) {
      errors['comorbidities'] = 'Too long (max 1000 characters)';
    }

    // Medication history validation
    final medicationHistory = _medicationHistoryController.text.trim();
    if (medicationHistory.isNotEmpty && medicationHistory.length > 1000) {
      errors['medicationHistory'] = 'Too long (max 1000 characters)';
    }

    // Prevent SQL/script injection (basic check)
    final maliciousPattern = RegExp(r'[<>{};]|(\b(OR|AND|SELECT|INSERT|DELETE|UPDATE|DROP|UNION)\b)',
        caseSensitive: false);

    final textFields = [
      _nameController.text,
      _addressController.text,
      _comorbiditiesController.text,
      _medicationHistoryController.text,
    ];

    for (var field in textFields) {
      if (maliciousPattern.hasMatch(field)) {
        errors['security'] = 'Invalid characters detected in input';
        break;
      }
    }

    return errors;
  }

  // Check if phone number already exists
  Future<bool> _isPhoneNumberDuplicate(String phoneNumber) async {
    try {
      // This would need a method in your service to check for duplicates
      // For now, returning false. Implement based on your Firestore structure
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _addPatient() async {
    // Rate limiting check
    final now = DateTime.now();
    if (_lastPatientAddedTime != null &&
        now.difference(_lastPatientAddedTime!) < _rateLimitDuration) {
      _showErrorMessage('Please wait 1 minute before adding another patient');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation
    final validationErrors = _validateAllFields();
    if (validationErrors.isNotEmpty) {
      final firstError = validationErrors.values.firstWhere((error) => error != null);
      _showErrorMessage(firstError!);
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

      // Format phone number
      final phoneNumber = '+92${_phoneController.text.trim()}';

      // Check for duplicate phone number
      final isDuplicate = await _isPhoneNumberDuplicate(phoneNumber);
      if (isDuplicate) {
        throw Exception('Phone number already registered');
      }

      // Log the patient addition attempt
      await _logPatientAdditionAttempt(chwId, _nameController.text.trim());

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
        createdAt: now,
        updatedAt: now,
        language: "English",
        symptoms: "none",
        imageUrl: null,
        diagnosisStatus: "Pending",
        address: _addressController.text.trim(),
      );

      // Validate patient object
      if (patient.name.isEmpty || patient.phone.isEmpty) {
        throw Exception('Invalid patient data');
      }

      await _patientService.addPatient(patient, chwId);

      // Update last added time for rate limiting
      _lastPatientAddedTime = now;

      // Log successful addition
      await _logSuccessfulPatientAddition(chwId, patient.id, patient.name);

      // Show success message
      _showSuccessMessage('Patient added successfully!');

      // Clear form after successful addition
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

  Future<void> _logPatientAdditionAttempt(String chwId, String patientName) async {
    try {
      await FirebaseFirestore.instance
          .collection('chw_activity_logs')
          .add({
        'chwId': chwId,
        'action': 'patient_add_attempt',
        'patientName': patientName,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': 'N/A', // You can get this if needed
      });
    } catch (e) {
      debugPrint('Failed to log patient addition attempt: $e');
    }
  }

  Future<void> _logSuccessfulPatientAddition(String chwId, String patientId, String patientName) async {
    try {
      await FirebaseFirestore.instance
          .collection('chw_activity_logs')
          .add({
        'chwId': chwId,
        'action': 'patient_add_success',
        'patientId': patientId,
        'patientName': patientName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to log successful patient addition: $e');
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
            Icon(Icons.check_circle, color: successColor),
            SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.green.shade50,
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
            Icon(Icons.error_outline, color: errorColor),
            SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade50,
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
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Patient Registration Guidelines'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('• All fields marked with * are required'),
                        SizedBox(height: 8),
                        Text('• Phone number must be 10 digits starting with 3'),
                        SizedBox(height: 8),
                        Text('• Age must be between 1-120 years'),
                        SizedBox(height: 8),
                        Text('• Weight must be between 2-300 kg'),
                        SizedBox(height: 8),
                        Text('• Avoid special characters in name field'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    _buildHeaderCard(),

                    const SizedBox(height: 24),

                    // Personal Information Card
                    _buildSectionCard(
                      title: "Personal Information",
                      icon: Icons.person_outline,
                      children: [
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
                            if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                              return 'Only letters and spaces allowed';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
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
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _buildDropdown(
                                "Gender",
                                ["Male", "Female", "Other"],
                                _selectedGender,
                                    (val) => setState(() => _selectedGender = val!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
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

                    const SizedBox(height: 20),

                    // Contact Details Card
                    _buildSectionCard(
                      title: "Contact Details",
                      icon: Icons.phone_outlined,
                      children: [
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
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Medical History Card
                    _buildSectionCard(
                      title: "Medical History",
                      icon: Icons.medical_services_outlined,
                      children: [
                        _buildTextField(
                          _comorbiditiesController,
                          "Comorbidities (if any)",
                          maxLines: 2,
                          validator: (value) {
                            if (value != null && value.trim().length > 1000) {
                              return 'Too long (max 1000 characters)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _medicationHistoryController,
                          "Current Medications",
                          maxLines: 2,
                          validator: (value) {
                            if (value != null && value.trim().length > 1000) {
                              return 'Too long (max 1000 characters)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          "Appetite Level",
                          ["Low", "Normal", "High"],
                          _selectedAppetite,
                              (val) => setState(() => _selectedAppetite = val!),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Form actions
                    _buildFormActions(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormActions() {
    return Column(
      children: [
        Center(
          child: _isLoading
              ? _buildLoadingButton()
              : _buildSubmitButton(),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: _clearForm,
            icon: Icon(Icons.clear_all, color: Colors.grey.shade600),
            label: Text(
              'Clear Form',
              style: TextStyle(color: Colors.grey.shade600),
            ),
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
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      validator: validator,
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      cursorColor: primaryColor,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        prefix: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(
            '+92',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
        counterText: "",
        hintText: "3XXXXXXXXX",
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor.withOpacity(0.9), primaryColor],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_add_alt_1, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              "Add New Patient",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Patient will be automatically taken to screening after registration",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "All fields marked with * are required",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  child: Icon(icon, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        TextInputType inputType = TextInputType.text,
        int maxLines = 1,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      cursorColor: primaryColor,
      inputFormatters: inputType == TextInputType.number
          ? [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ]
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label,
      List<String> items,
      String value,
      Function(String?) onChanged,
      ) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
      ),
      dropdownColor: Colors.white,
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item, style: const TextStyle(color: Colors.black87)),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isButtonDisabled ? null : _addPatient,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 3,
          shadowColor: primaryColor.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, size: 22),
            SizedBox(width: 12),
            Text(
              "Add Patient & Start Screening",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor.withOpacity(0.7),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text(
              "Adding Patient...",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
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