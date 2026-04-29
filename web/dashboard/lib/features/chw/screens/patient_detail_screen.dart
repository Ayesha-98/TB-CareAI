import 'package:flutter/material.dart';
import 'package:tbcare_main/features/chw/models/patient_detail_model.dart';
import 'package:tbcare_main/features/chw/services/patient_detail_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PatientDetailScreen extends StatefulWidget {
  final String chwId;
  final String patientId;

  const PatientDetailScreen({
    Key? key,
    required this.chwId,
    required this.patientId,
  }) : super(key: key);

  @override
  _PatientDetailScreenState createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _isSaving = false;

  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _medHistoryController = TextEditingController();
  final _comorbiditiesController = TextEditingController();
  final _appetiteController = TextEditingController();
  final _weightController = TextEditingController();

  late PatientDetailService _service;
  Patient? _patient;

  @override
  void initState() {
    super.initState();
    _service = PatientDetailService();
    _loadPatient();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _medHistoryController.dispose();
    _comorbiditiesController.dispose();
    _appetiteController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadPatient() async {
    setState(() => _loading = true);
    try {
      _patient = await _service.getPatientDetail(widget.chwId, widget.patientId);
      if (_patient != null) {
        _nameController.text = _patient!.name;
        _ageController.text = _patient!.age.toString();
        _phoneController.text = _patient!.phone;
        _medHistoryController.text = _patient!.medicationHistory;
        _comorbiditiesController.text = _patient!.comorbidities;
        _appetiteController.text = _patient!.appetite;
        _weightController.text = _patient!.weight.toString();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Patient not found")),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading patient: $e")),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate() || _patient == null) return;

    setState(() => _isSaving = true);

    final updatedPatient = Patient(
      id: _patient!.id,
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      gender: _patient!.gender,
      phone: _phoneController.text.trim(),
      weight: int.tryParse(_weightController.text.trim()) ?? 0,
      comorbidities: _comorbiditiesController.text.trim(),
      medicationHistory: _medHistoryController.text.trim(),
      appetite: _appetiteController.text.trim(),
      createdBy: _patient!.createdBy,
      chwName: _patient!.chwName,
      createdAt: _patient!.createdAt,
      diagnosisStatus: _patient!.diagnosisStatus,
      imageUrl: null,
    );

    try {
      await _service.updatePatientDetail(widget.chwId, updatedPatient);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Patient updated successfully"),
            backgroundColor: Colors.green, // Fixed: Use direct color instead of successColor if it's causing issues
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating patient: $e"),
            backgroundColor: Colors.red, // Fixed: Use direct color
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.grey[50], // Fixed: Use direct color
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue), // Fixed: Use direct color
              const SizedBox(height: 16),
              Text(
                "Loading Patient Details...",
                style: TextStyle(color: Colors.grey[800], fontSize: 16), // Fixed: Use direct color
              ),
            ],
          ),
        ),
      );
    }

    // Choose layout based on platform
    if (kIsWeb) {
      return _buildWebLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildWebLayout() {
    final primaryColor = Color(0xFF2196F3); // Define local colors
    final secondaryColor = Color(0xFF666666);
    final bgColor = Colors.grey[50];

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(primaryColor, secondaryColor),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Patient Details",
                              style: TextStyle(
                                color: secondaryColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Update patient medical information and personal details",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, color: primaryColor, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "Patient ID: ${_patient?.id.substring(0, 8) ?? ''}...",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Content Grid
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column - Basic Info
                        Expanded(
                          child: Column(
                            children: [
                              _buildWebCard(
                                "Personal Information",
                                Icons.person,
                                primaryColor,
                                secondaryColor,
                                bgColor!,
                                [
                                  _buildWebTextField(_nameController, "Full Name", true,
                                      primaryColor, secondaryColor, bgColor!),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildWebTextField(_ageController, "Age", false,
                                          primaryColor, secondaryColor, bgColor!,
                                          inputType: TextInputType.number,
                                          icon: Icons.cake,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: _buildWebTextField(_weightController, "Weight (kg)", false,
                                          primaryColor, secondaryColor, bgColor!,
                                          inputType: TextInputType.number,
                                          icon: Icons.monitor_weight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _buildWebTextField(_phoneController, "Phone Number", true,
                                    primaryColor, secondaryColor, bgColor!,
                                    inputType: TextInputType.phone,
                                    icon: Icons.phone,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildWebTextField(_appetiteController, "Appetite Level", false,
                                    primaryColor, secondaryColor, bgColor!,
                                    icon: Icons.restaurant,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              _buildWebCard(
                                "Medical History",
                                Icons.medical_services,
                                primaryColor,
                                secondaryColor,
                                bgColor!,
                                [
                                  _buildWebTextArea(_medHistoryController, "Medication History", 3,
                                      primaryColor, secondaryColor, bgColor!),
                                  const SizedBox(height: 20),
                                  _buildWebTextArea(_comorbiditiesController, "Comorbidities", 2,
                                      primaryColor, secondaryColor, bgColor!),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Right Column - Summary & Actions
                        SizedBox(
                          width: 400,
                          child: Column(
                            children: [
                              _buildWebCard(
                                "Patient Summary",
                                Icons.summarize,
                                primaryColor,
                                secondaryColor,
                                bgColor!,
                                [
                                  _buildSummaryItem("Patient ID", _patient?.id ?? "", secondaryColor),
                                  _buildSummaryItem("Gender", _patient?.gender ?? "Not specified", secondaryColor),
                                  _buildSummaryItem("Created By", _patient?.chwName ?? "N/A", secondaryColor),
                                  _buildSummaryItem("Diagnosis Status", _patient?.diagnosisStatus ?? "Pending", secondaryColor,
                                    color: (_patient?.diagnosisStatus?.toLowerCase() ?? "") == "completed"
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, color: primaryColor, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "All fields marked with * are required",
                                            style: TextStyle(
                                              color: secondaryColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              Container(
                                padding: const EdgeInsets.all(24),
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
                                  children: [
                                    Text(
                                      "Save Changes",
                                      style: TextStyle(
                                        color: secondaryColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _isSaving
                                        ? SizedBox(
                                      height: 56,
                                      child: Center(
                                        child: CircularProgressIndicator(color: primaryColor),
                                      ),
                                    )
                                        : ElevatedButton.icon(
                                      onPressed: _savePatient,
                                      icon: const Icon(Icons.save, size: 24),
                                      label: const Text(
                                        "Update Patient Details",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                        minimumSize: const Size(double.infinity, 56),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.arrow_back),
                                      label: const Text("Cancel"),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: secondaryColor,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(color: Colors.grey.shade300),
                                        minimumSize: const Size(double.infinity, 56),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(Color primaryColor, Color secondaryColor) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medical_services, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "CHW Portal",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Community Health Worker",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildNavItem(Icons.dashboard, "Dashboard", primaryColor),
                _buildNavItem(Icons.group, "Patients", primaryColor, true),
                _buildNavItem(Icons.assignment, "Screenings", primaryColor),
                _buildNavItem(Icons.medical_services, "Diagnostics", primaryColor),
                _buildNavItem(Icons.report, "Reports", primaryColor),
              ],
            ),
          ),

          // Current Patient Info
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Current Patient",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _patient?.name ?? "Loading...",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // User Profile
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CHW Name",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Community Health Worker",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
    );
  }

  Widget _buildNavItem(IconData icon, String title, Color primaryColor, [bool isActive = false]) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 20),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
      ),
    );
  }

  Widget _buildWebCard(String title, IconData icon, Color primaryColor,
      Color secondaryColor, Color bgColor, List<Widget> children) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTextField(
      TextEditingController controller,
      String label,
      bool isRequired,
      Color primaryColor,
      Color secondaryColor,
      Color bgColor, {
        TextInputType inputType = TextInputType.text,
        IconData? icon,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label + (isRequired ? " *" : ""),
              style: TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          style: TextStyle(color: secondaryColor, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: bgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: isRequired ? (v) => v == null || v.isEmpty ? "Please enter $label" : null : null,
        ),
      ],
    );
  }

  Widget _buildWebTextArea(TextEditingController controller, String label, int maxLines,
      Color primaryColor, Color secondaryColor, Color bgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: secondaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: secondaryColor, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: bgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color secondaryColor, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                color: color ?? secondaryColor,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Original Mobile Layout (updated with direct colors)
  Widget _buildMobileLayout() {
    final primaryColor = Color(0xFF2196F3);
    final secondaryColor = Color(0xFF666666);
    final bgColor = Colors.grey[900];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Patient Details", style: TextStyle(color: Colors.white)),
        backgroundColor: secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(_nameController, "Name", primaryColor, isRequired: true),
                _buildTextField(_ageController, "Age", primaryColor, inputType: TextInputType.number),
                _buildTextField(_phoneController, "Phone", primaryColor, inputType: TextInputType.phone),
                _buildTextField(_medHistoryController, "Medication History", primaryColor, maxLines: 2),
                _buildTextField(_comorbiditiesController, "Comorbidities", primaryColor),
                _buildTextField(_appetiteController, "Appetite", primaryColor),
                _buildTextField(_weightController, "Weight (kg)", primaryColor, inputType: TextInputType.number),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _savePatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text("Save Changes", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      Color primaryColor, {
        TextInputType inputType = TextInputType.text,
        bool isRequired = false,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: primaryColor,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          contentPadding: const EdgeInsets.only(bottom: 4),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white38),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
        validator: isRequired ? (v) => v == null || v.isEmpty ? "Enter $label" : null : null,
      ),
    );
  }
}