import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

// 🎨 Modern Color Scheme
const primaryColor = Color(0xFF1B4D3E);
const secondaryColor = Color(0xFF2E7D32);
const accentColor = Color(0xFF81C784);
const backgroundColor = Color(0xFFF8FDF9);
const cardColor = Color(0xFFFFFFFF);
const textColor = Color(0xFF333333);
const lightTextColor = Color(0xFF666666);
const errorColor = Color(0xFFD32F2F);
const warningColor = Color(0xFFFF9800);
const successColor = Color(0xFF4CAF50);

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
  bool _isButtonDisabled = false;
  String patientId = "";

  final String _geminiApiKey = "AIzaSyAW4gEBkV6NI9wZ6EbDc49YOCvafQoYwKU";
  final String _modelName = "models/gemini-2.5-flash";

  final String _systemPrompt = '''
You are TB-CareAI Diet Assistant, a medical nutrition expert specializing in tuberculosis (TB) recovery.

Important rules:
1. ONLY provide diet and nutrition advice for TB patients
2. Use simple, clear language with bullet points (use • for bullet points)
3. Include specific foods, meal timing, and portion suggestions
4. Add hydration tips and foods to avoid
5. Keep response detailed and complete - provide a FULL daily meal plan
6. Do NOT cut off or shorten your response
7. Do NOT use markdown formatting like **bold** or *italic*
8. Do NOT use asterisks (*) for bullet points - use • instead
9. Use line breaks to separate sections
''';

  final Map<String, String?> _validationErrors = {};

  final List<String> validGenders = ['Male', 'Female', 'Other'];
  final List<String> validActivityLevels = ['Low', 'Moderate', 'High'];
  final List<String> validFoodPreferences = ['Vegetarian', 'Non-Vegetarian', 'Vegan'];
  final List<String> validAppetiteLevels = ['Good', 'Moderate', 'Poor', 'Very Poor'];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      patientId = user.uid;
    } else {
      patientId = "";
    }
  }

  bool validateAge(String value) {
    if (value.isEmpty) {
      _validationErrors['age'] = 'Age is required';
      return false;
    }
    final age = int.tryParse(value);
    if (age == null) {
      _validationErrors['age'] = 'Age must be a valid number';
      return false;
    }
    if (age < 1 || age > 120) {
      _validationErrors['age'] = 'Age must be between 1 and 120';
      return false;
    }
    _validationErrors.remove('age');
    return true;
  }

  bool validateWeight(String value) {
    if (value.isEmpty) {
      _validationErrors['weight'] = 'Weight is required';
      return false;
    }
    final weight = double.tryParse(value);
    if (weight == null) {
      _validationErrors['weight'] = 'Weight must be a valid number';
      return false;
    }
    if (weight < 20 || weight > 300) {
      _validationErrors['weight'] = 'Weight must be between 20 and 300 kg';
      return false;
    }
    _validationErrors.remove('weight');
    return true;
  }

  bool validateAppetite(String value) {
    if (value.isEmpty) {
      _validationErrors['appetite'] = 'Appetite level is required';
      return false;
    }
    if (!validAppetiteLevels.map((a) => a.toLowerCase()).contains(value.toLowerCase())) {
      _validationErrors['appetite'] = 'Please select: Good, Moderate, Poor, or Very Poor';
      return false;
    }
    _validationErrors.remove('appetite');
    return true;
  }

  bool validateSymptoms(String value) {
    if (value.isEmpty) {
      _validationErrors['symptoms'] = 'Symptoms description is required';
      return false;
    }
    if (value.length < 5) {
      _validationErrors['symptoms'] = 'Please provide more details (minimum 5 characters)';
      return false;
    }
    if (value.length > 500) {
      _validationErrors['symptoms'] = 'Description too long (maximum 500 characters)';
      return false;
    }
    _validationErrors.remove('symptoms');
    return true;
  }

  bool validateDiseases(String value) {
    if (value.isNotEmpty && value.length < 3) {
      _validationErrors['diseases'] = 'Description too short (minimum 3 characters)';
      return false;
    }
    if (value.length > 300) {
      _validationErrors['diseases'] = 'Description too long (maximum 300 characters)';
      return false;
    }
    _validationErrors.remove('diseases');
    return true;
  }

  bool validateAllergies(String value) {
    if (value.isNotEmpty && value.length < 3) {
      _validationErrors['allergies'] = 'Description too short (minimum 3 characters)';
      return false;
    }
    if (value.length > 200) {
      _validationErrors['allergies'] = 'Description too long (maximum 200 characters)';
      return false;
    }
    _validationErrors.remove('allergies');
    return true;
  }

  bool validateAllFields() {
    _validationErrors.clear();
    bool isValid = true;
    isValid &= validateAge(ageController.text.trim());
    isValid &= validateWeight(weightController.text.trim());
    isValid &= validateAppetite(appetiteController.text.trim());
    isValid &= validateSymptoms(symptomsController.text.trim());
    isValid &= validateDiseases(diseaseController.text.trim());
    isValid &= validateAllergies(allergiesController.text.trim());
    return isValid;
  }

  void _showValidationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: warningColor),
            SizedBox(width: 10),
            Text('Validation Errors', style: TextStyle(color: errorColor)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _validationErrors.length,
            itemBuilder: (context, index) {
              final key = _validationErrors.keys.elementAt(index);
              final error = _validationErrors[key]!;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: errorColor),
                    SizedBox(width: 8),
                    Expanded(child: Text('• ${key.replaceFirst(key[0], key[0].toUpperCase())}: $error')),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: primaryColor))),
        ],
      ),
    );
  }

  String _cleanResponse(String text) {
    String cleaned = text;
    cleaned = cleaned.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'\*(.*?)\*'), r'$1');
    final lines = cleaned.split('\n');
    final cleanedLines = lines.map((line) {
      if (line.trim().startsWith('*') || line.trim().startsWith('-')) {
        return line.replaceFirst(RegExp(r'^[\s]*[\*\-]\s+'), '• ');
      }
      return line;
    }).toList();
    cleaned = cleanedLines.join('\n');
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return cleaned.trim();
  }

  Future<void> getDietRecommendation() async {
    if (!validateAllFields()) {
      _showValidationDialog();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Please sign in'), backgroundColor: errorColor),
      );
      return;
    }

    setState(() {
      loading = true;
      _isButtonDisabled = true;
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
''';

    try {
      final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/$_modelName:generateContent?key=$_geminiApiKey");
      final requestBody = {
        "contents": [{"parts": [{"text": "$_systemPrompt\n\n$userMessage\n\nAssistant:"}]}],
        "generationConfig": {"temperature": 0.6, "maxOutputTokens": 4096, "topP": 0.95},
      };

      final response = await http.post(url, headers: {"Content-Type": "application/json"}, body: jsonEncode(requestBody)).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String generatedPlan = data['candidates'][0]['content']['parts'][0]['text'];
        generatedPlan = _cleanResponse(generatedPlan);
        await saveDietToFirebase(generatedPlan);
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error: ${errorData['error']['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Failed to generate diet plan")));
    } finally {
      if (mounted) setState(() { loading = false; _isButtonDisabled = false; });
    }
  }

  Future<void> saveDietToFirebase(String plan) async {
    try {
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
        'userId': patientId,
      };
      await FirebaseFirestore.instance.collection('patients').doc(patientId).collection('diet_recommendations').add(data);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Diet plan generated and saved!"), backgroundColor: successColor));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Failed to save diet plan")));
    }
  }

  void _clearAllFields() {
    ageController.clear();
    weightController.clear();
    appetiteController.clear();
    symptomsController.clear();
    diseaseController.clear();
    allergiesController.clear();
    setState(() {
      gender = 'Male';
      activityLevel = 'Low';
      foodPreference = 'Vegetarian';
      _validationErrors.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("TB Diet Planner"),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Form Fields Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text("Patient Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                    const SizedBox(height: 16),
                    TextField(controller: ageController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Age (years)*", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 12),
                    TextField(controller: weightController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Weight (kg)*", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: gender,
                      decoration: InputDecoration(labelText: "Gender", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: validGenders.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                      onChanged: (val) => setState(() => gender = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: activityLevel,
                      decoration: InputDecoration(labelText: "Activity Level", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: validActivityLevels.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                      onChanged: (val) => setState(() => activityLevel = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: foodPreference,
                      decoration: InputDecoration(labelText: "Food Preference", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: validFoodPreferences.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                      onChanged: (val) => setState(() => foodPreference = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: appetiteController, decoration: InputDecoration(labelText: "Appetite Level", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 12),
                    TextField(controller: symptomsController, decoration: InputDecoration(labelText: "Symptoms", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 12),
                    TextField(controller: diseaseController, decoration: InputDecoration(labelText: "Existing Diseases (optional)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 12),
                    TextField(controller: allergiesController, decoration: InputDecoration(labelText: "Allergies (optional)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: loading ? null : getDietRecommendation,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: loading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text("Generate Diet Plan", style: TextStyle(color: Colors.white)),
                    ),
                    if (_validationErrors.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: errorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: _validationErrors.entries.map((entry) => Row(
                            children: [Icon(Icons.error, size: 16, color: errorColor), SizedBox(width: 8), Expanded(child: Text(entry.value!, style: TextStyle(color: errorColor, fontSize: 12)))],
                          )).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Diet Plans Section
            Text("Your Diet Plans", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 12),

            // Results Panel - Fixed scrolling
            patientId.isEmpty
                ? Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text("Please Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ]),
            )
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('patients').doc(patientId).collection('diet_recommendations').orderBy('generatedAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }
                if (snapshot.hasError) {
                  return Container(padding: const EdgeInsets.all(40), child: Center(child: Text("Error: ${snapshot.error}")));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                      Icon(Icons.restaurant_menu_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text("No Diet Plans Yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text("Generate a diet plan using the form above", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                    ]),
                  );
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final dietPlan = data['dietPlan'] ?? '';
                    final date = (data['generatedAt'] as Timestamp).toDate();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.check_circle, color: Colors.green),
                          ),
                          title: Text("Diet Plan - ${date.day}/${date.month}/${date.year}", style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(data['foodPreference'] ?? 'Unknown'),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                              child: SelectableText(dietPlan, style: TextStyle(fontSize: 14, height: 1.6, color: textColor)),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}