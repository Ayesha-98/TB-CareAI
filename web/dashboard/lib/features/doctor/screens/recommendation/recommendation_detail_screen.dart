import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/doctor/models/patient_model.dart';
import 'package:tbcare_main/features/doctor/models/recommendation_model.dart';
import 'package:tbcare_main/features/doctor/services/recommendation_service.dart';
import 'components/add_recommendation_form.dart';
import 'components/recommendation_list_item.dart';
import 'components/empty_state_widget.dart';

class RecommendationDetailScreen extends StatefulWidget {
  final PatientModel patient;

  const RecommendationDetailScreen({super.key, required this.patient});

  @override
  State<RecommendationDetailScreen> createState() =>
      _RecommendationDetailScreenState();
}

class _RecommendationDetailScreenState
    extends State<RecommendationDetailScreen> {
  final TextEditingController _medicalController = TextEditingController();
  final TextEditingController _lifestyleController = TextEditingController();

  bool isSubmitting = false;

  // JAB AUTH HOGA TOU YEH HARDCODED ID REPLACE KRNI
  final String doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _submitRecommendation() async {
    final medical = _medicalController.text.trim();
    final lifestyle = _lifestyleController.text.trim();

    if (medical.isEmpty && lifestyle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Enter at least one recommendation"),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await RecommendationService.addRecommendation(
        patientId: widget.patient.uid,
        doctorId: doctorId,
        medicalAdvice: medical,
        lifestyleAdvice: lifestyle,
      );

      _medicalController.clear();
      _lifestyleController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Recommendation added"),
          backgroundColor: successColor,
        ),
      );
    } catch (e) {
      debugPrint("Error adding recommendation: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to save recommendation"),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          "Recommendations - ${widget.patient.name}",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AddRecommendationForm(
                    medicalController: _medicalController,
                    lifestyleController: _lifestyleController,
                    isSubmitting: isSubmitting,
                    onSubmit: _submitRecommendation,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Text(
                        "Recommendation History",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Divider(color: Colors.grey[200])),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ✅ Fetch latest screening and show recs
                  FutureBuilder<String?>(
                    future: RecommendationService.fetchLatestScreeningId(
                      widget.patient.uid,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return const EmptyStateWidget(
                          icon: Icons.error_outline,
                          title: "Error loading data",
                          subtitle: "Failed to fetch screenings",
                        );
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const EmptyStateWidget(
                          icon: Icons.assessment_outlined,
                          title: "No screenings found",
                          subtitle: "Complete a screening first",
                        );
                      }

                      final screeningId = snapshot.data!;

                      return StreamBuilder<List<RecommendationModel>>(
                        stream: RecommendationService.fetchRecommendations(
                          widget.patient.uid,
                          screeningId,
                        ),
                        builder: (context, recSnapshot) {
                          if (recSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                ),
                              ),
                            );
                          }
                          if (recSnapshot.hasError) {
                            return const EmptyStateWidget(
                              icon: Icons.error_outline,
                              title: "Error loading data",
                              subtitle: "Failed to fetch recommendations",
                            );
                          }
                          if (!recSnapshot.hasData || recSnapshot.data!.isEmpty) {
                            return const EmptyStateWidget(
                              icon: Icons.recommend_outlined,
                              title: "No recommendations yet",
                              subtitle: "Add your first recommendation above",
                            );
                          }

                          final recs = recSnapshot.data!;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recs.length,
                            itemBuilder: (context, index) {
                              final rec = recs[index];
                              return RecommendationListItem(
                                recommendation: rec,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}