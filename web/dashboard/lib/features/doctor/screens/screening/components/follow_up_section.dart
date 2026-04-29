import 'package:flutter/material.dart';
import 'package:tbcare_main/core/constants.dart';
import '../../../models/ai_case_model.dart';


class FollowUpSection extends StatefulWidget {
  final AiCaseModel caseData;

  const FollowUpSection({super.key, required this.caseData});

  @override
  State<FollowUpSection> createState() => _FollowUpSectionState();
}

class _FollowUpSectionState extends State<FollowUpSection> {
  final TextEditingController _followUpNotesController =
      TextEditingController();
  String? _finalVerdict;

  final List<String> mockTestUploads = [
    'https://dummyupload.com/lab1.pdf',
    'https://dummyupload.com/result2.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text("Uploaded Test Results", style: _titleStyle()),
        const SizedBox(height: 10),
        ...mockTestUploads.map(
          (url) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file, size: 20, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    url,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.download_rounded,
                    size: 18,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _finalVerdict,
          decoration: InputDecoration(
            labelText: "Final Diagnosis",
            labelStyle: TextStyle(color: Colors.white70),
            filled: true,
            fillColor: secondaryColor,
            border: OutlineInputBorder(),
          ),
          dropdownColor: secondaryColor,
          style: TextStyle(color: Colors.white),
          items: ['TB', 'Not TB']
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value, style: TextStyle(color: Colors.white)),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _finalVerdict = value),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _followUpNotesController,
          maxLines: 3,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Final Remarks",
            labelStyle: TextStyle(color: Colors.white70),
            hintText: "e.g., prescribe medication, recommend treatment...",
            hintStyle: TextStyle(color: Colors.white60),
            filled: true,
            fillColor: secondaryColor,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              // future Firebase call placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Final verdict saved."),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: Icon(Icons.check_circle_outline),
            label: Text("Confirm Diagnosis"),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
          ),
        ),
      ],
    );
  }

  TextStyle _titleStyle() =>
      TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white);
}

/*import 'package:flutter/material.dart';
import 'package:tb_care/models/ai_case_model.dart';
import 'package:tb_care/models/lab_test_model.dart';
import 'package:tb_care/services/lab_test_service.dart';
import 'package:tb_care/services/diagnosis_service.dart';
import '../../constants.dart';

class FollowUpSection extends StatefulWidget {
  final AiCaseModel caseData;
  final String doctorId; // pass doctorId from parent

  const FollowUpSection({
    super.key,
    required this.caseData,
    required this.doctorId,
  });

  @override
  State<FollowUpSection> createState() => _FollowUpSectionState();
}

class _FollowUpSectionState extends State<FollowUpSection> {
  final TextEditingController _followUpNotesController =
      TextEditingController();
  String? _finalVerdict;
  List<LabTestModel> labTests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLabTests();
  }

  Future<void> _loadLabTests() async {
    try {
      final tests = await LabTestService.getLabTests(
        patientId: widget.caseData.patientId,
        screeningId: widget.caseData.screeningId,
      );
      if (!mounted) return;
      setState(() {
        labTests = tests;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading lab tests: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveFinalVerdict() async {
    if (_finalVerdict == null || _finalVerdict!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a final diagnosis")),
      );
      return;
    }

    try {
      await DiagnosisService.updateFinalVerdict(
        patientId: widget.caseData.patientId,
        screeningId: widget.caseData.screeningId,
        doctorId: widget.doctorId,
        status: _finalVerdict!,
        notes: _followUpNotesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Final diagnosis saved successfully"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error saving final verdict: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save final diagnosis"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text("Uploaded Test Results", style: _titleStyle()),
              const SizedBox(height: 10),
              if (labTests.isEmpty)
                Text("No tests uploaded yet",
                    style: TextStyle(color: Colors.white54))
              else
                ...labTests.map(
                  (test) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file,
                            size: 20, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${test.testName} • ${test.status}",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (test.fileUrl != null)
                          IconButton(
                            onPressed: () {
                              // TODO: open PDF/Image preview if required
                            },
                            icon: Icon(Icons.download_rounded,
                                size: 18, color: primaryColor),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Only show final diagnosis form if still reviewable
              if (widget.caseData.status == 'Needs Lab Test') ...[
                DropdownButtonFormField<String>(
                  value: _finalVerdict,
                  decoration: InputDecoration(
                    labelText: "Final Diagnosis",
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: secondaryColor,
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: secondaryColor,
                  style: TextStyle(color: Colors.white),
                  items: ['TB', 'Not TB']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value,
                              style: TextStyle(color: Colors.white)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _finalVerdict = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _followUpNotesController,
                  maxLines: 3,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Final Remarks",
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: "e.g., prescribe medication, recommend treatment...",
                    hintStyle: TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: secondaryColor,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _saveFinalVerdict,
                    icon: Icon(Icons.check_circle_outline),
                    label: Text("Confirm Diagnosis"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor),
                  ),
                ),
              ] else ...[
                Text(
                  "Final Verdict: ${widget.caseData.status}",
                  style: TextStyle(color: Colors.greenAccent, fontSize: 16),
                ),
              ]
            ],
          );
  }

  TextStyle _titleStyle() =>
      TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white);
}
*/
