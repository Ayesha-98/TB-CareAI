import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'enhanced_fitness_dashboard.dart';

// 🎨 Modern Color Scheme
const primaryColor = Color(0xFF1B4D3E);
const secondaryColor = Color(0xFF2E7D32);
const accentColor = Color(0xFF81C784);
const backgroundColor = Color(0xFFF8FDF9);
const cardColor = Color(0xFFFFFFFF);
const textColor = Color(0xFF333333);
const dashboardButtonColor = Color(0xFF2196F3);

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String? _selectedAppetite;
  String? _selectedDisease;
  bool _loading = false;
  bool _checkingExistingData = true;
  String? _recommendedExercise;
  double? _calorieTarget;
  double? _exerciseDuration;
  String? _exerciseDescription;

  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _appId = "7166aaaa";
  final String _apiKey = "900ab12fd49c4dc71ab24921817c3f3d";

  @override
  void initState() {
    super.initState();
    _checkExistingExerciseData();
  }

  Future<void> _checkExistingExerciseData() async {
    if (user == null) {
      if (mounted) setState(() => _checkingExistingData = false);
      return;
    }

    try {
      final plansSnapshot = await _firestore
          .collection("patients")
          .doc(user!.uid)
          .collection("exercise_plans")
          .limit(1)
          .get();

      if (plansSnapshot.docs.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _navigateToFitnessDashboard();
        });
        return;
      }

      final exerciseSnapshot = await _firestore
          .collection("patients")
          .doc(user!.uid)
          .collection("exercise")
          .limit(1)
          .get();

      if (exerciseSnapshot.docs.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _navigateToFitnessDashboard();
        });
        return;
      }

      final sessionsSnapshot = await _firestore
          .collection("patients")
          .doc(user!.uid)
          .collection("exercise_sessions")
          .limit(1)
          .get();

      if (sessionsSnapshot.docs.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _navigateToFitnessDashboard();
        });
        return;
      }
    } catch (e) {
      debugPrint('❌ Error checking plans: $e');
    } finally {
      if (mounted) setState(() => _checkingExistingData = false);
    }
  }

  void _navigateToFitnessDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedFitnessDashboard(),
      ),
          (route) => false,
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phone_android,
                size: 80,
                color: primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                "📱 Mobile App Required",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      "Please use the TB Care mobile app for exercise tracking",
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem("Step-by-step exercise guidance"),
                    _buildFeatureItem("Real-time activity tracking"),
                    _buildFeatureItem("Exercise timer and progress"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Return to Dashboard"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    if (_checkingExistingData) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text("Exercise Recommendation"),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              SizedBox(height: 16),
              Text(
                "Checking your exercise plan...",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_recommendedExercise != null) {
      return _buildMobileRecommendation();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("Exercise Recommendation"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Get Your Exercise Plan",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Fill in your details for a personalized TB-friendly exercise recommendation",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildMobileTextField("Age", _ageController, TextInputType.number),
                        const SizedBox(height: 12),
                        _buildMobileTextField("Weight (kg)", _weightController, TextInputType.number),
                        const SizedBox(height: 12),
                        _buildMobileTextField("Height (cm)", _heightController, TextInputType.number),
                        const SizedBox(height: 12),
                        _buildMobileDropdown(
                          "Appetite Level",
                          _selectedAppetite,
                          ["Low", "Medium", "High"],
                              (val) => setState(() => _selectedAppetite = val),
                        ),
                        const SizedBox(height: 12),
                        _buildMobileDropdown(
                          "TB Condition",
                          _selectedDisease,
                          ["Active", "Recovered", "Latent"],
                              (val) => setState(() => _selectedDisease = val),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _getExerciseRecommendation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search, size: 18),
                                SizedBox(width: 8),
                                Text("Get Recommendation"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTextField(String label, TextEditingController controller, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: "Enter $label",
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildMobileDropdown(
      String label,
      String? value,
      List<String> items,
      void Function(String?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: Text("Select $label", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                items: items
                    .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileRecommendation() {
    final exerciseType = _determineExerciseType(_recommendedExercise ?? '');

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("Exercise Plan Ready"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getExerciseTypeIcon(exerciseType),
                          color: _getExerciseTypeColor(exerciseType),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _recommendedExercise!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _exerciseDescription!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMobileMetric("Calories", "${_calorieTarget?.toStringAsFixed(0)} kcal"),
                        _buildMobileMetric("Duration", "${_exerciseDuration?.toStringAsFixed(0)} min"),
                        _buildMobileMetric("Type", _getExerciseTypeText(exerciseType)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Routine",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._getRoutineForExercise(exerciseType).map((step) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_forward, size: 14, color: primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _navigateToFitnessDashboard,
                icon: const Icon(Icons.dashboard, size: 20),
                label: const Text("Go to Fitness Dashboard"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dashboardButtonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMetric(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Future<void> _getExerciseRecommendation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    final query =
        "light home exercises for TB patient with ${_selectedAppetite ?? 'medium'} appetite and ${_selectedDisease ?? 'Active'} condition, no gym equipment";

    final url = Uri.parse("https://trackapi.nutritionix.com/v2/natural/exercise");

    final body = jsonEncode({
      "query": query,
      "gender": "male",
      "weight_kg": double.parse(_weightController.text),
      "height_cm": double.parse(_heightController.text),
      "age": int.parse(_ageController.text)
    });

    try {
      final response = await http.post(
        url,
        headers: {
          "x-app-id": _appId,
          "x-app-key": _apiKey,
          "Content-Type": "application/json"
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final exercises = data['exercises'];

        if (exercises != null && exercises.isNotEmpty) {
          final name = exercises[0]['name'] ?? "Light Stretching";
          final calories = exercises[0]['nf_calories'] ?? 50.0;
          final duration = exercises[0]['duration_min'] ?? 15.0;

          final mappedExercise = _mapExerciseName(name);

          setState(() {
            _recommendedExercise = mappedExercise['name'];
            _calorieTarget = calories.toDouble();
            _exerciseDuration = duration.toDouble();
            _exerciseDescription = mappedExercise['description'];
          });

          await _saveToFirestore(_recommendedExercise!, _calorieTarget!, _exerciseDescription!, _exerciseDuration!);
        } else {
          _useFallbackExercise();
        }
      } else {
        _useFallbackExercise();
      }
    } catch (e) {
      _showError("Failed to connect: $e");
      _useFallbackExercise();
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _useFallbackExercise() {
    final fallbackExercises = [
      {
        'name': 'Deep Breathing Exercises',
        'calories': 45.0,
        'duration': 15.0,
        'description': 'Improve lung capacity with controlled breathing patterns'
      },
      {
        'name': 'Light Walking in Place',
        'calories': 60.0,
        'duration': 20.0,
        'description': 'Gentle walking while standing to improve circulation'
      },
    ];

    final exercise = fallbackExercises[DateTime.now().millisecondsSinceEpoch % fallbackExercises.length];

    setState(() {
      _recommendedExercise = exercise['name'] as String;
      _calorieTarget = exercise['calories'] as double;
      _exerciseDuration = exercise['duration'] as double;
      _exerciseDescription = exercise['description'] as String;
    });

    _saveToFirestore(_recommendedExercise!, _calorieTarget!, _exerciseDescription!, _exerciseDuration!);
  }

  Map<String, String> _mapExerciseName(String apiExercise) {
    final exerciseMap = {
      'running': 'Walking in Place',
      'jogging': 'Light Marching',
      'cycling': 'Leg Raises',
      'swimming': 'Arm Circles',
      'weight lifting': 'Bodyweight Squats',
      'push up': 'Wall Push-ups',
      'pull up': 'Arm Stretches',
      'sit up': 'Seated Leg Lifts',
      'squat': 'Chair Squats',
      'yoga': 'Breathing Exercises',
      'general gym': 'Home Exercises',
      'walking': 'Indoor Walking',
    };

    final lowerExercise = apiExercise.toLowerCase();
    var matchedExercise = 'Light Stretching';

    for (var entry in exerciseMap.entries) {
      if (lowerExercise.contains(entry.key)) {
        matchedExercise = entry.value;
        break;
      }
    }

    final descriptions = {
      'Walking in Place': 'Gentle walking while standing, improves circulation',
      'Light Marching': 'Slow marching to build leg strength',
      'Leg Raises': 'Lying down leg lifts for core strength',
      'Arm Circles': 'Rotating arms to improve shoulder mobility',
      'Bodyweight Squats': 'Using own weight for leg strength',
      'Wall Push-ups': 'Gentle push-ups against wall for upper body',
      'Arm Stretches': 'Stretching arms to improve flexibility',
      'Seated Leg Lifts': 'Leg exercises while sitting down',
      'Chair Squats': 'Squats using chair for support and safety',
      'Breathing Exercises': 'Deep breathing for lung capacity improvement',
      'Home Exercises': 'Light physical activity suitable for home',
      'Light Stretching': 'Gentle stretching for flexibility and relaxation',
      'Indoor Walking': 'Walking around your home space safely',
    };

    return {
      'name': matchedExercise,
      'description': descriptions[matchedExercise] ?? 'Light physical activity for TB recovery',
    };
  }

  Future<void> _saveToFirestore(String exercise, double calories, String description, double duration) async {
    final userId = user?.uid ?? "unknown_user";
    final date = DateTime.now().toIso8601String().split('T')[0];

    try {
      String exerciseType = _determineExerciseType(exercise);
      int targetValue = _getTargetValueForExercise(exerciseType, duration.toInt());
      List<String> routine = _getRoutineForExercise(exerciseType);

      await _firestore.collection("patients").doc(userId).collection("exercise").doc(date).set({
        "age": _ageController.text,
        "weight": _weightController.text,
        "height": _heightController.text,
        "appetite": _selectedAppetite,
        "disease": _selectedDisease,
        "recommendedExercise": exercise,
        "calorieTarget": calories,
        "description": description,
        "duration": duration,
        "exerciseType": exerciseType,
        "targetValue": targetValue,
        "routine": routine,
        "timestamp": FieldValue.serverTimestamp(),
        "date": date,
        "userId": userId,
      }, SetOptions(merge: true));

      await _firestore.collection("patients").doc(userId).collection("exercise_plans").doc(date).set({
        'exercise': exercise,
        'type': exerciseType,
        'duration': duration,
        'calorieTarget': calories,
        'description': description,
        'targetValue': targetValue,
        'routine': routine,
        'condition': _selectedDisease ?? 'Active',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'date': date,
        'userId': userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("🎉 Exercise plan saved successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          _navigateToFitnessDashboard();
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving exercise: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _determineExerciseType(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();

    if (lowerName.contains('breathing') || lowerName.contains('breath')) return 'breathing';
    if (lowerName.contains('walking') || lowerName.contains('walk') || lowerName.contains('steps') || lowerName.contains('marching')) return 'walking';
    if (lowerName.contains('stretch') || lowerName.contains('stretching') || lowerName.contains('flexibility')) return 'stretching';
    if (lowerName.contains('strength') || lowerName.contains('lift') || lowerName.contains('squat') || lowerName.contains('push-up')) return 'strength';

    return 'stretching';
  }

  int _getTargetValueForExercise(String type, int duration) {
    switch (type) {
      case 'walking': return 1000;
      case 'breathing': return 10;
      case 'stretching': return duration;
      case 'strength': return duration;
      default: return duration;
    }
  }

  List<String> _getRoutineForExercise(String type) {
    switch (type) {
      case 'breathing':
        return [
          'Inhale deeply through nose (4 seconds)',
          'Hold breath (4 seconds)',
          'Exhale slowly through mouth (6 seconds)',
          'Rest (2 seconds)',
        ];
      case 'stretching':
        return [
          'Warm up with gentle movements',
          'Perform full body stretches',
          'Focus on major muscle groups',
          'Cool down with light stretching',
        ];
      case 'walking':
        return [
          'Start with slow pace',
          'Increase to comfortable pace',
          'Maintain steady rhythm',
          'Cool down with slower pace',
        ];
      case 'strength':
        return [
          'Warm up with light cardio',
          'Perform strength exercises',
          'Focus on proper form throughout',
          'Cool down and stretch',
        ];
      default:
        return [
          'Follow the exercise instructions',
          'Maintain proper form',
          'Breathe steadily throughout',
          'Stop if you feel any discomfort',
        ];
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getExerciseTypeColor(String type) {
    switch (type) {
      case 'walking': return Colors.blue;
      case 'breathing': return Colors.green;
      case 'stretching': return Colors.orange;
      case 'strength': return Colors.purple;
      default: return primaryColor;
    }
  }

  IconData _getExerciseTypeIcon(String type) {
    switch (type) {
      case 'walking': return Icons.directions_walk;
      case 'breathing': return Icons.air;
      case 'stretching': return Icons.fitness_center;
      case 'strength': return Icons.accessible;
      default: return Icons.emoji_people;
    }
  }

  String _getExerciseTypeText(String type) {
    switch (type) {
      case 'walking': return 'Walking';
      case 'breathing': return 'Breathing';
      case 'stretching': return 'Stretching';
      case 'strength': return 'Strength';
      default: return 'Exercise';
    }
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWebLayout() : _buildMobileLayout();
  }
}