import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🎨 Color Scheme
const primaryColor = Color(0xFF1B4D3E);
const secondaryColor = Color(0xFF424242);
const accentColor = Color(0xFFE0F2F1);
const bgColor = Color(0xFFF8F9FA);

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  // Input controllers
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String? _selectedGender;
  String? _selectedAppetite;
  String? _selectedDisease;

  // States
  bool _loading = false;
  bool _generatedToday = false; // 🔒 THE LOCK: True if target set for specific date
  String? _recommendedExercise;
  double? _calorieTarget;
  bool _showForm = true;

  // Pedometer
  StreamSubscription<StepCount>? _stepSubscription;
  int _baseSensorValue = -1;
  int _stepsToday = 0;
  double _caloriesBurned = 0.0;

  List<Map<String, dynamic>> _weeklyData = [];
  Timer? _firestoreSaveTimer;

  @override
  void initState() {
    super.initState();
    _initializeEverything();
  }

  // --- INITIALIZATION ---
  Future<void> _initializeEverything() async {
    await _loadLocalState();
    await _initializeTracking();
    await _loadTodayTargetFromFirestoreOrFallback();
    _startPeriodicFirestoreSave();
  }

  // 🕒 Current Date String (Updates automatically)
  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<String> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If no user is logged in, redirect to signin
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signin');
      }
      return ""; // Return empty string as fallback
    }
    return user.uid;
  }

  // --- LOCAL STATE MANAGEMENT ---
  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('weekly_history') ?? [];
    _weeklyData = historyJson.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList();

    final today = _today;
    _baseSensorValue = prefs.getInt('base_sensor') ?? -1;
    _stepsToday = prefs.getInt('steps_$today') ?? 0;
    _caloriesBurned = prefs.getDouble('calories_$today') ?? 0.0;
    _calorieTarget = prefs.getDouble('target_$today');
    _recommendedExercise = prefs.getString('exercise_$today');

    // 🔒 CHECK: Has the user generated a target specifically for this date string?
    _generatedToday = prefs.getBool('generated_$today') ?? false;

    // LOGIC:
    // 1. If generated today -> Lock form.
    // 2. If NOT generated today (New Day) -> Open form (even if we have old data loaded).
    if (_generatedToday && _calorieTarget != null) {
      _showForm = false;
    } else {
      _showForm = true;
    }

    setState(() {});
  }

  Future<void> _saveLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today;

    await prefs.setInt('base_sensor', _baseSensorValue);
    await prefs.setInt('steps_$today', _stepsToday);
    await prefs.setDouble('calories_$today', _caloriesBurned);

    if (_calorieTarget != null) await prefs.setDouble('target_$today', _calorieTarget!);
    if (_recommendedExercise != null) await prefs.setString('exercise_$today', _recommendedExercise!);

    // 🔒 SAVE THE LOCK for this specific date
    await prefs.setBool('generated_$today', _generatedToday);
  }

  Future<void> _saveWeeklyData(String date, double target, double burned, bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> history = _weeklyData.map((e) => Map<String, dynamic>.from(e)).toList();
    history.removeWhere((item) => item['date'] == date);
    history.add({'date': date, 'target': target, 'burned': burned, 'completed': completed});
    history.sort((a, b) => a['date'].compareTo(b['date']));
    if (history.length > 7) history = history.sublist(history.length - 7);
    await prefs.setStringList('weekly_history', history.map((e) => jsonEncode(e)).toList());
    setState(() => _weeklyData = history);
  }

  // --- PEDOMETER ---
  Future<void> _initializeTracking() async {
    var status = await Permission.activityRecognition.status;
    if (!status.isGranted) status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _startPedometer();
    }
  }

  void _startPedometer() {
    _stepSubscription?.cancel();
    _stepSubscription = Pedometer.stepCountStream.listen((event) => _onSensorStep(event.steps));
  }

  Future<void> _onSensorStep(int rawValue) async {
    if (_baseSensorValue == -1) {
      final prefs = await SharedPreferences.getInstance();
      _baseSensorValue = prefs.getInt('base_sensor') ?? rawValue;
      if (prefs.getInt('base_sensor') == null) await prefs.setInt('base_sensor', _baseSensorValue);
    }
    final steps = (rawValue - _baseSensorValue).clamp(0, 999999);
    setState(() {
      _stepsToday = steps;
      _caloriesBurned = _stepsToday * 0.035;
    });
    await _saveLocalState();
  }

  // --- FIRESTORE & FALLBACK LOGIC ---
  Future<void> _loadTodayTargetFromFirestoreOrFallback() async {
    final userId = await _getUserId();
    if (userId.isEmpty) return;

    // 1. Check for TODAY'S document
    final doc = await _firestore.collection('patients').doc(userId).collection('exercise').doc(_today).get();

    if (doc.exists) {
      // ✅ Target Exists for Today
      setState(() {
        _generatedToday = true; // Lock it
        _calorieTarget = (doc['calorieTarget'] ?? 0).toDouble();
        _recommendedExercise = doc['recommendedExercise'];
        _showForm = false; // Hide form
      });
    } else {
      // ❌ New Day (No target yet)
      // Fetch the MOST RECENT target to use as a placeholder
      final lastSnapshot = await _firestore.collection('patients').doc(userId).collection('exercise').orderBy('timestamp', descending: true).limit(1).get();

      if (lastSnapshot.docs.isNotEmpty) {
        final last = lastSnapshot.docs.first.data();
        setState(() {
          // Use yesterday's data as placeholder
          _calorieTarget = (last['calorieTarget'] ?? 0).toDouble();
          _recommendedExercise = last['recommendedExercise'];

          // 🔓 UNLOCK: It's a new day, so allow generation
          _generatedToday = false;
          _showForm = true; // Show form to remind them to calculate
        });
      } else {
        // First time user
        setState(() {
          _showForm = true;
          _generatedToday = false;
        });
      }
    }
    await _saveLocalState();
  }

  Future<void> _saveToFirestore(String exercise, double target, double burned) async {
    final userId = await _getUserId();
    if (userId.isEmpty) return;

    await _firestore.collection('patients').doc(userId).collection('exercise').doc(_today).set({
      "recommendedExercise": exercise,
      "calorieTarget": target,
      "caloriesBurned": burned,
      "timestamp": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _startPeriodicFirestoreSave() {
    _firestoreSaveTimer?.cancel();
    _firestoreSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_calorieTarget != null) {
        await _saveToFirestore(_recommendedExercise ?? "Unknown", _calorieTarget!, _caloriesBurned);
        final completed = _caloriesBurned >= (_calorieTarget ?? 0);
        await _saveWeeklyData(_today, _calorieTarget ?? 0, _caloriesBurned, completed);
      }
    });
  }

  // --- CALCULATION LOGIC ---
  Future<void> _calculateExerciseTarget() async {
    // 🔒 GUARD CLAUSE: Prevent multiple generations
    if (_generatedToday) {
      _showError("Target already set for today! Come back tomorrow.");
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));

    try {
      final int age = int.parse(_ageController.text);
      final double weight = double.parse(_weightController.text);
      final double height = double.parse(_heightController.text);

      // BMR Calc
      double bmr = (_selectedGender == "Male")
          ? (10 * weight) + (6.25 * height) - (5 * age) + 5
          : (10 * weight) + (6.25 * height) - (5 * age) - 161;

      double targetBurn = 0.0;
      String activityName = "Walking";

      if (_selectedDisease == "Active") {
        targetBurn = bmr * 0.10;
        activityName = "Slow Walk / Light Stretch";
      }
      else if (_selectedDisease == "Recovered") {
        targetBurn = bmr * 0.20;
        activityName = "Brisk Walking";
      }
      else {
        targetBurn = bmr * 0.30;
        activityName = "Jogging / Active Steps";
      }

      if (_selectedAppetite == "Low") {
        targetBurn = targetBurn * 0.7;
      }

      targetBurn = (targetBurn / 10).round() * 10.0;

      setState(() {
        _recommendedExercise = activityName;
        _calorieTarget = targetBurn;
        _generatedToday = true; // 🔒 LOCK IT NOW
        _showForm = false; // Hide form
      });

      await _saveLocalState();
      await _saveToFirestore(activityName, targetBurn, _caloriesBurned);
      await _saveWeeklyData(_today, targetBurn, _caloriesBurned, _caloriesBurned >= targetBurn);
      _showSuccess("Target Calculated! Locked until tomorrow.");
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProgress() async {
    if (_calorieTarget == null) return _showError("No target available.");
    final completed = _caloriesBurned >= _calorieTarget!;
    await _saveToFirestore(_recommendedExercise ?? "Unknown", _calorieTarget!, _caloriesBurned);
    await _saveWeeklyData(_today, _calorieTarget!, _caloriesBurned, completed);
    await _saveLocalState();
    _showSuccess(completed ? "Target Reached! Great job!" : "Progress Saved.");
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: primaryColor));

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _firestoreSaveTimer?.cancel();
    super.dispose();
  }

  // --- UI SECTION ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildCustomAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCollapsibleForm(),
                    const SizedBox(height: 20),
                    _buildMainDashboard(),
                    const SizedBox(height: 25),
                    const Text("Weekly History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: secondaryColor)),
                    const SizedBox(height: 10),
                    _buildWeeklyList(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return SliverAppBar(
      expandedHeight: 80.0,
      floating: false,
      pinned: true,
      backgroundColor: bgColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          "Exercise Tracker",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 22),
        ),
      ),
      actions: [
        IconButton(
          // 🔒 Button only visible if it is a New Day or form forced open
          icon: Icon(_showForm ? Icons.keyboard_arrow_up : Icons.tune, color: primaryColor),
          onPressed: () {
            // Optional: prevent opening form if already generated, or allow viewing only
            if (_generatedToday) {
              _showError("Target already set for today.");
            } else {
              setState(() => _showForm = !_showForm);
            }
          },
        )
      ],
    );
  }

  Widget _buildCollapsibleForm() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _showForm ? null : 0,
      child: _showForm
          ? Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Set Today's Target", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                    // 🔒 Lock Icon
                    if (_generatedToday) const Icon(Icons.lock, color: Colors.grey, size: 18),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildModernInput(_ageController, "Age", Icons.cake)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildModernDropdown("Gender", _selectedGender, ["Male", "Female"], (v) => setState(() => _selectedGender = v), Icons.person)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildModernInput(_weightController, "Weight(kg)", Icons.monitor_weight)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildModernInput(_heightController, "Height(cm)", Icons.height)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildModernDropdown("Appetite", _selectedAppetite, ["Low", "Medium", "High"], (v) => setState(() => _selectedAppetite = v), Icons.restaurant)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildModernDropdown("TB Phase", _selectedDisease, ["Active", "Recovered", "Latent"], (v) => setState(() => _selectedDisease = v), Icons.local_hospital)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    // 🔒 DISABLE BUTTON if already generated today
                    onPressed: (_loading || _generatedToday) ? null : _calculateExerciseTarget,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_generatedToday ? "Come back tomorrow" : "Calculate Safe Target", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _generatedToday ? Colors.grey : Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          : Container(),
    );
  }

  Widget _buildMainDashboard() {
    final double target = _calorieTarget ?? 1;
    final double progressPercent = (target == 0) ? 0 : (_caloriesBurned / target).clamp(0.0, 1.0);

    return Column(
      children: [
        if (_recommendedExercise != null)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_services_outlined, color: primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Medical Recommendation", style: TextStyle(fontSize: 12, color: secondaryColor)),
                      Text(_recommendedExercise!, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),

        Stack(
          alignment: Alignment.center,
          children: [
            CircularPercentIndicator(
              radius: 100.0,
              lineWidth: 15.0,
              percent: progressPercent,
              animation: true,
              circularStrokeCap: CircularStrokeCap.round,
              backgroundColor: Colors.grey.shade200,
              progressColor: primaryColor,
              footer: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton.icon(
                  onPressed: _saveProgress,
                  icon: const Icon(Icons.save_alt, size: 18, color: Colors.white),
                  label: const Text("Save Daily Progress", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_walk, color: primaryColor, size: 30),
                Text(
                  "$_stepsToday",
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: secondaryColor),
                ),
                const Text("STEPS", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),

        const SizedBox(height: 30),

        Row(
          children: [
            Expanded(child: _buildStatCard("Target", "${_calorieTarget?.toInt() ?? 0}", "kcal", Icons.flag, Colors.blue.shade50, Colors.blue)),
            const SizedBox(width: 15),
            Expanded(child: _buildStatCard("Burned", "${_caloriesBurned.toInt()}", "kcal", Icons.local_fire_department, Colors.orange.shade50, Colors.orange)),
          ],
        )
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: secondaryColor)),
          RichText(
            text: TextSpan(
              text: unit,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              children: [TextSpan(text: " $title", style: const TextStyle(fontWeight: FontWeight.w500))],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyList() {
    if (_weeklyData.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("No history yet. Start moving!", style: TextStyle(color: Colors.grey.shade400))));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _weeklyData.length,
      separatorBuilder: (c, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final data = _weeklyData[index];
        final completed = data['completed'] == true;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: completed ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.1)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: completed ? Colors.green.shade50 : Colors.red.shade50,
              child: Icon(completed ? Icons.check : Icons.close, color: completed ? Colors.green : Colors.red, size: 18),
            ),
            title: Text(data['date'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("${data['burned'].toInt()} / ${data['target'].toInt()} kcal", style: const TextStyle(fontSize: 12)),
            trailing: completed ? const Icon(Icons.emoji_events, color: Colors.amber) : const SizedBox(),
          ),
        );
      },
    );
  }

  Widget _buildModernInput(TextEditingController c, String label, IconData icon) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      validator: (v) => (v == null || v.isEmpty) ? "" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: primaryColor),
        filled: true,
        fillColor: accentColor,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }

  Widget _buildModernDropdown(String label, String? value, List<String> items, Function(String?) onChanged, IconData icon) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      isDense: true,
      items: items.map((e) => DropdownMenuItem(
          value: e,
          child: Text(e, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)
      )).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? "" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: primaryColor),
        filled: true,
        fillColor: accentColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }
}