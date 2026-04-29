import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/doctor/models/patient_model.dart';
import 'package:tbcare_main/features/doctor/models/screening_model.dart';
import 'package:tbcare_main/features/doctor/services/diagnosis_service.dart';

class DiagnoseScreen extends StatefulWidget {
  final PatientModel patient;
  final ScreeningModel screening;

  const DiagnoseScreen({
    super.key,
    required this.patient,
    required this.screening,
  });

  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _testController = TextEditingController();
  String? _selectedDiagnosis;
  bool _showTestField = false;
  bool _isLoading = false;

  final List<String> diagnosisOptions = ['TB', 'Not TB', 'Needs Lab Test'];

  void _onDiagnosisChanged(String? value) {
    setState(() {
      _selectedDiagnosis = value;
      _showTestField = value == 'Needs Lab Test';
    });
  }

  Future<void> _submitDiagnosis() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Authentication error. Please sign in again."),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await DiagnosisService.saveDiagnosisAndLabTest(
        patientId: widget.patient.uid,
        screeningId: widget.screening.screeningId,
        doctorId: currentUser.uid,
        diagnosis: _selectedDiagnosis!,
        notes: _notesController.text.trim(),
        requestedTest: _showTestField ? _testController.text.trim() : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Diagnosis saved successfully"),
          backgroundColor: successColor,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving diagnosis: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to save diagnosis"),
            backgroundColor: errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Diagnose Case"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(largePadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Diagnosis", 
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Select Diagnosis",
                    labelStyle: TextStyle(color: secondaryColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(defaultRadius),
                      borderSide: const BorderSide(color: secondaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(defaultRadius),
                      borderSide: const BorderSide(color: secondaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(defaultRadius),
                      borderSide: const BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: secondaryColor),
                  value: _selectedDiagnosis,
                  validator: (value) => value == null ? "Please select a diagnosis" : null,
                  items: diagnosisOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option, style: const TextStyle(color: secondaryColor)),
                    );
                  }).toList(),
                  onChanged: _onDiagnosisChanged,
                ),
                const SizedBox(height: 16),
                if (_showTestField) ...[
                  TextFormField(
                    controller: _testController,
                    style: const TextStyle(color: secondaryColor),
                    validator: (value) => _showTestField && (value == null || value.trim().isEmpty) ? "Please specify the lab test required" : null,
                    decoration: InputDecoration(
                      labelText: "Requested Test",
                      labelStyle: TextStyle(color: secondaryColor.withOpacity(0.7)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(defaultRadius),
                        borderSide: const BorderSide(color: secondaryColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(defaultRadius),
                        borderSide: const BorderSide(color: secondaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(defaultRadius),
                        borderSide: const BorderSide(color: primaryColor, width: 2),
                      ),
                      hintText: "e.g., Sputum, CBC, etc.",
                      hintStyle: TextStyle(color: secondaryColor.withOpacity(0.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  style: const TextStyle(color: secondaryColor),
                  decoration: InputDecoration(
                    labelText: "Notes (Optional)",
                    labelStyle: TextStyle(color: secondaryColor.withOpacity(0.7)),
                    hintText: "Additional comments, prescription, etc.",
                    hintStyle: TextStyle(color: secondaryColor.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(defaultRadius),
                      borderSide: const BorderSide(color: secondaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(defaultRadius),
                      borderSide: const BorderSide(color: secondaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(defaultRadius),
                      borderSide: const BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitDiagnosis,
                    icon: const Icon(Icons.save),
                    label: const Text("Submit Diagnosis"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(defaultRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}