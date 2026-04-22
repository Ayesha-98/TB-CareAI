import 'package:flutter/material.dart';
import 'package:tbcare_main/features/chw/models/patient_detail_model.dart';
import 'package:tbcare_main/features/chw/services/patient_detail_service.dart';
import 'package:tbcare_main/core/app_constants.dart';

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

  static const Color textColor = Colors.white;

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
      diagnosisStatus: _patient!.diagnosisStatus, // preserved for doctor
      imageUrl: null,
    );

    setState(() => _loading = true);
    try {
      await _service.updatePatientDetail(widget.chwId, updatedPatient);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Patient updated successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating patient: $e")),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Patient Details", style: TextStyle(color: textColor)),
        backgroundColor: secondaryColor,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(_nameController, "Name", isRequired: true),
                _buildTextField(_ageController, "Age", inputType: TextInputType.number),
                _buildTextField(_phoneController, "Phone", inputType: TextInputType.phone),
                _buildTextField(_medHistoryController, "Medication History", maxLines: 2),
                _buildTextField(_comorbiditiesController, "Comorbidities"),
                _buildTextField(_appetiteController, "Appetite"),
                _buildTextField(_weightController, "Weight (kg)", inputType: TextInputType.number),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _savePatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Save Changes", style: TextStyle(fontSize: 16)),
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
      String label, {
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
        style: const TextStyle(color: textColor, fontSize: 16),
        cursorColor: primaryColor,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          contentPadding: const EdgeInsets.only(bottom: 4),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white38),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
        validator: isRequired ? (v) => v == null || v.isEmpty ? "Enter $label" : null : null,
      ),
    );
  }
}
