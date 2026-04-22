import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tbcare_main/features/chw/services/lab_test_service.dart';
import 'package:tbcare_main/core/app_constants.dart';

class LabTestScreen extends StatefulWidget {
  const LabTestScreen({super.key});

  @override
  State<LabTestScreen> createState() => _LabTestScreenState();
}

class _LabTestScreenState extends State<LabTestScreen> {
  final LabTestService _service = LabTestService();
  File? _pickedFile;
  String? _selectedTestDocId; // 🔥 Store the document ID to update

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final patientId = args['patientId'] ?? '';
    final screeningId = args['screeningId'] ?? '';
    final patientName = args['patientName'] ?? 'Unnamed Patient';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Lab Test - $patientName"),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _service.getSinglePatientLabTest(patientId, screeningId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Loading Lab Test Information...",
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: errorColor.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: errorColor, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      "Error Loading Lab Test Data",
                      style: TextStyle(
                        color: errorColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No Lab Test Data Found",
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Unable to load lab test information",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final status = (data['status'] ?? '').toString().toLowerCase();
          final requestedTests = (data['requestedTests'] as List?)?.cast<String>() ?? [];
          final uploadedTests = (data['uploadedTests'] as List?) ?? [];
          final pendingTests = (data['pendingTests'] as List?) ?? [];
          final allTests = (data['allTests'] as List?) ?? [];
          final hasUploadedTests = data['hasUploadedTests'] ?? false;
          final isPending = status == 'needs_lab_test' || status.contains('needs');

          // 🔥 DEBUG: Print all tests to see document IDs
          print("\n📊 [DEBUG] All lab tests found:");
          for (var i = 0; i < allTests.length; i++) {
            final test = allTests[i] as Map<String, dynamic>;
            print("   Test $i: ${test['testName']} - ID: ${test['id']} - docId: ${test['docId']} - status: ${test['status']}");
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                // Patient Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                    border: Border.all(color: Colors.grey.shade100),
                  ),
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
                            child: Icon(
                              Icons.person,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientName,
                                  style: TextStyle(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Patient ID: ${patientId.substring(0, 8)}...",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.shade200),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.medical_information,
                            color: isPending ? warningColor : successColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Lab Test Status",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasUploadedTests
                                      ? "UPLOADED"
                                      : "NEEDS LAB TEST",
                                  style: TextStyle(
                                    color: hasUploadedTests ? successColor : warningColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 🔥 Show requested tests
                if (requestedTests.isNotEmpty)
                  _buildRequestedTestsCard(requestedTests, hasUploadedTests, allTests),

                const SizedBox(height: 24),

                // 🔥 Show pending tests (not uploaded yet)
                if (pendingTests.isNotEmpty && !hasUploadedTests)
                  _buildPendingTestsCard(pendingTests),

                const SizedBox(height: 24),

                // 🔥 Show uploaded tests if any
                if (uploadedTests.isNotEmpty)
                  _buildUploadedTestsCard(uploadedTests),

                // 🔥 Show upload button ONLY if not uploaded yet
                if (!hasUploadedTests && requestedTests.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file, size: 24),
                      label: const Text(
                        "Upload Lab Test Results",
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
                      ),
                      onPressed: () => _showUploadDialog(
                          patientId,
                          screeningId,
                          requestedTests,
                          pendingTests
                      ),
                    ),
                  )
                else if (hasUploadedTests)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: successColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: successColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Lab Test Uploaded",
                          style: TextStyle(
                            color: successColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Help text
                if (!hasUploadedTests && requestedTests.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "Please upload the requested lab test results. The doctor will review them.",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestedTestsCard(List<String> requestedTests, bool hasUploadedTests, List<dynamic> allTests) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasUploadedTests ? successColor.withOpacity(0.1) : warningColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medical_services,
                  color: hasUploadedTests ? successColor : warningColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Doctor Requested Tests",
                style: TextStyle(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: requestedTests.map((test) {
              // 🔥 Find if this test already has a document
              String? existingDocId;
              for (final labTest in allTests) {
                final testData = labTest as Map<String, dynamic>;
                final testName = (testData['testName'] ?? '').toString();
                if (testName.toLowerCase() == test.toLowerCase()) {
                  existingDocId = testData['id']?.toString();
                  break;
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasUploadedTests ? Colors.green.withOpacity(0.05) : Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: hasUploadedTests ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasUploadedTests ? Icons.check_circle : Icons.circle_outlined,
                      color: hasUploadedTests ? successColor : primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test,
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 14,
                              fontWeight: hasUploadedTests ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (existingDocId != null && !hasUploadedTests)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Document ID: ${existingDocId.substring(0, 8)}...",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTestsCard(List<dynamic> pendingTests) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pending_actions,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded( // 🔥 FIX: Wrap with Expanded
                child: Text(
                  "Pending Tests (Ready to Upload)",
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: pendingTests.map((test) {
              final testData = test as Map<String, dynamic>;
              final testName = testData['testName']?.toString() ?? 'Unknown Test';
              final docId = testData['id']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pending, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded( // 🔥 FIX: Wrap with Expanded
                          child: Text(
                            testName,
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (docId.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Will update document: ${docId.substring(0, 8)}...",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  Widget _buildUploadedTestsCard(List<dynamic> uploadedTests) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: successColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_done,
                  color: successColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Uploaded Lab Tests",
                style: TextStyle(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: uploadedTests.map((test) {
              final testData = test as Map<String, dynamic>;
              final testName = testData['testName']?.toString() ?? 'Unknown Test';
              final String uploadTime;
              if (testData['uploadedAt'] != null) {
                uploadTime = (testData['uploadedAt'] as Timestamp).toDate().toString().substring(0, 16);
              } else {
                uploadTime = 'Recently';
              }
              final docId = testData['id']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: successColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: successColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: successColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            testName,
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Uploaded: $uploadTime",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    if (docId.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          "Document ID: ${docId.substring(0, 8)}...",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _showUploadDialog(
      String patientId,
      String screeningId,
      List<String> requestedTests,
      List<dynamic> pendingTests
      ) async {
    String selectedTest = requestedTests.isNotEmpty ? requestedTests[0] : '';
    final testNameController = TextEditingController(
        text: requestedTests.isNotEmpty ? requestedTests[0] : ''
    );

    // 🔥 Find the document ID for the selected test
    String? selectedDocId;
    if (pendingTests.isNotEmpty) {
      for (final test in pendingTests) {
        final testData = test as Map<String, dynamic>;
        final testName = (testData['testName'] ?? '').toString();
        if (testName == selectedTest) {
          selectedDocId = testData['id']?.toString();
          break;
        }
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)
            ),
            title: const Text("Upload Lab Test"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedDocId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      "Will update existing document",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                // Show dropdown if there are requested tests
                if (requestedTests.isNotEmpty)
                  Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedTest,
                        decoration: const InputDecoration(
                          labelText: "Select Test",
                          border: OutlineInputBorder(),
                        ),
                        items: requestedTests.map((test) {
                          return DropdownMenuItem<String>(
                            value: test,
                            child: Text(test),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTest = value ?? '';
                            testNameController.text = selectedTest;

                            // 🔥 Find document ID for newly selected test
                            selectedDocId = null;
                            for (final test in pendingTests) {
                              final testData = test as Map<String, dynamic>;
                              final testName = (testData['testName'] ?? '').toString();
                              if (testName == selectedTest) {
                                selectedDocId = testData['id']?.toString();
                                break;
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Or enter custom test name:",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),

                // Text field for test name
                TextField(
                  controller: testNameController,
                  decoration: const InputDecoration(
                    labelText: "Test Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("Select & Upload File"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    final pickedFile = await _service.pickFile();
                    if (pickedFile != null) {
                      setState(() => _pickedFile = pickedFile);
                      final url = await _service.uploadToCloudinary(pickedFile);

                      // 🔥 Find the correct document ID before saving
                      if (selectedDocId == null && pendingTests.isNotEmpty) {
                        for (final test in pendingTests) {
                          final testData = test as Map<String, dynamic>;
                          final testName = (testData['testName'] ?? '').toString();
                          if (testName == selectedTest) {
                            selectedDocId = testData['id']?.toString();
                            break;
                          }
                        }
                      }

                      await _service.saveLabTest(
                        patientId: patientId,
                        screeningId: screeningId,
                        testName: testNameController.text.isNotEmpty
                            ? testNameController.text
                            : selectedTest,
                        fileUrl: url,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Lab test uploaded successfully!")
                            )
                        );
                        // Refresh the screen
                        Navigator.pop(context);
                        setState(() {});
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No file selected")),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          );
        },
      ),
    );
  }
}