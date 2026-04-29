import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import '../../../models/ai_case_model.dart';
import '../../../services/diagnosis_service.dart';

class CaseActionModal extends StatefulWidget {
  final AiCaseModel caseData;
  final void Function(String diagnosis, String notes, String? requestedTest)?
  onActionSaved;

  const CaseActionModal({
    super.key,
    required this.caseData,
    this.onActionSaved,
  });

  @override
  State<CaseActionModal> createState() => _CaseActionModalState();
}

class _CaseActionModalState extends State<CaseActionModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _requestedTestController =
      TextEditingController();
  String? _diagnosis;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.caseData.doctorNotes ?? '';
    _diagnosis = widget.caseData.status == 'Needs Lab Test'
        ? 'Needs Lab Test'
        : null;
  }

  Future<void> _submitDiagnosis() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final note = _noteController.text.trim();
    final diagnosis = _diagnosis ?? '';
    final requestedTest = _diagnosis == 'Needs Lab Test'
        ? _requestedTestController.text.trim()
        : null;

    setState(() => isSubmitting = true);

    try {
      await DiagnosisService.saveDiagnosisAndLabTest(
        patientId: widget.caseData.patientId,
        screeningId: widget.caseData.screeningId,
        doctorId: FirebaseAuth.instance.currentUser!.uid,
        diagnosis: diagnosis,
        notes: note,
        requestedTest: requestedTest,
      );

      widget.onActionSaved?.call(diagnosis, note, requestedTest);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Doctor's action saved successfully"),
            backgroundColor: successColor,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving action: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save action. Try again."),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Leave 25% margin on left and right for larger screens, otherwise use default padding
    final horizontalPadding = screenWidth > 800 ? screenWidth * 0.25 : 16.0;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        elevation: 15,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        padding: const EdgeInsets.all(28.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medical_services,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Doctor's Action",
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: secondaryColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Patient Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: secondaryColor.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.caseData.patientName,
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: bodySize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildTextField(
                controller: _noteController,
                labelText: "Doctor Notes",
                maxLines: 4,
                icon: Icons.note_alt,
              ),
              const SizedBox(height: 20),

              _buildDropdownField(
                value: _diagnosis,
                labelText: "Diagnosis",
                items: ['TB', 'Not TB', 'Needs Lab Test'],
                onChanged: (value) => setState(() => _diagnosis = value),
                icon: Icons.assignment_turned_in,
                validator: (value) => value == null || value.isEmpty ? 'Please select a diagnosis' : null,
              ),
              const SizedBox(height: 20),

              if (_diagnosis == 'Needs Lab Test')
                Column(
                  children: [
                    _buildTextField(
                      controller: _requestedTestController,
                      labelText: "Requested Test",
                      maxLines: 1,
                      icon: Icons.science,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please specify the requested test' : null,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: warningColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: warningColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Patient will upload test result via app.",
                              style: TextStyle(
                                color: secondaryColor.withOpacity(0.8),
                                fontSize: captionSize,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondaryColor,
                      side: BorderSide(color: secondaryColor.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: bodySize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : _submitDiagnosis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "Save Action",
                            style: TextStyle(
                              fontSize: bodySize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Row(
            children: [
              Icon(icon, size: 16, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                labelText,
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: captionSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(color: secondaryColor, fontSize: bodySize),
          decoration: InputDecoration(
            labelText: icon == null ? labelText : null,
            labelStyle: TextStyle(color: secondaryColor.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: secondaryColor.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: secondaryColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String labelText,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Row(
            children: [
              Icon(icon, size: 16, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                labelText,
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: captionSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          decoration: InputDecoration(
            labelText: icon == null ? labelText : null,
            labelStyle: TextStyle(color: secondaryColor.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: secondaryColor.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: secondaryColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          dropdownColor: Colors.white,
          style: TextStyle(color: secondaryColor, fontSize: bodySize),
          iconEnabledColor: secondaryColor.withOpacity(0.7),
          items: items
              .map(
                (itemValue) => DropdownMenuItem(
                  value: itemValue,
                  child: Text(
                    itemValue,
                    style: TextStyle(color: secondaryColor),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}