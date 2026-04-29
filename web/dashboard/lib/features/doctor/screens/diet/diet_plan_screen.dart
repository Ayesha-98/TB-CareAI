import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/doctor/models/patient_model.dart';
import 'package:tbcare_main/features/doctor/models/plan_item_model.dart';
import 'package:tbcare_main/features/doctor/models/diet_recommendation_model.dart';
import 'package:tbcare_main/features/doctor/services/diet_exercise_service.dart';
import 'package:intl/intl.dart';

class DietPlanScreen extends StatefulWidget {
  final PatientModel patient;

  const DietPlanScreen({super.key, required this.patient});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  bool _isLoading = true;
  DietRecommendationModel? _aiPlan;
  
  // Legacy Data
  Map<String, dynamic> _legacyPlans = {};
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _quantityControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Try fetching AI Plan
      final aiData = await DietExerciseService.fetchLatestDietRecommendation(
        widget.patient.uid,
      );
      
      if (aiData != null) {
        if (mounted) {
          setState(() {
            _aiPlan = DietRecommendationModel.fromMap(aiData);
            _isLoading = false;
          });
        }
        return;
      }

      // 2. If no AI plan, fetch legacy plans
      final plans = await DietExerciseService.fetchAllDietPlans(
        widget.patient.uid,
      );
      _legacyPlans = plans;
    } catch (e) {
      debugPrint("Error loading diet data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: $e"), backgroundColor: errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- AI PLAN ACTIONS ---

  Future<void> _approveAIPlan() async {
    try {
      await DietExerciseService.approveDietRecommendation(widget.patient.uid);
      
      if (!mounted) return;
      // Update local state
      if (_aiPlan != null) {
        setState(() {
          _aiPlan = DietRecommendationModel(
            activityLevel: _aiPlan!.activityLevel,
            age: _aiPlan!.age,
            allergies: _aiPlan!.allergies,
            appetite: _aiPlan!.appetite,
            approved: true, // Mark as approved
            dietPlan: _aiPlan!.dietPlan,
            diseases: _aiPlan!.diseases,
            foodPreference: _aiPlan!.foodPreference,
            gender: _aiPlan!.gender,
            generatedAt: _aiPlan!.generatedAt,
            symptoms: _aiPlan!.symptoms,
            weight: _aiPlan!.weight,
          );
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Diet Plan Approved Successfully"), backgroundColor: successColor),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to approve: $e"), backgroundColor: errorColor),
        );
      }
    }
  }


  // --- LEGACY ACTIONS ---

  Future<void> _addLegacyItem(String timeOfDay) async {
    final name = _nameControllers[timeOfDay]?.text.trim() ?? '';
    final quantity = _quantityControllers[timeOfDay]?.text.trim() ?? '';

    if (name.isEmpty || quantity.isEmpty) return;

    final newItem = PlanItemModel(name: name, quantity: quantity);

    try {
      final docId = _legacyPlans[timeOfDay]['docId'];
      await DietExerciseService.addDietItem(
        patientId: widget.patient.uid,
        planDocId: docId,
        item: newItem,
      );
      
      if (!mounted) return;
      _nameControllers[timeOfDay]?.clear();
      _quantityControllers[timeOfDay]?.clear();
      
      // Reload legacy plans
      final plans = await DietExerciseService.fetchAllDietPlans(widget.patient.uid);
      if (mounted) {
        setState(() => _legacyPlans = plans);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add item: $e"), backgroundColor: errorColor),
        );
      }
    }
  }

  Future<void> _deleteLegacyItem(String timeOfDay, PlanItemModel item) async {
    try {
      final docId = _legacyPlans[timeOfDay]['docId'];
      await DietExerciseService.deleteDietItem(
        patientId: widget.patient.uid,
        planDocId: docId,
        item: item,
      );
      final plans = await DietExerciseService.fetchAllDietPlans(widget.patient.uid);
      if (mounted) {
        setState(() => _legacyPlans = plans);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete item: $e"), backgroundColor: errorColor),
        );
      }
    }
  }

  Future<void> _approveLegacyPlan(String timeOfDay) async {
    try {
      final docId = _legacyPlans[timeOfDay]['docId'];
      await DietExerciseService.approveDietPlan(
        patientId: widget.patient.uid,
        planDocId: docId,
      );
      final plans = await DietExerciseService.fetchAllDietPlans(widget.patient.uid);
      if (mounted) {
        setState(() => _legacyPlans = plans);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Plan approved."), backgroundColor: successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to approve plan: $e"), backgroundColor: errorColor),
        );
      }
    }
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Diet Recommendation",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _aiPlan != null
              ? _buildAIUI(_aiPlan!)
              : _buildLegacyUI(),
    );
  }

  Widget _buildAIUI(DietRecommendationModel plan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header with Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Personalized AI Plan",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: secondaryColor),
              ),
              if (plan.generatedAt != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy').format(plan.generatedAt!),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Patient Stats Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("Age", "${plan.age ?? widget.patient.age}", Icons.cake_outlined, Colors.white),
                _buildVerticalDivider(),
                _buildStatItem("Weight", "${plan.weight ?? 'N/A'} kg", Icons.monitor_weight_outlined, Colors.white),
                _buildVerticalDivider(),
                 _buildStatItem("Gender", "${plan.gender ?? widget.patient.gender}", Icons.person_outline, Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Details Grid
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 420,
              childAspectRatio: 3.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            children: [
              _buildDetailCard("Activity Level", plan.activityLevel ?? "N/A", Icons.directions_run_outlined),
              _buildDetailCard("Appetite", plan.appetite ?? "N/A", Icons.restaurant_menu_outlined),
              _buildDetailCard("Food Pref", plan.foodPreference ?? "N/A", Icons.fastfood_outlined),
              _buildDetailCard("Allergies", plan.allergies ?? "None", Icons.warning_amber_rounded),
            ],
          ),
          const SizedBox(height: 32),

          // Plan Content
          Text(
            "Recommended Diet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: secondaryColor),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: _buildFormattedText(plan.dietPlan),
          ),
          
          const SizedBox(height: 40),

          // Approve Button
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 52,
              width: plan.approved ? 240 : 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: plan.approved
                    ? []
                    : [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: ElevatedButton.icon(
                onPressed: plan.approved ? null : _approveAIPlan,
                icon: Icon(plan.approved ? Icons.check_circle_rounded : Icons.verified_user_rounded, size: 22),
                label: Text(
                  plan.approved ? "Approved" : "Approve Plan",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: plan.approved ? successColor : primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: successColor.withOpacity(0.9),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                  shadowColor: Colors.transparent, // Handled by container
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
         Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.white.withOpacity(0.2));
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: secondaryColor.withOpacity(0.6), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: secondaryColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Simple Markdown-like formatter
  Widget _buildFormattedText(String text) {
    List<Widget> spans = [];
    final lines = text.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) {
        spans.add(const SizedBox(height: 8));
        continue;
      }
      
      // Check for bullet points
      if (line.trim().startsWith('-')) {
        String content = line.trim().substring(1).trim();
         spans.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("•", style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold, height: 1.4)),
                const SizedBox(width: 16),
                Expanded(child: _parseRichText(content)),
              ],
            ),
          ),
        );
      } else {
        // Normal text
        spans.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _parseRichText(line),
          ),
        );
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: spans);
  }

  Widget _parseRichText(String text) {
    List<InlineSpan> children = [];
    final RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    
    int lastMatchEnd = 0;
    
    for (final Match match in exp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        children.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(color: secondaryColor, fontSize: 16, height: 1.6),
        ));
      }
      
      children.add(TextSpan(
        text: match.group(1),
        style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold, fontSize: 16, height: 1.6),
      ));
      
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < text.length) {
      children.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(color: secondaryColor, fontSize: 16, height: 1.6),
      ));
    }
    
    return RichText(text: TextSpan(children: children));
  }

  // --- LEGACY UI ---
  
  Widget _buildLegacyUI() {
    if (_legacyPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note, size: 60, color: secondaryColor.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              "No diet plans available",
              style: TextStyle(color: secondaryColor.withOpacity(0.5), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(defaultPadding),
          children: _legacyPlans.entries.map((entry) {
        // ... (Keep existing legacy item builder logic but modernized slightly if needed)
        // For brevity and minimal risk, using a simplified version of the old code structure
        
        final timeOfDay = entry.key;
        final planData = entry.value;
        final List<PlanItemModel> items = List<PlanItemModel>.from(planData['items']);
        final bool isApproved = planData['approvedByDoctor'] ?? false;
        
         _nameControllers.putIfAbsent(timeOfDay, () => TextEditingController());
         _quantityControllers.putIfAbsent(timeOfDay, () => TextEditingController());

        return Card(
           margin: const EdgeInsets.only(bottom: 20),
           elevation: 0,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
           child: Padding(
             padding: const EdgeInsets.all(20),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   children: [
                     Text(planData['title'] ?? timeOfDay, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                     const Spacer(),
                     if (isApproved)
                       Chip(label: const Text("Approved", style: TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: successColor)
                     else
                       TextButton(onPressed: () => _approveLegacyPlan(timeOfDay), child: const Text("Approve"))
                   ],
                 ),
                 const Divider(),
                 
                 // Items List
                 ...items.map((item) => ListTile(
                   contentPadding: EdgeInsets.zero,
                   title: Text(item.name, style: TextStyle(fontWeight: FontWeight.w600, color: secondaryColor)),
                   subtitle: Text(item.quantity),
                   trailing: IconButton(icon: Icon(Icons.delete_outline, color: errorColor), onPressed: () => _deleteLegacyItem(timeOfDay, item)),
                 )),
                 
                 if (items.isEmpty) Text("No items.", style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic)),
                 
                 const SizedBox(height: 16),
                 // Add Item Row
                 Row(
                   children: [
                     Expanded(flex: 3, child: TextField(controller: _nameControllers[timeOfDay], decoration: InputDecoration(hintText: "Item", isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), style: const TextStyle(fontSize: 14))),
                     const SizedBox(width: 8),
                     Expanded(flex: 2, child: TextField(controller: _quantityControllers[timeOfDay], decoration: InputDecoration(hintText: "Qty", isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), style: const TextStyle(fontSize: 14))),
                     const SizedBox(width: 8),
                     IconButton(icon: Icon(Icons.add_circle, color: successColor), onPressed: () => _addLegacyItem(timeOfDay)),
                   ],
                 )
               ],
             ),
           ),
        );
      }).toList(),
        ),
      ),
    );
  }
}