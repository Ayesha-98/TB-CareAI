import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

// 🎨 Updated Color Scheme
const primaryColor = Color(0xFF1B4D3E); // Dark green
const secondaryColor = Color(0xFFFFFFFF); // White
const bgColor = Color(0xFFFFFFFF); // White

class DietRecommendationScreen extends StatefulWidget {
  const DietRecommendationScreen({super.key});

  @override
  State<DietRecommendationScreen> createState() => _DietRecommendationScreenState();
}

class _DietRecommendationScreenState extends State<DietRecommendationScreen> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController appetiteController = TextEditingController();
  final TextEditingController symptomsController = TextEditingController();
  final TextEditingController diseaseController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();

  String gender = 'Male';
  String activityLevel = 'Low';
  String foodPreference = 'Vegetarian';

  bool loading = false;


  final String _geminiApiKey = "AIzaSyAW4gEBkV6NI9wZ6EbDc49YOCvafQoYwKU";
  final String _modelName = "models/gemini-2.5-flash";

  String get patientId => FirebaseAuth.instance.currentUser?.uid ?? "";

  final String _systemPrompt = '''
You are TB-CareAI Diet Assistant, a medical nutrition expert specializing in tuberculosis (TB) recovery.

Important rules:
1. ONLY provide diet and nutrition advice for TB patients
2. Use simple, clear language with bullet points (use • for bullet points)
3. Include specific foods, meal timing, and portion suggestions
4. Add hydration tips and foods to avoid
5. Keep response concise but informative
6. Do NOT use markdown formatting like **bold** or *italic*
7. Do NOT use asterisks (*) for bullet points - use • instead
8. Use line breaks to separate sections
''';

  Future<void> getDietRecommendation() async {
    if (ageController.text.isEmpty || weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in Age and Weight")),
      );
      return;
    }

    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final userMessage = '''
Generate a personalized TB recovery diet plan for a patient with the following details:

- Age: ${ageController.text} years
- Weight: ${weightController.text} kg
- Gender: $gender
- Appetite Level: ${appetiteController.text.isEmpty ? "Normal" : appetiteController.text}
- Current Symptoms: ${symptomsController.text.isEmpty ? "None reported" : symptomsController.text}
- Existing Diseases/Conditions: ${diseaseController.text.isEmpty ? "None" : diseaseController.text}
- Food Preference: $foodPreference
- Activity Level: $activityLevel
- Allergies: ${allergiesController.text.isEmpty ? "None" : allergiesController.text}

Please provide a complete daily diet plan including:
• Morning (breakfast)
• Mid-morning snack
• Lunch
• Evening snack
• Dinner
• Hydration recommendations
• Foods to avoid

Focus on foods that boost immunity, aid weight gain (if underweight), and support TB recovery.
''';

    try {
      // ✅ Google Gemini API call (same as ChatBot)
      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/$_modelName:generateContent?key=$_geminiApiKey"
      );

      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": "$_systemPrompt\n\n$userMessage\n\nAssistant:"}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.6,
          "maxOutputTokens": 3048,
          "topP": 0.95,
        }
      };

      print("📤 Sending request to Gemini API for diet plan...");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print("📥 Response status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String generatedPlan = data['candidates'][0]['content']['parts'][0]['text'];

        // ✅ Clean up the response (same as ChatBot)
        generatedPlan = _cleanResponse(generatedPlan);

        await saveDietToFirebase(generatedPlan);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Unknown error';
        print("❌ API Error: $errorMessage");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $errorMessage")),
        );
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  // ✅ Clean up response - remove markdown formatting (same as ChatBot)
  String _cleanResponse(String text) {
    String cleaned = text;

    // Remove **bold** markers
    cleaned = cleaned.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');

    // Remove *italic* markers
    cleaned = cleaned.replaceAll(RegExp(r'\*(.*?)\*'), r'$1');

    // Convert markdown bullet points to plain bullet points
    final lines = cleaned.split('\n');
    final cleanedLines = lines.map((line) {
      if (line.trim().startsWith('*') || line.trim().startsWith('-')) {
        return line.replaceFirst(RegExp(r'^[\s]*[\*\-]\s+'), '• ');
      }
      return line;
    }).toList();

    cleaned = cleanedLines.join('\n');

    // Remove extra newlines
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return cleaned.trim();
  }

  Future<void> saveDietToFirebase(String plan) async {
    final data = {
      'age': int.tryParse(ageController.text) ?? 0,
      'weight': double.tryParse(weightController.text) ?? 0,
      'gender': gender,
      'activityLevel': activityLevel,
      'foodPreference': foodPreference,
      'appetite': appetiteController.text.trim(),
      'symptoms': symptomsController.text.trim(),
      'diseases': diseaseController.text.trim(),
      'allergies': allergiesController.text.trim(),
      'dietPlan': plan,
      'generatedAt': Timestamp.now(),
    };

    await FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .collection('diet_recommendations')
        .doc('latest')
        .set(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Diet plan generated and saved!")),
    );
  }

  InputDecoration fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primaryColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: secondaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("TB Recovery Diet", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "📋 Patient Profile",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 15),

            TextField(controller: ageController, keyboardType: TextInputType.number, decoration: fieldDecoration('Age')),
            const SizedBox(height: 12),
            TextField(controller: weightController, keyboardType: TextInputType.number, decoration: fieldDecoration('Weight (kg)')),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: gender,
              decoration: fieldDecoration('Gender'),
              items: ['Male', 'Female', 'Other'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              onChanged: (val) => setState(() => gender = val!),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: activityLevel,
              decoration: fieldDecoration('Activity Level'),
              items: ['Low', 'Moderate', 'High'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              onChanged: (val) => setState(() => activityLevel = val!),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: foodPreference,
              decoration: fieldDecoration('Preference'),
              items: ['Vegetarian', 'Non-Vegetarian', 'Vegan'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              onChanged: (val) => setState(() => foodPreference = val!),
            ),
            const SizedBox(height: 12),

            TextField(controller: symptomsController, decoration: fieldDecoration('Symptoms')),
            const SizedBox(height: 12),
            TextField(controller: appetiteController, decoration: fieldDecoration('Appetite Level (Low/Medium/High)')),
            const SizedBox(height: 12),
            TextField(controller: diseaseController, decoration: fieldDecoration('Existing Diseases (if any)')),
            const SizedBox(height: 12),
            TextField(controller: allergiesController, decoration: fieldDecoration('Allergies')),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: loading ? null : getDietRecommendation,
              icon: const Icon(Icons.bolt, color: Colors.white),
              label: Text(loading ? "Generating..." : "Generate Diet Plan", style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),

            // --- Display Section (No approval status) ---
            const Text(
              "🍽️ Your Diet Plan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 10),

            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('patients')
                  .doc(patientId)
                  .collection('diet_recommendations')
                  .doc('latest')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: primaryColor),
                  ));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.restaurant_menu, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "No diet plan generated yet.\nFill the form above and click 'Generate Diet Plan'",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final String dietPlan = data['dietPlan'] ?? '';

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: SelectableText(
                    dietPlan,
                    style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}